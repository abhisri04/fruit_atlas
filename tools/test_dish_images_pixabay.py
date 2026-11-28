import copy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, Mock
import download_dish_images as pipeline
import download_dish_images_pexels as common
from dish_image_sources import PixabayAdapter, download_pixabay_image
import requests
from PIL import Image


class PixabayTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.addCleanup(self.temp.cleanup)

    def hit(self, tags='masala dosa, food', image_id=123):
        return dict(id=image_id, type='photo', tags=tags, imageWidth=2400, imageHeight=1800,
            pageURL=f'https://pixabay.com/photos/food-{image_id}/', user='Creator', user_id=10,
            largeImageURL='https://pixabay.com/get/photo_1280.jpg', webformatURL='https://pixabay.com/get/photo_640.jpg')

    def dish(self):
        return dict(id='DSH001', name='Masala Dosa', aliases=[], image_asset='assets/images/dishes/DSH001.webp')

    def test_transport_error_reports_class_and_sanitized_message(self):
        adapter = PixabayAdapter('private_key', self.root)
        error = requests.exceptions.ProxyError('Proxy refused https://pixabay.com/api/?key=private_key&q=food')
        with patch.object(adapter.session, 'get', side_effect=error):
            with self.assertRaises(common.StopRun) as caught:
                adapter.diagnose()
        message = str(caught.exception)
        self.assertIn('ProxyError', message)
        self.assertIn('Proxy refused', message)
        self.assertNotIn('private_key', message)
        self.assertNotIn('https://pixabay.com/api/?', message)

    def test_streamed_image_download_checks_content_type_and_empty_body(self):
        session = Mock()
        session.__enter__ = Mock(return_value=session)
        session.__exit__ = Mock(return_value=False)
        response = Mock(status_code=200, headers={'Content-Type': 'image/jpeg'})
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        session.get.return_value = response
        with patch('dish_image_sources.requests.Session', return_value=session):
            response.iter_content.return_value = [b'abc', b'def']
            self.assertEqual(download_pixabay_image('https://cdn.pixabay.com/photo.jpg'), b'abcdef')
            self.assertTrue(session.get.call_args.kwargs['stream'])
            response.iter_content.return_value = []
            with self.assertRaisesRegex(common.StopRun, 'empty'):
                download_pixabay_image('https://cdn.pixabay.com/photo.jpg')
            response.headers = {'Content-Type': 'text/html'}
            with self.assertRaisesRegex(common.StopRun, 'non-image'):
                download_pixabay_image('https://cdn.pixabay.com/photo.jpg')

    def test_exact_metadata_still_needs_review_and_wrong_dish_stays_low(self):
        adapter = PixabayAdapter('dummy', self.root)
        exact = adapter.candidate(self.hit(), self.dish(), 'Masala Dosa')
        wrong = adapter.candidate(self.hit('potato curry, food'), self.dish(), 'Masala Dosa')
        self.assertEqual(exact['confidence'], 'MEDIUM')
        self.assertEqual(wrong['confidence'], 'LOW')
        self.assertEqual(exact['source'], 'pixabay')
        self.assertEqual(exact['pixabayImageId'], '123')
        self.assertIn('license-summary', exact['licenseReference'])
        self.assertIn('Creator-10', exact['creatorPageUrl'])

    def test_synthetic_and_untrusted_sources_are_flagged(self):
        adapter = PixabayAdapter('dummy', self.root)
        self.assertIn('generated', adapter.candidate(self.hit('masala dosa, ai generated'), self.dish(), 'Masala Dosa')['flags'])
        hit = self.hit()
        hit['largeImageURL'] = 'https://unrelated.example/food.jpg'
        self.assertIn('invalid_source', adapter.candidate(hit, self.dish(), 'Masala Dosa')['flags'])

    def test_cache_is_used_for_24_hours_without_saving_credentials(self):
        adapter = PixabayAdapter('secret_not_persisted', self.root, pause=0)
        adapter.cache['Masala Dosa'] = {'cachedAt': common.time.time(), 'hits': [self.hit()]}
        with patch.object(adapter.session, 'get') as request:
            self.assertEqual(len(adapter.search('Masala Dosa')), 1)
            request.assert_not_called()
        common.atomic_json(adapter.cache_path, adapter.cache)
        self.assertNotIn('secret_not_persisted', adapter.cache_path.read_text())

    def test_429_stops_without_retries_or_secret_error_output(self):
        adapter = PixabayAdapter('secret_not_persisted', self.root, pause=0)
        response = Mock(status_code=429, headers={'X-RateLimit-Reset': '90'}, text='Rate limit exceeded')
        with patch.object(adapter.session, 'get', return_value=response) as request, patch('sys.stdout', io.StringIO()):
            for _ in range(2):
                with self.assertRaises(common.StopRun) as caught:
                    adapter.search('Masala Dosa')
                self.assertNotIn('secret_not_persisted', str(caught.exception))
            self.assertEqual(request.call_count, 1)

    def test_actual_batch_is_20_common_10_obscure_and_preserves_catalogue(self):
        before = common.CATALOGUE.read_bytes()
        manifest, batch, dishes = pipeline.prepare()
        self.assertEqual(len(batch), 30)
        self.assertEqual(sum(r['group']=='common' for r in batch), 20)
        self.assertEqual(sum(r['group']=='obscure' for r in batch), 10)
        self.assertTrue(all(row['dishId'] in dishes for row in batch))
        self.assertEqual(common.CATALOGUE.read_bytes(), before)
        self.assertEqual(len(manifest['items']), 640)

    def test_duplicate_ids_are_source_scoped(self):
        manifest = {'items': [dict(dishId='one', sourceRuns={'pixabay': {'selectedSourceId': '123'}}), dict(dishId='two', sourceRuns={'pexels': {'selectedSourceId': '123'}})]}
        self.assertEqual(pipeline.duplicate_assignments(manifest), [])
        manifest['items'][1]['sourceRuns'] = {'pixabay': {'selectedSourceId': '123'}}
        self.assertEqual(len(pipeline.duplicate_assignments(manifest)), 1)

    def test_missing_key_never_calls_adapter(self):
        with patch.dict(pipeline.os.environ, {}, clear=True), patch.object(pipeline.sys, 'argv', ['pipeline', 'discover']), patch.object(PixabayAdapter, 'search') as request, patch('sys.stdout', io.StringIO()):
            self.assertEqual(pipeline.main(), 2)
            request.assert_not_called()

    def test_exports_require_batch_quality_permission(self):
        with patch.dict(pipeline.os.environ, {'PIXABAY_API_KEY': 'dummy'}), patch.object(pipeline.sys, 'argv', ['pipeline', 'finalize']), patch.object(pipeline, 'finalize') as download, patch('sys.stdout', io.StringIO()):
            self.assertEqual(pipeline.main(), 2)
            download.assert_not_called()

    def test_review_uses_large_images_and_unmeasured_rates_are_null(self):
        manifest, batch, _ = pipeline.prepare()
        with patch.object(pipeline, 'REPORTS', self.root):
            summary = pipeline.reports(manifest, batch)
        page = (self.root / 'dish_image_review.html').read_text(encoding='utf-8')
        self.assertIn('height:340px', page)
        self.assertIn('Export approval CSV', page)
        self.assertIn('No candidate is automatically approved', page)
        self.assertIsNone(summary['commonApprovedRate'])
        self.assertIsNone(summary['obscureApprovedRate'])

    def test_pixabay_export_preserves_provenance_and_webp_dimensions(self):
        adapter = PixabayAdapter('dummy', self.root)
        choice = adapter.candidate(self.hit(), self.dish(), 'Masala Dosa')
        state = dict(status='reviewed_high', reviewStatus='approved', confidence='HIGH', visualReviewed=True,
                     notes='Exact dosa presentation, food dominates, no text or branding.',
                     selectedSourceId='123', candidates=[choice])
        row = dict(dishId='DSH001', expectedImageFile='assets/images/dishes/DSH001.webp', sourceRuns={'pixabay': state})
        manifest = {'items': [row]}
        raw = io.BytesIO()
        Image.new('RGB', (1600, 1200), 'orange').save(raw, format='JPEG')
        with patch.object(pipeline, 'ROOT', self.root), patch.object(common, 'MANIFEST', self.root / 'manifest.json'), patch.object(pipeline, 'download_pixabay_image', return_value=raw.getvalue()):
            pipeline.finalize(manifest, [{'dishId': 'DSH001'}])
        self.assertEqual(common.inspect_image(self.root / row['imageFile']), ('WEBP', 1600, 1200))
        self.assertEqual(row['source'], 'pixabay')
        self.assertEqual(row['pixabayImageId'], '123')
        self.assertEqual(row['creator'], 'Creator')
        self.assertEqual(row['status'], 'pixabay_approved')

    def test_diagnose_uses_exact_successful_parameters_and_one_request(self):
        adapter = PixabayAdapter('test_secret', self.root)
        response = Mock(status_code=200, headers={'Content-Type': 'application/json'})
        response.json.return_value = {'totalHits': 500, 'hits': [self.hit()]}
        with patch.object(adapter.session, 'get', return_value=response) as request, patch('sys.stdout', io.StringIO()) as output:
            adapter.diagnose()
        request.assert_called_once()
        args, kwargs = request.call_args
        self.assertEqual(args, ('https://pixabay.com/api/',))
        self.assertEqual(kwargs['params'], dict(key='test_secret', q='butter chicken', image_type='photo', per_page=3, safesearch='true'))
        self.assertEqual(kwargs['headers']['User-Agent'], 'UPLYFA/1.0 dish-image-validation')
        self.assertEqual(kwargs['timeout'], 20)
        self.assertEqual(kwargs['headers'], {'User-Agent': 'UPLYFA/1.0 dish-image-validation'})
        self.assertNotIn('allow_redirects', kwargs)
        self.assertIn('HTTP status: 200', output.getvalue())
        self.assertIn('Number of hits: 1', output.getvalue())
        self.assertIn('First result ID: 123', output.getvalue())
        self.assertNotIn('test_secret', output.getvalue())
        self.assertFalse(adapter.cache_path.exists())
        self.assertFalse(adapter.rate_path.exists())

    def test_error_body_and_headers_are_sanitized(self):
        adapter = PixabayAdapter('secret not+logged', self.root)
        response = Mock(status_code=403, headers={'Server': 'cloudflare', 'Location': 'https://pixabay.com/api/?key=secret+not%2Blogged&q=food'}, text='Forbidden: secret not+logged; https://pixabay.com/api/?key=secret+not%2Blogged&q=food')
        with patch.object(adapter.session, 'get', return_value=response) as request, patch('sys.stdout', io.StringIO()) as output:
            with self.assertRaises(common.StopRun):
                adapter.diagnose()
        self.assertEqual(request.call_count, 1)
        self.assertIn('Response body: Forbidden:', output.getvalue())
        self.assertIn('Server: cloudflare', output.getvalue())
        self.assertNotIn('secret not+logged', output.getvalue())
        self.assertNotIn('secret+not%2Blogged', output.getvalue())
        self.assertNotIn('https://pixabay.com/api/?', output.getvalue())

    def test_diagnose_cli_never_touches_manifest_batch_or_reports(self):
        with patch.dict(pipeline.os.environ, {'PIXABAY_API_KEY': 'test_secret'}), patch.object(pipeline.sys, 'argv', ['pipeline', 'diagnose']), patch.object(pipeline, 'prepare') as prepare, patch.object(pipeline, 'reports') as reports, patch.object(PixabayAdapter, 'diagnose') as diagnose:
            self.assertEqual(pipeline.main(), 0)
            diagnose.assert_called_once()
            prepare.assert_not_called()
            reports.assert_not_called()


if __name__ == '__main__':
    unittest.main()
