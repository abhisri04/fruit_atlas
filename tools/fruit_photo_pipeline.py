#!/usr/bin/env python3
"""Discover, review, finalize and validate Fruit Atlas photographs.

Run from the repository root:
  python tools/fruit_photo_pipeline.py discover
  python tools/fruit_photo_pipeline.py import-curated --curated docs/image_sources/fruit_photo_curated.csv
  open docs/image_sources/fruit_photo_review.html; export selections JSON
  python tools/fruit_photo_pipeline.py finalize
  python tools/fruit_photo_pipeline.py validate

Discovery is advisory; only a human-exported selection can trigger a download
or approval. The review file opens directly in a browser; its remote thumbnails
need internet. Use --limit 20 and --start-after FR060 for smaller review sets.
Python 3.10+ is required. Install the sole third-party dependency from
tools/requirements-fruit-photo-pipeline.txt for finalize/validate.
"""

from __future__ import annotations

import argparse
import csv
from datetime import date
import hashlib
import html
from html.parser import HTMLParser
import io
import json
from pathlib import Path
import re
import sys
import tempfile
import time
from urllib.parse import urlencode, urlparse, urljoin
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
DEFAULTS = {
    "seed": "assets/data/fruit_atlas_seed.json",
    "queue": "docs/image_sources/fruit_photo_sourcing_queue.md",
    "manifest": "docs/image_sources/fruit_photo_manifest.csv",
    "candidates": "docs/image_sources/fruit_photo_candidates.csv",
    "review": "docs/image_sources/fruit_photo_review.html",
    "selections": "docs/image_sources/fruit_photo_selections.json",
    "report": "docs/image_sources/fruit_photo_validation_report.md",
}
CANDIDATE_FIELDS = ["fruit_id", "fruit_name", "scientific_name", "candidate_number",
                    "source_platform", "source_page_url", "original_image_url", "creator",
                    "license", "license_url", "attribution_required",
                    "candidate_identity_notes", "preview_url"]
CC0_URL = "https://creativecommons.org/publicdomain/zero/1.0/"
BY4_URL = "https://creativecommons.org/licenses/by/4.0/"
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
INAT_API = "https://api.inaturalist.org/v1"
PEXELS_LICENSE_URL = "https://www.pexels.com/license/"
UNSPLASH_LICENSE_URL = "https://unsplash.com/license"
PIXABAY_LICENSE_URL = "https://pixabay.com/service/license-summary/"
USER_AGENT = "FruitAtlasPhotoPipeline/1.0 (local catalogue research; contact via project repository)"
HASH_RE = re.compile(r"^[0-9a-f]{64}$")
FORBIDDEN_LICENSE = re.compile(r"(?:CC[ -]?BY[ -]?(?:NC|ND|SA)|all rights reserved|copyrighted|noncommercial|no derivatives)", re.I)


class PipelineError(Exception):
    pass


class PlainText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def clean_html(value):
    parser = PlainText()
    parser.feed(html.unescape(str(value or "")))
    return re.sub(r"\s+", " ", " ".join(parser.parts)).strip()


class MetaParser(HTMLParser):
    """Extract a small set of metadata from stock-photo pages."""
    def __init__(self):
        super().__init__()
        self.meta = {}
        self.title = ""
        self._in_title = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag.lower() == "meta":
            key = (attrs.get("property") or attrs.get("name") or "").strip().lower()
            value = (attrs.get("content") or "").strip()
            if key and value and key not in self.meta:
                self.meta[key] = value
        elif tag.lower() == "title":
            self._in_title = True

    def handle_endtag(self, tag):
        if tag.lower() == "title":
            self._in_title = False

    def handle_data(self, data):
        if self._in_title:
            self.title += data


def request_text(url, *, max_bytes=4_000_000, timeout=25):
    return request_bytes(url, max_bytes=max_bytes, timeout=timeout).decode("utf-8", errors="replace")


def stock_page_metadata(url):
    parser = MetaParser()
    parser.feed(request_text(url))
    return parser.meta, clean_html(parser.title)


def first_meta(meta, *keys):
    for key in keys:
        value = (meta.get(key.lower()) or "").strip()
        if value:
            return html.unescape(value)
    return ""


def verify_stock_candidate(candidate, fruit):
    """Validate a manually curated Pexels / Unsplash / Pixabay candidate.

    Stock sites can block automated page scraping, so the curated input itself
    carries the exact source page, direct image URL, creator and license that
    were manually researched. We strictly validate platform/source/image hosts
    and the expected platform license before allowing download.
    """
    platform = candidate["source_platform"]
    source_page = (candidate.get("source_page_url") or "").strip()
    original = (candidate.get("original_image_url") or "").strip()
    creator = (candidate.get("creator") or "").strip()
    license_name = (candidate.get("license") or "").strip()
    license_url = (candidate.get("license_url") or "").strip()
    attribution_required = (candidate.get("attribution_required") or "").strip().lower()
    note = (candidate.get("candidate_identity_notes") or "").strip()

    rules = {
        "Pexels": {
            "page_hosts": {"www.pexels.com", "pexels.com"},
            "image_hosts": {"images.pexels.com"},
            "license": "Pexels License",
            "license_url": PEXELS_LICENSE_URL,
            "attribution_required": "false",
        },
        "Unsplash": {
            "page_hosts": {"unsplash.com", "www.unsplash.com"},
            "image_hosts": {"images.unsplash.com", "plus.unsplash.com"},
            "license": "Unsplash License",
            "license_url": UNSPLASH_LICENSE_URL,
            "attribution_required": "false",
        },
        "Pixabay": {
            "page_hosts": {"pixabay.com", "www.pixabay.com"},
            "image_hosts": {"cdn.pixabay.com", "pixabay.com", "www.pixabay.com"},
            "license": "Pixabay Content License",
            "license_url": PIXABAY_LICENSE_URL,
            "attribution_required": "false",
        },
    }
    if platform not in rules:
        raise PipelineError("Unsupported curated stock platform")
    rule = rules[platform]

    page = urlparse(source_page)
    image = urlparse(original)
    if page.scheme != "https" or page.hostname not in rule["page_hosts"]:
        raise PipelineError(f"Invalid {platform} source page URL")
    if image.scheme != "https" or image.hostname not in rule["image_hosts"]:
        raise PipelineError(f"Invalid {platform} image URL")
    if not creator:
        raise PipelineError(f"{platform} candidate is missing creator/photographer")
    if license_name != rule["license"]:
        raise PipelineError(f"{platform} license label mismatch")
    if license_url.rstrip("/") != rule["license_url"].rstrip("/"):
        raise PipelineError(f"{platform} license URL mismatch")
    if attribution_required != rule["attribution_required"]:
        raise PipelineError(f"{platform} attribution flag mismatch")
    if not note:
        raise PipelineError("Curated stock candidate is missing identity verification notes")

    return {
        "fruit_id": fruit["id"],
        "fruit_name": fruit["name"],
        "scientific_name": fruit["scientificName"],
        "source_platform": platform,
        "source_page_url": source_page,
        "original_image_url": original,
        "creator": creator,
        "license": license_name,
        "license_url": license_url,
        "attribution_required": attribution_required,
        "candidate_identity_notes": note,
        "preview_url": original,
    }


def valid_https(url, hosts):
    parsed = urlparse(url)
    return parsed.scheme == "https" and parsed.hostname in hosts and not parsed.username



def commons_thumbnail_url(original_url, width=1280):
    """Return a Wikimedia thumbnail URL for a direct upload.wikimedia.org file URL.

    The original URL is retained in the manifest/provenance. Only the downloaded
    binary uses the thumbnail path to reduce request size and avoid full-original
    rate limiting.
    """
    parsed = urlparse(original_url)
    prefix = "/wikipedia/commons/"
    if parsed.scheme != "https" or parsed.hostname != "upload.wikimedia.org" or not parsed.path.startswith(prefix):
        raise PipelineError("Cannot derive Commons thumbnail URL")
    rel = parsed.path[len(prefix):]
    parts = rel.split("/")
    if len(parts) < 3 or not parts[-1]:
        raise PipelineError("Unexpected Commons upload URL")
    filename = parts[-1]
    thumb_path = prefix + "thumb/" + rel + f"/{width}px-{filename}"
    return parsed._replace(path=thumb_path, query="", fragment="").geturl()

def request_bytes(url, *, max_bytes=30_000_000, timeout=25):
    if urlparse(url).scheme != "https":
        raise PipelineError("Only HTTPS URLs are permitted")
    req = Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json,image/*;q=0.9,*/*;q=0.1"})
    last_error = None
    for attempt in range(3):
        try:
            with urlopen(req, timeout=timeout) as response:
                if (urlparse(response.url).scheme != "https" or
                        urlparse(response.url).hostname != urlparse(url).hostname):
                    raise PipelineError("Cross-host or non-HTTPS redirect blocked")
                data = response.read(max_bytes + 1)
            if len(data) > max_bytes:
                raise PipelineError("Download exceeds size limit")
            return data
        except (OSError, TimeoutError) as exc:
            last_error = exc
            if attempt < 2:
                time.sleep(attempt + 1)
    raise PipelineError(f"Network request failed: {last_error}")


def request_json(url):
    data = json.loads(request_bytes(url, max_bytes=8_000_000).decode("utf-8"))
    if "error" in data:
        raise PipelineError(f"API error: {data['error'].get('info', data['error'])}")
    return data


def api_url(base, **params):
    return base + "?" + urlencode(params)


def read_csv(path):
    with path.open(encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream)
        return list(reader.fieldnames or []), list(reader)


def write_csv(path, fields, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def load_catalog(args):
    fruits = json.loads(args.seed.read_text(encoding="utf-8"))["fruits"]
    fruit_by_id = {item["id"]: item for item in fruits}
    if len(fruit_by_id) != len(fruits):
        raise PipelineError("Duplicate fruit IDs in seed")
    fields, manifest = read_csv(args.manifest)
    by_id = {item["fruit_id"]: item for item in manifest}
    if len(by_id) != len(manifest) or set(by_id) != set(fruit_by_id):
        raise PipelineError("Manifest fruit IDs are not one-to-one with seed")
    for fruit_id, fruit in fruit_by_id.items():
        row = by_id[fruit_id]
        if (row["fruit_name"], row["scientific_name"], row["image_asset"]) != (
            fruit["name"], fruit["scientificName"], f"assets/images/fruits/{fruit_id}.webp"):
            raise PipelineError(f"Manifest identity mismatch: {fruit_id}")
    queue = args.queue.read_text(encoding="utf-8")
    holds = set(re.findall(r"^\| (FR\d{3}) \|[^\n]*\| HOLD PHOTO UNTIL REVIEW \|$", queue, re.M))
    safe_text = queue.split("## Safe-to-source batches", 1)[-1]
    safe = set(re.findall(r"^\| (FR\d{3}) \|", safe_text, re.M))
    if safe & holds or safe | holds != set(fruit_by_id):
        raise PipelineError("Sourcing queue does not partition all manifest fruits")
    return fields, manifest, fruit_by_id, safe, holds


def meta_value(metadata, key):
    return clean_html(metadata.get(key, {}).get("value", ""))


def commons_file(title):
    if not title.startswith("File:"):
        raise PipelineError("Invalid Commons file title")
    query = api_url(COMMONS_API, action="query", format="json", formatversion="2",
                    prop="imageinfo|revisions", titles=title,
                    iiprop="url|size|mime|extmetadata", iiurlwidth=500,
                    rvprop="content", rvslots="main")
    pages = request_json(query).get("query", {}).get("pages", [])
    if len(pages) != 1 or "missing" in pages[0]:
        raise PipelineError("Commons file page unavailable")
    return pages[0]


def commons_candidate(page, fruit):
    title = page.get("title", "")
    info = (page.get("imageinfo") or [{}])[0]
    if not title.startswith("File:") or info.get("mime", "") not in {"image/jpeg", "image/png", "image/webp"}:
        return None
    metadata = info.get("extmetadata", {})
    short = meta_value(metadata, "LicenseShortName")
    license_url = meta_value(metadata, "LicenseUrl")
    revisions = page.get("revisions") or []
    content = revisions[0].get("slots", {}).get("main", {}).get("content", "") if revisions else ""
    if not content or FORBIDDEN_LICENSE.search(content) or FORBIDDEN_LICENSE.search(short):
        return None
    if short.upper() == "CC0" and license_url.rstrip("/") == CC0_URL.rstrip("/") and re.search(r"\{\{\s*CC0\b", content, re.I):
        license_name, license_url, required = "CC0", CC0_URL, "false"
    elif short.upper().replace("-", " ") == "CC BY 4.0" and license_url.rstrip("/") == BY4_URL.rstrip("/") and re.search(r"\{\{\s*CC-BY-4\.0\b", content, re.I):
        license_name, license_url, required = "CC BY 4.0", BY4_URL, "true"
    elif short.lower() in {"public domain", "pd"} and meta_value(metadata, "Copyrighted").lower() == "false":
        match = re.search(r"\{\{\s*(PD-self|PD-user|PD-author|PD-USGov|PD-old-100)\b", content, re.I)
        if not match:
            return None
        license_name, license_url, required = "Public domain", f"https://commons.wikimedia.org/wiki/Template:{match.group(1)}", "false"
    else:
        return None
    creator = meta_value(metadata, "Artist")
    if not creator or creator.lower() in {"unknown", "anonymous"}:
        return None
    description_url = info.get("descriptionurl", "")
    original = info.get("url", "")
    if not valid_https(description_url, {"commons.wikimedia.org"}) or not valid_https(original, {"upload.wikimedia.org"}):
        return None
    scientific = fruit["scientificName"].replace("×", "x").lower()
    searchable = (title + " " + meta_value(metadata, "ImageDescription") + " " + meta_value(metadata, "Categories")).replace("×", "x").replace("_", " ").lower()
    normalized = re.sub(r"[^a-z0-9 ]", " ", searchable)
    tokens = re.sub(r"[^a-z0-9 ]", " ", scientific).split()
    if "spp" in tokens or len(tokens) < 2:
        genus_match = bool(tokens and re.search(r"\b" + re.escape(tokens[0]) + r"\b", normalized))
        if not genus_match:
            return None
        note = "Group-level taxon: human must confirm fruit and representative species."
    elif not all(re.search(r"\b" + re.escape(token) + r"\b", normalized) for token in tokens if token != "x"):
        return None
    else:
        note = "Scientific name appears on Commons file title/description; verify visible fruit and taxon."
    if fruit.get("researchStatus") == "legacy_review_needed" or "×" in scientific or "/" in scientific:
        note += " EXTRA IDENTITY REVIEW REQUIRED."
    return {"fruit_id": fruit["id"], "fruit_name": fruit["name"], "scientific_name": fruit["scientificName"],
            "source_platform": "Wikimedia Commons", "source_page_url": description_url,
            "original_image_url": original, "creator": creator, "license": license_name,
            "license_url": license_url, "attribution_required": required,
            "candidate_identity_notes": note, "preview_url": info.get("thumburl", original)}


def discover_commons(fruit):
    scientific = fruit["scientificName"]
    query = api_url(COMMONS_API, action="query", format="json", formatversion="2",
                    generator="search", gsrsearch=scientific,
                    gsrnamespace=6, gsrlimit=30, prop="imageinfo|revisions",
                    iiprop="url|size|mime|extmetadata", iiurlwidth=500,
                    rvprop="content", rvslots="main")
    pages = request_json(query).get("query", {}).get("pages", [])
    pages.sort(key=lambda page: page.get("index", 9999))
    results = []
    for page in pages:
        candidate = commons_candidate(page, fruit)
        if candidate:
            results.append(candidate)
        if len(results) >= 3:
            break
    return results


def inat_candidate(photo, observation, fruit):
    taxon = observation.get("taxon") or {}
    if taxon.get("name", "").casefold() != fruit["scientificName"].casefold():
        return None
    if str(photo.get("license_code", "")).lower() != "cc0":
        return None  # iNat's cc-by code does not establish a 4.0 version.
    photo_id = photo.get("id")
    creator = str(photo.get("attribution") or "").strip()
    if not photo_id or not creator or creator.lower() in {"no rights reserved", "some rights reserved", "all rights reserved"}:
        return None
    source_page = f"https://www.inaturalist.org/photos/{int(photo_id)}"
    preview = photo.get("url", "")
    if not valid_https(preview, {"static.inaturalist.org", "inaturalist-open-data.s3.amazonaws.com",
                                 "inaturalist-production.s3.amazonaws.com", "inaturalist-production.s3.us-west-2.amazonaws.com"}):
        return None
    original = re.sub(r"/(?:square|small|medium|large)\.", "/original.", preview)
    note = f"Research-grade observation {observation['id']} identifies exact taxon; verify fruit visible."
    if fruit.get("researchStatus") == "legacy_review_needed":
        note += " EXTRA IDENTITY REVIEW REQUIRED."
    return {"fruit_id": fruit["id"], "fruit_name": fruit["name"], "scientific_name": fruit["scientificName"],
            "source_platform": "iNaturalist", "source_page_url": source_page,
            "original_image_url": original, "creator": creator,
            "license": "CC0", "license_url": CC0_URL, "attribution_required": "false",
            "candidate_identity_notes": note, "preview_url": preview}


def discover_inat(fruit, count):
    if "spp." in fruit["scientificName"].lower() or "/" in fruit["scientificName"]:
        return []
    url = api_url(f"{INAT_API}/observations", taxon_name=fruit["scientificName"],
                  quality_grade="research", photos="true", photo_license="cc0",
                  per_page=30, order_by="votes")
    results = []
    for observation in request_json(url).get("results", []):
        for item in observation.get("photos", []):
            try:
                candidate = inat_candidate(item, observation, fruit)
                if candidate:
                    results.append(candidate)
            except (KeyError, ValueError, PipelineError):
                continue
            if len(results) >= count:
                return results
    return results


def discovery_targets(manifest, fruit_by_id, safe, selected_id, limit, start_after=None):
    targets = [fruit_by_id[row["fruit_id"]] for row in manifest
               if row["fruit_id"] in safe and row["approval_status"] != "approved"]
    targets.sort(key=lambda item: item["id"])
    if start_after:
        targets = [fruit for fruit in targets if fruit["id"] > start_after]
    if selected_id:
        targets = [fruit for fruit in targets if fruit["id"] == selected_id]
        if not targets:
            raise PipelineError(f"{selected_id} is approved, held, or absent")
    return targets[:limit] if limit is not None else targets


def review_html(fruits, rows):
    by_id = {}
    for row in rows:
        by_id.setdefault(row["fruit_id"], []).append(row)
    cards = []
    for fruit in fruits:
        fruit_id = fruit["id"]
        notes = []
        if "spp." in fruit["scientificName"].lower() or "/" in fruit["scientificName"] or fruit.get("researchStatus") == "legacy_review_needed":
            notes.append("Extra identity review required: group-level or unresolved record.")
        candidates = by_id.get(fruit_id, [])
        blocks = []
        for candidate in candidates:
            number = candidate["candidate_number"]
            h = lambda key: html.escape(candidate[key], quote=True)
            blocks.append(f'<label class="candidate"><input type="radio" name="{fruit_id}" value="{number}" '
                          f'data-source-page-url="{h("source_page_url")}" data-original-image-url="{h("original_image_url")}">'
                          f'<img loading="lazy" referrerpolicy="no-referrer" src="{h("preview_url")}" alt="Candidate {number}">'
                          f'<strong>Candidate {number}</strong><small>{h("source_platform")} · {h("creator")} · {h("license")}</small>'
                          f'<a href="{h("source_page_url")}" target="_blank" rel="noopener noreferrer">Original source page</a>'
                          f'<small>{h("candidate_identity_notes")}</small></label>')
        if not blocks:
            blocks.append('<p>No candidate passed the automatic licence and identity filters. Research manually.</p>')
        blocks.append(f'<label class="none"><input type="radio" name="{fruit_id}" value="none"> NO ACCEPTABLE IMAGE</label>')
        badge = f'<p class="warning">{" ".join(notes)}</p>' if notes else ""
        cards.append(f'<section><h2>{fruit_id} · {html.escape(fruit["name"])} <em>{html.escape(fruit["scientificName"])}</em></h2>'
                     f'{badge}<div class="grid">{"".join(blocks)}</div></section>')
    ids = json.dumps([fruit["id"] for fruit in fruits]).replace("<", "\\u003c")
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Fruit Atlas photo review</title>
<style>body{{font:16px system-ui;margin:2rem auto;max-width:1250px;padding:0 1rem;background:#f5f7f4;color:#18251b}}
section{{background:white;border:1px solid #d8e2d9;border-radius:10px;margin:1.5rem 0;padding:1.2rem}}
h2 em{{font-size:.85em;font-weight:normal;margin-left:1rem}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:1rem}}
.candidate,.none{{display:flex;flex-direction:column;gap:.4rem;padding:.7rem;border:1px solid #cbd8cb;border-radius:8px;cursor:pointer}}
.candidate:has(input:checked),.none:has(input:checked){{border:3px solid #267c43}}img{{width:100%;height:190px;object-fit:contain;background:#eee}}
small{{display:block}}.warning{{color:#9a3d05;font-weight:bold}}button{{font-size:1rem;padding:.8rem;cursor:pointer}}</style></head><body>
<h1>Fruit Atlas photo review</h1><p>Choose one real photograph per fruit after checking the linked original page, visible fruit, taxon and licence. Nothing is approved until finalize re-verifies it. Thumbnails require internet; this page itself needs no server.</p>
<button id="export">Export selections</button><span id="status"></span>{''.join(cards)}
<script>const ids={ids};document.getElementById('export').onclick=()=>{{
const selections=[];for(const fruit_id of ids){{const chosen=document.querySelector('input[name="'+fruit_id+'"]:checked');
if(!chosen){{alert('Select a candidate or NO ACCEPTABLE IMAGE for '+fruit_id);return;}}
selections.push({{fruit_id,candidate_number:chosen.value==='none'?null:Number(chosen.value),
source_page_url:chosen.dataset.sourcePageUrl||null,original_image_url:chosen.dataset.originalImageUrl||null}});}}
const blob=new Blob([JSON.stringify({{version:1,selections}},null,2)],{{type:'application/json'}});
const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='fruit_photo_selections.json';a.click();
setTimeout(()=>URL.revokeObjectURL(a.href),1000);document.getElementById('status').textContent=' Save the JSON in docs/image_sources/ and run finalize.';}};</script></body></html>'''


def discover(args):
    _, manifest, fruit_by_id, safe, _ = load_catalog(args)
    targets = discovery_targets(manifest, fruit_by_id, safe, args.fruit_id, args.limit, args.start_after)
    rows = []
    unavailable = []
    for index, fruit in enumerate(targets, 1):
        try:
            candidates = discover_commons(fruit)
        except (OSError, ValueError, PipelineError) as exc:
            print(f"{fruit['id']}: Commons error: {exc}", file=sys.stderr)
            unavailable.append(f"{fruit['id']} Wikimedia Commons: {exc}")
            candidates = []
        if len(candidates) < 3:
            try:
                candidates += discover_inat(fruit, 3 - len(candidates))
            except (OSError, ValueError, PipelineError) as exc:
                print(f"{fruit['id']}: iNaturalist error: {exc}", file=sys.stderr)
                unavailable.append(f"{fruit['id']} iNaturalist: {exc}")
        seen = set()
        for candidate in candidates:
            if candidate["original_image_url"] in seen:
                continue
            seen.add(candidate["original_image_url"])
            candidate["candidate_number"] = str(len([r for r in rows if r["fruit_id"] == fruit["id"]]) + 1)
            rows.append(candidate)
        print(f"[{index}/{len(targets)}] {fruit['id']}: {len(seen)} candidate(s)")
        if args.pause and index < len(targets):
            time.sleep(args.pause)
    write_csv(args.candidates, CANDIDATE_FIELDS, rows)
    args.review.parent.mkdir(parents=True, exist_ok=True)
    args.review.write_text(review_html(targets, rows), encoding="utf-8")
    print(f"Wrote {len(rows)} candidates and local review page for {len(targets)} fruits")
    if unavailable:
        raise PipelineError(f"Discovery had {len(unavailable)} source error(s); retry before reviewing empty results")


def selected_rows(args, safe, manifest):
    data = json.loads(args.selections.read_text(encoding="utf-8"))
    if data.get("version") != 1 or not isinstance(data.get("selections"), list):
        raise PipelineError("Invalid selection file schema")
    fields, candidates = read_csv(args.candidates)
    if fields != CANDIDATE_FIELDS:
        raise PipelineError("Candidate CSV columns have changed")
    candidate_map = {(row["fruit_id"], int(row["candidate_number"])): row for row in candidates}
    if len(candidate_map) != len(candidates) or any(number not in {1, 2, 3} for _, number in candidate_map):
        raise PipelineError("Duplicate or out-of-range candidate numbers")
    manifest_map = {row["fruit_id"]: row for row in manifest}
    chosen, seen = [], set()
    for selection in data["selections"]:
        fruit_id = selection.get("fruit_id")
        number = selection.get("candidate_number")
        if fruit_id in seen or fruit_id not in safe or manifest_map.get(fruit_id, {}).get("approval_status") == "approved":
            raise PipelineError(f"Duplicate, held, approved or unknown selection: {fruit_id}")
        seen.add(fruit_id)
        if number is None:
            print(f"{fruit_id}: NO ACCEPTABLE IMAGE, left unresolved")
            continue
        if type(number) is not int or (fruit_id, number) not in candidate_map:
            raise PipelineError(f"Invalid candidate selection: {fruit_id} #{number}")
        row = candidate_map[(fruit_id, number)]
        if (selection.get("source_page_url") != row["source_page_url"] or
                selection.get("original_image_url") != row["original_image_url"]):
            raise PipelineError(f"Candidate list changed since human review: {fruit_id}")
        if any(row[key] != manifest_map[fruit_id][other] for key, other in
               [("fruit_name", "fruit_name"), ("scientific_name", "scientific_name")]):
            raise PipelineError(f"Candidate identity mismatch: {fruit_id}")
        chosen.append(row)
    return chosen



def verify_curated_commons(candidate, fruit):
    """Validate a manually curated Wikimedia Commons photo without calling the API.

    This mode exists for rate-limited cases. It still requires:
    - an exact Commons File: source page,
    - an upload.wikimedia.org direct image URL,
    - a non-empty creator,
    - an allow-listed commercial-use licence,
    - a matching licence URL,
    - explicit human identity notes.
    """
    source_page = (candidate.get("source_page_url") or "").strip()
    original = (candidate.get("original_image_url") or "").strip()
    creator = (candidate.get("creator") or "").strip()
    license_name = (candidate.get("license") or "").strip()
    license_url = (candidate.get("license_url") or "").strip()
    attribution_required = (candidate.get("attribution_required") or "").strip().lower()
    note = (candidate.get("candidate_identity_notes") or "").strip()

    page = urlparse(source_page)
    image = urlparse(original)
    if page.scheme != "https" or page.hostname != "commons.wikimedia.org" or not page.path.startswith("/wiki/File:"):
        raise PipelineError("Invalid curated Commons source page URL")
    if image.scheme != "https" or image.hostname != "upload.wikimedia.org":
        raise PipelineError("Invalid curated Commons direct image URL")
    if not creator:
        raise PipelineError("Curated Commons candidate is missing creator")
    if not note:
        raise PipelineError("Curated Commons candidate is missing identity verification notes")

    if license_name == "CC0":
        if license_url.rstrip("/") != CC0_URL.rstrip("/") or attribution_required != "false":
            raise PipelineError("Curated Commons CC0 metadata mismatch")
    elif license_name == "CC BY 4.0":
        if license_url.rstrip("/") != BY4_URL.rstrip("/") or attribution_required != "true":
            raise PipelineError("Curated Commons CC BY 4.0 metadata mismatch")
    elif license_name == "Public domain":
        if not license_url.startswith("https://commons.wikimedia.org/wiki/Template:PD-") or attribution_required != "false":
            raise PipelineError("Curated Commons public-domain metadata mismatch")
    else:
        raise PipelineError("Unapproved curated Commons licence")

    return {
        "fruit_id": fruit["id"],
        "fruit_name": fruit["name"],
        "scientific_name": fruit["scientificName"],
        "source_platform": "Wikimedia Commons Curated",
        "source_page_url": source_page,
        "original_image_url": original,
        "creator": creator,
        "license": license_name,
        "license_url": license_url,
        "attribution_required": attribution_required,
        "candidate_identity_notes": note + " Manually curated Commons metadata; API reverification intentionally skipped due rate limiting.",
        "preview_url": original,
    }


def verify_local_commons(candidate, fruit):
    """Validate a manually downloaded Wikimedia Commons photo.

    The remote source-page/original-image URLs remain provenance. The actual
    binary is read from candidate preview_url as a local filesystem path, so
    finalize performs no Wikimedia network request.
    """
    # Reuse curated metadata validation for identity/licence/provenance.
    proxy = dict(candidate)
    proxy["source_platform"] = "Wikimedia Commons Curated"
    verified = verify_curated_commons(proxy, fruit)
    local_path = (candidate.get("preview_url") or "").strip()
    if not local_path:
        raise PipelineError("Local Commons candidate is missing local file path in preview_url")
    path = Path(local_path)
    if not path.is_file():
        raise PipelineError(f"Local Commons file not found: {path}")
    verified["source_platform"] = "Wikimedia Commons Local"
    verified["preview_url"] = str(path)
    verified["candidate_identity_notes"] += " Binary supplied from a manual browser download; no Wikimedia network request was made during finalize."
    return verified

def reverify(candidate, fruit):
    if candidate["source_platform"] == "Wikimedia Commons":
        path = urlparse(candidate["source_page_url"])
        if not valid_https(candidate["source_page_url"], {"commons.wikimedia.org"}) or not path.path.startswith("/wiki/File:"):
            raise PipelineError("Invalid Commons source page URL")
        title = "File:" + path.path.split("/wiki/File:", 1)[1].replace("_", " ")
        from urllib.parse import unquote
        verified = commons_candidate(commons_file(unquote(title)), fruit)
    elif candidate["source_platform"] == "iNaturalist":
        match = re.fullmatch(r"https://www\.inaturalist\.org/photos/(\d+)", candidate["source_page_url"])
        note = re.search(r"observation (\d+)", candidate["candidate_identity_notes"])
        if not match or not note:
            raise PipelineError("Missing iNaturalist photo or observation ID")
        obs_data = request_json(f"{INAT_API}/observations/{note.group(1)}")
        observations = obs_data.get("results") or []
        if len(observations) != 1 or int(match.group(1)) not in [int(photo["id"]) for photo in observations[0].get("photos", [])]:
            raise PipelineError("Photo no longer belongs to observation")
        current_photo = next(photo for photo in observations[0]["photos"] if int(photo["id"]) == int(match.group(1)))
        verified = inat_candidate(current_photo, observations[0], fruit)
    elif candidate["source_platform"] in {"Pexels", "Unsplash", "Pixabay"}:
        verified = verify_stock_candidate(candidate, fruit)
    elif candidate["source_platform"] == "Wikimedia Commons Curated":
        verified = verify_curated_commons(candidate, fruit)
    elif candidate["source_platform"] == "Wikimedia Commons Local":
        verified = verify_local_commons(candidate, fruit)
    else:
        raise PipelineError("Unsupported source platform")
    if not verified:
        raise PipelineError("Source no longer passes identity/licence filters")

    # Wikimedia Commons metadata can normalize both the direct upload URL and
    # creator/artist string even when the same File: page and license remain valid.
    # For Commons, trust the freshly reverified API values for original URL and
    # creator, while still requiring the same source page and license terms.
    if candidate["source_platform"] == "Wikimedia Commons":
        keys = ["source_page_url", "license", "license_url", "attribution_required"]
    else:
        keys = ["source_page_url", "original_image_url", "creator", "license", "license_url", "attribution_required"]

    for key in keys:
        if candidate[key] != verified[key]:
            raise PipelineError(f"Source metadata changed: {key}")
    return verified


def convert_webp(source):
    try:
        import cv2
        import numpy as np
    except ImportError as exc:
        raise PipelineError("Finalize/validate requires opencv-python (pip install opencv-python)") from exc
    # IMREAD_COLOR applies EXIF orientation by default (without IGNORE_ORIENTATION).
    image = cv2.imdecode(np.frombuffer(source, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None or min(image.shape[:2]) < 200:
        raise PipelineError("Original image is missing, undecodable, or too small")
    height, width = image.shape[:2]
    if max(height, width) > 1500:
        scale = 1500 / max(height, width)
        image = cv2.resize(image, (round(width * scale), round(height * scale)), interpolation=cv2.INTER_AREA)
    ok, encoded = cv2.imencode(".webp", image, [cv2.IMWRITE_WEBP_QUALITY, 85])
    if not ok:
        raise PipelineError("WebP encoding failed")
    return encoded.tobytes()


def replace_manifest_row(path, fruit_id, new_row):
    # Preserve every other row verbatim, including approved Batch 1/2 records.
    raw = path.read_bytes()
    newline = b"\r\n" if b"\r\n" in raw else b"\n"
    lines = raw.splitlines(keepends=True)
    found = 0
    for index in range(1, len(lines)):
        if lines[index].startswith((fruit_id + ",").encode("utf-8")):
            out = io.StringIO(newline="")
            csv.writer(out, lineterminator="").writerow(list(new_row.values()))
            lines[index] = out.getvalue().encode("utf-8") + newline
            found += 1
    if found != 1:
        raise PipelineError(f"Manifest row not unique: {fruit_id}")
    temp = path.with_suffix(".csv.tmp")
    temp.write_bytes(b"".join(lines))
    temp.replace(path)


def finalize(args):
    _, manifest, fruit_by_id, safe, _ = load_catalog(args)
    selected = selected_rows(args, safe, manifest)
    failures = 0
    for candidate in selected:
        fruit_id = candidate["fruit_id"]
        try:
            verified = reverify(candidate, fruit_by_id[fruit_id])
            original = verified["original_image_url"]
            allowed_original_hosts = {
                "upload.wikimedia.org",
                "static.inaturalist.org",
                "inaturalist-open-data.s3.amazonaws.com",
                "inaturalist-production.s3.amazonaws.com",
                "inaturalist-production.s3.us-west-2.amazonaws.com",
                "images.pexels.com",
                "images.unsplash.com",
                "plus.unsplash.com",
                "cdn.pixabay.com",
                "pixabay.com",
                "www.pixabay.com",
            }
            if urlparse(original).scheme != "https" or urlparse(original).hostname not in allowed_original_hosts:
                raise PipelineError("Original image host not allowed")
            with tempfile.TemporaryDirectory() as work:
                if verified["source_platform"] == "Wikimedia Commons Local":
                    source = Path(verified["preview_url"]).read_bytes()
                else:
                    download_url = (commons_thumbnail_url(original)
                                    if verified["source_platform"] == "Wikimedia Commons Curated"
                                    else original)
                    source = request_bytes(download_url)
                source_sha = hashlib.sha256(source).hexdigest()
                Path(work, "original").write_bytes(source)
                webp = convert_webp(source)
                asset_sha = hashlib.sha256(webp).hexdigest()
                asset = args.root / f"assets/images/fruits/{fruit_id}.webp"
                if asset.exists():
                    raise PipelineError("Unapproved asset already exists; refusing overwrite")
                _, current_rows, _, _, _ = load_catalog(args)
                current = next(row for row in current_rows if row["fruit_id"] == fruit_id)
                if current["approval_status"] == "approved":
                    raise PipelineError("Manifest became approved during finalize")
                if any(row["asset_file_sha256"] == asset_sha or row["source_file_sha256"] == source_sha
                       for row in current_rows if row["approval_status"] == "approved"):
                    raise PipelineError("Image duplicates an already approved asset/source")
                asset.parent.mkdir(parents=True, exist_ok=True)
                staged = asset.with_suffix(".webp.tmp")
                staged.write_bytes(webp)
                staged.replace(asset)
                try:
                    updated = dict(current)
                    creator, licence, page = verified["creator"], verified["license"], verified["source_page_url"]
                    updated.update({"source_platform": verified["source_platform"], "source_page_url": page,
                                    "original_image_url": original, "photographer_or_creator": creator,
                                    "license": licence, "license_url": verified["license_url"],
                                    "attribution_required": verified["attribution_required"],
                                    "attribution_text": f"Photo by {creator}, via {verified['source_platform']} ({page}); {licence} ({verified['license_url']}). Resized and converted to WebP.",
                                    "date_accessed": date.today().isoformat(), "commercial_use_verified": "true",
                                    "modification_allowed": "true",
                                    "verification_notes": f"Human-selected candidate {candidate['candidate_number']}. Source metadata reverified on {date.today().isoformat()}. {verified['candidate_identity_notes']}",
                                    "source_file_sha256": source_sha, "asset_file_sha256": asset_sha,
                                    "approval_status": "approved"})
                    replace_manifest_row(args.manifest, fruit_id, updated)
                except Exception:
                    asset.unlink(missing_ok=True)
                    raise
            print(f"{fruit_id}: approved; {asset_sha}")
        except Exception as exc:
            failures += 1
            print(f"{fruit_id}: unresolved: {exc}", file=sys.stderr)
    if failures:
        raise PipelineError(f"{failures} selection(s) failed; their manifest rows remain unresolved")


CURATED_FIELDS = ["fruit_id", "source_platform", "source_page_url", "original_image_url", "creator", "license", "license_url", "attribution_required", "candidate_identity_notes"]

def import_curated(args):
    _, manifest, fruit_by_id, safe, _ = load_catalog(args)
    if not args.curated:
        raise PipelineError("--curated CSV is required for import-curated")
    fields, rows = read_csv(args.curated)
    if fields != CURATED_FIELDS:
        raise PipelineError("Curated CSV columns must be: " + ",".join(CURATED_FIELDS))
    approved_ids = {row["fruit_id"] for row in manifest if row["approval_status"] == "approved"}
    output = []
    fruits = []
    seen = set()
    for row in rows:
        fruit_id = row["fruit_id"].strip()
        if fruit_id in seen:
            raise PipelineError(f"Duplicate curated fruit: {fruit_id}")
        seen.add(fruit_id)
        if fruit_id not in safe or fruit_id in approved_ids or fruit_id not in fruit_by_id:
            raise PipelineError(f"Curated fruit is held, approved or unknown: {fruit_id}")
        platform = row["source_platform"].strip()
        if platform not in {"Pexels", "Unsplash", "Pixabay", "Wikimedia Commons Curated", "Wikimedia Commons Local"}:
            raise PipelineError(f"Unsupported curated platform for {fruit_id}: {platform}")
        if platform in {"Pexels", "Unsplash", "Pixabay", "Wikimedia Commons Curated", "Wikimedia Commons Local"}:
            stub = {
                "fruit_id": fruit_id,
                "fruit_name": fruit_by_id[fruit_id]["name"],
                "scientific_name": fruit_by_id[fruit_id]["scientificName"],
                "candidate_number": "1",
                "source_platform": platform,
                "source_page_url": row["source_page_url"].strip(),
                "original_image_url": row["original_image_url"].strip(),
                "creator": row["creator"].strip(),
                "license": row["license"].strip(),
                "license_url": row["license_url"].strip(),
                "attribution_required": row["attribution_required"].strip().lower(),
                "candidate_identity_notes": row["candidate_identity_notes"].strip(),
                "preview_url": row["original_image_url"].strip(),
            }
            if platform == "Wikimedia Commons Curated":
                verified = verify_curated_commons(stub, fruit_by_id[fruit_id])
            elif platform == "Wikimedia Commons Local":
                verified = verify_local_commons(stub, fruit_by_id[fruit_id])
            else:
                verified = verify_stock_candidate(stub, fruit_by_id[fruit_id])
            stub.update({
                "source_platform": verified["source_platform"],
                "original_image_url": verified["original_image_url"],
                "creator": verified["creator"],
                "license": verified["license"],
                "license_url": verified["license_url"],
                "attribution_required": verified["attribution_required"],
                "candidate_identity_notes": verified["candidate_identity_notes"],
                "preview_url": verified["preview_url"],
            })
            output.append(stub)
        fruits.append(fruit_by_id[fruit_id])

    write_csv(args.candidates, CANDIDATE_FIELDS, output)
    args.review.parent.mkdir(parents=True, exist_ok=True)
    args.review.write_text(review_html(fruits, output), encoding="utf-8")
    print(f"Imported {len(output)} curated candidates; review page: {args.review}")


def inspect_webp(path):
    try:
        import cv2
    except ImportError as exc:
        raise PipelineError("Validation requires opencv-python") from exc
    data = path.read_bytes()
    if len(data) < 32 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        raise PipelineError("Not a nonempty WebP file")
    image = cv2.imread(str(path))
    if image is None:
        raise PipelineError("WebP does not decode")
    height, width = image.shape[:2]
    if min(height, width) < 200 or max(height, width) > 1600:
        raise PipelineError(f"Implausible dimensions: {width}x{height}")
    return data, width, height


def validate(args):
    _, manifest, _, _, holds = load_catalog(args)
    issues = []
    source_hashes, asset_hashes = {}, {}
    approved = [row for row in manifest if row["approval_status"] == "approved"]
    required = ["source_platform", "source_page_url", "original_image_url", "photographer_or_creator",
                "license", "license_url", "attribution_required", "attribution_text", "date_accessed",
                "commercial_use_verified", "modification_allowed", "verification_notes",
                "source_file_sha256", "asset_file_sha256"]
    for row in approved:
        fruit_id = row["fruit_id"]
        def issue(message):
            issues.append(f"{fruit_id}: {message}")
        if fruit_id in holds:
            issue("HOLD fruit is approved")
        if row["image_asset"] != f"assets/images/fruits/{fruit_id}.webp":
            issue("Noncanonical asset path")
        for field in required:
            if not row[field].strip():
                issue(f"Missing {field}")
        if row["license"] not in {"CC0", "CC BY 4.0", "Public domain", "Pexels License", "Unsplash License", "Pixabay Content License"}:
            issue("Unapproved licence")
        if row["license"] == "CC0" and row["license_url"].rstrip("/") != CC0_URL.rstrip("/"):
            issue("CC0 licence URL mismatch")
        if row["license"] == "CC BY 4.0" and row["license_url"].rstrip("/") != BY4_URL.rstrip("/"):
            issue("CC BY 4.0 licence URL mismatch")
        if row["license"] == "Public domain" and not row["license_url"].startswith("https://commons.wikimedia.org/wiki/Template:PD-"):
            issue("Public domain evidence URL missing")
        if row["license"] == "Pexels License" and row["license_url"].rstrip("/") != PEXELS_LICENSE_URL.rstrip("/"):
            issue("Pexels licence URL mismatch")
        if row["license"] == "Unsplash License" and row["license_url"].rstrip("/") != UNSPLASH_LICENSE_URL.rstrip("/"):
            issue("Unsplash licence URL mismatch")
        if row["license"] == "Pixabay Content License" and row["license_url"].rstrip("/") != PIXABAY_LICENSE_URL.rstrip("/"):
            issue("Pixabay licence URL mismatch")
        if row["attribution_required"] not in {"true", "false"} or row["commercial_use_verified"] != "true" or row["modification_allowed"] != "true":
            issue("Usage verification fields invalid")
        try:
            date.fromisoformat(row["date_accessed"])
        except ValueError:
            issue("Invalid date_accessed")
        source_hosts = {
            "commons.wikimedia.org", "www.inaturalist.org",
            "www.pexels.com", "pexels.com",
            "unsplash.com", "www.unsplash.com",
            "pixabay.com", "www.pixabay.com",
        }
        if urlparse(row["source_page_url"]).scheme != "https" or urlparse(row["source_page_url"]).hostname not in source_hosts:
            issue("Invalid source page host")
        image_hosts = {
            "upload.wikimedia.org", "static.inaturalist.org",
            "inaturalist-open-data.s3.amazonaws.com",
            "inaturalist-production.s3.amazonaws.com",
            "inaturalist-production.s3.us-west-2.amazonaws.com",
            "images.pexels.com", "images.unsplash.com", "plus.unsplash.com",
            "cdn.pixabay.com", "pixabay.com", "www.pixabay.com",
        }
        if urlparse(row["original_image_url"]).scheme != "https" or urlparse(row["original_image_url"]).hostname not in image_hosts:
            issue("Invalid original image host")
        for field, registry in (("source_file_sha256", source_hashes), ("asset_file_sha256", asset_hashes)):
            value = row[field]
            if not HASH_RE.fullmatch(value):
                issue(f"Invalid {field}")
            elif value in registry:
                if field == "asset_file_sha256" or "duplicate_source_verified:" not in row["verification_notes"].lower():
                    issue(f"Duplicate {field} with {registry[value]}")
            else:
                registry[value] = fruit_id
        asset = args.root / row["image_asset"]
        if not asset.is_file():
            issue("Approved asset missing")
        else:
            try:
                data, width, height = inspect_webp(asset)
                if hashlib.sha256(data).hexdigest() != row["asset_file_sha256"]:
                    issue("Asset SHA-256 mismatch")
            except (OSError, PipelineError) as exc:
                issue(str(exc))
    lines = ["# Fruit photo validation", "", f"Approved rows checked: {len(approved)}", f"Issues: {len(issues)}", ""]
    lines.extend([f"- {message}" for message in issues] or ["All approved records passed local validation."])
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Validated {len(approved)} approved photos: {len(issues)} issue(s); report: {args.report}")
    if issues:
        raise PipelineError("Validation failed")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("discover", "import-curated", "finalize", "validate"))
    parser.add_argument("--root", type=Path, default=ROOT, help="Repository root (also useful for fixture tests)")
    parser.add_argument("--fruit-id", help="Discover one safe unapproved fruit")
    parser.add_argument("--start-after", help="Discover only IDs after this canonical fruit ID")
    parser.add_argument("--limit", type=int, help="Discover first N safe unapproved fruits; 0 initializes empty review")
    parser.add_argument("--pause", type=float, default=0.2, help="Seconds between fruit discovery requests")
    parser.add_argument("--curated", type=Path, help="Curated stock-photo CSV for import-curated mode")
    for name, default in DEFAULTS.items():
        parser.add_argument(f"--{name}", type=Path, help=f"Override {default}")
    args = parser.parse_args(argv)
    if args.limit is not None and args.limit < 0:
        parser.error("--limit must be zero or greater")
    if args.start_after and not re.fullmatch(r"FR\d{3}", args.start_after):
        parser.error("--start-after must be a canonical FR ID")
    args.root = args.root.resolve()
    for name, default in DEFAULTS.items():
        path = getattr(args, name) or Path(default)
        setattr(args, name, path if path.is_absolute() else args.root / path)
    try:
        if args.mode == "discover":
            discover(args)
        elif args.mode == "import-curated":
            if args.curated and not args.curated.is_absolute():
                args.curated = args.root / args.curated
            import_curated(args)
        elif args.mode == "finalize":
            finalize(args)
        else:
            validate(args)
    except (OSError, ValueError, KeyError, PipelineError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
