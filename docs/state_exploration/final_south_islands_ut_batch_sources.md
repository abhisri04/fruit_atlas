# Final South, islands and UT State Exploration source ledger

Checked on 2026-09-20. Government, administration and official tourism sources substantiate the six new datasets. IDs below refer to records in `assets/data/<id>_experiences.json`. Runtime data has no source fields.

## Administrative baseline

| Context | District records | Authority |
|---|---:|---|
| Kerala | 14 (Alappuzha, Ernakulam, Idukki, Kannur, Kasaragod, Kollam, Kottayam, Kozhikode, Malappuram, Palakkad, Pathanamthitta, Thiruvananthapuram, Thrissur, Wayanad) | [Government district directory](https://igod.gov.in/sg/KL/E042/organizations) |
| Tamil Nadu | 38 (Ariyalur, Chengalpattu, Chennai, Coimbatore, Cuddalore, Dharmapuri, Dindigul, Erode, Kallakurichi, Kancheepuram, Kanniyakumari, Karur, Krishnagiri, Madurai, Mayiladuthurai, Nagapattinam, Namakkal, Perambalur, Pudukkottai, Ramanathapuram, Ranipet, Salem, Sivaganga, Tenkasi, Thanjavur, The Nilgiris, Theni, Thoothukudi, Tiruchirappalli, Tirunelveli, Tirupathur, Tiruppur, Tiruvallur, Tiruvannamalai, Tiruvarur, Vellore, Viluppuram, Virudhunagar) | [Government district directory](https://igod.gov.in/sg/TN/E042/organizations) |
| Puducherry | 2 (Puducherry, Karaikal) | [Government district directory](https://www.py.gov.in/districts) |
| Andaman & Nicobar Islands | 3 (Nicobar, North and Middle Andaman, South Andaman) | [Government district directory](https://igod.gov.in/sg/AN/E042/organizations) |
| Lakshadweep | 1 (Lakshadweep) | [Government district directory](https://lakshadweep.gov.in/about-lakshadweep/administrative-setup/) |
| Dadra & Nagar Haveli and Daman & Diu | 3 (Dadra & Nagar Haveli, Daman, Diu) | [Government district directory](https://ddd.gov.in/faqs/) |

Puducherry is modelled as two revenue districts: Puducherry (including the outlying Mahe and Yanam administrative units) and Karaikal. The [government districts page](https://www.py.gov.in/districts) explicitly lists two, yet its surrounding prose loosely refers to four districts; the [planning department document](https://pandr.py.gov.in/sites/default/files/Sectoral%20Document%202019-2020.pdf) also specifies two revenue districts. The four regional/census units should not be counted as four revenue districts.

Lakshadweep is one district covering multiple islands; islands are not districts. The merged Dadra & Nagar Haveli and Daman & Diu UT has three districts, not four. Tourism experiences on islands are limited to publicly accessible, permitted activities; the datasets do not invite visits to protected tribal areas. Lakshadweep water activities are subject to the applicable permits and operators.

## Experience evidence

Each row covers all listed IDs. The source supports the named subject or tradition; descriptions are concise editorial summaries, not quotations.

### Kerala

| Collection | Experience ID(s) | Official source |
|---|---|---|
| Landmarks Heritage | `exp_kerala_mattancherry_palace`, `exp_kerala_paradesi_synagogue`, `exp_kerala_bekal_fort`, `exp_kerala_palakkad_fort`, `exp_kerala_thalassery_fort`, `exp_kerala_shakthan_thampuran_palace` | [Source](https://www.incredibleindia.gov.in/en/kerala) |
| Nature Wildlife | `exp_kerala_eravikulam_national_park`, `exp_kerala_periyar_national_park`, `exp_kerala_silent_valley_national_park` | [Source](https://www.incredibleindia.gov.in/en/kerala) |
| Nature Wildlife | `exp_kerala_athirappilly_falls`, `exp_kerala_vazhachal_falls` | [Source](https://www.keralatourism.org/destination/athirappalli-vazhachal-waterfalls/79/) |
| Experiences Activities | `exp_kerala_cruise_the_alappuzha_backwaters` | [Source](https://www.keralatourism.org/houseboat/) |
| Experiences Activities | `exp_kerala_watch_a_kalaripayattu_demonstration` | [Source](https://www.keralatourism.org/faq/what-are-the-traditional-martial-arts-of-kerala) |
| Dishes | `exp_kerala_puttu_and_kadala_curry`, `exp_kerala_appam_and_stew`, `exp_kerala_karimeen_pollichathu`, `exp_kerala_ada_pradhaman`, `exp_kerala_kappa_and_fish_curry`, `exp_kerala_pazham_pori`, `exp_kerala_kerala_sadya` | [Source](https://www.keralatourism.org/responsible-tourism/ethnic-cuisine/dishes/karimeen-vatti-pattichathu-units/60) |
| Drinks | `exp_kerala_sulaimani_tea` | [Source](https://www.keralatourism.org/malabar/malabar-cuisine/55) |
| Arts Crafts | `exp_kerala_aranmula_kannadi`, `exp_kerala_balaramapuram_handloom`, `exp_kerala_nettur_petti`, `exp_kerala_kerala_mural_painting` | [Source](https://www.keralatourism.org/campaigns/kerala365/arts-crafts-village-vellar-kerala) |
| Festivals Fairs | `exp_kerala_onam`, `exp_kerala_thrissur_pooram`, `exp_kerala_nishagandhi_dance_and_music_festival` | [Source](https://www.keralatourism.org/1000festivals/index.php/Festival_directory) |
| Music Dance | `exp_kerala_kathakali`, `exp_kerala_mohiniyattam`, `exp_kerala_theyyam`, `exp_kerala_thiruvathirakali` | [Source](https://www.incredibleindia.gov.in/en/kerala) |

### Tamil Nadu

| Collection | Experience ID(s) | Official source |
|---|---|---|
| Landmarks Heritage | `exp_tamil_nadu_shore_temple_at_mamallapuram`, `exp_tamil_nadu_brihadeeswara_temple_at_thanjavur`, `exp_tamil_nadu_gangaikonda_cholapuram_temple`, `exp_tamil_nadu_airavatesvara_temple_at_darasuram`, `exp_tamil_nadu_vivekananda_rock_memorial`, `exp_tamil_nadu_padmanabhapuram_palace` | [Source](https://www.incredibleindia.gov.in/en/tamil-nadu) |
| Nature Wildlife | `exp_tamil_nadu_mudumalai_tiger_reserve`, `exp_tamil_nadu_guindy_national_park`, `exp_tamil_nadu_vedanthangal_bird_sanctuary`, `exp_tamil_nadu_pichavaram_mangroves` | [Source](https://www.incredibleindia.gov.in/en/tamil-nadu) |
| Experiences Activities | `exp_tamil_nadu_ride_the_nilgiri_mountain_railway` | [Source](https://www.incredibleindia.gov.in/en/tamil-nadu) |
| Dishes | `exp_tamil_nadu_ven_pongal`, `exp_tamil_nadu_sakkarai_pongal`, `exp_tamil_nadu_sundal`, `exp_tamil_nadu_thayir_sadam` | [Source](https://www.incredibleindia.gov.in/en/tamil-nadu/chennai/a-foodies-guide-to-trying-local) |
| Dishes | `exp_tamil_nadu_kanchipuram_idli` | [Source](https://www.incredibleindia.gov.in/en/tamil-nadu/kanchipuram) |
| Drinks | `exp_tamil_nadu_madurai_jigarthanda` | [Source](https://www.incredibleindia.gov.in/en/trips/trip-listing/unravelling-madurai-s-cultural-and-historical-threads) |
| Arts Crafts | `exp_tamil_nadu_kanchipuram_silk`, `exp_tamil_nadu_nagercoil_temple_jewellery`, `exp_tamil_nadu_thanjavur_dolls` | [Source](https://www.pib.gov.in/FactsheetDetails.aspx?ModuleId=16&id=150307&lang=1&reg=37) |
| Arts Crafts | `exp_tamil_nadu_thanjavur_painting` | [Source](https://www.incredibleindia.gov.in/en/tamil-nadu/thanjavur) |
| Festivals Fairs | `exp_tamil_nadu_pongal_festival`, `exp_tamil_nadu_chennai_margazhi_music_season` | [Source](https://www.incredibleindia.gov.in/en/tamil-nadu/chennai) |
| Festivals Fairs | `exp_tamil_nadu_mamallapuram_indian_dance_festival` | [Source](https://utsav.gov.in/view-event/indian-dance-festival-2) |
| Music Dance | `exp_tamil_nadu_bharatanatyam` | [Source](https://www.incredibleindia.gov.in/en/tamil-nadu) |

### Puducherry

| Collection | Experience ID(s) | Official source |
|---|---|---|
| Landmarks Heritage | `exp_puducherry_sri_aurobindo_ashram`, `exp_puducherry_manakula_vinayagar_temple` | [Source](https://www.incredibleindia.gov.in/en/puducherry/puducherry/exploring-puducherry) |
| Landmarks Heritage | `exp_puducherry_arikamedu_archaeological_site` | [Source](https://www.incredibleindia.gov.in/en/puducherry/puducherry/arikamedu) |
| Landmarks Heritage | `exp_puducherry_puducherry_museum` | [Source](https://www.py.gov.in/districts) |
| Landmarks Heritage | `exp_puducherry_thirunallar_dharbaranyeswarar_temple` | [Source](https://karaikal.gov.in/places-of-interest/) |
| Nature Wildlife | `exp_puducherry_ousteri_lake`, `exp_puducherry_paradise_beach`, `exp_puducherry_puducherry_botanical_garden` | [Source](https://www.incredibleindia.gov.in/en/puducherry/puducherry) |
| Experiences Activities | `exp_puducherry_boat_on_the_chunnambar_backwaters` | [Source](https://www.incredibleindia.gov.in/en/puducherry/puducherry/chunnambar-boat-house) |
| Experiences Activities | `exp_puducherry_walk_puducherry_s_french_quarter` | [Source](https://www.incredibleindia.gov.in/en/puducherry) |
| Dishes | `exp_puducherry_kadugu_yerra` | [Source](https://www.prod.incredibleindia.gov.in/content/incredible-india-v2/en/destinations/puducherry/food-and-cuisine.html) |
| Arts Crafts | `exp_puducherry_villianur_terracotta` | [Source](https://www.incredibleindia.gov.in/en/puducherry/villianur-terracotta-works) |
| Arts Crafts | `exp_puducherry_puducherry_bommai` | [Source](https://www.incredibleindia.gov.in/en/puducherry/puducherry/embrace-the-cultural-kaleidoscope-of-puducherry) |
| Festivals Fairs | `exp_puducherry_karaikal_mangani_festival` | [Source](https://karaikal.gov.in/places-of-interest/) |
| Festivals Fairs | `exp_puducherry_puducherry_masquerade_festival` | [Source](https://www.presidentofindia.gov.in/speeches/address-honble-president-india-smt-droupadi-murmu-civic-reception-puducherry-and-virtual) |
| Music Dance | `exp_puducherry_garadi` | [Source](https://www.education.gov.in/sites/upload_files/mhrd/files/ebsb%20letter%2020.11.2020.pdf) |

### Andaman & Nicobar Islands

| Collection | Experience ID(s) | Official source |
|---|---|---|
| Landmarks Heritage | `exp_andaman_nicobar_cellular_jail_national_memorial`, `exp_andaman_nicobar_chatham_saw_mill`, `exp_andaman_nicobar_samudrika_naval_marine_museum`, `exp_andaman_nicobar_zonal_anthropological_museum` | [Source](https://southandaman.nic.in/tourism/) |
| Nature Wildlife | `exp_andaman_nicobar_mahatma_gandhi_marine_national_park`, `exp_andaman_nicobar_chidiya_tapu`, `exp_andaman_nicobar_wandoor_beach` | [Source](https://southandaman.nic.in/tourism/) |
| Nature Wildlife | `exp_andaman_nicobar_radhanagar_beach` | [Source](https://tourism.andamannicobar.gov.in/) |
| Experiences Activities | `exp_andaman_nicobar_scuba_dive_off_swaraj_dweep` | [Source](https://tourism.andamannicobar.gov.in/) |
| Experiences Activities | `exp_andaman_nicobar_cellular_jail_sound_and_light_show` | [Source](https://www.andamantourism.gov.in/faq.php) |
| Dishes | `exp_andaman_nicobar_andaman_prawn_curry` | [Source](https://www.incredibleindia.gov.in/en/andaman-and-nicobar-islands) |
| Arts Crafts | `exp_andaman_nicobar_nicobari_hodi_craft` | [Source](https://search.ipindia.gov.in/GIRPublicSearch/Application/Details/998) |
| Arts Crafts | `exp_andaman_nicobar_nicobari_mat_weaving`, `exp_andaman_nicobar_andaman_padauk_wood_craft` | [Source](https://andamannicobar.gov.in/admin-pannel/newsletterupload/699fcacb23f275.01906640-4th%20Edition%20Newsletter1.pdf.pdf) |
| Festivals Fairs | `exp_andaman_nicobar_island_tourism_festival` | [Source](https://www.utsav.gov.in/view-event/island-tourism-festival-1) |
| Festivals Fairs | `exp_andaman_nicobar_andaman_island_food_festival` | [Source](https://tourism.andamannicobar.gov.in/userpages/admin/whatsnewfile/2026041389Application%20for%20Cultural%20programme%20during%20Island%20Food%20Festival%202026.pdf) |
| Music Dance | `exp_andaman_nicobar_nicobari_dance` | [Source](https://www.incredibleindia.gov.in/en/andaman-and-nicobar-islands/sri-vijaya-puram/a-tapestry-of-rich-culture-and-tradition) |

### Lakshadweep

| Collection | Experience ID(s) | Official source |
|---|---|---|
| Landmarks Heritage | `exp_lakshadweep_minicoy_lighthouse` | [Source](https://www.incredibleindia.gov.in/en/lakshadweep) |
| Landmarks Heritage | `exp_lakshadweep_lakshadweep_heritage_museum` | [Source](https://lakshadweep.gov.in/department-of-art-and-culture/) |
| Nature Wildlife | `exp_lakshadweep_bangaram_lagoon` | [Source](https://lakshadweep.gov.in/islands/bangaram/) |
| Nature Wildlife | `exp_lakshadweep_kalpeni_atoll` | [Source](https://lakshadweep.gov.in/tourist-place/kalpeni/) |
| Experiences Activities | `exp_lakshadweep_scuba_dive_off_kadmat` | [Source](https://lakshadweeptourism.com/documents/Scuba%20Broucher.pdf) |
| Experiences Activities | `exp_lakshadweep_lakshadweep_samudram_cruise` | [Source](https://www.lakshadweeptourism.com/) |
| Dishes | `exp_lakshadweep_masmin` | [Source](https://lakshadweep.gov.in/departments/fisheries-2/) |
| Arts Crafts | `exp_lakshadweep_minicoy_jahadhoni_boat_craft`, `exp_lakshadweep_minicoy_wooden_swing_cots` | [Source](https://www.incredibleindia.gov.in/en/lakshadweep/kavaratti/minicoy) |
| Festivals Fairs | `exp_lakshadweep_national_minicoy_fest` | [Source](https://utsav.gov.in/view-event/national-minicoy-fest) |
| Music Dance | `exp_lakshadweep_lava_dance`, `exp_lakshadweep_kolkali`, `exp_lakshadweep_parichakali` | [Source](https://lakshadweep.gov.in/about-lakshadweep/culture-heritage/) |

### Dadra & Nagar Haveli and Daman & Diu

| Collection | Experience ID(s) | Official source |
|---|---|---|
| Landmarks Heritage | `exp_dadra_nagar_haveli_daman_diu_silvassa_tribal_cultural_museum`, `exp_dadra_nagar_haveli_daman_diu_church_of_our_lady_of_piety_silvassa`, `exp_dadra_nagar_haveli_daman_diu_nani_daman_fort`, `exp_dadra_nagar_haveli_daman_diu_moti_daman_fort`, `exp_dadra_nagar_haveli_daman_diu_diu_fort`, `exp_dadra_nagar_haveli_daman_diu_st_paul_s_church_diu` | [Source](https://www.incredibleindia.gov.in/en/dadra-and-nagar-haveli-and-daman-and-diu) |
| Nature Wildlife | `exp_dadra_nagar_haveli_daman_diu_vanganga_lake_garden`, `exp_dadra_nagar_haveli_daman_diu_nagoa_beach` | [Source](https://www.incredibleindia.gov.in/en/dadra-and-nagar-haveli-and-daman-and-diu) |
| Experiences Activities | `exp_dadra_nagar_haveli_daman_diu_boat_on_dudhni_lake` | [Source](https://www.incredibleindia.gov.in/en/dadra-and-nagar-haveli-and-daman-and-diu) |
| Dishes | `exp_dadra_nagar_haveli_daman_diu_daman_jetty_roll` | [Source](https://www.prod.incredibleindia.gov.in/content/incredible-india-v2/en/destinations/daman/food-and-cuisine.html) |
| Arts Crafts | `exp_dadra_nagar_haveli_daman_diu_daman_mat_weaving` | [Source](https://cdnbbsr.s3waas.gov.in/s32d2ca7eedf739ef4c3800713ec482e1a/uploads/2023/09/2023092156.pdf) |
| Festivals Fairs | `exp_dadra_nagar_haveli_daman_diu_festa_de_diu` | [Source](https://www.presidentofindia.gov.in/shri-pranab-mukherjee/speeches/speech-president-india-shri-pranab-mukherjee-occasion-19) |
| Music Dance | `exp_dadra_nagar_haveli_daman_diu_tarpa_dance`, `exp_dadra_nagar_haveli_daman_diu_bhawada_dance`, `exp_dadra_nagar_haveli_daman_diu_tur_and_thali_dance` | [Source](https://www.incredibleindia.gov.in/en/dadra-and-nagar-haveli-and-daman-and-diu) |

The Kerala Sulaimani tea reference comes from Kerala Tourism?s Malabar cuisine guide. Lakshadweep?s Masmin reference comes from the UT Fisheries Department. The Chennai Margazhi music season has one Tamil Nadu experience record with two collection memberships. Fruit memberships are derived at runtime from the canonical Fruit Atlas seed, so there are no Fruit source IDs in this ledger.
