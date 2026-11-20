# Easy hobbies and experiences: research shortlist

_Researched 2026-11-20 for UPLYFA. Status: **implemented** as the `try_easy_hobbies` challenge (`assets/data/easy_hobbies.json`). The JSON snippets below are the original proposal. The shipped entry also sets `completion_filters` and `item_summary`, omits `geography`, and stores hobby groups in `filter_group` with display labels such as "Creative & Crafts"._

> **Product decision (later):** cost tiers were removed from the app. Money can stop people trying something they'd enjoy, so hobbies and games are never labelled, filtered or matched by price. The cost columns below are research notes only.

## Source note

This was meant to come from r/Hobbies, but Reddit blocks Claude at every route (browser, page fetch, web search). **None of this list comes from Reddit.** It combines publicly accessible hobby round-ups, adult hobby surveys and India-focused hobby features (sources at the end), filtered for UPLYFA's own constraints.

## What the sources agree on

- **Most-cited cheap, easy starters:** colouring/drawing, writing and journaling, puzzles (crosswords, sudoku, jigsaws), birdwatching, knitting/crochet, cycling, gardening, yoga, origami and calligraphy.
- **Most-practised hobbies (US surveys):** after screen time, the top hobbies are reading, outdoor activities and cooking/baking. Reading is tipped as the trend for 2026.
- **India-specific:** gully cricket dominates. Kabaddi, kho-kho and traditional crafts (block printing, pottery, rangoli) endure, while photography, digital art and dance are growing.
- **Why low-cost hobbies work:** the main barrier is getting started, not equipment. Free tutorials and library books are the usual on-ramp.

## Fit criteria for UPLYFA

UPLYFA is a checklist of things you *do*, so each hobby becomes a **"first win": one concrete, completable starter task**. "Do origami" isn't checkable; "Fold your first paper crane" is. Each item also has to:

1. Be finishable in one sitting, or in a day for the outdoor ones.
2. Cost nothing or very little (Free / ₹ under 300 / ₹₹ under 1,500).
3. Be doable in India without special access.
4. Not duplicate an existing challenge (no yoga poses, dishes, fruits or books).

## Shortlist (60 items)

Cost: Free · ₹ (under ₹300) · ₹₹ (under ₹1,500). Place: 🏠 home · 🌳 outdoors · 🏘️ local.

### Creative & crafts (`filterGroup: creative`)
| Hobby | First win (checklist item) | Cost | Place |
|---|---|---|---|
| Origami | Fold a paper crane | Free | 🏠 |
| Sketching | Draw an object from your room from life | Free | 🏠 |
| Doodling / Zentangle | Fill a page with one repeating pattern | Free | 🏠 |
| Calligraphy / hand lettering | Letter your name in three styles | ₹ | 🏠 |
| Watercolour | Paint a simple sky gradient | ₹₹ | 🏠 |
| Rangoli | Make a rangoli at your doorstep | ₹ | 🏠 |
| Mehendi | Draw a mehendi pattern on your hand | ₹ | 🏠 |
| Crochet | Crochet a simple coaster | ₹ | 🏠 |
| Knitting | Knit a 10 × 10 cm swatch | ₹ | 🏠 |
| Embroidery | Stitch your initial on cloth | ₹ | 🏠 |
| Block printing | Print a pattern with a vegetable or wooden block | ₹ | 🏠 |
| Clay modelling | Shape a small diya or pot from air-dry clay | ₹ | 🏠 |
| Paper quilling | Make a quilled flower | ₹ | 🏠 |
| Collage / scrapbooking | Make a one-page collage from old magazines | Free | 🏠 |
| Upcycling | Turn a glass jar or bottle into something useful | Free | 🏠 |

### Mind & words (`filterGroup: mind`)
| Hobby | First win | Cost | Place |
|---|---|---|---|
| Journaling | Journal for 7 days in a row | Free | 🏠 |
| Gratitude log | Write three gratitudes a day for a week | Free | 🏠 |
| Poetry | Write a haiku or a short poem | Free | 🏠 |
| Short story | Write a 300-word story | Free | 🏠 |
| Crossword | Finish a newspaper crossword | Free | 🏠 |
| Sudoku | Solve a medium sudoku | Free | 🏠 |
| Jigsaw | Complete a 500-piece jigsaw | ₹₹ | 🏠 |
| Chess | Play and finish a full game of chess | Free | 🏠 |
| Rubik's cube | Solve a 3×3 cube once | ₹ | 🏠 |
| Memory | Memorise a short poem or shloka | Free | 🏠 |
| New script | Learn to write your name in another Indian script | Free | 🏠 |
| Language | Learn 20 words in a new language | Free | 🏠 |
| Meditation | Meditate for 10 minutes a day for 7 days | Free | 🏠 |

### Outdoors & nature (`filterGroup: outdoors`)
| Hobby | First win | Cost | Place |
|---|---|---|---|
| Birdwatching | Identify 10 bird species near home | Free | 🌳 |
| Stargazing | Spot a planet and one constellation | Free | 🌳 |
| Moon watching | Photograph the moon in three phases | Free | 🌳 |
| Sunrise | Watch a full sunrise | Free | 🌳 |
| Tree spotting | Identify 10 trees on your street | Free | 🌳 |
| Butterfly spotting | Photograph and identify 5 butterflies | Free | 🌳 |
| Nature walk | Take a 5 km walk somewhere new | Free | 🌳 |
| Heritage walk | Join or self-guide a heritage walk in your city | Free–₹ | 🏘️ |
| Trek | Complete a beginner day trek | ₹ | 🌳 |
| Cycling | Do a 20 km bike ride | Free | 🌳 |
| Kite flying | Fly a kite (Makar Sankranti counts) | ₹ | 🌳 |
| Cloud watching | Identify 4 cloud types | Free | 🌳 |

### Grow & make at home (`filterGroup: home`)
| Hobby | First win | Cost | Place |
|---|---|---|---|
| Herb garden | Grow tulsi, mint or coriander from seed or cutting | ₹ | 🏠 |
| Microgreens | Harvest a tray of microgreens | ₹ | 🏠 |
| Composting | Start a kitchen-waste compost bin | ₹ | 🏠 |
| Houseplant propagation | Root a money-plant cutting in water | Free | 🏠 |
| Bread | Bake a loaf of bread | ₹ | 🏠 |
| Pickling | Make a small jar of nimbu or mango pickle | ₹ | 🏠 |
| Fermentation | Set curd or ferment idli/dosa batter from scratch | ₹ | 🏠 |
| Chai craft | Make masala chai from whole spices you grind | ₹ | 🏠 |

### Music, movement & play (`filterGroup: play`)
| Hobby | First win | Cost | Place |
|---|---|---|---|
| Singing | Learn and sing a full song by heart | Free | 🏠 |
| Rhythm | Learn a basic beat on a dholak, tabla or a table top | Free | 🏠 |
| Instrument | Play a simple tune on harmonica, flute or ukulele | ₹₹ | 🏠 |
| Dance | Learn a full dance routine from a tutorial | Free | 🏠 |
| Skipping | Do 100 skips without stopping | ₹ | 🏠 |
| Gully cricket | Play a game of gully cricket | Free | 🏘️ |
| Carrom | Win a game of carrom | ₹₹ | 🏠 |
| Kho-kho / kabaddi | Play a game of kho-kho or kabaddi | Free | 🏘️ |
| Juggling | Juggle three balls for 10 catches | ₹ | 🏠 |

### Capture & share (`filterGroup: capture`)
| Hobby | First win | Cost | Place |
|---|---|---|---|
| Phone photography | Take a 10-photo themed series | Free | 🌳 |
| Street photography | Photograph one street from morning to evening | Free | 🏘️ |
| Short video | Edit a 30-second clip of your day | Free | 🏠 |

## How it fits the app

### Proposed challenge (`assets/data/challenges.json`)

This uses the existing, currently unused `life_experiences` category and the generic checklist flow, the same one Yoga uses:

```json
{
  "id": "try_easy_hobbies",
  "category_id": "life_experiences",
  "name": "Try 60 Easy Hobbies",
  "description": "Low-cost hobbies to start this week, each with a first win you can finish in a day.",
  "item_type": "hobby",
  "geography": "India",
  "total_items": 60,
  "has_sub_items": false,
  "sub_item_type": null,
  "presentation_type": "checklist_with_details",
  "data_asset": "assets/data/easy_hobbies.json",
  "progress_key": "completed_hobby_ids",
  "short_title": "Easy Hobbies",
  "category_name": "Life Experiences",
  "primary_action": "tried",
  "primary_action_label": "Done",
  "progress_verb": "tried",
  "start_label": "Start a hobby",
  "continue_label": "Try another",
  "singular_noun": "hobby",
  "plural_noun": "hobbies",
  "icon_identifier": "hobby",
  "show_in_quick_explore": true,
  "status": "planned"
}
```

### Proposed item shape (`assets/data/easy_hobbies.json`)

```json
{
  "id": "hobby_origami_crane",
  "challenge_id": "try_easy_hobbies",
  "name": "Origami",
  "description": "Fold a paper crane.",
  "difficulty": "beginner",
  "filterGroup": "creative",
  "tags": ["paper", "mindful", "indoor"],
  "howToSteps": [
    "Start with a square sheet of paper.",
    "Follow a beginner crane tutorial step by step.",
    "Crease each fold firmly before moving on."
  ],
  "metadata": { "cost": "Free", "place": "home", "time": "20 min" }
}
```

### Engineering to-dos before shipping

1. **Progress key and XP.** The generic flow needs a `progress_key` and an entry in `ProgressService._completionPrefixForProgressKey` (for example `hobby`). Without it, completions are saved but earn no XP, which is the same bug we just fixed for varieties.
2. **Daily quest.** Decide which quest path `hobby:` counts toward, or add a third task.
3. **Icon.** Add a `hobby` case to `challenge_icon.dart` / `category_icon.dart` (for example `Icons.palette_outlined`).
4. **Search.** Add the item keywords to `search_keywords.json`.
5. **Safety copy.** Add notes for treks and cycling (go with others, carry water) and for foraging, which I left out because no source covered it safely.

### Ideas the research suggests beyond this checklist

- **Hobby streaks:** "Journal 7 days in a row" fits the existing streak engine.
- **Festival tie-ins:** rangoli for Diwali, kites for Makar Sankranti, mehendi for Teej and Karva Chauth. These could feed Daily Discovery on the right dates.
- **Starter kits by budget:** a "Free this week" filter using `metadata.cost`.

## Sources

- [Yardbarker: 20 inexpensive hobbies that are easy to pick up](https://www.yardbarker.com/lifestyle/articles/20_inexpensive_hobbies_that_are_easy_to_pick_up/s1__40188160)
- [AOL: 12 fun hobbies that are surprisingly inexpensive to start](https://www.aol.com/finance/12-fun-hobbies-surprisingly-inexpensive-140000340.html)
- [Woman & Home: cheap and easy hobbies to try at home](https://www.womanandhome.com/hobbies/cheap-and-easy-ideas-for-hobbies/)
- [FaveCrafts: 25 low-cost hobbies](https://Favecrafts.com/Most-Popular-Crafts/Low-Cost-Hobbies)
- [The Motley Fool: hobbies on a dollar-store budget](https://fool.com/the-ascent/personal-finance/articles/6-hobbies-you-can-start-on-a-dollar-store-budget/)
- [CivicScience: budget-friendly hobbies survey](https://civicscience.com/how-americans-are-redefining-free-time-through-budget-friendly-hobbies/)
- [AYTM: hobbies survey](https://aytm.com/blog/daily-survey-results/hobbies-survey)
- [Statista: most popular hobbies in the US](https://www.statista.com/statistics/997050/most-popular-hobbies-and-activities-in-the-us)
- [The Scotsman: reading tipped as the 2026 hobby trend](https://www.scotsman.com/read-this/reading-is-set-to-be-the-hot-new-hobby-trend-for-2026-5485351)
- [Udayavani: exploring India's top 5 hobbies](https://english.udayavani.com/article/english-news/exploring-indias-top-5-hobbies-a-cultural-odyssey/1574866)
- [YourStory: hobbies in India](https://yourstory.com/mystory/hobbies-that-seem-to-fetch-the-most-in-india-uy01hse5vk)
- [American Express India: unusual hobby ideas](https://www.americanexpress.com/in/articles/life-with-amex/entertainment/unusual-hobby-ideas.html)
- [REI: bird-watching for beginners](https://www.rei.com/learn/expert-advice/beginner-bird-watching.html)
- [AARP: beginner's guide to birding](https://www.aarp.org/home-living/beginners-guide-to-bird-watching/)
- [MoneySavingExpert: birdwatching as a cheap hobby](https://www.moneysavingexpert.com/team-blog/2025/01/birdwatching-cheap-hobby/)
- [Apartment Therapy: outdoor hobbies for beginners](https://www.apartmenttherapy.com/best-outdoor-hobbies-for-beginners-37073492)
- [top10.com: hobbies you can take up at home for free](https://top10.com/blog/10-hobbies-you-can-take-up-at-home-for-free)
- [Stylist: easy hobbies for mental health](https://stylist.co.uk/life/best-hobbies-for-mental-health/687691)
