import csv
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import dish_image_review as review
import download_dish_images as pipeline


class HumanReviewTests(unittest.TestCase):
    def test_queries_keep_exact_identity_and_region(self):
        dish = dict(name='Chhena Poda', aliases=['Chhena Podo'], origin_state_ids=['odisha'], dish_type='dessert')
        queries = review.queries(dish, ['Chenna Poda'])
        self.assertIn('Chhena Poda odisha', queries)
        self.assertIn('Chhena Poda dessert', queries)
        self.assertIn('Chenna Poda odisha', queries)
        self.assertNotIn('Indian dessert', queries)
        self.assertTrue(all(any(name in q for name in ['Chhena Poda', 'Chhena Podo', 'Chenna Poda']) for q in queries))

    def test_generic_and_flagged_candidates_excluded_and_maximum_five(self):
        choices = [dict(score=75, flags=[], sourceId=str(i)) for i in range(8)]
        choices.extend([dict(score=25, flags=[]), dict(score=90, flags=['logo'])])
        self.assertEqual(len(review.candidates({'candidates': choices})), 5)
        self.assertTrue(all(c['score'] >= 60 and not c['flags'] for c in review.candidates({'candidates': choices})))

    def test_high_metadata_without_explicit_approval_never_downloaded(self):
        state = dict(status='reviewed_high', confidence='HIGH', candidates=[])
        row = dict(dishId='example', sourceRuns={'pixabay': state})
        with patch.object(pipeline, 'download_pixabay_image') as download:
            pipeline.finalize({'items': [row]}, [{'dishId': 'example'}])
        download.assert_not_called()

    def test_pending_csv_revokes_stale_selection(self):
        state = dict(status='reviewed_high', reviewStatus='approved', selectedSourceId='old', candidates=[])
        row = dict(dishId='example', sourceRuns={'pixabay': state})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/'approval.csv'
            with path.open('w', newline='', encoding='utf-8') as file:
                writer = csv.DictWriter(file, fieldnames=review.APPROVAL_FIELDS)
                writer.writeheader()
                writer.writerow(dict(dishId='example', reviewStatus='pending'))
            review.load_approvals(path, [row])
        self.assertEqual(state['status'], 'pending_review')
        self.assertIsNone(state['selectedSourceId'])
        self.assertFalse(state['visualReviewed'])
