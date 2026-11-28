"""Generate the UPLYFA Garden & Plants catalogues.

Run from the repository root:  python tools/build_garden.py

Writes four files to assets/data/:
  garden_ways.json    ways to garden (by space and style), each with starter plants
  garden_plants.json  plants to grow, grouped by type, with Indian seasons
  garden_skills.json  gardening skills, basics to advanced
  garden_visits.json  famous gardens in India; ids carry the state id so a
                      visit can stamp India Passport

Seasons follow India's three growing seasons, as approximate sowing windows
(check with a local nursery): Summer/Zaid sow Feb-Apr, Monsoon/Kharif sow
Jun-Jul, Winter/Rabi sow Sep-Nov. No prices; reused containers count as pots.
Descriptions are original summaries.
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets/data"

SOW_MONTHS = {
    "Summer": [2, 3, 4],
    "Monsoon": [6, 7],
    "Winter": [9, 10, 11],
    "Any time": list(range(1, 13)),
}


def slug(text):
    out = "".join(c if c.isalnum() else "_" for c in text.lower())
    while "__" in out:
        out = out.replace("__", "_")
    return out.strip("_")


# ------------------------------------------------------------------ Ways
# name (action), style label, about, space, light, starter plants, first win, steps
WAYS = [
    ("Start a windowsill herb garden", "Windowsill herbs", "Three or four herbs on a sunny sill: the easiest way to start.",
     "A sunny windowsill", "4+ hours of sun", "Tulsi, mint, coriander, basil", "First herb leaves in 3–4 weeks",
     ["Pick your sunniest window.", "Plant tulsi or mint cuttings and coriander seeds in small pots.", "Water when the top inch of soil is dry."]),
    ("Grow a balcony container garden", "Balcony containers", "A few pots and grow bags turn a balcony into a small garden.",
     "A balcony", "Depends on the balcony", "Chilli, tomato, marigold, money plant", "First flower or fruit in 2–3 months",
     ["Watch which hours your balcony gets sun.", "Start with 3–5 pots; check the weight on the railing.", "Mix shade-lovers and sun-lovers to match each spot."]),
    ("Start a terrace kitchen garden", "Terrace kitchen garden", "Grow-bags of vegetables on a rooftop: India's favourite urban garden.",
     "A terrace or rooftop", "Full sun", "Tomato, palak, okra, gourds", "First harvest in 6–10 weeks",
     ["Use grow bags or old buckets with drainage holes.", "Sow what suits the season.", "Water early morning or evening in summer."]),
    ("Create a houseplant corner", "Houseplant corner", "A green corner indoors with easy, forgiving plants.",
     "Any room", "Bright indirect or low light", "Money plant, snake plant, ZZ plant, peace lily", "Settled in after 2–3 weeks",
     ["Find a bright spot out of direct afternoon sun.", "Start with two hardy plants.", "Water only when the soil is dry. Overwatering is the usual mistake."]),
    ("Start a succulent collection", "Succulents & cacti", "Fleshy, sculptural plants that need little water.",
     "A sunny sill or balcony", "Bright light", "Aloe vera, jade, echeveria, haworthia", "New growth in a month",
     ["Use a fast-draining mix with sand or pebbles.", "Water deeply, then wait until the soil is fully dry.", "Grow new plants from fallen leaves."]),
    ("Grow a tray of microgreens", "Microgreens", "Tiny edible greens ready in about a week, even in a flat.",
     "A tray on a table", "Indirect light", "Mustard, methi, moong, radish", "Harvest in 7–10 days",
     ["Soak seeds overnight.", "Spread them thickly on soil in a shallow tray.", "Mist daily and snip when 5–8 cm tall."]),
    ("Try a simple hydroponic jar", "Hydroponics", "Grow greens in water and nutrients, no soil, using the simple jar method.",
     "A sunny sill", "Bright light", "Lettuce, basil, spinach", "First leaves in 3–4 weeks",
     ["Fill a jar with water and hydroponic nutrients.", "Set a seedling in a net cup so its roots touch the water.", "Top up the water as the level drops."]),
    ("Begin a bonsai", "Bonsai", "The slow art of shaping a tree in a small pot.",
     "A sunny outdoor spot", "Sun most of the day", "Ficus, jade, bougainvillea", "First shaping in a few months",
     ["Start with a hardy ficus or jade.", "Pot it in a shallow container with good drainage.", "Prune a little at a time and be patient."]),
    ("Build a terrarium", "Terrarium", "A miniature garden in a glass jar.",
     "A tabletop", "Bright indirect light", "Small ferns, moss, fittonia, small succulents", "Done in an afternoon",
     ["Layer pebbles, charcoal and soil in a clean jar.", "Plant two or three small plants.", "Mist lightly; closed jars rarely need water."]),
    ("Plant a butterfly garden", "Pollinator garden", "Flowers that feed butterflies and bees in your own space.",
     "Balcony, terrace or yard", "Full sun", "Marigold, zinnia, periwinkle, curry leaf", "First visitors in weeks",
     ["Plant bright, nectar-rich flowers.", "Add a host plant like curry leaf for caterpillars.", "Avoid chemical sprays."]),
    ("Make a vertical garden", "Vertical garden", "Grow up the wall when floor space is short.",
     "A wall or railing", "Depends on the wall", "Money plant, herbs, ferns, strawberry", "Green wall in 1–2 months",
     ["Hang pots, pockets or reused bottles on a frame.", "Group plants by water needs.", "Water from the top so it trickles down."]),
    ("Grow a lotus in a tub", "Water garden", "A water lily or lotus in a big tub of water.",
     "A sunny terrace or yard", "Full sun", "Lotus, water lily, water lettuce", "First bloom in a season",
     ["Fill a wide tub with clay soil and water.", "Plant a lotus tuber or water lily.", "Add a few small fish to keep mosquitoes away."]),
]

# ------------------------------------------------------------------ Plants
# group, name, seasons, light, pot, ease, first harvest/flower, about, tip
PLANTS = [
    ("Vegetables", "Tomato", ["Winter"], "Full sun", "Large (15+ litres)", "Moderate", "Harvest in 60–80 days", "The most rewarding kitchen-garden crop.", "Stake it early. Pinch side shoots for bigger fruit."),
    ("Vegetables", "Chilli (Mirchi)", ["Summer", "Monsoon"], "Full sun", "Medium", "Easy", "Harvest in 60–90 days", "Prolific and pretty. One plant gives handfuls.", "Let the soil dry slightly between waterings."),
    ("Vegetables", "Brinjal (Baingan)", ["Monsoon", "Winter"], "Full sun", "Large", "Moderate", "Harvest in 70–90 days", "A sturdy plant with glossy purple fruit.", "Feed with compost every few weeks."),
    ("Vegetables", "Okra (Bhindi)", ["Summer", "Monsoon"], "Full sun", "Medium", "Easy", "Harvest in 45–60 days", "Loves heat and grows fast.", "Pick pods young and tender, every two days."),
    ("Vegetables", "Spinach (Palak)", ["Winter"], "Full sun to partial", "Wide, shallow", "Easy", "Harvest in 30–40 days", "Cut-and-come-again greens for months.", "Harvest outer leaves and let the centre keep growing."),
    ("Vegetables", "Fenugreek (Methi)", ["Winter"], "Full sun", "Wide, shallow", "Easy", "Harvest in 20–30 days", "One of the fastest crops you can grow.", "Sow thickly; harvest by snipping."),
    ("Vegetables", "Radish (Mooli)", ["Winter"], "Full sun", "Deep", "Easy", "Harvest in 30–45 days", "Quick roots for impatient gardeners.", "Thin seedlings so each root has space."),
    ("Vegetables", "Carrot (Gajar)", ["Winter"], "Full sun", "Deep", "Moderate", "Harvest in 70–90 days", "Sweet winter roots, best in loose soil.", "Keep the soil moist while seeds germinate."),
    ("Vegetables", "Bottle gourd (Lauki)", ["Summer", "Monsoon"], "Full sun", "Large", "Moderate", "Harvest in 60–75 days", "A vigorous climber with big fruit.", "Give it a trellis or terrace railing to climb."),
    ("Vegetables", "French beans", ["Monsoon", "Winter"], "Full sun", "Medium", "Easy", "Harvest in 50–60 days", "Climbing or bush beans, generous and quick.", "Pick often to keep them producing."),
    ("Vegetables", "Peas (Matar)", ["Winter"], "Full sun", "Medium", "Easy", "Harvest in 60–70 days", "Sweet pods straight from the vine.", "Give them a small net or sticks to climb."),
    ("Vegetables", "Lettuce", ["Winter"], "Partial sun", "Shallow", "Easy", "Harvest in 40–50 days", "Crisp salad leaves for cool months.", "Shade it from harsh afternoon sun."),
    ("Vegetables", "Cucumber (Kheera)", ["Summer"], "Full sun", "Large", "Moderate", "Harvest in 50–60 days", "A summer climber with crunchy fruit.", "Water regularly; dry soil makes them bitter."),
    ("Vegetables", "Spring onion", ["Winter", "Any time"], "Full sun", "Small", "Easy", "Harvest in 3–4 weeks", "Regrow from kitchen scraps in a glass or pot.", "Replant the white root ends from the market bunch."),
    ("Herbs", "Tulsi (Holy basil)", ["Summer", "Monsoon"], "Full sun", "Medium", "Easy", "Leaves in 3–4 weeks", "A sacred, fragrant household herb.", "Pinch off flower spikes to keep it bushy."),
    ("Herbs", "Mint (Pudina)", ["Any time"], "Partial sun", "Medium", "Easy", "Leaves in 2–3 weeks", "Grows from a market sprig and spreads happily.", "Give it its own pot. It takes over."),
    ("Herbs", "Coriander (Dhaniya)", ["Winter"], "Full sun to partial", "Wide, shallow", "Easy", "Leaves in 3–4 weeks", "The everyday kitchen herb.", "Crush the seeds lightly before sowing."),
    ("Herbs", "Curry leaf (Kadi patta)", ["Summer", "Monsoon"], "Full sun", "Large", "Moderate", "Leaves in a few months", "A small tree with leaves for every tadka.", "Grows slowly at first; be patient."),
    ("Herbs", "Lemongrass", ["Summer", "Monsoon"], "Full sun", "Medium", "Easy", "Stalks in 3–4 months", "Citrusy grass for chai and soups.", "Root a market stalk in water first."),
    ("Herbs", "Ajwain leaf (Karpooravalli)", ["Any time"], "Partial sun", "Small", "Easy", "Leaves in 3–4 weeks", "Fleshy, aromatic leaves, a home remedy favourite.", "Grows easily from a cutting."),
    ("Herbs", "Sweet basil", ["Summer"], "Full sun", "Small", "Easy", "Leaves in 4 weeks", "The basil of pesto and pasta.", "Pinch the tips to make it bushy."),
    ("Herbs", "Ginger (Adrak)", ["Summer", "Monsoon"], "Partial sun", "Wide", "Easy", "Harvest in 8–10 months", "Grow from a sprouting market rhizome.", "Plant a piece with a visible bud just under the soil."),
    ("Herbs", "Turmeric (Haldi)", ["Summer", "Monsoon"], "Partial sun", "Wide", "Easy", "Harvest in 8–9 months", "Lush leaves and golden roots.", "Plant a fresh rhizome before the monsoon."),
    ("Herbs", "Garlic (Lehsun)", ["Winter"], "Full sun", "Medium", "Easy", "Harvest in 4–5 months", "Plant single cloves and harvest whole bulbs.", "Plant cloves pointy end up."),
    ("Flowers", "Marigold (Genda)", ["Winter", "Monsoon"], "Full sun", "Medium", "Easy", "Flowers in 45–60 days", "India's festival flower, and loved by bees.", "Deadhead spent flowers for more blooms."),
    ("Flowers", "Hibiscus (Gudhal)", ["Any time"], "Full sun", "Large", "Easy", "Flowers in a few months", "Big, bold blooms nearly all year.", "Feed regularly and water well in summer."),
    ("Flowers", "Rose (Gulab)", ["Winter"], "Full sun", "Large", "Moderate", "Flowers in 2–3 months", "The classic garden flower.", "Prune after flowering; give plenty of sun."),
    ("Flowers", "Jasmine (Mogra)", ["Summer"], "Full sun", "Medium", "Easy", "Flowers in summer", "Fragrant white summer flowers.", "Prune after the flowering season."),
    ("Flowers", "Sunflower", ["Summer"], "Full sun", "Large", "Easy", "Flowers in 70–90 days", "Tall, cheerful and easy for children to grow.", "Sow directly where it will grow."),
    ("Flowers", "Zinnia", ["Summer", "Monsoon"], "Full sun", "Medium", "Easy", "Flowers in 50–60 days", "Bright, butterfly-friendly blooms.", "Water at the base to keep leaves dry."),
    ("Flowers", "Petunia", ["Winter"], "Full sun", "Small", "Easy", "Flowers in 60–70 days", "Colourful winter balcony flowers.", "Pinch back leggy stems."),
    ("Flowers", "Periwinkle (Sadabahar)", ["Any time"], "Full sun to partial", "Small", "Easy", "Flowers in 6–8 weeks", "Flowers almost every day of the year.", "Tolerates heat and neglect."),
    ("Flowers", "Portulaca (9 o'clock flower)", ["Summer"], "Full sun", "Small", "Easy", "Flowers in 4–6 weeks", "Opens bright flowers in the morning sun.", "Grows from cuttings; loves heat."),
    ("Flowers", "Bougainvillea", ["Any time"], "Full sun", "Large", "Easy", "Flowers in a season", "A riot of colour that thrives in heat.", "Flowers best when slightly under-watered."),
    ("Flowers", "Chrysanthemum (Guldaudi)", ["Monsoon"], "Full sun", "Medium", "Moderate", "Flowers in winter", "The star of winter flower shows.", "Pinch tips until late monsoon for more buds."),
    ("Flowers", "Cosmos", ["Summer", "Monsoon"], "Full sun", "Medium", "Easy", "Flowers in 50–60 days", "Airy, daisy-like flowers that self-seed.", "Poor soil gives more flowers."),
    ("Flowers", "Balsam (Gul mehendi)", ["Summer", "Monsoon"], "Full sun to partial", "Small", "Easy", "Flowers in 40–50 days", "Old-fashioned monsoon flowers in pink, red and white.", "Sow straight in the pot; it grows fast."),
    ("Flowers", "Celosia (Cockscomb)", ["Summer", "Monsoon"], "Full sun", "Small", "Easy", "Flowers in 50–60 days", "Velvety, flame-like flowers that last for weeks.", "Let the soil dry a little between waterings."),
    ("Flowers", "Gaillardia (Blanket flower)", ["Winter", "Summer"], "Full sun", "Medium", "Easy", "Flowers in 60–70 days", "Red-and-yellow daisies that love heat and dry spells.", "Hardly needs feeding; too much food means fewer flowers."),
    ("Flowers", "Nasturtium", ["Winter"], "Full sun to partial", "Small", "Easy", "Flowers in 45–60 days", "Bright trailing flowers you can eat in salads.", "Poor soil gives more flowers and fewer leaves."),
    ("Flowers", "Pansy", ["Winter"], "Partial sun", "Small", "Moderate", "Flowers in 70–90 days", "Little faces in every colour for the cool season.", "Start from nursery seedlings for an easy win."),
    ("Flowers", "Dahlia", ["Winter"], "Full sun", "Large", "Moderate", "Flowers in about 90 days", "Big, showy blooms that steal winter shows.", "Stake tall varieties; pinch for more buds."),
    ("Flowers", "Ixora (Rugmini)", ["Any time"], "Full sun to partial", "Medium", "Easy", "Flowers most of the year", "Round clusters of red, orange or pink flowers.", "Feed lightly every month in summer."),
    ("Flowers", "Desert rose (Adenium)", ["Any time"], "Full sun", "Medium", "Easy", "Flowers in summer", "A chunky-stemmed plant with rose-like flowers.", "Water sparingly; it hates wet feet."),
    ("Flowers", "Tuberose (Rajnigandha)", ["Summer"], "Full sun", "Medium", "Easy", "Flowers in 90–120 days", "Tall stems of deeply fragrant white flowers.", "Plant the bulbs about 5 cm deep."),
    ("Flowers", "Night jasmine (Raat ki rani)", ["Monsoon"], "Full sun to partial", "Large", "Easy", "Flowers in a year", "Tiny flowers that fill the night air with scent.", "Prune after flowering to keep it tidy."),
    ("Houseplants", "Money plant (Pothos)", ["Any time"], "Low to bright indirect", "Small", "Easy", "Settles in 2–3 weeks", "The classic Indian houseplant: grows in water or soil.", "Root a cutting in a bottle of water."),
    ("Houseplants", "Snake plant", ["Any time"], "Low to bright indirect", "Medium", "Easy", "Slow and steady", "Nearly indestructible upright leaves.", "Water only when completely dry."),
    ("Houseplants", "ZZ plant", ["Any time"], "Low light", "Medium", "Easy", "Slow and steady", "Glossy leaves that handle neglect.", "Water every few weeks."),
    ("Houseplants", "Spider plant", ["Any time"], "Bright indirect", "Small", "Easy", "Babies in a few months", "Arching leaves that make baby plants.", "Pot up the babies to share with friends."),
    ("Houseplants", "Peace lily", ["Any time"], "Low to medium light", "Medium", "Easy", "Flowers in a few months", "White flowers indoors; droops when thirsty.", "Water when it droops; it bounces back."),
    ("Houseplants", "Areca palm", ["Any time"], "Bright indirect", "Large", "Moderate", "Grows steadily", "A feathery indoor palm.", "Keep the soil lightly moist."),
    ("Houseplants", "Rubber plant", ["Any time"], "Bright indirect", "Large", "Easy", "New leaves monthly", "Big, glossy, dark leaves.", "Wipe the leaves to keep them shiny."),
    ("Houseplants", "Syngonium", ["Any time"], "Bright indirect", "Small", "Easy", "New leaves monthly", "Arrow-shaped leaves in pinks and greens.", "Grows easily from cuttings."),
    ("Houseplants", "Aglaonema (Chinese evergreen)", ["Any time"], "Low to medium light", "Medium", "Easy", "Slow and steady", "Patterned leaves for darker corners.", "Keep it away from cold drafts."),
    ("Houseplants", "Lucky bamboo", ["Any time"], "Low to medium light", "Vase of water", "Easy", "Grows in water", "Grows in a vase of water and pebbles.", "Change the water every week or two."),
    ("Succulents & Cacti", "Aloe vera", ["Any time"], "Bright light", "Medium", "Easy", "Pups in a few months", "Soothing gel and endless baby plants.", "Water sparingly; let it dry out."),
    ("Succulents & Cacti", "Jade plant", ["Any time"], "Bright light", "Small", "Easy", "Slow and steady", "A chunky little tree, said to bring luck.", "Grows from a single leaf or cutting."),
    ("Succulents & Cacti", "Echeveria", ["Any time"], "Bright light", "Small", "Moderate", "Slow and steady", "Rose-shaped succulents in soft colours.", "Water at the soil, not into the rosette."),
    ("Succulents & Cacti", "Haworthia", ["Any time"], "Bright indirect", "Small", "Easy", "Slow and steady", "Small, striped and happy indoors.", "Handles less light than most succulents."),
    ("Succulents & Cacti", "Kalanchoe", ["Any time"], "Bright light", "Small", "Easy", "Flowers in winter", "A succulent with clusters of bright flowers.", "Pinch spent flowers for repeat blooms."),
    ("Succulents & Cacti", "Bunny ears cactus (Opuntia)", ["Any time"], "Full sun", "Small", "Easy", "Slow and steady", "Paddle-shaped pads, easy from a cutting.", "Handle with care: tiny spines."),
    ("Fruit", "Lemon (Nimbu)", ["Monsoon", "Any time"], "Full sun", "Large", "Moderate", "Fruit in 1–2 years", "Fragrant flowers and your own lemons.", "Start from a nursery sapling, not a seed."),
    ("Fruit", "Papaya", ["Summer", "Monsoon"], "Full sun", "Large or ground", "Easy", "Fruit in 8–10 months", "Grows fast from seed.", "Plant a few; some plants won't fruit."),
    ("Fruit", "Strawberry", ["Winter"], "Full sun", "Medium", "Moderate", "Fruit in 2–3 months", "Sweet winter berries in a pot or hanging basket.", "Grows best in the cool season."),
    ("Fruit", "Guava (Amrood)", ["Monsoon"], "Full sun", "Large or ground", "Easy", "Fruit in 2–3 years", "A hardy fruit tree that suits containers too.", "Choose a dwarf variety for pots."),
    ("Fruit", "Pomegranate (Anaar)", ["Monsoon"], "Full sun", "Large", "Moderate", "Fruit in 2–3 years", "Orange-red flowers and jewel-like fruit.", "Loves sun and little water."),
    ("Trees", "Neem", ["Monsoon"], "Full sun", "In the ground", "Easy", "Shade in a few years", "A hardy, much-loved native tree.", "Plant during the monsoon for easy rooting."),
    ("Trees", "Moringa (Drumstick)", ["Monsoon"], "Full sun", "Large or ground", "Easy", "Leaves in months, pods in a year", "Fast-growing with nutritious leaves and pods.", "Grows from a thick cutting."),
    ("Trees", "Jamun", ["Monsoon"], "Full sun", "In the ground", "Easy", "Fruit in a few years", "A native shade tree with purple summer fruit.", "Give it space to spread."),
    ("Trees", "Gulmohar", ["Monsoon"], "Full sun", "In the ground", "Easy", "Flowers in a few years", "Fiery red-orange summer flowers.", "Plant away from walls; roots spread."),
    ("Trees", "Champa (Frangipani)", ["Summer", "Monsoon"], "Full sun", "Large or ground", "Easy", "Flowers in 1–2 years", "Fragrant temple flowers on a small tree.", "Grows from a cutting dried for a week."),
]

# ------------------------------------------------------------------ Skills
# group, name (action), about, steps
SKILLS = [
    ("Basics", "Sow seeds in a tray", "Start seeds in a shallow tray before moving them to pots.", ["Fill a tray with fine, moist soil.", "Sow seeds about twice as deep as their size.", "Keep it moist and in light until they sprout."]),
    ("Basics", "Transplant a seedling", "Move a young plant to its own pot without shocking it.", ["Water the seedling first.", "Lift it with its root ball intact.", "Plant at the same depth and water gently."]),
    ("Basics", "Pot a plant properly", "The right pot is half the battle.", ["Pick a pot with drainage holes.", "Add soil, set the plant, and fill around it.", "Leave space at the top for watering."]),
    ("Basics", "Mix your own potting soil", "A simple mix of garden soil, compost and cocopeat.", ["Mix roughly equal parts soil, compost and cocopeat.", "Add a handful of sand for succulents.", "Moisten before using."]),
    ("Basics", "Water the right way", "Most plants die from too much water, not too little.", ["Push a finger an inch into the soil.", "Water only if it feels dry.", "Water deeply until it drains out the bottom."]),
    ("Basics", "Read the light in your space", "Know which spots get full sun, part sun or shade.", ["Note where sunlight falls at 9 am, 1 pm and 4 pm.", "Count the hours of direct sun.", "Match plants to each spot."]),
    ("Care", "Make kitchen compost", "Turn peels and leaves into rich soil.", ["Layer vegetable scraps with dry leaves.", "Turn it weekly and keep it damp.", "Use it when it's dark and crumbly."]),
    ("Care", "Mulch your pots", "A layer on top keeps soil moist and cool.", ["Spread dry leaves or coco husk on the soil.", "Keep it a little away from the stem.", "Top up as it breaks down."]),
    ("Care", "Pinch and prune", "Cutting tips makes plants bushier.", ["Pinch the top pair of leaves on basil or tulsi.", "Cut just above a leaf node.", "Use clean scissors."]),
    ("Care", "Deadhead flowers", "Remove faded flowers for more blooms.", ["Snip spent flowers below the bloom.", "Do it weekly in the flowering season.", "Watch new buds appear."]),
    ("Care", "Feed with compost or vermicompost", "Plants in pots need regular food.", ["Add a handful of compost every few weeks.", "Mix it into the top layer of soil.", "Water well afterwards."]),
    ("Care", "Spray neem against pests", "A gentle natural way to keep pests away.", ["Mix a little neem oil and soap in water.", "Spray under the leaves in the evening.", "Repeat weekly if pests return."]),
    ("Care", "Repot a root-bound plant", "Give a cramped plant a bigger home.", ["Look for roots coming out of the bottom.", "Move it to a pot one size bigger.", "Loosen the roots gently before replanting."]),
    ("Care", "Support a climber", "Help gourds, beans and money plants climb.", ["Add sticks, a net or a string up a railing.", "Guide the tendrils onto it.", "Tie gently with soft string if needed."]),
    ("Care", "Make a self-watering bottle", "Reuse a plastic bottle to water slowly.", ["Poke small holes in a bottle cap.", "Fill it and push it upside down into the soil.", "Refill as it empties."]),
    ("Grow more", "Take a stem cutting", "Make a new plant from a piece of the old one.", ["Cut 10–15 cm below a leaf node.", "Remove the lower leaves.", "Root it in water or moist soil."]),
    ("Grow more", "Grow from kitchen scraps", "Regrow spring onion, ginger or mint from the kitchen.", ["Keep the root end of a spring onion.", "Stand it in water for a few days.", "Plant it once new shoots appear."]),
    ("Grow more", "Divide a plant", "Split an overgrown plant into two.", ["Take the plant out of its pot.", "Gently pull or cut the clump apart.", "Pot each part separately."]),
    ("Grow more", "Save your own seeds", "Keep seeds from this season for the next.", ["Let a healthy fruit or flower fully ripen.", "Dry the seeds in the shade.", "Store them in a labelled paper packet."]),
    ("Grow more", "Make seed balls", "Clay-and-compost balls to scatter seeds.", ["Mix clay, compost and a few seeds with a little water.", "Roll into small balls and dry them.", "Toss them on bare ground before the monsoon."]),
    ("Advanced", "Try air layering", "Root a branch while it's still on the plant.", ["Remove a ring of bark on a healthy branch.", "Wrap it in moist moss and plastic.", "Cut and pot it once roots show."]),
    ("Advanced", "Hand-pollinate flowers", "Help gourds and squash set fruit on a terrace.", ["Find a male flower (no tiny fruit behind it).", "Brush its pollen onto a female flower.", "Do it in the morning."]),
    ("Advanced", "Start vermicomposting", "Let earthworms make rich compost.", ["Set up a bin with moist bedding and worms.", "Feed vegetable scraps, not dairy or oil.", "Harvest the compost after a few months."]),
    ("Advanced", "Collect rainwater for the garden", "Save monsoon rain for drier days.", ["Place a bucket or drum under a downpipe.", "Cover it to keep mosquitoes out.", "Use it to water your plants."]),
    ("Advanced", "Shape a bonsai", "Prune and wire a small tree into shape.", ["Choose a branch structure you like.", "Prune unwanted branches gradually.", "Wire lightly and remove before it cuts in."]),
]

# ------------------------------------------------------------------ Visits
# state id, name, city, best time, about
VISITS = [
    ("karnataka", "Lalbagh Botanical Garden", "Bengaluru", "Flower shows around 26 January and 15 August", "A grand old garden known for its glasshouse flower shows."),
    ("karnataka", "Brindavan Gardens", "Mysuru", "Evenings, for the musical fountain", "Terraced gardens below the KRS dam."),
    ("west_bengal", "Indian Botanic Garden", "Howrah, Kolkata", "October to March", "India's oldest botanic garden, home to the Great Banyan."),
    ("west_bengal", "Lloyd's Botanical Garden", "Darjeeling", "March to May", "A hillside garden of orchids and Himalayan plants."),
    ("tamil_nadu", "Government Botanical Garden, Ooty", "Ooty", "April to June", "Terraced gardens in the Nilgiri hills."),
    ("tamil_nadu", "Sim's Park", "Coonoor", "April to June", "A sloping valley garden full of rare trees."),
    ("delhi", "Amrit Udyan, Rashtrapati Bhavan", "New Delhi", "February to March, when it opens to visitors", "Formal gardens famous for their tulips and roses."),
    ("delhi", "Lodhi Garden", "New Delhi", "October to March", "A green park around 15th-century tombs."),
    ("delhi", "Sunder Nursery", "New Delhi", "October to March", "A restored heritage park with a historic nursery."),
    ("jammu_kashmir", "Indira Gandhi Memorial Tulip Garden", "Srinagar", "Late March to April", "Asia's largest tulip garden, blooming each spring."),
    ("jammu_kashmir", "Shalimar Bagh", "Srinagar", "April to October", "A Mughal garden of terraces and water channels."),
    ("uttarakhand", "Valley of Flowers", "Chamoli", "July to September", "A high Himalayan valley carpeted with wildflowers in the monsoon."),
    ("maharashtra", "Kaas Plateau", "Satara", "August to October", "A plateau that bursts into tiny wildflowers after the rains."),
    ("maharashtra", "Hanging Gardens", "Mumbai", "October to March", "Terraced gardens with topiary animals on Malabar Hill."),
    ("chandigarh", "Rock Garden", "Chandigarh", "October to March", "A sculpture garden built from recycled waste."),
    ("haryana", "Pinjore Gardens (Yadavindra Gardens)", "Pinjore", "October to March", "A Mughal-style terraced garden near Chandigarh."),
]


def item(prefix, challenge, name, category, group, about, steps, tags, keywords, meta):
    return {
        "id": prefix,
        "challenge_id": challenge,
        "name": name,
        "category": category,
        "filter_group": group,
        "difficulty": "beginner",
        "about": about,
        "howToSteps": steps,
        "tags": tags,
        "keywords": keywords,
        "metadata": meta,
    }


def ways():
    return [
        item(f"way_{slug(style)}", "explore_garden_ways", name, style, "Ways to garden", about, steps,
             ["garden", "way"], [style.lower(), "gardening"],
             {"Space": space, "Light": light, "Good plants": plants, "First win": win})
        for name, style, about, space, light, plants, win, steps in WAYS
    ]


# Which light answers suit a plant: sun (4+ hours), some (part sun or bright
# shade), low (indoors, away from windows).
LIGHT_LEVELS = {
    "Full sun": ["sun"],
    "Full sun to partial": ["sun", "some"],
    "Partial sun": ["sun", "some"],
    "Bright light": ["sun", "some"],
    "Bright indirect": ["some"],
    "Low to medium light": ["low", "some"],
    "Low to bright indirect": ["low", "some"],
    "Low light": ["low", "some"],
}

POT_SPACES = {
    "Small": ["windowsill", "balcony", "terrace", "ground"],
    "Shallow": ["windowsill", "balcony", "terrace", "ground"],
    "Wide, shallow": ["windowsill", "balcony", "terrace", "ground"],
    "Vase of water": ["windowsill"],
    "Medium": ["balcony", "terrace", "ground"],
    "Deep": ["balcony", "terrace", "ground"],
    "Wide": ["balcony", "terrace", "ground"],
    "Large": ["balcony", "terrace", "ground"],
    "Large (15+ litres)": ["balcony", "terrace", "ground"],
    "Large or ground": ["terrace", "ground"],
    "In the ground": ["ground"],
}

INDOOR_LIGHT = {"Bright indirect", "Bright light", "Low to medium light", "Low to bright indirect", "Low light"}

LOW_CARE = {
    "Periwinkle (Sadabahar)", "Portulaca (9 o'clock flower)", "Bougainvillea", "Lemongrass",
    "Curry leaf (Kadi patta)", "Gaillardia (Blanket flower)", "Desert rose (Adenium)", "Ixora (Rugmini)",
    "Neem", "Moringa (Drumstick)", "Mint (Pudina)",
}


def spaces_for(pot, light):
    spaces = list(POT_SPACES[pot])
    if light in INDOOR_LIGHT:
        spaces.append("indoors")
    return spaces


def plants():
    out = []
    for group, name, seasons, light, pot, ease, first, about, tip in PLANTS:
        for season in seasons:
            assert season in SOW_MONTHS, (name, season)
        months = sorted({m for s in seasons for m in SOW_MONTHS[s]})
        sow = "Any time" if "Any time" in seasons else " · ".join(seasons)
        out.append({
            **item(f"plant_{slug(name.split(' (')[0])}", "explore_garden_plants", name,
                   group, group, about,
                   [f"Best started: {sow.lower()} (approximate; check locally).",
                    f"Give it {light.lower()} and a {pot.lower()} pot.", tip],
                   ["garden", "plant", slug(group)], [name.lower(), group.lower()],
                   {"Plant in": sow, "Light": light, "Pot": pot, "Ease": ease, "First reward": first}),
            "sow_months": months,
            # Tags for the "Start gardening" matcher.
            "light_levels": LIGHT_LEVELS[light],
            "spaces": spaces_for(pot, light),
            "beginner": ease == "Easy",
            "low_care": ease == "Easy" and (group in ("Succulents & Cacti", "Houseplants") or name in LOW_CARE),
        })
    return out


def skills():
    return [
        item(f"skill_{slug(name)}", "explore_garden_skills", name, group, group, about, steps,
             ["garden", "skill"], [name.lower(), "gardening skill"], {"Level": group})
        for group, name, about, steps in SKILLS
    ]


def visits():
    out = []
    for state, name, city, best, about in VISITS:
        out.append(item(
            f"visit_{state}_{slug(name)}", "explore_garden_visits", f"Visit {name}", name,
            REGION[state], about,
            ["Check opening days and timings before you go.", f"Best time: {best}.",
             "Note three plants or flowers you've never seen before."],
            ["garden", "visit", state], [name.lower(), city.lower(), "garden"],
            {"Where": city, "Best time": best, "India Passport": "Visiting stamps this state"}))
    return out


REGION = {
    "karnataka": "South India", "tamil_nadu": "South India",
    "west_bengal": "East India",
    "delhi": "North India", "jammu_kashmir": "North India", "uttarakhand": "North India",
    "chandigarh": "North India", "haryana": "North India",
    "maharashtra": "West India",
}


if __name__ == "__main__":
    for filename, cid, items in [
        ("garden_ways.json", "explore_garden_ways", ways()),
        ("garden_plants.json", "explore_garden_plants", plants()),
        ("garden_skills.json", "explore_garden_skills", skills()),
        ("garden_visits.json", "explore_garden_visits", visits()),
    ]:
        ids = [i["id"] for i in items]
        names = [i["name"] for i in items]
        assert len(ids) == len(set(ids)), filename
        assert len(names) == len(set(names)), filename
        (OUT / filename).write_text(
            json.dumps({"challenge_id": cid, "version": 1, "items": items}, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8")
        print(filename, len(items))
