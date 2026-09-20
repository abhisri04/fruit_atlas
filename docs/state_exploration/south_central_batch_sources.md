# South / central batch source ledger

Research checked 2026-09-17. This batch includes Mizoram and Tripura as well as the three southern states. Source metadata is documentation only; no runtime models were changed.

## Administrative baselines

| State | Districts | Current government baseline |
| --- | ---: | --- |
| Mizoram | 11 | [NIC government directory](https://igod.gov.in/sg/MZ/E042/organizations) |
| Tripura | 8 | [NIC government directory](https://igod.gov.in/sg/TR/E042/organizations) |
| Andhra Pradesh | 28 | [NIC government directory](https://igod.gov.in/sg/AP/E042/organizations), [state district history](https://allurisitharamaraju.ap.gov.in/history/) |
| Telangana | 33 | [State district web directory](https://www.telangana.gov.in/district-web-directory/) |
| Karnataka | 31 | [NIC government directory](https://igod.gov.in/sg/KA/E042/organizations) |

### Administrative differences resolved before creating runtime data

- Mizoram: older profiles and tourism introductions still mention eight districts. The current NIC directory includes Hnahthial, Khawzawl and Saitual, giving 11. Siaha is the current directory spelling; Saiha remains a search alias. See also [DIPR administrative profile](https://dipr.mizoram.gov.in/page/administrations).
- Andhra Pradesh: the 26-district baseline is superseded by 28 from 31 December 2025. [Markapuram](https://markapuram.ap.gov.in/about-district/) and [Polavaram](https://polavaram.ap.gov.in/) are included. District records do not infer tourist-site boundaries from older pages. Nellore, Kadapa and Anantapur are aliases for the selected administrative names.
- Telangana: use Hanumakonda and Warangal from the current state directory, retaining Warangal Urban/Rural as aliases. Kumuram Bheem follows the directory; Asifabad and Komaram Bheem are aliases, not extra districts.
- Karnataka: Bengaluru South follows its [current district portal](https://bengalurusouth.nic.in/en/); Ramanagara remains an alias. The current NIC district directory and [Bengaluru Rural district portal](https://bangalorerural.nic.in/en/) still use Bengaluru Rural. A July 2025 cabinet announcement described Bengaluru North, but the administrative portals consulted do not consistently implement it. This batch therefore retains Bengaluru Rural with Bengaluru North as an alias, and records that naming uncertainty rather than adding a district. The Bengaluru North municipal corporation is not a separate district. Vijayanagara is included; older 30-district tourism maps are not used for administrative counts.

## Canonical identity decisions

- New IDs are deterministic state-prefixed slugs. All new IDs and accent/punctuation/case-normalized titles were checked against every existing experience file before writing.
- Tholu Bommalata deliberately uses one ID (`exp_andhra_pradesh_tholu_bommalata`) in Andhra Pradesh Arts & Crafts and Music & Dance. There is one record and one completion state. It is not copied into Telangana.
- Bidriware is represented once, under Karnataka, despite retail availability in Hyderabad. Generic dosa, idli, Carnatic music and broadly shared festivals were not duplicated per state.
- Pesarattu (green gram) and Neer Dosa (thin rice batter) are different preparations. Hyderabadi Biryani is distinct from existing Awadhi Dum Biryani. Ragi Mudde is represented once, not again as Andhra ragi sangati. Bobbatlu/Obbattu were omitted because the shared stuffed sweet already exists as Puran Poli. Garijelu was omitted to avoid introducing another broadly shared filled-pastry identity.
- Srikalahasti hand painting and Machilipatnam block printing are separate textile processes. Kondapalli figures, Etikoppaka lacquer work and Channapatna toys represent distinct craft centres/traditions; none is labelled merely generic wooden toys. Risa and Rignai are different garments.
- Mizoram, Araku and Kodagu coffee entries identify verified growing origins, not three copies of generic filter coffee. Estate walks are activities distinct from tasting a brew. Tripura Tea and Hyderabadi Irani Chai are non-alcoholic. No alcoholic rice beverages are included.
- Neermahal is not duplicated as a Rudrasagar visit; Ujjayanta Palace/museum is one entity. Chabimura is one boat-based activity rather than a second heritage record. Vangchhia/Kawtchhuah Ropui is one archaeological entry. Hampi is an aggregate monument experience without duplicated individual temple records.
- Some broad tourism pages contain inconsistent food ingredients or regional attributions. Tripura food descriptions avoid disputed recipe details; no Chauk drink is included. Tangmuri and Wangala were not attributed to Mizoram. Administrative names always use the baseline above rather than tourism-page geography.

## Experience-to-source ledger

Each canonical ID below maps to the government/tourism source used for its identity and short description. Titles alone do not imply exclusive state ownership. The coffee origins also follow the [Coffee Board growing-region reference](https://coffeeboard.gov.in/coffee-regions-india.html).

### Mizoram

- **landmarks_heritage** â€” [Government/tourism source](https://mizoramtourism.com/things-to-do/Heritage): `exp_mizoram_vangchhia_monoliths`, `exp_mizoram_lamsial_puk`.
- **landmarks_heritage** â€” [Government/tourism source](https://aizawl.nic.in/tourist-place/typical-mizo-village-zokhua-falkawn/): `exp_mizoram_falkawn_zokhua`.
- **landmarks_heritage** â€” [Government/tourism source](https://hcikl.gov.in/pdf/menu/Newsletter_Sept_2025.pdf): `exp_mizoram_mizoram_state_museum`.
- **nature_wildlife** â€” [Government/tourism source](https://mizoramtourism.com/things-to-do/Nature): `exp_mizoram_vantawng_falls`, `exp_mizoram_tuirihiau_falls`, `exp_mizoram_tam_dil`, `exp_mizoram_palak_lake`, `exp_mizoram_murlen_national_park`, `exp_mizoram_phawngpui_national_park`.
- **experiences_activities** â€” [Government/tourism source](https://mizoramtourism.com/things-to-do/Hiking): `exp_mizoram_hike_reiek_hills`.
- **experiences_activities** â€” [Government/tourism source](https://thenzawlgolfresort.com/): `exp_mizoram_play_golf_at_thenzawl`.
- **dishes** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/mizoram/aizawl/taste-the-essence-of-aizawl): `exp_mizoram_bai`, `exp_mizoram_arsa_buhchiar`, `exp_mizoram_vawksa_rep`, `exp_mizoram_hmarcha_rawt`.
- **drinks** â€” [Government/tourism source](https://newsonair.gov.in/coffee-board-of-india-showcases-varieties-at-world-of-coffee-dubai/): `exp_mizoram_mizoram_coffee`.
- **arts_crafts** â€” [Government/tourism source](https://mistic.mizoram.gov.in/patent-information-centre/): `exp_mizoram_mizo_puanchei`, `exp_mizoram_tawlhlohpuan`, `exp_mizoram_pawndum`.
- **festivals_fairs** â€” [Government/tourism source](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2297053&lang=2&reg=48): `exp_mizoram_chapchar_kut`, `exp_mizoram_thalfavang_kut`, `exp_mizoram_mizoram_anthurium_festival`.
- **music_dance** â€” [Government/tourism source](https://forest.mizoram.gov.in/uploads/attachments/5752451f548b54d5017f7e59f9c7f801/splendid-wildlife-mizoram.pdf): `exp_mizoram_cheraw`, `exp_mizoram_khuallam`, `exp_mizoram_chheihlam`.

### Tripura

- **landmarks_heritage** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/tripura): `exp_tripura_neermahal`, `exp_tripura_ujjayanta_palace`, `exp_tripura_unakoti_rock_carvings`, `exp_tripura_pilak_archaeological_site`, `exp_tripura_tripura_sundari_temple`, `exp_tripura_bhuvaneswari_temple`.
- **nature_wildlife** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/tripura): `exp_tripura_jampui_hills`, `exp_tripura_sepahijala_wildlife_sanctuary`, `exp_tripura_gumti_wildlife_sanctuary`, `exp_tripura_dumboor_lake`.
- **experiences_activities** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/tripura/agartala/durgabari-tea-estate): `exp_tripura_walk_durgabari_tea_estate`.
- **experiences_activities** â€” [Government/tourism source](https://tourism.gov.in/sites/default/files/2025-02/MOT%20Annual%20Report_2022-23_English%20%282%29_0.pdf): `exp_tripura_boat_to_chabimura_rock_carvings`.
- **dishes** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/tripura): `exp_tripura_muya_awandru`, `exp_tripura_kosoi_bwtwi`, `exp_tripura_muya_bai_wahan`, `exp_tripura_gudok`, `exp_tripura_mosdeng_serma`.
- **drinks** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/tripura/agartala/durgabari-tea-estate): `exp_tripura_tripura_tea`.
- **arts_crafts** â€” [Government/tourism source](https://trlm.tripura.gov.in/sites/default/files/2023-08/SHG_PRODUCTS_AVAILABLE_AT_RURAL_MART.pdf): `exp_tripura_risa_weaving`, `exp_tripura_rignai_weaving`.
- **festivals_fairs** â€” [Government/tourism source](https://ignca.gov.in/online-digital-resources/archaeological-sites/introduction-tripura/): `exp_tripura_kharchi_puja`, `exp_tripura_garia_puja`.
- **festivals_fairs** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/tripura): `exp_tripura_ker_puja`, `exp_tripura_unakoti_ashokastami_fair`.
- **music_dance** â€” [Government/tourism source](https://ignca.gov.in/online-digital-resources/archaeological-sites/introduction-tripura/): `exp_tripura_hojagiri`, `exp_tripura_garia_dance`.
- **music_dance** â€” [Government/tourism source](https://rajbhavan-maharashtra.gov.in/en/21-01-2024-manipur-meghalaya-tripura-foundation-day-celebrated-in-maharashtra-raj-bhavan/): `exp_tripura_lebang_boomani`.

### Andhra Pradesh

- **landmarks_heritage** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/andhra-pradesh): `exp_andhra_pradesh_undavalli_caves`, `exp_andhra_pradesh_amaravati_mahachaitya`, `exp_andhra_pradesh_lepakshi_veerabhadra_temple`, `exp_andhra_pradesh_tirumala_venkateswara_temple`, `exp_andhra_pradesh_kondapalli_fort`, `exp_andhra_pradesh_chandragiri_fort`.
- **nature_wildlife** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/andhra-pradesh): `exp_andhra_pradesh_borra_caves`, `exp_andhra_pradesh_talakona_falls`, `exp_andhra_pradesh_kolleru_lake`, `exp_andhra_pradesh_uppalapadu_bird_sanctuary`, `exp_andhra_pradesh_rollapadu_wildlife_sanctuary`.
- **experiences_activities** â€” [Government/tourism source](https://allurisitharamaraju.ap.gov.in/tourism/): `exp_andhra_pradesh_walk_araku_coffee_plantations`.
- **experiences_activities** â€” [Government/tourism source](https://visakhapatnam.ap.gov.in/beaches/): `exp_andhra_pradesh_windsurf_at_rushikonda`.
- **dishes** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/andhra-pradesh/srikakulam): `exp_andhra_pradesh_pesarattu`, `exp_andhra_pradesh_chepala_pulusu`, `exp_andhra_pradesh_andhra_kodi_kura`.
- **dishes** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/andhra-pradesh): `exp_andhra_pradesh_gongura_pachadi`, `exp_andhra_pradesh_tirupati_laddu`.
- **dishes** â€” [Government/tourism source](https://www.niti.gov.in/sites/default/files/2026-04/Divya-Bharat-A-WIndow-to-the-Soul-of-India-Web.pdf): `exp_andhra_pradesh_pootharekulu`.
- **drinks** â€” [Government/tourism source](https://coffeeboard.gov.in/coffee-regions-india.html): `exp_andhra_pradesh_araku_coffee`.
- **arts_crafts** â€” [Government/tourism source](https://www.handicrafts.nic.in/CmsUpload/12222017102212GI%20BOOK%20FINAL%202-5-17_resized.pdf): `exp_andhra_pradesh_srikalahasti_kalamkari`, `exp_andhra_pradesh_machilipatnam_kalamkari`, `exp_andhra_pradesh_kondapalli_toys`.
- **arts_crafts** â€” [Government/tourism source](https://www.prod.incredibleindia.gov.in/content/incredible-india-v2/en/destinations/states/andhra-pradesh.html): `exp_andhra_pradesh_etikoppaka_lacquer_toys`.
- **festivals_fairs** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/andhra-pradesh/tirupati/sri-venkateswara-swamy-vaari-temple): `exp_andhra_pradesh_tirumala_brahmotsavam`.
- **festivals_fairs** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/festivals-and-events/andhra-pradesh/kanipakam-vinayaka-brahmotsavam): `exp_andhra_pradesh_kanipakam_vinayaka_brahmotsavam`.
- **festivals_fairs** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/festivals-and-events/andhra-pradesh/dwaraka-tirumala-brahmotsavam): `exp_andhra_pradesh_dwaraka_tirumala_brahmotsavam`.
- **music_dance** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/andhra-pradesh): `exp_andhra_pradesh_kuchipudi`, `exp_andhra_pradesh_vilasini_natyam`.
- **music_dance** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/andhra-pradesh/amaravati/leather-puppetry): `exp_andhra_pradesh_tholu_bommalata`.

### Telangana

- **landmarks_heritage** â€” [Government/tourism source](https://www.tourism.telangana.gov.in/experience/heritage): `exp_telangana_charminar`, `exp_telangana_golconda_fort`, `exp_telangana_qutb_shahi_tombs`, `exp_telangana_warangal_fort`, `exp_telangana_ramappa_temple`, `exp_telangana_chowmahalla_palace`.
- **nature_wildlife** â€” [Government/tourism source](https://www.prod.incredibleindia.gov.in/content/incredible-india-v2/en/destinations/states/telangana.html): `exp_telangana_kawal_tiger_reserve`, `exp_telangana_amrabad_tiger_reserve`, `exp_telangana_kasu_brahmananda_reddy_national_park`, `exp_telangana_mrugavani_national_park`, `exp_telangana_kuntala_falls`.
- **experiences_activities** â€” [Government/tourism source](https://hyderabad.telangana.gov.in/tourist-place/hussain-sagar-lake/): `exp_telangana_boat_on_hussain_sagar`.
- **experiences_activities** â€” [Government/tourism source](https://www.incredibleindia.gov.in/en/telangana/hyderabad): `exp_telangana_browse_laad_bazaar`.
- **dishes** â€” [Government/tourism source](https://www.tourism.telangana.gov.in/page/where-eat): `exp_telangana_hyderabadi_biryani`, `exp_telangana_hyderabadi_haleem`, `exp_telangana_sarva_pindi`, `exp_telangana_osmania_biscuits`.
- **dishes** â€” [Government/tourism source](https://telangana.gov.in/wp-content/uploads/2023/05/Telangana-4-Glorious-years.pdf): `exp_telangana_sakinalu`, `exp_telangana_qubani_ka_meetha`.
- **drinks** â€” [Government/tourism source](https://www.tourism.telangana.gov.in/page/where-eat): `exp_telangana_hyderabadi_irani_chai`.
- **arts_crafts** â€” [Government/tourism source](https://www.tourism.telangana.gov.in/page/arts-crafts): `exp_telangana_pochampally_ikat`, `exp_telangana_gadwal_sarees`, `exp_telangana_nirmal_paintings`, `exp_telangana_cheriyal_scroll_painting`.
- **festivals_fairs** â€” [Government/tourism source](https://www.tourism.telangana.gov.in/page/history-culture): `exp_telangana_bathukamma`, `exp_telangana_bonalu`, `exp_telangana_sammakka_saralamma_jatara`.
- **music_dance** â€” [Government/tourism source](https://www.tourism.telangana.gov.in/page/arts-crafts): `exp_telangana_perini_shivatandavam`, `exp_telangana_oggu_katha`, `exp_telangana_gussadi_dance`.

### Karnataka

- **landmarks_heritage** â€” [Government/tourism source](https://karnatakatourism.org/en/experiences/heritage-history): `exp_karnataka_hampi_monuments`, `exp_karnataka_pattadakal_temple_complex`, `exp_karnataka_badami_cave_temples`, `exp_karnataka_belur_chennakeshava_temple`, `exp_karnataka_halebidu_hoysaleswara_temple`, `exp_karnataka_mysuru_palace`, `exp_karnataka_gol_gumbaz`.
- **nature_wildlife** â€” [Government/tourism source](https://karnatakatourism.org/wp-content/uploads/2020/05/Karnataka-Map-1.pdf): `exp_karnataka_bandipur_national_park`, `exp_karnataka_nagarahole_national_park`, `exp_karnataka_jog_falls`, `exp_karnataka_ranganathittu_bird_sanctuary`, `exp_karnataka_kudremukh_national_park`.
- **experiences_activities** â€” [Government/tourism source](https://karnatakatourism.org/en/experiences/rafting-in-dandeli): `exp_karnataka_raft_the_kali_river_at_dandeli`.
- **experiences_activities** â€” [Government/tourism source](https://old.karnatakatourism.org/accommodation/alath-cad-estate-bungalow/): `exp_karnataka_walk_a_kodagu_coffee_estate`.
- **dishes** â€” [Government/tourism source](https://karnatakatourism.org/en/experiences/south-karnataka-food-trail): `exp_karnataka_bisi_bele_bath`, `exp_karnataka_neer_dosa`, `exp_karnataka_kori_gassi`, `exp_karnataka_goli_baje`, `exp_karnataka_mysore_pak`.
- **dishes** â€” [Government/tourism source](https://old.karnatakatourism.org/tour-item/cuisines/): `exp_karnataka_dharwad_pedha`, `exp_karnataka_ragi_mudde`, `exp_karnataka_maddur_vada`.
- **drinks** â€” [Government/tourism source](https://coffeeboard.gov.in/coffee-regions-india.html): `exp_karnataka_kodagu_coffee`.
- **arts_crafts** â€” [Government/tourism source](https://www.handicrafts.nic.in/CmsUpload/12222017102212GI%20BOOK%20FINAL%202-5-17_resized.pdf): `exp_karnataka_channapatna_toys`, `exp_karnataka_mysore_silk`, `exp_karnataka_ilkal_sarees`, `exp_karnataka_bidriware`.
- **festivals_fairs** â€” [Government/tourism source](https://karnatakatourism.org/en/local-culture-customs/): `exp_karnataka_mysuru_dasara`, `exp_karnataka_hampi_utsav`, `exp_karnataka_bengaluru_karaga`.
- **music_dance** â€” [Government/tourism source](https://karnatakatourism.org/en/experiences/heritage-history): `exp_karnataka_yakshagana`, `exp_karnataka_dollu_kunitha`, `exp_karnataka_veeragase`.

