# Human dish photograph review

Correct image > beautiful image > coverage. Only the existing saved 30-dish
batch is supported; do not expand it before reviewing candidate accuracy.
Canonical IDs, catalogue names and asset paths remain unchanged.

Run `python tools/download_dish_images.py discover --source pixabay` in the
terminal containing PIXABAY_API_KEY to resume the new exact-name queries.
Saved candidates, caches and completed queries are retained. Search queries
combine canonical names, canonical aliases and the separate
`image_search_aliases.json` layer with state and dish type. Every query retains
the dish name; no generic food/category fallback is generated.

Open `pixabay_30/dish_image_review.html`. Up to five eligible metadata matches
are shown per dish. Matching tags and HIGH priority never establish visual
identity. Reject generic substitutes, even beautiful ones. The original saved
candidate pool is retained for inspection; flagged and generic metadata results
are excluded from cards. No matches after completed searches means unresolved.

Choose a candidate, None are correct, or Needs more search. Add identification,
quality, real-photograph and license evidence in the review notes. Export the
CSV and save it as `docs/image_sources/dishes/dish_image_approvals.csv`.
The generated pending template is never overwritten by report generation.
Allowed reviewStatus values: pending, approved, none_correct, needs_more_search.
Source plus photo ID identify the approved image; candidate number is a visual
reference and may change when rankings change.

Run:

```
python tools/download_dish_images.py finalize --approved-only
```

The finalizer reads the entire bounded approval CSV, rejects unknown/duplicate
IDs and unqualified approvals, and exports only explicitly approved candidates.
No HIGH-only export is allowed. Existing files remain protected. WebP conversion,
dimensions, attribution, original source URL and checksum are preserved.
None are correct marks unresolved; pending and needs_more_search retain the
placeholder. Never approve solely to increase coverage.

The source-neutral candidate contract and selection policy are prepared for
Pexels, Pixabay, Openverse, specifically reviewed Wikimedia and manually licensed
images. Only Pixabay is callable in this pilot. Other adapters require explicit
implementation and license/provenance validation; no random website scraping or
automatic source fallback is enabled.

Accuracy metrics remain unmeasured until human decisions are imported. Common
and obscure approval rates use approved / (approved + none_correct), reported
separately. No-result metadata counts are not visual accuracy conclusions.
