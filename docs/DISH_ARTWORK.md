# UPLYFA dish artwork

The dish UI uses reusable local vector artwork rather than individual placeholder
files. No photo sourcing was resumed. No unapproved Pixabay candidate is loaded.

Created: `lib/models/dish_visual_style.dart`, `lib/widgets/dish_artwork.dart`,
`test/dish_artwork_test.dart`, and this report.

Modified: Indian Dishes browse/detail, ExperienceArtwork (Daily Discovery),
SearchResultTile, ShareHighlightItem, ShareStudioService and Share Studio preview.
State dish pages use the same canonical dish list and shared artwork component.
The older DishImage utility remains for drink rendering, not production dish UI.

## Categories and palettes

| Category | Background | Accent | Motif |
|---|---|---|---|
| Bread / flatbread | wheat, cream | gold | stacked round bread |
| Rice | saffron, cream | burnt gold | rice-grain bowl |
| Curry | terracotta, cream | deep red | steaming bowl |
| Snack | yellow, cream | saffron | triangular savouries on a plate |
| Dessert | peach, cream | rose | sweets in a bowl |
| Leafy / vegetables | sage, cream | olive | leafy bowl |
| Seafood | pale teal, cream | teal | stylised fish |
| Meat speciality | warm brown, cream | maroon | speciality serving bowl |
| Regional speciality | pale aubergine | muted purple | traditional covered pot |
| Default food | warm grey, cream | neutral brown | covered serving bowl |

All colours and category labels are centralized in DishVisualStyle. Artwork is
original CustomPainter geometry. Subtle floral/mandala fragments in two corners
use low-opacity linework; no raster assets, blur or expensive shaders are used.
The illustrations represent categories, not exact dishes.

## Resolution and metadata

Controlled normalized word matching uses dish type, names and tags. Specific
bread, rice, sweet and snack terms precede broader seafood, vegetable, curry,
meat and regional terms; unknown metadata resolves to default food. Dietary
metadata never determines the artwork category. Two ID overrides are defined:
Kafuli and Ambadyachi Uddamethi use the vegetable category. Compiled search
patterns and style configuration are reused.

State label: one distinct origin state, otherwise one associated state when no
origin is given, otherwise one distinct region, otherwise India. Multiple states
are never arbitrarily reduced to their first entry. Canonical Aloo Paratha is
Chandigarh in this catalogue, so it is not relabelled Punjab.

Dietary labels preserve Veg, Non-Veg and Contains egg. Unknown dietary metadata
omits the chip. Chips include text, so colour is not the sole distinction.

## Layout and photos

Compact artwork places illustration above title, location and chips. List artwork
puts illustration left and metadata right. Hero uses a richer, larger composition
and full title; wide heroes place text alongside illustration. Thumbnail omits
metadata for small search/share items. Titles use readable 17/24-point typography;
compact/list titles allow two lines then ellipsis. Hero titles remain complete.
Constrained metadata can scroll at large text scales rather than overflow.
Semantics include dish name, location and dietary label.

The approved image and asset manifests are read once per app session. A real
photo requires an explicitly approved status, matching canonical dish ID/path and
a bundled asset. Missing/broken assets return to vector artwork. An image file or
candidate URL alone cannot enable the override. Painter delegates only repaint
when configuration changes, with RepaintBoundary around food artwork.

## Validation and Android inspection

All 640 dishes resolve to configured visual styles. Resolver and widget tests
cover representative categories, seafood/default fallbacks, multi-region labels,
dietary meaning, long titles, all variants, large text, Daily Discovery, shared
list cards and approval gating. Android device inspection was not performed in
this session; automated widget tests do not replace device visual review.

Inspect these ten catalogue entries on Android in both list and detail views:

1. Aloo Paratha (bread; canonical Chandigarh label)
2. Butter Chicken (curry; Non-Veg)
3. Hyderabadi Biryani (rice; Telangana)
4. Chhena Poda (dessert; Odisha)
5. Samosa (snack)
6. Kafuli (leafy vegetables; Uttarakhand)
7. Andhra Chicken Pakodi (long title; snack)
8. Ambadyachi Uddamethi (long title; vegetable override)
9. Amritsari Fish (seafood; check multi-state/region label)
10. Aamat (default category when no reliable visual taxonomy is present)

Also exercise the synthetic long title Amritsari Kulcha Chandigarh Style in
widget tests, since it is not a separate canonical catalogue dish. Check the
Daily Discovery dish artwork, search thumbnail, Share Studio thumbnail, narrow
screens and Android's largest text size.
