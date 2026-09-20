# Fruit Atlas catalogue and real-photo handoff

The current active catalogue contains **115 canonical fruits**, **54 nested
varieties**, and **160 recorded fruit-State/UT relationships**. The five approved
additions are FR121-FR125. All earlier active IDs and the ten retired-ID
redirects remain unchanged; completion and Saved keys continue to use the
existing canonical-ID flow.

The [finalization review](fruit_catalogue_finalization.md) records a decision
for each of the 61 fruits that previously had `legacy_review_needed`, the
scientific-name corrections, the 16 records still awaiting further review, and
the evidence for added relationships. The [variety backlog](fruit_variety_backlog.md)
contains later research candidates; no existing variety was removed or
renumbered.

Each active fruit reserves `assets/images/fruits/<fruit_id>.webp`. None of the
115 physical WebP files is present yet. The shared `FruitImage` widget displays
its fallback when a local image is missing or cannot be decoded. The
[115-row photo manifest](image_sources/fruit_photo_manifest.csv) contains only
fruit identities and target paths; photo-source and approval fields are blank.

The later image phase is for **real photographs** with individually verified
commercially reusable rights and recorded provenance. No photograph has been
downloaded or bundled during catalogue finalization.
