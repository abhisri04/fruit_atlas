# Fruit Atlas real-photo sourcing queue

Catalogue snapshot: 115 active fruits, 112 safe to source, 3 identity holds, 115 expected `assets/images/fruits/<FRUIT_ID>.webp` paths, and 0 physical fruit images. This is a sourcing plan only; no photograph or source metadata has been selected.

## Decision rule

`SAFE TO SOURCE PHOTO NOW` means the intended photographed taxon or fruit is defined well enough to search for a real photograph. It does **not** resolve an open question about Indian cultivation, food use, or catalogue inclusion. A candidate photo must still pass the source, license, species, and quality checks below. `HOLD PHOTO UNTIL REVIEW` means the fruit record's consumer or taxonomic identity could lead to a misleading image. No held ID is queued below. None of the 16 records is changed by this classification.

## The 16 unresolved fruit records

| Fruit ID | Current common name | Scientific name | Exact unresolved issue and photo-specific constraint | Photo subject stable? | Photo sourcing |
|---|---|---|---|---|---|
| FR048 | Sweet Lime | *Citrus × limettioides* | The Mosambi consumer category remains distinct in the catalogue, but Kew treats this botanical name as a synonym of lemon; the photo target needs a verified horticultural identity. | NO | HOLD PHOTO UNTIL REVIEW |
| FR053 | Cape Gooseberry | *Physalis peruviana* | India-specific cultivation and a suitable physical fruit identity still need evidence; the named species fixes the intended subject. | YES | SAFE TO SOURCE PHOTO NOW |
| FR057 | Breadfruit | *Artocarpus altilis* | Present-day Indian food use and location need confirmation; the named species fixes the subject. | YES | SAFE TO SOURCE PHOTO NOW |
| FR059 | Cherimoya | *Annona cherimola* | Meaningful Indian cultivation or consumption needs confirmation; the named species fixes the subject. | YES | SAFE TO SOURCE PHOTO NOW |
| FR060 | Atemoya | *Annona × atemoya* | Distinct Indian product relevance needs confirmation; the named hybrid fixes the subject, provided the original photo source identifies the hybrid rather than only a parent. | YES | SAFE TO SOURCE PHOTO NOW |
| FR063 | Indian Persimmon | *Diospyros peregrina* | Indian food use and the name-to-taxon match are unresolved; Indian sources use this common name for D. malabarica and sometimes conflate the two names. | NO | HOLD PHOTO UNTIL REVIEW |
| FR066 | Mahua Fruit | *Madhuca longifolia* | Edible use of the fruit needs separation from the better-documented flower and seed uses; photograph the fruit itself. | YES | SAFE TO SOURCE PHOTO NOW |
| FR068 | Jujube | *Ziziphus jujuba* | Distinct Indian cultivation or consumption needs confirmation apart from ber (Z. mauritiana); the named species fixes the subject. | YES | SAFE TO SOURCE PHOTO NOW |
| FR077 | Indian Date Palm | *Phoenix sylvestris* | Food use of the fruit needs verification apart from sap use; photograph the fruit, not sap collection. | YES | SAFE TO SOURCE PHOTO NOW |
| FR080 | Persian Lime | *Citrus × latifolia* | Distinct Indian cultivation needs verification apart from acid lime; the named hybrid fixes the subject. | YES | SAFE TO SOURCE PHOTO NOW |
| FR083 | Kaffir Lime | *Citrus hystrix* | Indian fruit use needs verification, and makrut lime imagery must be distinguished from regional Satkara/Hatkora labels that may be mapped into the same taxonomic complex. | NO | HOLD PHOTO UNTIL REVIEW |
| FR085 | Sweet Granadilla | *Passiflora ligularis* | Distinct Indian cultivation and consumer relevance need confirmation; the named species fixes the subject. | YES | SAFE TO SOURCE PHOTO NOW |
| FR086 | Prickly Pear | *Opuntia ficus-indica* | Meaningful Indian food use of the fruit needs confirmation beyond planting or naturalization; the named species fixes the subject. | YES | SAFE TO SOURCE PHOTO NOW |
| FR093 | Mango Plum | *Bouea macrophylla* | Meaningful Indian cultivation or food use needs confirmation; the named species fixes the subject despite the broad common name. | YES | SAFE TO SOURCE PHOTO NOW |
| FR096 | Fig Mulberry | *Ficus racemosa* | Locally documented food use of the fruit needs confirmation; the named species fixes the subject. | YES | SAFE TO SOURCE PHOTO NOW |
| FR097 | Strawberry Guava | *Psidium cattleianum* | Meaningful Indian cultivation or food use needs confirmation; the named species fixes the subject. | YES | SAFE TO SOURCE PHOTO NOW |

FR048 remains on hold because [Kew places *Citrus × limettioides* under *C. × limon*](https://powo.science.kew.org/taxon/urn%3Alsid%3Aipni.org%3Anames%3A771957-1), whereas the app record is the Mosambi consumer fruit. FR063 remains on hold because [Kew accepts *D. peregrina*](https://powo.science.kew.org/taxon/urn%3Alsid%3Aipni.org%3Anames%3A322850-1/general-information) and [*D. malabarica*](https://powo.science.kew.org/taxon/322658-1) separately, while [University of Kerala uses Indian persimmon for *D. malabarica* and lists *D. peregrina* as a synonym](https://www.keralauniversity.ac.in/digital_garden/128.html). FR083 remains on hold until the app's makrut-lime photo identity is separated from Satkara/Hatkora usage; [Kew accepts *C. hystrix*](https://powo.science.kew.org/taxon/urn%3Alsid%3Aipni.org%3Anames%3A771927-1/general-information) and [places *C. macroptera* under it](https://powo.science.kew.org/taxon/771970-1). These are editorial holds, not changes to the catalogue.

## Safe-to-source batches

Within each batch, IDs are in ascending canonical order. Process batches in the order shown; batch membership is fixed by the current catalogue and the three holds. The four columns below mirror the manifest identity fields.

### Batch 1 (20 fruits)

| fruit_id | fruit_name | scientific_name | expected image path |
|---|---|---|---|
| FR001 | Mango | *Mangifera indica* | `assets/images/fruits/FR001.webp` |
| FR002 | Banana | *Musa spp.* | `assets/images/fruits/FR002.webp` |
| FR003 | Guava | *Psidium guajava* | `assets/images/fruits/FR003.webp` |
| FR004 | Papaya | *Carica papaya* | `assets/images/fruits/FR004.webp` |
| FR005 | Grapes | *Vitis vinifera* | `assets/images/fruits/FR005.webp` |
| FR006 | Sapota | *Manilkara zapota* | `assets/images/fruits/FR006.webp` |
| FR007 | Lime | *Citrus aurantiifolia* | `assets/images/fruits/FR007.webp` |
| FR008 | Lemon | *Citrus limon* | `assets/images/fruits/FR008.webp` |
| FR009 | Aonla | *Phyllanthus emblica* | `assets/images/fruits/FR009.webp` |
| FR010 | Apple | *Malus domestica* | `assets/images/fruits/FR010.webp` |
| FR011 | Pomegranate | *Punica granatum* | `assets/images/fruits/FR011.webp` |
| FR012 | Pineapple | *Ananas comosus* | `assets/images/fruits/FR012.webp` |
| FR013 | Litchi | *Litchi chinensis* | `assets/images/fruits/FR013.webp` |
| FR014 | Custard Apple | *Annona squamosa* | `assets/images/fruits/FR014.webp` |
| FR015 | Watermelon | *Citrullus lanatus* | `assets/images/fruits/FR015.webp` |
| FR016 | Muskmelon | *Cucumis melo* | `assets/images/fruits/FR016.webp` |
| FR017 | Jackfruit | *Artocarpus heterophyllus* | `assets/images/fruits/FR017.webp` |
| FR018 | Bael | *Aegle marmelos* | `assets/images/fruits/FR018.webp` |
| FR019 | Ber | *Ziziphus mauritiana* | `assets/images/fruits/FR019.webp` |
| FR020 | Jamun | *Syzygium cumini* | `assets/images/fruits/FR020.webp` |

### Batch 2 (20 fruits)

| fruit_id | fruit_name | scientific_name | expected image path |
|---|---|---|---|
| FR021 | Karonda | *Carissa carandas* | `assets/images/fruits/FR021.webp` |
| FR022 | Phalsa | *Grewia asiatica* | `assets/images/fruits/FR022.webp` |
| FR023 | Tamarind | *Tamarindus indica* | `assets/images/fruits/FR023.webp` |
| FR024 | Kokum | *Garcinia indica* | `assets/images/fruits/FR024.webp` |
| FR025 | Avocado | *Persea americana* | `assets/images/fruits/FR025.webp` |
| FR026 | Dragon Fruit | *Selenicereus spp.* | `assets/images/fruits/FR026.webp` |
| FR027 | Strawberry | *Fragaria × ananassa* | `assets/images/fruits/FR027.webp` |
| FR028 | Peach | *Prunus persica* | `assets/images/fruits/FR028.webp` |
| FR029 | Plum | *Prunus domestica / Prunus salicina* | `assets/images/fruits/FR029.webp` |
| FR030 | Pear | *Pyrus spp.* | `assets/images/fruits/FR030.webp` |
| FR031 | Apricot | *Prunus armeniaca* | `assets/images/fruits/FR031.webp` |
| FR032 | Cherry | *Prunus avium / P. cerasus* | `assets/images/fruits/FR032.webp` |
| FR033 | Kiwi | *Actinidia deliciosa* | `assets/images/fruits/FR033.webp` |
| FR034 | Persimmon | *Diospyros kaki* | `assets/images/fruits/FR034.webp` |
| FR035 | Fig | *Ficus carica* | `assets/images/fruits/FR035.webp` |
| FR036 | Mulberry | *Morus spp.* | `assets/images/fruits/FR036.webp` |
| FR037 | Loquat | *Eriobotrya japonica* | `assets/images/fruits/FR037.webp` |
| FR038 | Passion Fruit | *Passiflora edulis* | `assets/images/fruits/FR038.webp` |
| FR039 | Rambutan | *Nephelium lappaceum* | `assets/images/fruits/FR039.webp` |
| FR040 | Mangosteen | *Garcinia mangostana* | `assets/images/fruits/FR040.webp` |

### Batch 3 (20 fruits)

| fruit_id | fruit_name | scientific_name | expected image path |
|---|---|---|---|
| FR041 | Durian | *Durio zibethinus* | `assets/images/fruits/FR041.webp` |
| FR042 | Star Fruit | *Averrhoa carambola* | `assets/images/fruits/FR042.webp` |
| FR043 | Wood Apple | *Limonia acidissima* | `assets/images/fruits/FR043.webp` |
| FR044 | Coconut | *Cocos nucifera* | `assets/images/fruits/FR044.webp` |
| FR045 | Cashew Apple | *Anacardium occidentale* | `assets/images/fruits/FR045.webp` |
| FR047 | Orange | *Citrus sinensis* | `assets/images/fruits/FR047.webp` |
| FR049 | Mandarin | *Citrus reticulata* | `assets/images/fruits/FR049.webp` |
| FR050 | Grapefruit | *Citrus × paradisi* | `assets/images/fruits/FR050.webp` |
| FR051 | Pomelo | *Citrus maxima* | `assets/images/fruits/FR051.webp` |
| FR052 | Citron | *Citrus medica* | `assets/images/fruits/FR052.webp` |
| FR053 | Cape Gooseberry | *Physalis peruviana* | `assets/images/fruits/FR053.webp` |
| FR054 | Water Apple | *Syzygium aqueum* | `assets/images/fruits/FR054.webp` |
| FR055 | Rose Apple | *Syzygium jambos* | `assets/images/fruits/FR055.webp` |
| FR056 | Malay Apple | *Syzygium malaccense* | `assets/images/fruits/FR056.webp` |
| FR057 | Breadfruit | *Artocarpus altilis* | `assets/images/fruits/FR057.webp` |
| FR058 | Soursop | *Annona muricata* | `assets/images/fruits/FR058.webp` |
| FR059 | Cherimoya | *Annona cherimola* | `assets/images/fruits/FR059.webp` |
| FR060 | Atemoya | *Annona × atemoya* | `assets/images/fruits/FR060.webp` |
| FR061 | Bilimbi | *Averrhoa bilimbi* | `assets/images/fruits/FR061.webp` |
| FR064 | Tendu | *Diospyros melanoxylon* | `assets/images/fruits/FR064.webp` |

### Batch 4 (20 fruits)

| fruit_id | fruit_name | scientific_name | expected image path |
|---|---|---|---|
| FR065 | Khirni | *Manilkara hexandra* | `assets/images/fruits/FR065.webp` |
| FR066 | Mahua Fruit | *Madhuca longifolia* | `assets/images/fruits/FR066.webp` |
| FR067 | Lasora | *Cordia dichotoma* | `assets/images/fruits/FR067.webp` |
| FR068 | Jujube | *Ziziphus jujuba* | `assets/images/fruits/FR068.webp` |
| FR069 | Chironji Fruit | *Buchanania lanzan* | `assets/images/fruits/FR069.webp` |
| FR070 | Burmese Grape | *Baccaurea ramiflora* | `assets/images/fruits/FR070.webp` |
| FR071 | Governor's Plum | *Flacourtia indica* | `assets/images/fruits/FR071.webp` |
| FR072 | Indian Plum | *Flacourtia jangomas* | `assets/images/fruits/FR072.webp` |
| FR073 | Bakul Fruit | *Mimusops elengi* | `assets/images/fruits/FR073.webp` |
| FR074 | Palmyra Fruit | *Borassus flabellifer* | `assets/images/fruits/FR074.webp` |
| FR076 | Date | *Phoenix dactylifera* | `assets/images/fruits/FR076.webp` |
| FR077 | Indian Date Palm | *Phoenix sylvestris* | `assets/images/fruits/FR077.webp` |
| FR079 | Olive | *Olea europaea* | `assets/images/fruits/FR079.webp` |
| FR080 | Persian Lime | *Citrus × latifolia* | `assets/images/fruits/FR080.webp` |
| FR085 | Sweet Granadilla | *Passiflora ligularis* | `assets/images/fruits/FR085.webp` |
| FR086 | Prickly Pear | *Opuntia ficus-indica* | `assets/images/fruits/FR086.webp` |
| FR088 | Noni | *Morinda citrifolia* | `assets/images/fruits/FR088.webp` |
| FR091 | Hog Plum | *Spondias pinnata* | `assets/images/fruits/FR091.webp` |
| FR092 | Ambarella | *Spondias dulcis* | `assets/images/fruits/FR092.webp` |
| FR093 | Mango Plum | *Bouea macrophylla* | `assets/images/fruits/FR093.webp` |

### Batch 5 (20 fruits)

| fruit_id | fruit_name | scientific_name | expected image path |
|---|---|---|---|
| FR094 | Yellow Mangosteen | *Garcinia xanthochymus* | `assets/images/fruits/FR094.webp` |
| FR095 | Kadam Fruit | *Neolamarckia cadamba* | `assets/images/fruits/FR095.webp` |
| FR096 | Fig Mulberry | *Ficus racemosa* | `assets/images/fruits/FR096.webp` |
| FR097 | Strawberry Guava | *Psidium cattleianum* | `assets/images/fruits/FR097.webp` |
| FR098 | White Sapote | *Casimiroa edulis* | `assets/images/fruits/FR098.webp` |
| FR099 | Black Sapote | *Diospyros nigra* | `assets/images/fruits/FR099.webp` |
| FR100 | Mamey Sapote | *Pouteria sapota* | `assets/images/fruits/FR100.webp` |
| FR101 | Longan | *Dimocarpus longan* | `assets/images/fruits/FR101.webp` |
| FR102 | Sohiong | *Prunus nepalensis* | `assets/images/fruits/FR102.webp` |
| FR103 | Sohshang | *Elaeagnus latifolia* | `assets/images/fruits/FR103.webp` |
| FR104 | Elephant Apple | *Dillenia indica* | `assets/images/fruits/FR104.webp` |
| FR105 | Sea Buckthorn | *Hippophae rhamnoides* | `assets/images/fruits/FR105.webp` |
| FR106 | Tamarillo | *Solanum betaceum* | `assets/images/fruits/FR106.webp` |
| FR107 | Star Apple | *Chrysophyllum cainito* | `assets/images/fruits/FR107.webp` |
| FR108 | Acerola | *Malpighia emarginata* | `assets/images/fruits/FR108.webp` |
| FR109 | Blood Fruit | *Haematocarpus validus* | `assets/images/fruits/FR109.webp` |
| FR110 | Wax Apple | *Syzygium samarangense* | `assets/images/fruits/FR110.webp` |
| FR111 | Sohphie | *Myrica esculenta* | `assets/images/fruits/FR111.webp` |
| FR112 | Star Gooseberry | *Phyllanthus acidus* | `assets/images/fruits/FR112.webp` |
| FR113 | Surinam Cherry | *Eugenia uniflora* | `assets/images/fruits/FR113.webp` |

### Batch 6 (12 fruits)

| fruit_id | fruit_name | scientific_name | expected image path |
|---|---|---|---|
| FR114 | Naga Tenga | *Rhus semialata* | `assets/images/fruits/FR114.webp` |
| FR115 | Tropical Apricot | *Dovyalis abyssinica* | `assets/images/fruits/FR115.webp` |
| FR116 | Velvet Apple | *Diospyros discolor* | `assets/images/fruits/FR116.webp` |
| FR117 | Andaman Garcinia | *Garcinia andamanica* | `assets/images/fruits/FR117.webp` |
| FR118 | Antidesma Berry | *Antidesma ghaesembilla* | `assets/images/fruits/FR118.webp` |
| FR119 | Langsat | *Lansium parasiticum* | `assets/images/fruits/FR119.webp` |
| FR120 | Moottipazham | *Baccaurea courtallensis* | `assets/images/fruits/FR120.webp` |
| FR121 | Ramphal | *Annona reticulata* | `assets/images/fruits/FR121.webp` |
| FR122 | Jungle Jalebi | *Pithecellobium dulce* | `assets/images/fruits/FR122.webp` |
| FR123 | Malabar Tamarind | *Garcinia gummi-gutta* | `assets/images/fruits/FR123.webp` |
| FR124 | Bor Thekera | *Garcinia pedunculata* | `assets/images/fruits/FR124.webp` |
| FR125 | Monkey Jack | *Artocarpus lakoocha* | `assets/images/fruits/FR125.webp` |

## Source and license policy for the later image phase

- For common fruits, search Pexels, Unsplash, or Pixabay first. For rare or species-specific fruits, search Wikimedia Commons; Openverse is only a discovery layer. An iNaturalist observation is eligible only if the **individual photograph**, not merely its observation data, has an acceptable commercial-use license. [iNaturalist says photo licenses are individually visible and its default is CC BY-NC](https://help.inaturalist.org/en/support/solutions/articles/151000175695).
- Accept a verified Public Domain dedication/status, [CC0](https://creativecommons.org/publicdomain/zero/1.0/), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), or a clearly applicable [Pexels](https://www.pexels.com/license/), [Unsplash](https://unsplash.com/license), or [Pixabay Content License](https://pixabay.com/service/license-summary/). Record the exact license and original photo page for each candidate. CC BY 4.0 requires attribution, license link, and modification notice. Stock-platform licenses have their own restrictions, including limits on unaltered standalone distribution or implied endorsement.
- Reject CC BY-NC, CC BY-ND, All Rights Reserved, unknown or unclear licenses, Pinterest, Google Images as a source, random blogs, and reposts without verifiable original provenance. Do not select CC BY-SA as a routine option; any exceptional proposal needs a separate review of ShareAlike obligations before use.
- Verify the license on the original image page and record the source platform, page URL, original image URL, creator, license and license URL, attribution, access date, commercial-use and modification checks, verification notes, file hashes, and approval status in the manifest **only when an image is actually reviewed**. A downloadable file or a search result alone is insufficient.

## Photo quality and identity checks

- Use a real photograph with the fruit as the primary subject, natural colors, adequate resolution, no watermark or text overlay, no collage, no brand packaging, and no person as the primary subject. Prefer landscape or square-friendly framing that survives the app crop.
- Match the **scientific identity**, not the common name alone. For rare fruits, botanical correctness takes priority over composition. Reject an attractive photo if its species or hybrid cannot be verified from the original source.
- For group-level catalogue records (for example FR002 Banana, FR026 Dragon Fruit, FR029 Plum, FR030 Pear, FR032 Cherry, and FR036 Mulberry), choose a representative member of the stated group and record the photographed taxon in `verification_notes`. For FR060, a photo labelled only cherimoya or custard apple is insufficient. For FR066 and FR077, show the fruit rather than another useful plant part.

## Manifest readiness

`docs/image_sources/fruit_photo_manifest.csv` has one row for each of the 115 active IDs. Its `fruit_id`, `fruit_name`, `scientific_name`, and `image_asset` fields match the catalogue. All photo-source and approval fields remain blank. The manifest is unchanged by this queue.
