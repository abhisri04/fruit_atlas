import copy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from PIL import Image
import download_dish_images_pexels as pipeline


class PipelineTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.dish = dict(id='DSH001', name='Masala Dosa', aliases=['Masala Dosai'], origin_state_ids=['karnataka'], associated_state_ids=['karnataka'], dish_type='main_course', dietary_type='vegetarian', image_asset='assets/images/dishes/DSH001.webp')
        catalogue = self.root / 'assets/data/indian_dishes.json'
        catalogue.parent.mkdir(parents=True)
        catalogue.write_text(json.dumps({'items': [self.dish]}))
        (self.root / 'pubspec.yaml').write_text('flutter:\n  assets:\n    - assets/images/dishes/\n')
        self.patchers = [patch.object(pipeline, name, value) for name, value in {
            'ROOT': self.root, 'CATALOGUE': catalogue,
            'MANIFEST': self.root / 'assets/data/dish_image_manifest.json',
            'REPORTS': self.root / 'reports', 'WORK': self.root / 'work',
        }.items()]
        for item in self.patchers:
            item.start()
        self.addCleanup(self.temporary.cleanup)
        for item in self.patchers:
            self.addCleanup(item.stop)

    def photo(self, photo_id=123, alt='Masala dosa on a plate'):
        return dict(id=photo_id, alt=alt, width=2400, height=1800,
                    url=f'https://www.pexels.com/photo/{photo_id}/', photographer='Test Photographer',
                    photographer_url='https://www.pexels.com/@example',
                    src={'original': f'https://images.pexels.com/photos/{photo_id}/photo.jpeg', 'medium': 'https://images.pexels.com/photos/123/photo.jpeg'})

    def reviewed(self):
        manifest = pipeline.initialize()
        row = manifest['items'][0]
        row['candidates'] = [pipeline.candidate(self.photo(), self.dish, 'Masala Dosa')]
        decisions = self.root / 'approval.json'
        decisions.write_text(json.dumps([dict(dishId='DSH001', selectedPhotoId='123', confidence='HIGH', visualReviewed=True, notes='Identified dosa roll with potato masala; focused composition.')]))
        pipeline.approve(manifest, decisions)
        return manifest

    def test_offline_initialization_preserves_ids_and_produces_all_reports(self):
        before = pipeline.CATALOGUE.read_bytes()
        manifest = pipeline.initialize()
        self.assertEqual(len(manifest['items']), 1)
        self.assertEqual(manifest['items'][0]['status'], 'awaiting_api_key')
        self.assertEqual(pipeline.validate(manifest), [])
        summary = pipeline.reports(manifest)
        self.assertEqual(summary['searched'], 0)
        self.assertEqual(pipeline.CATALOGUE.read_bytes(), before)
        for filename in ['dish_image_review.csv', 'dish_images_unresolved.csv', 'dish_image_duplicates.csv', 'dish_image_review.html']:
            self.assertTrue((pipeline.REPORTS / filename).exists())

    def test_queries_are_specific_and_aliases_do_not_change_identity(self):
        queries = pipeline.queries(self.dish)
        self.assertIn('Masala Dosa karnataka', queries)
        self.assertIn('Masala Dosai food', queries)
        self.assertNotIn('Indian food', queries)
        self.assertEqual(self.dish['id'], 'DSH001')

    def test_exact_metadata_never_receives_unreviewed_high_confidence(self):
        exact = pipeline.candidate(self.photo(), self.dish, 'Masala Dosa')
        unrelated = pipeline.candidate(self.photo(124, 'Indian curry'), self.dish, 'Masala Dosa')
        self.assertEqual(exact['confidence'], 'MEDIUM')
        self.assertEqual(unrelated['confidence'], 'LOW')
        poor = pipeline.candidate(self.photo(125, 'Masala dosa packaging advertisement'), self.dish, 'Masala Dosa')
        self.assertEqual(poor['confidence'], 'LOW')

    def test_resume_does_not_repeat_completed_searches(self):
        manifest = pipeline.initialize()
        row = manifest['items'][0]
        row['completedQueries'] = row['queries'][:-1]
        args = type('Args', (), dict(max_requests=10, pause=0, limit=1, dish_id=None))()
        with patch.object(pipeline.PexelsClient, 'search', return_value=[self.photo()]) as search:
            pipeline.discover(manifest, args, 'never_logged_test_key')
            self.assertEqual(search.call_count, 1)
            pipeline.discover(manifest, args, 'never_logged_test_key')
            self.assertEqual(search.call_count, 1)
        self.assertNotIn('never_logged_test_key', pipeline.MANIFEST.read_text())

    def test_visual_review_is_required(self):
        manifest = pipeline.initialize()
        row = manifest['items'][0]
        row['candidates'] = [pipeline.candidate(self.photo(), self.dish, 'Masala Dosa')]
        path = self.root / 'bad_approval.json'
        path.write_text(json.dumps([dict(dishId='DSH001', selectedPhotoId='123', confidence='HIGH', notes='metadata only')]))
        with self.assertRaises(ValueError):
            pipeline.approve(manifest, path)
        self.assertNotEqual(row['status'], 'reviewed_high')

    def test_real_webp_export_and_provenance_without_upscale_or_crop(self):
        manifest = self.reviewed()
        image = Image.new('RGB', (2400, 1800), 'orange')
        source = io.BytesIO()
        image.save(source, format='JPEG')
        response = io.BytesIO(source.getvalue())
        opener = type('Opener', (), {'open': lambda *_args, **_kwargs: response})()
        with patch.object(pipeline, 'build_opener', return_value=opener):
            pipeline.finalize(manifest)
        row = manifest['items'][0]
        self.assertEqual(row['status'], 'pexels_approved')
        self.assertEqual(pipeline.inspect_image(self.root / row['imageFile']), ('WEBP', 1600, 1200))
        self.assertEqual(pipeline.validate(manifest), [])
        self.assertEqual(row['photographer'], 'Test Photographer')
        self.assertTrue(row['downloadedSourceUrl'].startswith('https://images.pexels.com'))
        # Simulate a crash after file export but before the final status save.
        row['status'] = 'reviewed_high'
        pipeline.finalize(manifest)
        self.assertEqual(row['status'], 'pexels_approved')

    def test_existing_files_are_protected(self):
        destination = self.root / self.dish['image_asset']
        destination.parent.mkdir(parents=True)
        destination.write_bytes(b'existing_manual_asset')
        manifest = pipeline.initialize()
        self.assertEqual(manifest['items'][0]['status'], 'existing_needs_review')
        self.assertEqual(destination.read_bytes(), b'existing_manual_asset')

    def test_duplicates_and_corrupt_approved_assets_are_reported(self):
        manifest = self.reviewed()
        duplicate = copy.deepcopy(manifest['items'][0])
        duplicate['dishId'] = 'unknown'
        manifest['items'].append(duplicate)
        self.assertEqual(len(pipeline.duplicates(manifest)), 1)
        self.assertTrue(pipeline.validate(manifest))
        manifest['items'].pop()
        row = manifest['items'][0]
        row['status'] = 'pexels_approved'
        row['imageFile'] = row['expectedImageFile']
        path = self.root / row['imageFile']
        path.parent.mkdir(parents=True)
        path.write_bytes(b'')
        self.assertIn('Missing/corrupt approved image: DSH001', pipeline.validate(manifest))

    def test_hourly_rate_checkpoint_stops_without_a_request(self):
        client = pipeline.PexelsClient('never_logged_test_key')
        client.rate['requests'] = [pipeline.time.time()] * 190
        with patch.object(client.opener, 'open') as request:
            with self.assertRaises(pipeline.StopRun):
                client.search('Masala Dosa')
            request.assert_not_called()

    def test_missing_key_stops_before_any_search(self):
        with patch.dict(pipeline.os.environ, {}, clear=True), patch.object(pipeline.sys, 'argv', ['pipeline', 'discover']), patch.object(pipeline.PexelsClient, 'search') as search, patch('sys.stdout', io.StringIO()):
            self.assertEqual(pipeline.main(), 2)
            search.assert_not_called()

    def test_429_is_checkpointed_and_not_retried(self):
        client = pipeline.PexelsClient('never_logged_test_key', pause=0)
        error = pipeline.HTTPError('https://api.pexels.com/v1/search', 429, 'rate limited', {'Retry-After': '3600'}, None)
        with patch.object(client.opener, 'open', side_effect=error) as request:
            with self.assertRaises(pipeline.StopRun):
                client.search('Masala Dosa')
            with self.assertRaises(pipeline.StopRun):
                client.search('Masala Dosa')
            self.assertEqual(request.call_count, 1)
        self.assertGreater(client.rate['blockedUntil'], pipeline.time.time())

    def test_cached_results_do_not_make_an_api_call(self):
        client = pipeline.PexelsClient('never_logged_test_key', pause=0)
        client.cache['Masala Dosa'] = [self.photo()]
        with patch.object(client.opener, 'open') as request:
            self.assertEqual(len(client.search('Masala Dosa')), 1)
            request.assert_not_called()


if __name__ == '__main__':
    unittest.main()
