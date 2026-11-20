"""Generate assets/data/easy_hobbies.json, the UPLYFA hobby catalogue.

Run from the repository root:  python tools/build_easy_hobbies.py

Each hobby has a one-sitting "first win", three how-to-start steps, a skill
ladder (Tried -> Learning -> Practising -> Confident) and attributes used by
the hobby finder: setting, cost, session length, energy, social and goals.
Sources: docs/research/easy_hobbies_shortlist.md.
"""
import json
from pathlib import Path

CH = "try_easy_hobbies"
GROUPS = {
    "creative": "Creative & Crafts",
    "mind": "Mind & Words",
    "outdoors": "Outdoors & Nature",
    "home": "Grow & Make",
    "play": "Music & Play",
    "capture": "Capture & Share",
    "fitness": "Fitness & Movement",
    "learn": "Learn & Explore",
    "people": "People & Community",
}
WHERE = {"home": "At home", "out": "Outdoors", "local": "In your neighbourhood"}
SETTING = {"home": "indoor", "out": "outdoor", "local": "either"}
COST_LABEL = {"free": "Free", "low": "Under ₹300", "medium": "Under ₹1,500"}
ENERGY = {"calm", "moderate", "active"}
SOCIAL = {"solo", "social", "either"}
GOALS = {"relax", "active", "create", "connect", "learn"}

H = []


def h(slug, group, hobby, win, about, steps, cost, where, time, minutes,
      energy, social, goals, ladder, tags):
    H.append(dict(slug=slug, group=group, hobby=hobby, win=win, about=about,
                  steps=steps, cost=cost, where=where, time=time,
                  minutes=minutes, energy=energy, social=social,
                  goals=goals.split(), ladder=ladder, tags=tags.split()))


# ---------------------------------------------------------------- Creative
h("origami_crane", "creative", "Origami", "Fold a paper crane",
  "The classic Japanese paper fold. A crane takes about twenty minutes and only a square of paper.",
  ["Cut any sheet of paper into a square.", "Follow a beginner crane tutorial one fold at a time.", "Crease every fold firmly before moving on."],
  "free", "home", "20 min", 20, "calm", "solo", "relax create",
  ["Fold five different models", "Fold a crane from memory", "Fold a modular model from 6+ units"], "paper mindful")
h("sketch_from_life", "creative", "Sketching", "Draw an object from life",
  "Pick something in your room and draw what you actually see, not what you think it looks like.",
  ["Choose a simple object such as a mug or a shoe.", "Sketch light outlines first, then add shading.", "Spend at least 15 minutes looking more than drawing."],
  "free", "home", "30 min", 30, "calm", "solo", "relax create",
  ["Fill ten sketchbook pages", "Sketch daily for two weeks", "Draw a full room scene in perspective"], "drawing art")
h("zentangle_page", "creative", "Doodling", "Fill a page with one repeating pattern",
  "Pattern doodling (often called Zentangle) is a calming, no-skill-needed way to start drawing.",
  ["Draw a border on a blank page.", "Pick one simple pattern of lines, dots or waves.", "Repeat it until the page is full."],
  "free", "home", "30 min", 30, "calm", "solo", "relax create",
  ["Learn ten patterns", "Combine patterns on one tile daily for a week", "Fill a whole notebook"], "drawing mindful")
h("hand_lettering", "creative", "Hand lettering", "Letter your name in three styles",
  "Hand lettering and calligraphy turn everyday writing into something decorative.",
  ["Write your name in neat capitals.", "Write it again in joined-up script with thick downstrokes.", "Try a third style of your own, then pick a favourite."],
  "low", "home", "30 min", 30, "calm", "solo", "create relax",
  ["Letter the full alphabet in one style", "Letter a quote for a friend", "Design a lettered poster"], "writing art calligraphy")
h("watercolour_sky", "creative", "Watercolour", "Paint a simple sky gradient",
  "A sky wash is the first exercise most watercolour painters learn.",
  ["Wet the top half of the paper with clean water.", "Drop in blue at the top and let it fade downwards.", "Add a band of orange near the horizon and let it dry flat."],
  "medium", "home", "45 min", 45, "calm", "solo", "create relax",
  ["Paint five skies at different times of day", "Paint a simple landscape", "Paint a scene from a photo you took"], "painting art")
h("rangoli_doorstep", "creative", "Rangoli", "Make a rangoli at your doorstep",
  "A traditional Indian floor design of coloured powder, rice or flowers, made to welcome guests.",
  ["Mark a grid of dots with chalk or rice flour.", "Join the dots into a symmetrical design.", "Fill it in with colours or petals."],
  "low", "home", "1 hr", 60, "calm", "either", "create connect",
  ["Make three dot-grid designs", "Make a freehand rangoli", "Make a festival-size rangoli"], "india festival art")
h("mehendi_pattern", "creative", "Mehendi", "Draw a mehendi pattern on your hand",
  "Henna art is a celebration tradition across India. Start with a simple floral motif.",
  ["Practise the design on paper first.", "Apply henna in thin, steady lines.", "Let it dry for a few hours before scraping it off."],
  "low", "home", "1 hr", 60, "calm", "either", "create connect",
  ["Master five basic motifs", "Do a full palm design", "Do mehendi for someone at a celebration"], "india festival art")
h("crochet_coaster", "creative", "Crochet", "Crochet a simple coaster",
  "A round coaster teaches the chain, slip stitch and single crochet: the basics of almost every project.",
  ["Get a ball of cotton yarn and a hook.", "Follow a beginner coaster tutorial.", "Finish by weaving in the loose ends."],
  "low", "home", "1–2 hr", 90, "calm", "solo", "create relax",
  ["Crochet a set of four coasters", "Crochet a small bag or hat", "Follow a pattern for a blanket square set"], "yarn mindful")
h("knit_swatch", "creative", "Knitting", "Knit a 10 × 10 cm swatch",
  "A practice square is how every knitter learns to cast on, knit, purl and cast off.",
  ["Cast on about 20 stitches.", "Knit rows until the piece is square.", "Cast off and admire your first fabric."],
  "low", "home", "2 hr", 120, "calm", "solo", "create relax",
  ["Knit a scarf", "Knit a hat in the round", "Knit a sweater or a cable pattern"], "yarn mindful")
h("embroider_initial", "creative", "Embroidery", "Stitch your initial on cloth",
  "Embroidery needs only a needle, thread and scrap fabric to get started.",
  ["Draw your initial lightly on a piece of cloth.", "Outline it with a backstitch.", "Fill it in with a satin stitch if you like."],
  "low", "home", "1 hr", 60, "calm", "solo", "create relax",
  ["Learn five stitches", "Embroider a small flower hoop", "Decorate a piece of clothing"], "sewing craft")
h("block_print", "creative", "Block printing", "Print a pattern with a block",
  "India's block-printing tradition can be tried at home with a carved potato or a wooden block.",
  ["Cut a simple shape into half a potato, or use a wooden block.", "Dab it in fabric or poster paint.", "Print a repeating pattern on paper or cloth."],
  "low", "home", "1 hr", 60, "calm", "solo", "create",
  ["Print two-colour patterns", "Print a cushion cover or tote", "Carve your own block design"], "india craft printing")
h("clay_diya", "creative", "Clay modelling", "Shape a small diya or pot",
  "Air-dry clay lets you try pottery without a wheel or kiln.",
  ["Knead a lump of air-dry clay until soft.", "Pinch it into a small bowl or diya shape.", "Let it dry for a day, then paint it if you wish."],
  "low", "home", "1 hr", 60, "calm", "solo", "create relax",
  ["Make a coil pot", "Model a small figure or animal", "Try a pottery wheel class"], "clay craft india")
h("paper_quilling", "creative", "Paper quilling", "Make a quilled flower",
  "Quilling rolls thin strips of paper into coils that form flowers and patterns.",
  ["Cut or buy thin paper strips.", "Roll strips tightly around a toothpick and pinch them into petals.", "Glue the petals into a flower on card."],
  "low", "home", "1 hr", 60, "calm", "solo", "create relax",
  ["Learn eight coil shapes", "Make a quilled greeting card", "Make a framed quilled artwork"], "paper craft")
h("magazine_collage", "creative", "Collage", "Make a one-page collage",
  "Collage turns old magazines and newspapers into art. There's no wrong answer.",
  ["Collect pictures and words around one theme.", "Arrange them on a page before gluing.", "Glue everything down and give it a title."],
  "free", "home", "45 min", 45, "calm", "solo", "create relax",
  ["Make a vision board", "Make a collage series of three", "Make a mixed-media art journal"], "paper art upcycling")
h("upcycle_jar", "creative", "Upcycling", "Turn a jar or bottle into something useful",
  "Give something headed for the bin a second life as a planter, lamp or organiser.",
  ["Clean a glass jar or plastic bottle.", "Decide what it will become.", "Paint, wrap or cut it to finish the job."],
  "free", "home", "1 hr", 60, "calm", "solo", "create",
  ["Upcycle three different items", "Upcycle an old T-shirt into a bag", "Refurbish a piece of furniture"], "craft sustainability")
h("mandala_art", "creative", "Mandala art", "Draw a mandala",
  "Circular, symmetrical patterns that build outward from a centre point. Very meditative.",
  ["Draw a small circle in the centre of the page.", "Add rings of repeating shapes around it.", "Keep each ring symmetrical and colour it in."],
  "free", "home", "45 min", 45, "calm", "solo", "relax create",
  ["Draw five mandalas", "Draw a mandala with a compass and ruler", "Paint a large mandala on a wall or canvas"], "drawing mindful india")
h("greeting_card", "creative", "Card making", "Make a greeting card by hand",
  "A handmade card means more than any shop-bought one.",
  ["Fold a sheet of card in half.", "Decorate the front with drawing, cut-outs or stamps.", "Write a personal message and give it to someone."],
  "free", "home", "45 min", 45, "calm", "either", "create connect",
  ["Make a pop-up card", "Make cards for a whole festival list", "Sell or gift a set of ten"], "paper craft gifting")
h("sew_tote", "creative", "Sewing", "Sew a simple tote bag",
  "A tote bag is two rectangles and two straps: the perfect first sewing project.",
  ["Cut two rectangles and two straps from sturdy cloth.", "Stitch the sides and bottom, inside out.", "Attach the straps and turn it right side out."],
  "low", "home", "2 hr", 120, "calm", "solo", "create",
  ["Sew a cushion cover", "Alter or repair a piece of clothing", "Sew a simple garment from a pattern"], "sewing craft")
h("bead_bracelet", "creative", "Jewellery making", "Make a beaded bracelet",
  "Beads and elastic thread are all it takes to make wearable art.",
  ["Pick beads in two or three colours.", "Thread them onto stretchy cord in a pattern.", "Tie a secure knot and trim the ends."],
  "low", "home", "30 min", 30, "calm", "either", "create relax",
  ["Make a set of matching pieces", "Make wire-wrapped earrings", "Design a necklace as a gift"], "craft gifting")
h("comic_strip", "creative", "Comics", "Draw a three-panel comic",
  "Stick figures are fine. A comic is about the story, not perfect drawing.",
  ["Think of a tiny joke or moment from your day.", "Split it into three panels: setup, build, punchline.", "Draw it with speech bubbles."],
  "free", "home", "45 min", 45, "calm", "solo", "create",
  ["Draw a comic a week for a month", "Create a recurring character", "Make an eight-page mini comic"], "drawing story")
h("pebble_painting", "creative", "Rock painting", "Paint a pebble",
  "Smooth stones make a tiny canvas for animals, patterns or kind messages.",
  ["Find a smooth, flat stone and wash it.", "Paint a base colour and let it dry.", "Add a design and seal it if you can."],
  "low", "home", "45 min", 45, "calm", "either", "create relax",
  ["Paint a themed set of five", "Leave a kindness rock for a stranger", "Paint a garden rock display"], "painting craft")
h("madhubani_bookmark", "creative", "Folk art", "Make a Madhubani-style bookmark",
  "Madhubani from Bihar uses bold outlines, fish, birds and double-line borders.",
  ["Cut a strip of thick paper.", "Draw a double-line border and a simple fish or peacock.", "Fill the shapes with patterns and bright colour."],
  "free", "home", "45 min", 45, "calm", "solo", "create learn",
  ["Try Warli and Gond styles too", "Paint an A4 folk-art piece", "Paint a folk-art panel for your home"], "india art folk")

# ---------------------------------------------------------------- Mind & Words
h("journal_seven_days", "mind", "Journaling", "Journal for 7 days in a row",
  "A few lines a day is enough to start a journaling habit.",
  ["Pick a notebook or notes app.", "Write at least three sentences each day.", "Read back the whole week on day seven."],
  "free", "home", "10 min a day", 10, "calm", "solo", "relax learn",
  ["Journal for 30 days", "Try three journaling styles", "Keep a journal for a full year"], "writing habit mindful")
h("gratitude_week", "mind", "Gratitude log", "Note three gratitudes a day for a week",
  "A short daily gratitude list is one of the simplest well-being habits.",
  ["Each evening, write down three things you are grateful for.", "Be specific: name people, moments and places.", "Keep going for seven days."],
  "free", "home", "5 min a day", 5, "calm", "solo", "relax",
  ["Keep it going for a month", "Write a thank-you note to someone on your list", "Make it a 100-day habit"], "writing habit mindful")
h("write_haiku", "mind", "Poetry", "Write a haiku",
  "Three lines of five, seven and five syllables. Small enough to finish in one sitting.",
  ["Pick a moment you noticed today.", "Write three lines of 5, 7 and 5 syllables.", "Read it aloud and adjust the words."],
  "free", "home", "15 min", 15, "calm", "solo", "create relax",
  ["Write a poem a week for a month", "Try three poetic forms", "Read a poem aloud to an audience"], "writing poetry")
h("short_story", "mind", "Story writing", "Write a 300-word story",
  "Very short fiction is a quick way to start writing stories.",
  ["Pick a character and one problem they face.", "Write a beginning, a turning point and an ending.", "Trim it to about 300 words."],
  "free", "home", "45 min", 45, "calm", "solo", "create",
  ["Write five flash stories", "Write a 2,000-word short story", "Submit a story to a magazine or contest"], "writing fiction")
h("newspaper_crossword", "mind", "Crosswords", "Finish a crossword",
  "Newspaper and online crosswords build vocabulary and make a good daily ritual.",
  ["Start with an easy or quick crossword.", "Fill in the clues you're sure of first.", "Use crossing letters to crack the rest."],
  "free", "home", "30 min", 30, "calm", "solo", "learn relax",
  ["Solve one every day for a week", "Finish a cryptic crossword", "Solve a weekend puzzle without help"], "puzzle words")
h("solve_sudoku", "mind", "Sudoku", "Solve a medium sudoku",
  "Number logic with no maths required.",
  ["Pick a medium-difficulty puzzle.", "Scan rows, columns and boxes for missing numbers.", "Pencil in candidates when you get stuck."],
  "free", "home", "30 min", 30, "calm", "solo", "learn relax",
  ["Solve a hard sudoku", "Learn two advanced techniques", "Solve an expert puzzle in under 30 minutes"], "puzzle logic")
h("jigsaw_500", "mind", "Jigsaw puzzles", "Complete a 500-piece jigsaw",
  "A satisfying slow hobby, and good to do with family.",
  ["Sort out the edge pieces first.", "Group the rest by colour or pattern.", "Build outwards from the parts you recognise."],
  "medium", "home", "A few evenings", 120, "calm", "either", "relax connect",
  ["Complete a 1,000-piece jigsaw", "Do a puzzle swap with friends", "Complete a 2,000-piece jigsaw"], "puzzle family")
h("chess_game", "mind", "Chess", "Play a full game of chess",
  "Chess began in India as chaturanga. Learn the moves and play one game to the end.",
  ["Learn how each piece moves.", "Play a friend or a free beginner app.", "Finish the game, win or lose."],
  "free", "home", "1 hr", 60, "calm", "either", "learn connect",
  ["Learn two openings", "Solve 50 tactics puzzles", "Play in a local or online tournament"], "game strategy india")
h("rubiks_cube", "mind", "Rubik's cube", "Solve a 3×3 cube",
  "With the layer-by-layer beginner method, anyone can solve the cube.",
  ["Learn the beginner method from a tutorial.", "Solve one layer at a time.", "Complete the whole cube once without help."],
  "low", "home", "A few days", 60, "calm", "solo", "learn",
  ["Solve it without notes", "Solve it in under 2 minutes", "Learn an advanced method (CFOP)"], "puzzle logic")
h("memorise_poem", "mind", "Memorisation", "Learn a poem or shloka by heart",
  "Memorising verse is an old Indian learning tradition and good exercise for the brain.",
  ["Choose a short poem, doha or shloka.", "Learn it two lines at a time.", "Recite the whole thing from memory."],
  "free", "home", "A few days", 15, "calm", "solo", "learn",
  ["Memorise three pieces", "Recite one for family or friends", "Memorise a long poem or chapter"], "memory india poetry")
h("new_script_name", "mind", "Scripts", "Write your name in another Indian script",
  "India has more than a dozen scripts. Try Devanagari, Tamil, Bengali, Gurmukhi or another.",
  ["Pick a script you can't yet read.", "Learn the letters that spell your name.", "Write your name neatly ten times."],
  "free", "home", "30 min", 30, "calm", "solo", "learn",
  ["Learn the full alphabet", "Read a street sign or headline", "Read a short children's story"], "language india writing")
h("twenty_words", "mind", "Languages", "Learn 20 words in a new language",
  "A first vocabulary of greetings, numbers and food words.",
  ["Pick a language you're curious about.", "Learn greetings, numbers 1–10 and a few foods.", "Test yourself the next day."],
  "free", "home", "1 week", 15, "calm", "solo", "learn",
  ["Learn 200 words", "Hold a 5-minute conversation", "Watch a film without subtitles"], "language learning")
h("meditate_week", "mind", "Meditation", "Meditate 10 minutes a day for 7 days",
  "Sitting quietly and following the breath is the simplest form of meditation.",
  ["Sit comfortably somewhere quiet.", "Follow your breath, and return to it when your mind wanders.", "Repeat daily for a week."],
  "free", "home", "10 min a day", 10, "calm", "solo", "relax",
  ["Meditate daily for a month", "Sit for 20 minutes", "Join a group or silent retreat day"], "mindful habit wellness")
h("read_short_book", "mind", "Reading", "Read a short book in a week",
  "Pick something under 200 pages and read a little every day.",
  ["Choose a short novel, memoir or graphic novel.", "Read 25–30 pages a day.", "Finish it and note one line you loved."],
  "free", "home", "30 min a day", 30, "calm", "solo", "relax learn",
  ["Read a book a month for three months", "Read a book in a new genre", "Read 20 books in a year"], "books reading")
h("handwritten_letter", "mind", "Letter writing", "Write a letter by hand",
  "A handwritten letter is slow, personal and memorable.",
  ["Pick someone you haven't spoken to in a while.", "Write a page about your life and ask about theirs.", "Post it or hand it over."],
  "low", "home", "30 min", 30, "calm", "social", "connect relax",
  ["Find a pen pal", "Write a letter a month", "Exchange letters with someone abroad"], "writing connection")
h("word_game_night", "mind", "Word games", "Play a game of Scrabble",
  "Word games are fun with family and sneakily build vocabulary.",
  ["Get a board or a free word-game app.", "Play a full game with someone.", "Look up one new word you learned."],
  "free", "home", "1 hr", 60, "calm", "social", "connect learn",
  ["Learn the two-letter words", "Score 300 in one game", "Play in a club or online league"], "game words family")
h("dream_journal", "mind", "Dream journaling", "Record your dreams for 5 nights",
  "Keep a notebook by your bed and write as soon as you wake.",
  ["Put a notebook and pen beside your bed.", "Write down whatever you remember on waking.", "After five nights, look for patterns."],
  "free", "home", "5 min a day", 5, "calm", "solo", "relax create",
  ["Keep it going for a month", "Turn a dream into a story or drawing", "Notice a recurring theme"], "writing mindful")
h("film_review", "mind", "Reviewing", "Write a review of a film you loved",
  "Putting your opinion into words helps you notice more in what you watch.",
  ["Pick a film or series you enjoyed.", "Write what worked, what didn't and who it's for.", "Keep it to about 300 words and share it."],
  "free", "home", "45 min", 45, "calm", "solo", "create learn",
  ["Review five films", "Watch and review a classic", "Start a review blog or channel"], "writing film")
h("vedic_maths", "mind", "Mental maths", "Learn three Vedic maths tricks",
  "Quick methods for multiplying and squaring numbers in your head.",
  ["Learn to multiply by 11 mentally.", "Learn squaring numbers ending in 5.", "Practise each trick on ten examples."],
  "free", "home", "30 min", 30, "calm", "solo", "learn",
  ["Learn ten tricks", "Do mental maths daily for two weeks", "Teach a trick to someone else"], "maths india learning")
h("pranayama_week", "mind", "Breathwork", "Practise pranayama for 7 days",
  "Simple breathing exercises like anulom vilom take five minutes and calm the mind.",
  ["Sit upright and learn one technique, such as alternate-nostril breathing.", "Practise for five minutes each morning.", "Stop if you feel dizzy, and keep it gentle."],
  "free", "home", "5 min a day", 5, "calm", "solo", "relax",
  ["Learn three techniques", "Practise daily for a month", "Join a guided breathwork session"], "breathing india wellness")

# ---------------------------------------------------------------- Outdoors
h("ten_birds", "outdoors", "Birdwatching", "Identify 10 bird species near home",
  "Mynas, bulbuls, sunbirds, kites: there's a lot to spot from a balcony or park.",
  ["Go out early in the morning, when birds are most active.", "Note colour, size, call and behaviour.", "Identify each bird with a field guide or free app."],
  "free", "out", "A few mornings", 60, "calm", "either", "relax learn",
  ["Identify 30 species", "Join a bird walk or count", "Log 100 species"], "nature birds outdoors")
h("planet_constellation", "outdoors", "Stargazing", "Spot a planet and a constellation",
  "No telescope needed. Venus, Jupiter and Orion are easy to find with the naked eye.",
  ["Find a dark spot away from bright lights.", "Use a free sky-map app to find a planet.", "Trace one constellation, such as Orion or Saptarishi (the Big Dipper)."],
  "free", "out", "1 hr", 60, "calm", "either", "relax learn",
  ["Find ten constellations", "See a meteor shower", "Look through a telescope at Saturn's rings"], "sky night outdoors")
h("moon_phases", "outdoors", "Moon watching", "Photograph three moon phases",
  "Watch the moon change over a couple of weeks.",
  ["Photograph the moon on three different nights.", "Try to capture a crescent, a half and a full moon.", "Put the photos side by side."],
  "free", "out", "2 weeks", 15, "calm", "solo", "relax learn",
  ["Photograph a full lunar cycle", "Name five craters", "Watch a lunar eclipse"], "sky photography")
h("full_sunrise", "outdoors", "Sunrise watching", "Watch a full sunrise",
  "A simple, memorable experience that costs nothing.",
  ["Check tomorrow's sunrise time.", "Find a spot with an open eastern view.", "Arrive 20 minutes early and watch the whole thing."],
  "free", "out", "1 hr", 60, "calm", "either", "relax",
  ["Watch sunrises at three places", "Watch a sunrise from a hilltop", "Watch sunrise and sunset on the same day"], "sky mindful outdoors")
h("ten_trees", "outdoors", "Tree spotting", "Identify 10 trees on your street",
  "Neem, peepal, gulmohar, banyan: learn the trees you walk past every day.",
  ["Look closely at the leaves, bark, flowers and fruit.", "Identify each tree with a guide or app.", "Note where each one grows."],
  "free", "local", "1 hr", 60, "calm", "solo", "learn relax",
  ["Identify 30 trees", "Map the trees in your area", "Join a tree walk or census"], "nature trees outdoors")
h("five_butterflies", "outdoors", "Butterfly spotting", "Identify 5 butterflies",
  "Gardens and parks are full of butterflies, especially after the monsoon.",
  ["Visit a flowering garden on a sunny morning.", "Photograph butterflies from a respectful distance.", "Identify five different species."],
  "free", "out", "A few mornings", 60, "calm", "solo", "relax learn",
  ["Identify 20 species", "Plant a host plant for caterpillars", "Join a butterfly count"], "nature insects photography")
h("walk_5km_new", "outdoors", "Nature walks", "Walk 5 km somewhere new",
  "Explore a park, lake or trail you've never walked before.",
  ["Pick a safe route you've never walked.", "Carry water and wear comfortable shoes.", "Walk the full 5 km at an easy pace."],
  "free", "out", "1–2 hr", 90, "moderate", "either", "active relax",
  ["Walk five new routes", "Walk 10 km in a day", "Complete a long-distance trail section"], "walking fitness outdoors")
h("heritage_walk", "outdoors", "Heritage walks", "Do a heritage walk in your city",
  "Most Indian cities have old quarters, monuments and markets with stories behind them.",
  ["Find a local heritage walk or plan your own route.", "Read a little about each stop beforehand.", "Walk it and note your favourite place."],
  "low", "local", "2–3 hr", 150, "moderate", "either", "learn connect",
  ["Do three different walks", "Lead a walk for friends", "Explore a heritage site in another city"], "history city walking")
h("beginner_trek", "outdoors", "Trekking", "Complete a beginner day trek",
  "Short, well-marked trails are a great introduction to the hills.",
  ["Choose a popular, well-marked beginner trail.", "Go with others and tell someone your plan.", "Carry water and snacks, and start early."],
  "low", "out", "1 day", 360, "active", "social", "active connect",
  ["Do three day treks", "Do an overnight trek with a group", "Complete a multi-day Himalayan trek"], "hiking fitness outdoors")
h("ride_20km", "outdoors", "Cycling", "Ride 20 km by bicycle",
  "A borrowed, rented or second-hand bicycle is all you need.",
  ["Check the tyres and brakes.", "Plan a safe route, ideally early in the morning.", "Wear a helmet and ride the full 20 km."],
  "free", "out", "2 hr", 120, "active", "either", "active",
  ["Ride 50 km in a day", "Join a group ride", "Ride 100 km (a century)"], "cycling fitness outdoors")
h("fly_kite", "outdoors", "Kite flying", "Fly a kite",
  "A favourite on Makar Sankranti and Independence Day across India.",
  ["Get a paper kite and some cotton string.", "Find an open space away from power lines.", "Launch into the wind and keep it airborne."],
  "low", "out", "1 hr", 60, "moderate", "either", "relax connect",
  ["Keep a kite up for 30 minutes", "Make your own kite", "Fly at a kite festival"], "india festival outdoors")
h("cloud_types", "outdoors", "Cloud watching", "Identify 4 cloud types",
  "Cumulus, cirrus, stratus, nimbus: the sky changes every day.",
  ["Look up a simple cloud chart.", "Photograph clouds over a few days.", "Match four different types."],
  "free", "out", "A few days", 15, "calm", "solo", "relax learn",
  ["Identify all ten main cloud types", "Predict the weather from the clouds", "Photograph a rare cloud formation"], "sky weather mindful")
h("picnic", "outdoors", "Picnics", "Have a picnic in a park",
  "Pack simple food, a mat and good company. No occasion needed.",
  ["Pick a park with shade and clean space.", "Pack food, water and a mat or sheet.", "Spend at least two hours outdoors, and leave no trace."],
  "low", "out", "2–3 hr", 150, "calm", "social", "relax connect",
  ["Picnic in three different places", "Host a picnic for a group", "Plan a sunrise picnic"], "food friends outdoors")
h("botanical_garden", "outdoors", "Garden visits", "Visit a botanical garden",
  "Many Indian cities have botanical gardens with rare and old trees.",
  ["Find the nearest botanical garden or large park.", "Go in the morning when it's cooler.", "Find three plants you've never seen before."],
  "low", "out", "2 hr", 120, "calm", "either", "relax learn",
  ["Visit three gardens", "Visit during a flower show", "Volunteer at a garden or nursery"], "plants nature city")
h("press_leaves", "outdoors", "Leaf pressing", "Press five leaves or flowers",
  "Pressed leaves turn into bookmarks, cards and framed art.",
  ["Collect five fallen leaves or flowers.", "Place them between paper inside a heavy book.", "Wait a week, then arrange them on card."],
  "free", "out", "1 week", 20, "calm", "solo", "create relax",
  ["Press 20 different plants", "Make a pressed-flower card", "Frame a botanical collection"], "nature craft")
h("monsoon_walk", "outdoors", "Monsoon walks", "Take a walk in the rain",
  "Monsoon is one of India's best seasons to be outdoors, safely.",
  ["Pick a safe, familiar route away from flooded areas.", "Wear grippy footwear and carry an umbrella or raincoat.", "Notice the smells, sounds and green."],
  "free", "out", "45 min", 45, "moderate", "either", "relax active",
  ["Visit a waterfall in season", "Do a monsoon trek with a group", "Photograph a monsoon series"], "monsoon walking seasonal")
h("camp_night", "outdoors", "Camping", "Camp out for one night",
  "A night under the stars, at a campsite or even in a garden.",
  ["Choose a safe, permitted campsite, or start in a garden.", "Borrow or rent a tent and sleeping mat.", "Cook a simple meal and stay the night."],
  "medium", "out", "Overnight", 720, "moderate", "social", "relax connect",
  ["Camp at three sites", "Pitch the tent yourself", "Do a multi-night camping trip"], "nature night outdoors")
h("day_trip", "outdoors", "Day trips", "Take a day trip to a fort or ruins",
  "Most of India is within a few hours of a fort, ruin or old temple town.",
  ["Pick a site within two or three hours of home.", "Plan transport, water and food.", "Spend the day exploring and learn its story."],
  "medium", "out", "1 day", 480, "moderate", "either", "learn active",
  ["Visit five historic sites", "Plan a day trip for friends", "Visit a UNESCO World Heritage Site"], "history travel india")
h("farm_visit", "outdoors", "Farm visits", "Visit a farm and help with a task",
  "See where food comes from: pick, plant or feed animals.",
  ["Find a farm stay, organic farm or relative's farm.", "Ask to help with one task.", "Learn how one crop is grown."],
  "low", "out", "Half a day", 240, "moderate", "social", "learn connect",
  ["Visit during harvest", "Stay overnight on a farm", "Volunteer for a week on a farm"], "farm food nature")
h("plant_tree", "outdoors", "Tree planting", "Plant a tree",
  "Plant a native sapling where it can grow for decades.",
  ["Get permission and pick a sunny spot.", "Choose a native sapling such as neem or jamun.", "Plant it, water it and check on it weekly."],
  "low", "out", "1 hr", 60, "moderate", "either", "connect active",
  ["Keep it alive through a summer", "Plant ten trees", "Join a city plantation drive"], "nature sustainability")

# ---------------------------------------------------------------- Grow & Make
h("herb_pot", "home", "Herb gardening", "Grow tulsi, mint or coriander",
  "A single pot on a windowsill is enough for a kitchen herb.",
  ["Fill a pot with soil and plant seeds or a cutting.", "Keep it in sunlight and water it lightly.", "Harvest your first leaves."],
  "low", "home", "2–4 weeks", 10, "calm", "solo", "relax learn",
  ["Grow three herbs", "Grow a herb from seed to harvest", "Start a balcony kitchen garden"], "gardening plants food")
h("microgreens_tray", "home", "Microgreens", "Harvest a tray of microgreens",
  "Mustard, methi or moong microgreens are ready in about a week.",
  ["Spread soaked seeds densely on soil in a shallow tray.", "Mist with water daily and keep it in indirect light.", "Snip the greens when they're 5–8 cm tall."],
  "low", "home", "1 week", 10, "calm", "solo", "learn relax",
  ["Grow three varieties", "Grow continuously for a month", "Gift trays to friends"], "gardening food")
h("start_compost", "home", "Composting", "Start a kitchen compost bin",
  "Turn vegetable peels into rich soil for your plants.",
  ["Make holes in a bucket or bin for air.", "Layer vegetable scraps with dry leaves or paper.", "Mix it weekly and keep it moist, not wet."],
  "low", "home", "1 hr to start", 60, "calm", "solo", "learn",
  ["Harvest your first compost", "Compost for three months", "Help your building start composting"], "gardening sustainability")
h("money_plant_cutting", "home", "Propagation", "Root a money-plant cutting",
  "Grow a new plant from a single cutting in a glass of water.",
  ["Cut a stem just below a node.", "Place it in a glass of water.", "Change the water weekly until roots appear."],
  "free", "home", "2 weeks", 10, "calm", "solo", "relax",
  ["Propagate three different plants", "Pot your cuttings in soil", "Gift propagated plants to friends"], "plants gardening")
h("bake_bread", "home", "Bread baking", "Bake a loaf of bread",
  "Flour, water, yeast and salt. Baking your first loaf is very satisfying.",
  ["Mix and knead a simple dough.", "Let it rise until it doubles in size.", "Shape it and bake until golden."],
  "low", "home", "3 hr", 180, "calm", "solo", "create",
  ["Bake three kinds of bread", "Bake pav for a family meal", "Keep a sourdough starter going"], "baking food")
h("small_pickle", "home", "Pickling", "Make a small jar of pickle",
  "A quick nimbu or mango pickle is a taste of home-kitchen tradition.",
  ["Chop fresh lime or raw mango.", "Mix with salt, spices and oil as a family or trusted recipe says.", "Store it in a clean, dry jar and let it mature."],
  "low", "home", "1 hr + resting", 60, "calm", "either", "create learn",
  ["Make three kinds of pickle", "Learn a family recipe from an elder", "Make a season's batch to share"], "food india preserving")
h("set_curd", "home", "Fermentation", "Set curd or ferment batter from scratch",
  "Dahi and idli batter are everyday ferments, and fun to get right yourself.",
  ["Warm milk and add a spoon of curd, or grind soaked rice and urad dal.", "Leave it covered somewhere warm overnight.", "Check the texture and taste the next day."],
  "low", "home", "Overnight", 30, "calm", "solo", "learn",
  ["Get consistent results three times", "Make dosa batter from scratch", "Try kanji or kombucha"], "food india fermentation")
h("masala_chai_whole", "home", "Chai making", "Make masala chai from whole spices",
  "Crush your own cardamom, ginger and cloves for a fragrant cup.",
  ["Crush cardamom, cloves and ginger.", "Simmer the spices in water, then add tea leaves.", "Add milk and sugar, bring it to a boil and strain."],
  "low", "home", "15 min", 15, "calm", "either", "create connect",
  ["Make your own chai masala blend", "Serve chai to guests", "Taste five single-origin teas"], "food india drink")
h("cook_new_recipe", "home", "Cooking", "Cook a new recipe on your own",
  "Pick a dish you've never made and follow the recipe start to finish.",
  ["Choose a simple recipe with under ten ingredients.", "Prepare and measure everything before you start.", "Cook it and share it with someone."],
  "low", "home", "1 hr", 60, "moderate", "either", "create connect",
  ["Cook ten new dishes", "Cook a three-course meal", "Cook a full festive meal"], "food cooking")
h("terrarium", "home", "Terrariums", "Build a mini terrarium",
  "A tiny garden in a glass jar, with layers of pebbles, charcoal, soil and small plants.",
  ["Layer pebbles, then soil, in a clean glass jar.", "Plant two or three small, slow-growing plants.", "Add moss or stones and mist lightly."],
  "low", "home", "1 hr", 60, "calm", "solo", "create relax",
  ["Keep it healthy for three months", "Build a closed terrarium", "Make one as a gift"], "plants craft")
h("bake_cookies", "home", "Baking", "Bake a batch of cookies",
  "Cookies are forgiving and quick, the perfect first bake.",
  ["Follow a simple butter-cookie or nankhatai recipe.", "Portion the dough evenly on a tray.", "Bake until just golden at the edges."],
  "low", "home", "1 hr", 60, "calm", "either", "create connect",
  ["Bake a cake", "Bake for a celebration", "Develop your own recipe"], "baking food")
h("candle_making", "home", "Candle making", "Make a candle",
  "Melt wax, add a wick and pour. Diwali diyas and jar candles are easy starts.",
  ["Melt soy or paraffin wax gently in a double boiler.", "Fix a wick in a jar or diya.", "Pour, let it set, and never leave melting wax alone."],
  "low", "home", "1 hr", 60, "calm", "solo", "create",
  ["Make scented candles", "Make a set for Diwali", "Make layered or moulded candles"], "craft festival gifting")
h("homemade_jam", "home", "Preserves", "Make a small jar of jam",
  "Fruit and sugar, cooked down. Seasonal mangoes or strawberries work well.",
  ["Chop ripe fruit and add sugar and lemon juice.", "Cook, stirring, until it thickens.", "Pour into a clean jar and let it cool."],
  "low", "home", "1 hr", 60, "calm", "solo", "create",
  ["Make three flavours", "Make a chutney", "Gift jars at a festival"], "food preserving")
h("grow_tomatoes", "home", "Container vegetables", "Grow tomatoes in a pot",
  "Cherry tomatoes grow happily on a sunny balcony.",
  ["Plant a seedling in a large pot with good soil.", "Give it six hours of sun and water regularly.", "Support it with a stick and harvest when red."],
  "low", "home", "2–3 months", 10, "calm", "solo", "learn relax",
  ["Grow three vegetables", "Save seeds for next season", "Grow a month's worth of greens"], "gardening food")
h("filter_coffee", "home", "Coffee brewing", "Brew South Indian filter coffee",
  "Decoction, hot milk and the famous pour between tumbler and dabarah.",
  ["Add coffee powder to the top chamber of a filter and pour in hot water.", "Let the decoction drip through.", "Mix with hot milk and sugar, and froth by pouring."],
  "low", "home", "20 min", 20, "calm", "either", "create learn",
  ["Try three brewing methods", "Make a pour-over", "Visit a coffee estate"], "drink india coffee")
h("homemade_paneer", "home", "Cheesemaking", "Make paneer at home",
  "Paneer needs just milk and lemon juice, and is ready in under an hour.",
  ["Bring full-fat milk to a boil.", "Add lemon juice until it curdles.", "Strain through cloth and press under a weight."],
  "low", "home", "45 min", 45, "calm", "solo", "learn create",
  ["Cook a dish with your own paneer", "Make chhena sweets", "Try a simple soft cheese"], "food india")

# ---------------------------------------------------------------- Music & Play
h("sing_by_heart", "play", "Singing", "Sing a full song by heart",
  "Learn every word of one song and sing it through.",
  ["Pick a song you love.", "Learn the lyrics verse by verse.", "Sing the whole song without reading the words."],
  "free", "home", "A few days", 20, "moderate", "either", "create relax",
  ["Learn five songs", "Sing for family or friends", "Take a singing class or join a choir"], "music voice")
h("basic_rhythm", "play", "Rhythm", "Learn a basic beat",
  "Learn a simple taal on a dholak, tabla or just a table top.",
  ["Learn a simple pattern, such as teental counting.", "Tap it slowly with a metronome app.", "Play it for one minute without losing the beat."],
  "free", "home", "1 hr", 30, "moderate", "solo", "create learn",
  ["Learn three taals", "Play along to a song", "Play with other musicians"], "music india rhythm")
h("play_simple_tune", "play", "Instruments", "Play a simple tune",
  "Harmonica, bansuri or ukulele are friendly first instruments.",
  ["Choose an affordable beginner instrument.", "Learn the notes of a simple tune.", "Play it from start to finish."],
  "medium", "home", "1 week", 30, "calm", "solo", "create learn",
  ["Play five songs", "Practise 20 minutes daily for a month", "Perform a song for others"], "music instrument")
h("learn_routine", "play", "Dance", "Learn a full dance routine",
  "From Bollywood to folk, follow a tutorial and learn one routine end to end.",
  ["Pick a beginner routine video.", "Learn it in short sections.", "Dance the whole routine without pausing."],
  "free", "home", "A few days", 30, "active", "either", "active create",
  ["Learn three routines", "Dance at a celebration", "Join a dance class"], "dance fitness music")
h("hundred_skips", "play", "Skipping", "Do 100 skips without stopping",
  "A skipping rope is cheap, portable and great exercise.",
  ["Adjust the rope to your height.", "Practise steady, low jumps.", "Build up to 100 in a row."],
  "low", "home", "A few days", 15, "active", "solo", "active",
  ["Skip 500 in a session", "Learn the criss-cross", "Learn double-unders"], "fitness play")
h("gully_cricket", "play", "Gully cricket", "Play a game of gully cricket",
  "India's favourite street game. All you need is a bat, a ball and friends.",
  ["Gather a few friends and a safe open space.", "Agree on local rules and boundaries.", "Play a full match."],
  "free", "local", "1–2 hr", 90, "active", "social", "active connect",
  ["Play every weekend for a month", "Organise a mini tournament", "Join a local club net session"], "sport india friends")
h("win_carrom", "play", "Carrom", "Win a game of carrom",
  "A classic Indian table game of flicks and angles.",
  ["Learn the basic rules and scoring.", "Practise striking towards the pockets.", "Play and win one game."],
  "medium", "home", "1 hr", 60, "calm", "social", "connect relax",
  ["Pocket the queen with cover", "Learn rebound shots", "Play in a local tournament"], "game india family")
h("kho_kho_kabaddi", "play", "Traditional games", "Play kho-kho or kabaddi",
  "Two traditional Indian team games that need no equipment at all.",
  ["Gather enough players for two teams.", "Learn the basic rules.", "Play one full game."],
  "free", "local", "1 hr", 60, "active", "social", "active connect",
  ["Play both games", "Teach the rules to newcomers", "Join a local team"], "sport india friends")
h("juggle_three", "play", "Juggling", "Juggle three balls for 10 catches",
  "Start with one ball, then two, then three.",
  ["Practise throwing one ball in an arc from hand to hand.", "Add a second ball, then a third.", "Keep going until you make 10 catches in a row."],
  "low", "home", "A few days", 15, "moderate", "solo", "learn active",
  ["Juggle for one minute", "Learn a trick such as the shower", "Juggle four balls"], "play coordination")
h("card_magic", "play", "Magic tricks", "Learn and perform a card trick",
  "One good trick, practised well, can delight a whole room.",
  ["Learn a simple self-working card trick.", "Practise it ten times in front of a mirror.", "Perform it for a friend."],
  "low", "home", "1 hr", 30, "calm", "either", "learn connect",
  ["Learn five tricks", "Learn a sleight-of-hand move", "Perform a short routine"], "magic play")
h("yoyo_trick", "play", "Yo-yo", "Land a yo-yo trick",
  "Start with a sleeper, then walk the dog.",
  ["Get a responsive beginner yo-yo.", "Learn to throw a sleeper that spins for 3 seconds.", "Land 'walk the dog' three times."],
  "low", "home", "A few days", 15, "moderate", "solo", "learn",
  ["Learn five tricks", "Learn a string trick", "Learn an unresponsive bind"], "play coordination")
h("antakshari", "play", "Antakshari", "Play a round of antakshari",
  "The singing game where each song starts with the last letter of the previous one.",
  ["Gather friends or family into two teams.", "Start with a song and follow the last-letter rule.", "Play until one team is stumped."],
  "free", "home", "1 hr", 60, "calm", "social", "connect relax",
  ["Play at a family gathering", "Play a themed round", "Host an antakshari night"], "music india friends")
h("beatboxing", "play", "Beatboxing", "Beatbox a basic beat",
  "Kick, hi-hat and snare, all with your mouth.",
  ["Learn the three basic sounds: 'b', 't' and 'pf'.", "Combine them into a simple 4-beat pattern.", "Keep it going for 30 seconds."],
  "free", "home", "30 min", 30, "moderate", "solo", "create learn",
  ["Add two new sounds", "Beatbox along to a song", "Perform for friends"], "music voice")
h("lagori", "play", "Lagori", "Play a game of lagori (pittu)",
  "Knock down a stack of stones with a ball, then rebuild it before you're tagged.",
  ["Stack seven flat stones.", "Split into two teams and take turns throwing.", "Rebuild the stack while dodging the other team."],
  "free", "local", "1 hr", 60, "active", "social", "active connect",
  ["Play with a new group", "Teach it to children", "Organise a traditional-games day"], "sport india friends")
h("dance_adavu", "play", "Classical dance", "Learn a basic Bharatanatyam adavu",
  "Adavus are the building-block steps of Bharatanatyam.",
  ["Watch a beginner tutorial on the first adavu (tatta adavu).", "Practise the posture (aramandi) and rhythm slowly.", "Perform eight counts cleanly."],
  "free", "home", "1 hr", 45, "active", "solo", "active learn",
  ["Learn five adavus", "Learn a short piece", "Join a dance school"], "dance india")
h("table_tennis", "play", "Table tennis", "Play a full game of table tennis",
  "Fast, fun and found in many clubs and community centres.",
  ["Find a table at a club, school or community centre.", "Learn to serve and keep a rally going.", "Play a full game to 11 points."],
  "low", "local", "1 hr", 60, "active", "social", "active connect",
  ["Rally 20 shots in a row", "Learn topspin", "Play in a local league"], "sport friends")

# ---------------------------------------------------------------- Capture & Share
h("photo_series", "capture", "Phone photography", "Shoot a 10-photo themed series",
  "Pick a theme, such as doors, shadows or chai stalls, and tell a story in ten shots.",
  ["Choose a theme.", "Take many photos over a day or two.", "Pick your best ten and arrange them in order."],
  "free", "out", "1–2 days", 60, "moderate", "solo", "create",
  ["Learn the rule of thirds and light", "Shoot a themed series every month", "Exhibit or publish a photo series"], "photography art")
h("street_day", "capture", "Street photography", "Photograph one street from morning to evening",
  "The same place looks completely different as the light and people change.",
  ["Choose a street you can return to safely.", "Photograph it in the morning, afternoon and evening.", "Compare the shots side by side."],
  "free", "local", "1 day", 90, "moderate", "solo", "create learn",
  ["Photograph five neighbourhoods", "Shoot candid portraits respectfully", "Build a city photo essay"], "photography city")
h("thirty_sec_video", "capture", "Video editing", "Edit a 30-second clip of your day",
  "Learn the basics of cutting clips and adding music with a free phone editor.",
  ["Record short clips throughout one day.", "Trim them into a 30-second sequence.", "Add music or text and export it."],
  "free", "home", "1 hr", 60, "calm", "solo", "create",
  ["Edit a 3-minute video", "Make a travel film", "Make a short film with a story"], "video creative")
h("stop_motion", "capture", "Stop motion", "Make a 10-second stop-motion clip",
  "Move an object a little, take a photo, repeat. A free app stitches it together.",
  ["Pick a small object, such as a toy, clay or coins.", "Fix your phone steady and take 50+ photos, moving it slightly each time.", "Play it back at 10 frames per second."],
  "free", "home", "1 hr", 60, "calm", "solo", "create",
  ["Make a 30-second story", "Animate a clay character", "Make a stop-motion short with sound"], "video animation")
h("record_podcast", "capture", "Podcasting", "Record a 10-minute podcast episode",
  "Just your phone, a quiet room and something you care about.",
  ["Pick a topic and jot down three talking points.", "Record in a quiet room, phone close to you.", "Trim the start and end and listen back."],
  "free", "home", "1 hr", 60, "calm", "either", "create connect",
  ["Record five episodes", "Interview a guest", "Publish a season"], "audio creative")
h("time_lapse", "capture", "Time-lapse", "Shoot a time-lapse",
  "Clouds, traffic or a sunset, sped up.",
  ["Set your phone on something steady facing a changing scene.", "Use the time-lapse mode for at least 15 minutes.", "Watch it back and share it."],
  "free", "out", "30 min", 30, "calm", "solo", "create",
  ["Shoot a sunrise time-lapse", "Make a day-to-night lapse", "Edit a time-lapse montage"], "video photography")
h("photo_a_day", "capture", "Photo-a-day", "Take one photo a day for a week",
  "A tiny daily habit that makes you notice your surroundings.",
  ["Take one deliberate photo each day.", "Pick a daily prompt, such as 'red' or 'shadow'.", "Make a seven-photo collage at the end."],
  "free", "local", "5 min a day", 5, "calm", "solo", "create relax",
  ["Keep it up for 30 days", "Do a 365-day project", "Print a photo book"], "photography habit")
h("travel_blog", "capture", "Blogging", "Write a blog post about a place",
  "Share a place you know well with tips only a local would know.",
  ["Pick a place: a market, a café or a temple.", "Write 500 words with three tips and two photos.", "Publish it on a free blog platform."],
  "free", "home", "1–2 hr", 90, "calm", "solo", "create connect",
  ["Write five posts", "Get your first comment from a stranger", "Write a guide to your city"], "writing travel")

# ---------------------------------------------------------------- Fitness & Movement
h("run_2km", "fitness", "Running", "Run 2 km without stopping",
  "Start with run-walk intervals and build up gradually.",
  ["Alternate one minute running and two minutes walking.", "Repeat three times a week, adding running time.", "Run 2 km continuously at an easy pace."],
  "free", "out", "30 min", 30, "active", "either", "active",
  ["Run 5 km", "Run three times a week for a month", "Run a 10 km race"], "running fitness")
h("stretch_week", "fitness", "Stretching", "Stretch for 10 minutes daily for a week",
  "Gentle stretching eases stiffness, especially after sitting all day.",
  ["Follow a beginner full-body stretch routine.", "Hold each stretch 20–30 seconds without bouncing.", "Repeat daily for seven days."],
  "free", "home", "10 min a day", 10, "calm", "solo", "active relax",
  ["Stretch daily for a month", "Touch your toes comfortably", "Learn a full mobility routine"], "fitness wellness")
h("swim_lengths", "fitness", "Swimming", "Swim 10 lengths of a pool",
  "Swimming works the whole body and is easy on the joints.",
  ["Find a public pool with lifeguards.", "Take lessons first if you can't swim yet.", "Swim 10 lengths at your own pace, resting as needed."],
  "medium", "local", "1 hr", 60, "active", "either", "active",
  ["Swim 500 m without stopping", "Learn a second stroke", "Swim 1.5 km"], "swimming fitness")
h("plank_minute", "fitness", "Core strength", "Hold a plank for 1 minute",
  "A plank builds core strength with no equipment.",
  ["Start on your forearms and toes with a straight body.", "Hold for 20 seconds, rest, and repeat.", "Build up to one full minute over a week."],
  "free", "home", "10 min", 10, "active", "solo", "active",
  ["Hold for 2 minutes", "Add side planks", "Complete a 30-day core plan"], "fitness bodyweight")
h("twenty_pushups", "fitness", "Bodyweight training", "Do 20 push-ups",
  "Start against a wall or on your knees, then progress to full push-ups.",
  ["Start with wall or knee push-ups.", "Do three sets a few times a week.", "Work up to 20 full push-ups in a row."],
  "free", "home", "15 min", 15, "active", "solo", "active",
  ["Do 50 in a session", "Do a pull-up", "Follow a 12-week strength plan"], "fitness bodyweight")
h("stair_climb", "fitness", "Stair climbing", "Climb 20 floors in a day",
  "Stairs are a free workout built into every building.",
  ["Take the stairs instead of the lift all day.", "Count the floors you climb.", "Reach 20 floors by evening."],
  "free", "local", "1 day", 15, "active", "solo", "active",
  ["Climb 50 floors in a day", "Climb 10 floors without stopping", "Do a stair-climb race"], "fitness habit")
h("zumba_class", "fitness", "Zumba", "Do a Zumba session",
  "Dance-based fitness to upbeat music. Fun even if you can't dance.",
  ["Find a free online class or a local trial session.", "Wear comfortable shoes and keep water nearby.", "Follow along for the full session."],
  "free", "home", "45 min", 45, "active", "either", "active relax",
  ["Do three sessions a week", "Join an in-person class", "Learn a full routine by heart"], "dance fitness music")
h("badminton_game", "fitness", "Badminton", "Play a game of badminton",
  "One of India's most-played sports, in parks, courts and colonies.",
  ["Find a partner and a court or open space.", "Learn the serve and basic rally.", "Play a full game to 21."],
  "low", "local", "1 hr", 60, "active", "social", "active connect",
  ["Play weekly for a month", "Learn the smash and drop shot", "Play a club doubles match"], "sport friends")
h("football_kickabout", "fitness", "Football", "Play a football match with friends",
  "Five-a-side in a park or turf is easy to organise.",
  ["Gather eight to ten people.", "Book a turf or find an open ground.", "Play a full match, warming up first."],
  "low", "local", "1–2 hr", 90, "active", "social", "active connect",
  ["Play weekly for a month", "Score a goal", "Join a local league"], "sport friends")
h("bouldering", "fitness", "Climbing", "Try indoor bouldering",
  "Short climbing routes over padded floors. No ropes, and beginners welcome.",
  ["Find a climbing gym and book a beginner session.", "Learn how to fall safely and read route grades.", "Complete three of the easiest problems."],
  "medium", "local", "2 hr", 120, "active", "either", "active learn",
  ["Climb the next grade up", "Climb weekly for a month", "Try outdoor climbing with a guide"], "climbing fitness")
h("ten_k_steps", "fitness", "Walking", "Walk 10,000 steps in a day",
  "Spread walks through the day: a morning stroll, walking calls, an evening loop.",
  ["Turn on your phone's step counter.", "Add three short walks to your day.", "Reach 10,000 by bedtime."],
  "free", "local", "1 day", 90, "moderate", "solo", "active",
  ["Hit 10,000 five days in a week", "Walk 100 km in a month", "Join a walking group"], "walking fitness habit")
h("roller_skate", "fitness", "Skating", "Skate 50 m without falling",
  "Roller skating rinks and coaching are common in many Indian cities.",
  ["Wear a helmet and knee and elbow pads.", "Practise balancing and small gliding steps.", "Skate 50 m in one go."],
  "medium", "local", "1 hr", 60, "active", "either", "active learn",
  ["Learn to stop smoothly", "Skate 1 km", "Learn a basic trick"], "skating fitness")
h("martial_arts_trial", "fitness", "Martial arts", "Take a martial arts trial class",
  "Karate, taekwondo or kalaripayattu: most schools offer a free first class.",
  ["Find a school offering a beginner trial.", "Wear comfortable clothes and arrive early.", "Complete the class and learn one technique."],
  "low", "local", "1 hr", 60, "active", "social", "active learn",
  ["Attend for a month", "Learn a full form or kata", "Earn your first belt"], "fitness india self-defence")
h("free_throws", "fitness", "Basketball", "Make 10 free throws",
  "Find a hoop in a park or school and practise your shot.",
  ["Stand at the free-throw line.", "Use the same simple routine for every shot.", "Keep shooting until you've made 10."],
  "free", "local", "45 min", 45, "active", "either", "active",
  ["Make 7 out of 10", "Play a pickup game", "Join a weekly game"], "sport")
h("home_workout", "fitness", "Home workouts", "Complete a 20-minute home workout",
  "Bodyweight circuits need no gym and no equipment.",
  ["Pick a beginner 20-minute video.", "Warm up, then follow at your own pace.", "Finish with a cool-down stretch."],
  "free", "home", "20 min", 20, "active", "solo", "active",
  ["Work out three times a week", "Complete a 30-day plan", "Design your own routine"], "fitness bodyweight")
h("tai_chi", "fitness", "Tai chi", "Learn a 5-minute tai chi sequence",
  "Slow, flowing movements for balance and calm.",
  ["Follow a beginner tai chi video.", "Move slowly and breathe steadily.", "Practise the sequence until you can do it without the video."],
  "free", "home", "15 min", 15, "calm", "solo", "relax active",
  ["Practise daily for two weeks", "Learn a longer form", "Join a park group"], "wellness balance")
h("hula_hoop", "fitness", "Hula hooping", "Hula hoop for 2 minutes",
  "A heavier adult hoop is easier to keep up than a kids' one.",
  ["Use a hoop that reaches about your waist.", "Push it around and rock your hips forward and back.", "Keep it going for 2 minutes."],
  "low", "home", "15 min", 15, "active", "solo", "active relax",
  ["Hoop for 10 minutes", "Learn a hand trick", "Hoop to a whole song with tricks"], "fitness play")
h("five_k", "fitness", "5K events", "Join a community 5 km walk or run",
  "Free weekly 5 km events and charity runs welcome walkers and runners alike.",
  ["Find a free weekly 5K or a charity run near you.", "Register and turn up a bit early.", "Walk or run the whole course at your own pace."],
  "free", "local", "1 hr", 60, "active", "social", "active connect",
  ["Do five events", "Beat your first time", "Volunteer at an event"], "running community")

# ---------------------------------------------------------------- Learn & Explore
h("sign_language", "learn", "Sign language", "Learn 10 Indian Sign Language signs",
  "Greetings, thank you, family and numbers are a great start.",
  ["Find a free ISL video course.", "Learn greetings, thank you and family signs.", "Sign them to someone and explain what they mean."],
  "free", "home", "1 hr", 30, "calm", "solo", "learn connect",
  ["Learn 100 signs", "Fingerspell your full name", "Hold a basic signed conversation"], "language accessibility")
h("code_web_page", "learn", "Coding", "Build a one-page website",
  "A few lines of HTML in a free online editor make a real web page.",
  ["Open a free online HTML editor.", "Add a heading, a paragraph and an image.", "Change the colours and share the link."],
  "free", "home", "1 hr", 60, "calm", "solo", "learn create",
  ["Add a style sheet and a second page", "Build a small app", "Publish a project others use"], "technology learning")
h("touch_typing", "learn", "Touch typing", "Type 40 words per minute",
  "Typing without looking saves hours every year.",
  ["Use a free typing tutor for 15 minutes a day.", "Keep your fingers on the home row.", "Take a test once you're comfortable."],
  "free", "home", "15 min a day", 15, "calm", "solo", "learn",
  ["Type 60 wpm", "Type in a second script", "Type 80 wpm accurately"], "skills technology")
h("documentary_facts", "learn", "Documentaries", "Watch a documentary and note 5 facts",
  "Nature, history or science: watch actively and learn something.",
  ["Pick a documentary on a topic new to you.", "Write down five things that surprised you.", "Tell someone the most interesting one."],
  "free", "home", "1–2 hr", 90, "calm", "either", "learn relax",
  ["Watch a documentary series", "Read a book on the same topic", "Visit a place from a documentary"], "film learning")
h("first_aid", "learn", "First aid", "Learn basic first aid",
  "Knowing CPR and how to treat burns or cuts can save a life.",
  ["Find a free online or Red Cross first-aid module.", "Learn CPR steps, recovery position and burn care.", "Assemble a basic first-aid kit at home."],
  "free", "home", "2 hr", 120, "calm", "solo", "learn",
  ["Take a hands-on CPR class", "Get certified", "Refresh your training every year"], "safety skills")
h("museum_visit", "learn", "Museums", "Visit a museum and find 3 favourites",
  "Most cities have a museum you've walked past but never visited.",
  ["Pick a museum near you.", "Spend at least an hour inside.", "Choose three favourite exhibits and learn their stories."],
  "low", "local", "2 hr", 120, "calm", "either", "learn",
  ["Visit three museums", "Join a guided tour", "Visit a national museum"], "history culture city")
h("five_knots", "learn", "Knot tying", "Learn 5 useful knots",
  "The reef knot, bowline, clove hitch, sheet bend and figure-eight.",
  ["Get a piece of rope or cord.", "Learn each knot from a diagram or video.", "Tie each from memory."],
  "free", "home", "45 min", 45, "calm", "solo", "learn",
  ["Tie all five blindfolded", "Learn ten knots", "Use knots on a camping trip"], "skills outdoors")
h("map_compass", "learn", "Navigation", "Find your way with a map and compass",
  "A paper map and compass work when phones don't.",
  ["Get a local map and a basic compass.", "Learn to orient the map to north.", "Navigate to three points in a park."],
  "low", "out", "2 hr", 120, "moderate", "either", "learn active",
  ["Navigate a new trail", "Try an orienteering event", "Plan a route for a group"], "skills outdoors")
h("online_course", "learn", "Online learning", "Finish one module of a free online course",
  "Free university courses cover almost any subject.",
  ["Pick a free course on a topic you're curious about.", "Complete the first module and its quiz.", "Write down the three key ideas."],
  "free", "home", "1–2 hr", 90, "calm", "solo", "learn",
  ["Finish the whole course", "Complete three courses", "Earn a certificate"], "learning")
h("bike_tube", "learn", "Bike repair", "Fix a bicycle puncture",
  "A basic repair that saves money and long walks home.",
  ["Remove the wheel and tyre lever off the tyre.", "Find the hole and patch it, or fit a new tube.", "Refit the tyre and pump it up."],
  "low", "home", "45 min", 45, "moderate", "solo", "learn",
  ["Adjust brakes and gears", "Service a bike fully", "Help someone fix theirs"], "skills cycling")
h("diy_repair", "learn", "DIY repair", "Fix something broken at home",
  "A loose hinge, a wobbly chair or a torn cushion. Repair instead of replace.",
  ["Pick one small broken thing.", "Watch a repair tutorial for it.", "Fix it with basic tools."],
  "low", "home", "1 hr", 60, "moderate", "solo", "learn create",
  ["Fix five things", "Learn basic electrical safety", "Hold a repair session for neighbours"], "skills sustainability")
h("simple_circuit", "learn", "Electronics", "Build a simple circuit",
  "Light an LED with a battery, a resistor and a switch.",
  ["Get a beginner kit with a battery, LED, resistor and wires.", "Follow a diagram to connect them.", "Add a switch to turn it on and off."],
  "low", "home", "1 hr", 60, "calm", "solo", "learn",
  ["Build a circuit with a sensor", "Program a microcontroller", "Build a useful gadget"], "technology science")
h("local_history", "learn", "Local history", "Learn the history of your neighbourhood",
  "Every street name and old building has a story.",
  ["Ask an elder or search for your area's history.", "Find out how three street or place names came about.", "Visit the oldest building near you."],
  "free", "local", "2 hr", 90, "calm", "either", "learn connect",
  ["Write a short history of your area", "Lead a walk for neighbours", "Record an elder's memories"], "history city")
h("birdsong", "learn", "Birdsong", "Recognise 5 birds by their call",
  "Koels, bulbuls and barbets are often heard before they're seen.",
  ["Use a free birdsong app or recordings.", "Listen outside at dawn.", "Match five calls to the right birds."],
  "free", "out", "A few mornings", 30, "calm", "solo", "learn relax",
  ["Recognise 15 calls", "Record birdsong on your phone", "Help a bird survey"], "nature birds sound")
h("home_science", "learn", "Home science", "Do a science experiment at home",
  "Grow crystals, make a lava lamp or test what floats. Kitchen science is fun at any age.",
  ["Pick a safe kitchen experiment.", "Predict what will happen, then try it.", "Write down what actually happened and why."],
  "free", "home", "1 hr", 60, "calm", "either", "learn connect",
  ["Do five experiments", "Grow sugar crystals over a week", "Run a science afternoon for kids"], "science learning family")

# ---------------------------------------------------------------- People & Community
h("volunteer_day", "people", "Volunteering", "Volunteer for a day",
  "Food banks, animal shelters and NGOs all welcome one-day volunteers.",
  ["Find a local NGO or shelter that takes volunteers.", "Sign up for a single shift.", "Show up, help out and ask how you can return."],
  "free", "local", "Half a day", 240, "moderate", "social", "connect",
  ["Volunteer monthly", "Volunteer for three causes", "Lead a volunteer project"], "community kindness")
h("join_club", "people", "Clubs", "Attend a local club or meetup",
  "Hiking, chess, photography or coding: there's a group for almost everything.",
  ["Search for a meetup in an interest you have.", "Go to one session, even if alone.", "Talk to at least two people."],
  "free", "local", "2 hr", 120, "calm", "social", "connect learn",
  ["Attend three meetings", "Bring a friend", "Help organise a meetup"], "community friends")
h("board_game_night", "people", "Board games", "Host a board game night",
  "Ludo, Monopoly or something new. Games bring people together.",
  ["Invite three or more friends.", "Pick one or two easy games.", "Play, snack and laugh."],
  "free", "home", "3 hr", 180, "calm", "social", "connect relax",
  ["Learn a new modern board game", "Host monthly", "Join a board game café night"], "game friends")
h("cook_for_friends", "people", "Hosting", "Cook a meal for friends",
  "Feeding people is one of the oldest ways to show care.",
  ["Invite two to four friends.", "Plan a simple menu you can cook ahead.", "Cook, serve and enjoy together."],
  "medium", "home", "3 hr", 180, "moderate", "social", "connect create",
  ["Host a themed dinner", "Host for eight people", "Host a festival meal"], "food friends")
h("cleanup_drive", "people", "Cleanup drives", "Join a cleanup drive",
  "Beaches, lakes and streets get cleaner one bag at a time.",
  ["Find a local cleanup group or start a small one.", "Bring gloves and bags.", "Collect litter for an hour and dispose of it properly."],
  "free", "out", "2 hr", 120, "moderate", "social", "connect active",
  ["Join three drives", "Organise one", "Adopt a spot to keep clean"], "community sustainability")
h("teach_skill", "people", "Teaching", "Teach someone a skill",
  "Teaching something you know, such as a recipe, a song or an app, helps you learn it better too.",
  ["Pick something you're good at.", "Break it into three simple steps.", "Teach it to a friend, child or elder."],
  "free", "home", "1 hr", 60, "calm", "social", "connect learn",
  ["Teach three people", "Run a small workshop", "Mentor someone for a month"], "community learning")
h("book_club", "people", "Book clubs", "Join or start a book club meeting",
  "Reading together gives you a reason to finish and someone to talk to.",
  ["Find a local or online book club, or invite two friends.", "Read the chosen book or a part of it.", "Join the discussion and share one opinion."],
  "free", "local", "2 hr", 120, "calm", "social", "connect learn",
  ["Attend three meetings", "Pick a book for the group", "Start your own club"], "books community")
h("local_festival", "people", "Festivals", "Attend a local festival or mela",
  "Melas, harvest festivals and cultural fairs are full of food, music and crafts.",
  ["Find a fair or festival happening near you.", "Go with friends or family.", "Try a new food, watch a performance and buy one handmade thing."],
  "low", "local", "Half a day", 240, "moderate", "social", "connect learn",
  ["Attend festivals from three cultures", "Volunteer at one", "Travel for a famous festival"], "india festival culture")
h("quiz_night", "people", "Quizzing", "Take part in a quiz night",
  "Pub quizzes, college quizzes and online quizzes are great team fun.",
  ["Find a quiz night or an online quiz.", "Team up with friends.", "Play the whole quiz and learn three new facts."],
  "low", "local", "2 hr", 120, "calm", "social", "connect learn",
  ["Attend monthly", "Win a round", "Write and host your own quiz"], "trivia friends")
h("karaoke", "people", "Karaoke", "Sing at a karaoke night",
  "Everyone sounds better when the whole room is singing along.",
  ["Find a karaoke night or use a karaoke app at home.", "Pick a song you know well.", "Sing it all the way through."],
  "low", "local", "2 hr", 120, "moderate", "social", "connect relax",
  ["Sing a duet", "Sing a song in another language", "Host a karaoke party"], "music friends")
h("call_old_friend", "people", "Reconnecting", "Call an old friend",
  "A real conversation with someone you've lost touch with.",
  ["Think of someone you miss.", "Message to find a good time.", "Call and talk for at least 20 minutes."],
  "free", "home", "30 min", 30, "calm", "social", "connect",
  ["Reconnect with three people", "Meet one in person", "Plan a reunion"], "friends connection")
h("potluck", "people", "Potlucks", "Organise a potluck",
  "Everyone brings one dish. Low effort, big feast.",
  ["Invite friends or neighbours and set a date.", "Ask each person to bring one dish.", "Host, eat and swap recipes."],
  "low", "home", "3 hr", 180, "calm", "social", "connect",
  ["Host a themed potluck", "Make it monthly", "Organise one for your whole building"], "food community")
h("open_mic", "people", "Open mics", "Attend an open mic night",
  "Poetry, music and comedy from local performers. Maybe you'll perform next time.",
  ["Find an open mic at a café or community space.", "Go and support the performers.", "Note one act that inspired you."],
  "low", "local", "2 hr", 120, "calm", "social", "connect create",
  ["Attend three", "Perform a piece", "Perform regularly"], "performance community")
h("kindness_act", "people", "Kindness", "Do a random act of kindness",
  "Small, unexpected kindness brightens two days: theirs and yours.",
  ["Think of something small: pay for a chai, help carry bags, leave a kind note.", "Do it without expecting anything back.", "Notice how it feels."],
  "free", "local", "15 min", 15, "calm", "social", "connect",
  ["Do one a day for a week", "Do one for a stranger", "Start a kindness challenge with friends"], "kindness community")
h("elder_story", "people", "Oral history", "Record an elder's story",
  "Grandparents and elders hold stories that disappear if no one asks.",
  ["Ask an elder relative or neighbour if they'd share a memory.", "Record a 15-minute conversation on your phone, with permission.", "Save it and share it with the family."],
  "free", "home", "1 hr", 60, "calm", "social", "connect learn",
  ["Record three stories", "Build a family tree", "Make a family history book or audio archive"], "family history")


def build():
    seen = set()
    items = []
    for e in H:
        assert e["group"] in GROUPS, e["slug"]
        assert e["cost"] in COST_LABEL, e["slug"]
        assert e["energy"] in ENERGY and e["social"] in SOCIAL, e["slug"]
        assert set(e["goals"]) <= GOALS and e["goals"], e["slug"]
        assert len(e["steps"]) == 3 and len(e["ladder"]) == 3, e["slug"]
        item_id = f"hobby_{e['slug']}"
        assert item_id not in seen, item_id
        seen.add(item_id)
        items.append({
            "id": item_id,
            "challenge_id": CH,
            "name": e["win"],
            "category": e["hobby"],
            "filter_group": GROUPS[e["group"]],
            "difficulty": "beginner",
            "about": e["about"],
            "howToSteps": e["steps"],
            "tags": e["tags"],
            "keywords": [e["hobby"].lower()],
            "metadata": {
                "Cost": COST_LABEL[e["cost"]],
                "Where": WHERE[e["where"]],
                "Time": e["time"],
            },
            "attributes": {
                "setting": SETTING[e["where"]],
                "cost": e["cost"],
                "session_minutes": e["minutes"],
                "energy": e["energy"],
                "social": e["social"],
                "goals": e["goals"],
            },
            "ladder": [
                {"level": "tried", "milestone": e["win"]},
                {"level": "learning", "milestone": e["ladder"][0]},
                {"level": "practising", "milestone": e["ladder"][1]},
                {"level": "confident", "milestone": e["ladder"][2]},
            ],
        })
    return {
        "challenge_id": CH,
        "version": 2,
        "source_note": "Curated from public hobby guides and surveys; see docs/research/easy_hobbies_shortlist.md. Generated by tools/build_easy_hobbies.py.",
        "items": items,
    }


if __name__ == "__main__":
    data = build()
    out = Path(__file__).resolve().parents[1] / "assets/data/easy_hobbies.json"
    out.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    counts = {}
    for item in data["items"]:
        counts[item["filter_group"]] = counts.get(item["filter_group"], 0) + 1
    print(len(data["items"]), "items:", counts)
