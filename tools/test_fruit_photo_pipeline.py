"""Offline safeguards for the local fruit photo pipeline."""

import csv
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import fruit_photo_pipeline as pipeline


class PhotoPipelineTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_licence_filter_rejects_share_alike_even_with_cc0(self):
        metadata = {
            "LicenseShortName": {"value": "CC0"},
            "LicenseUrl": {"value": pipeline.CC0_URL},
            "Artist": {"value": "Test photographer"},
            "ImageDescription": {"value": "Durio zibethinus fruit"},
        }
        info = {"mime": "image/jpeg", "extmetadata": metadata,
                "url": "https://upload.wikimedia.org/wikipedia/commons/test.jpg",
                "descriptionurl": "https://commons.wikimedia.org/wiki/File:Durio_zibethinus.jpg"}
        page = {"title": "File:Durio zibethinus.jpg", "imageinfo": [info],
                "revisions": [{"slots": {"main": {"content": "{{CC0}} {{CC-BY-SA-4.0}}"}}}]}
        fruit = {"id": "FR041", "name": "Durian", "scientificName": "Durio zibethinus"}
        self.assertIsNone(pipeline.commons_candidate(page, fruit))
        page["revisions"][0]["slots"]["main"]["content"] = "{{CC0}}"
        self.assertEqual(pipeline.commons_candidate(page, fruit)["license"], "CC0")

    def test_review_requires_explicit_choice_and_flags_ambiguous_record(self):
        fruit = {"id": "FR099", "name": "Example", "scientificName": "Example spp.",
                 "researchStatus": "legacy_review_needed"}
        page = pipeline.review_html([fruit], [])
        self.assertIn("NO ACCEPTABLE IMAGE", page)
        self.assertIn("Extra identity review required", page)
        self.assertIn("if(!chosen)", page)
        self.assertIn("fruit_photo_selections.json", page)

    def test_inaturalist_requires_individual_cc0_and_named_creator(self):
        fruit = {"id": "FR041", "name": "Durian", "scientificName": "Durio zibethinus"}
        observation = {"id": 123, "taxon": {"name": "Durio zibethinus"}}
        photo = {"id": 456, "license_code": "cc-by-nc", "attribution": "Example photographer",
                 "url": "https://static.inaturalist.org/photos/456/square.jpg"}
        self.assertIsNone(pipeline.inat_candidate(photo, observation, fruit))
        photo["license_code"] = "cc0"
        photo["attribution"] = "no rights reserved"
        self.assertIsNone(pipeline.inat_candidate(photo, observation, fruit))
        photo["attribution"] = "Example photographer"
        candidate = pipeline.inat_candidate(photo, observation, fruit)
        self.assertEqual(candidate["license"], "CC0")
        self.assertEqual(candidate["original_image_url"], "https://static.inaturalist.org/photos/456/original.jpg")

    def test_selection_cannot_approve_hold_or_missing_candidate(self):
        candidates = self.root / "candidates.csv"
        pipeline.write_csv(candidates, pipeline.CANDIDATE_FIELDS, [])
        selections = self.root / "selections.json"
        selections.write_text(json.dumps({"version": 1, "selections": [
            {"fruit_id": "FR048", "candidate_number": 1}]}), encoding="utf-8")
        args = type("Args", (), {"candidates": candidates, "selections": selections})()
        with self.assertRaises(pipeline.PipelineError):
            pipeline.selected_rows(args, {"FR041"}, [{"fruit_id": "FR048", "approval_status": ""}])

    def test_selection_rejects_candidate_changed_after_review(self):
        candidates = self.root / "candidates.csv"
        row = dict.fromkeys(pipeline.CANDIDATE_FIELDS, "")
        row.update({"fruit_id": "FR041", "fruit_name": "Durian", "scientific_name": "Durio zibethinus",
                    "candidate_number": "1", "source_page_url": "https://commons.wikimedia.org/wiki/File:new.jpg",
                    "original_image_url": "https://upload.wikimedia.org/new.jpg"})
        pipeline.write_csv(candidates, pipeline.CANDIDATE_FIELDS, [row])
        selections = self.root / "selections.json"
        selections.write_text(json.dumps({"version": 1, "selections": [{"fruit_id": "FR041",
            "candidate_number": 1, "source_page_url": "https://commons.wikimedia.org/wiki/File:old.jpg",
            "original_image_url": "https://upload.wikimedia.org/old.jpg"}]}), encoding="utf-8")
        args = type("Args", (), {"candidates": candidates, "selections": selections})()
        with self.assertRaisesRegex(pipeline.PipelineError, "changed since human review"):
            pipeline.selected_rows(args, {"FR041"}, [{"fruit_id": "FR041", "fruit_name": "Durian",
                "scientific_name": "Durio zibethinus", "approval_status": ""}])

    def test_replacing_one_manifest_row_preserves_approved_bytes(self):
        path = self.root / "manifest.csv"
        approved = b'FR001,Mango,"old, preserved",approved\r\n'
        path.write_bytes(b"fruit_id,fruit_name,note,approval_status\r\n" + approved +
                         b"FR041,Durian,,\r\n")
        pipeline.replace_manifest_row(path, "FR041", {
            "fruit_id": "FR041", "fruit_name": "Durian", "note": "new",
            "approval_status": "approved"})
        self.assertIn(approved, path.read_bytes())
        with path.open(encoding="utf-8", newline="") as stream:
            rows = list(csv.DictReader(stream))
        self.assertEqual(rows[1]["approval_status"], "approved")

    def test_webp_conversion_downsizes_without_upscaling(self):
        import cv2
        import numpy as np
        image = np.zeros((240, 320, 3), dtype=np.uint8)
        ok, source = cv2.imencode(".jpg", image)
        self.assertTrue(ok)
        webp = pipeline.convert_webp(source.tobytes())
        path = self.root / "test.webp"
        path.write_bytes(webp)
        _, width, height = pipeline.inspect_webp(path)
        self.assertEqual((width, height), (320, 240))

    def test_fixture_finalize_then_validate(self):
        import cv2
        import numpy as np
        image = np.full((300, 400, 3), 90, dtype=np.uint8)
        ok, encoded = cv2.imencode(".jpg", image)
        self.assertTrue(ok)
        seed = self.root / pipeline.DEFAULTS["seed"]
        queue = self.root / pipeline.DEFAULTS["queue"]
        manifest = self.root / pipeline.DEFAULTS["manifest"]
        candidates = self.root / pipeline.DEFAULTS["candidates"]
        selections = self.root / pipeline.DEFAULTS["selections"]
        seed.parent.mkdir(parents=True)
        queue.parent.mkdir(parents=True)
        seed.write_text(json.dumps({"fruits": [{"id": "FR041", "name": "Durian",
            "scientificName": "Durio zibethinus",
            "imageAsset": "assets/images/fruits/FR041.webp"}]}), encoding="utf-8")
        queue.write_text("## Safe-to-source batches\n### Batch 1\n| FR041 | Durian | *Durio zibethinus* | path |\n", encoding="utf-8")
        fields, _ = pipeline.read_csv(pipeline.ROOT / pipeline.DEFAULTS["manifest"])
        row = dict.fromkeys(fields, "")
        row.update({"fruit_id": "FR041", "fruit_name": "Durian", "scientific_name": "Durio zibethinus",
                    "image_asset": "assets/images/fruits/FR041.webp"})
        pipeline.write_csv(manifest, fields, [row])
        candidate = dict.fromkeys(pipeline.CANDIDATE_FIELDS, "")
        candidate.update({"fruit_id": "FR041", "fruit_name": "Durian", "scientific_name": "Durio zibethinus",
            "candidate_number": "1", "source_platform": "Wikimedia Commons",
            "source_page_url": "https://commons.wikimedia.org/wiki/File:Durio_zibethinus.jpg",
            "original_image_url": "https://upload.wikimedia.org/wikipedia/commons/test.jpg",
            "creator": "Fixture author", "license": "CC0", "license_url": pipeline.CC0_URL,
            "attribution_required": "false", "candidate_identity_notes": "Fixture fruit verified"})
        pipeline.write_csv(candidates, pipeline.CANDIDATE_FIELDS, [candidate])
        selections.write_text(json.dumps({"version": 1, "selections": [{"fruit_id": "FR041",
            "candidate_number": 1, "source_page_url": candidate["source_page_url"],
            "original_image_url": candidate["original_image_url"]}]}), encoding="utf-8")
        args = type("Args", (), {"root": self.root, "seed": seed, "queue": queue,
            "manifest": manifest, "candidates": candidates, "selections": selections,
            "report": self.root / pipeline.DEFAULTS["report"]})()
        with patch.object(pipeline, "reverify", return_value=candidate), patch.object(
                pipeline, "request_bytes", return_value=encoded.tobytes()):
            pipeline.finalize(args)
        _, rows = pipeline.read_csv(manifest)
        self.assertEqual(rows[0]["approval_status"], "approved")
        self.assertEqual(rows[0]["source_file_sha256"], hashlib.sha256(encoded.tobytes()).hexdigest())
        pipeline.validate(args)


if __name__ == "__main__":
    unittest.main()
