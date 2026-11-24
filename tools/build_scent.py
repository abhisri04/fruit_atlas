"""Generate the UPLYFA scent catalogues.

Run from the repository root:  python tools/build_scent.py

Writes four files to assets/data/:
  scent_families.json   the scent families, each explained with famous examples
  famous_perfumes.json  well-known perfumes, grouped by family (maker is a detail)
  scent_notes.json      raw ingredients to smell
  indian_attars.json    traditional Indian attars

Scent comes first: perfumes are grouped by family, never by brand. No prices
or costs anywhere; everything can be experienced at a tester, from a sample or
with ingredients from home and the market. Descriptions are original
summaries. Families follow a friendly blend of the Michael Edwards wheel and
the French classification (citrus, floral, amber, chypre, woody, fougère,
leather), plus gourmand and oud.
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets/data"

FAMILIES = [
    # id, label, plain words, key notes, how it feels, attars
    ("fresh", "Fresh", "Clean, sparkling and airy: citrus peel, sea breeze, crisp herbs.",
     "Bergamot, lemon, sea notes, green tea, rosemary", "Bright and energising; great in heat", "Kewra, Ruh Khus"),
    ("floral", "Floral", "Flowers: a single bloom, a whole bouquet, or rich white flowers.",
     "Rose, jasmine, tuberose, iris, orange blossom", "Romantic, soft or lush", "Ruh Gulab, Motia, Chameli"),
    ("amber", "Amber (Oriental)", "Warm and glowing: resins, spices and vanilla.",
     "Vanilla, benzoin, labdanum, cinnamon, clove", "Cosy, sensual, evening-friendly", "Shamama, Hina"),
    ("woody", "Woody", "Woods and roots: creamy sandalwood, dry cedar, earthy vetiver.",
     "Sandalwood, cedar, vetiver, patchouli", "Calm, grounded, quietly confident", "Chandan, Ruh Khus"),
    ("chypre", "Chypre", "A classic accord: bright citrus over a mossy, woody base.",
     "Bergamot, oakmoss, labdanum, patchouli", "Elegant, polished, a little vintage", ""),
    ("fougere", "Fougère", "The barbershop classic: lavender, herbs and soft moss.",
     "Lavender, geranium, oakmoss, coumarin", "Fresh-clean and familiar", ""),
    ("gourmand", "Gourmand", "Good enough to eat: dessert-like and sweet.",
     "Vanilla, caramel, praline, chocolate, coffee", "Playful, comforting, sweet", "Kesar"),
    ("leather", "Leather & Smoke", "Smoky, leathery and dark, like old books and campfires.",
     "Leather, birch tar, smoke, tobacco", "Bold, moody, unusual", ""),
    ("oud", "Oud & Attar", "Rich, resinous traditions of India and the Middle East.",
     "Oud (agarwood), rose, saffron, sandalwood", "Deep, long-lasting, ceremonial", "Oud, Shamama, Ruh Gulab, Mitti"),
]
FAMILY_LABEL = {f[0]: f[1] for f in FAMILIES}

# family, name, maker, key notes, one-line description (original wording)
PERFUMES = [
    ("fresh", "CK One", "Calvin Klein", "Bergamot, green tea, musk", "A clean, citrusy scent famous for being made to share by anyone."),
    ("fresh", "Acqua di Giò", "Giorgio Armani", "Sea notes, citrus, jasmine", "The scent of the Mediterranean: salty air and sunny citrus."),
    ("fresh", "Light Blue", "Dolce & Gabbana", "Sicilian lemon, apple, cedar", "A crisp, sunny summer classic."),
    ("fresh", "4711 Eau de Cologne", "4711", "Lemon, bergamot, neroli", "One of the oldest colognes still made, light and refreshing."),
    ("fresh", "Eau Sauvage", "Dior", "Lemon, basil, vetiver", "A breezy citrus-herb classic."),
    ("fresh", "L'Eau d'Issey", "Issey Miyake", "Watery notes, lotus, melon", "A pioneer of airy, watery floral freshness."),
    ("fresh", "Neroli Portofino", "Tom Ford", "Neroli, bergamot, lemon", "Bright orange blossom and citrus, like a seaside holiday."),
    ("fresh", "Wood Sage & Sea Salt", "Jo Malone London", "Sea salt, sage, ambrette", "A windswept, mineral, beachy freshness."),
    ("floral", "Chanel No. 5", "Chanel", "Aldehydes, jasmine, rose", "Perhaps the most famous perfume ever: a sparkling floral bouquet."),
    ("floral", "J'adore", "Dior", "Ylang-ylang, rose, jasmine", "A golden, luminous bouquet of flowers."),
    ("floral", "Daisy", "Marc Jacobs", "Strawberry, violet, jasmine", "Light, fresh and cheerful."),
    ("floral", "Fracas", "Robert Piguet", "Tuberose, orange blossom, jasmine", "The classic rich white-flower tuberose perfume."),
    ("floral", "Miss Dior", "Dior", "Rose, peony, musk", "A soft, romantic rose."),
    ("floral", "English Pear & Freesia", "Jo Malone London", "Pear, freesia, patchouli", "Fresh-cut fruit and soft white flowers."),
    ("floral", "Do Son", "Diptyque", "Tuberose, orange blossom, rose", "A lighter, airy take on tuberose by the sea."),
    ("floral", "Un Jardin sur le Nil", "Hermès", "Green mango, lotus, grapefruit", "A green, watery garden with a fruity twist."),
    ("floral", "Infusion d'Iris", "Prada", "Iris, orange blossom, cedar", "Clean, powdery iris: soft and elegant."),
    ("amber", "Shalimar", "Guerlain", "Bergamot, iris, vanilla", "A legendary amber: citrus melting into vanilla and resins."),
    ("amber", "Opium", "Yves Saint Laurent", "Spices, myrrh, vanilla", "A bold, spicy, resinous amber."),
    ("amber", "Obsession", "Calvin Klein", "Spices, amber, vanilla", "A warm, spicy amber classic."),
    ("amber", "Spicebomb", "Viktor&Rolf", "Chilli, cinnamon, tobacco", "Warm spices packed into a grenade-shaped bottle."),
    ("amber", "Poison", "Dior", "Plum, tuberose, amber", "A dramatic, fruity, spicy amber."),
    ("amber", "Tobacco Vanille", "Tom Ford", "Tobacco leaf, vanilla, tonka", "Sweet tobacco and vanilla, like a cosy library."),
    ("amber", "Habit Rouge", "Guerlain", "Citrus, rose, vanilla", "A refined, powdery amber with a citrus opening."),
    ("amber", "Baccarat Rouge 540", "Maison Francis Kurkdjian", "Saffron, ambergris notes, cedar", "An airy, glowing amber-woody scent that's become a modern icon."),
    ("woody", "Terre d'Hermès", "Hermès", "Orange, flint, vetiver", "Earthy citrus and woods, like warm soil and stone."),
    ("woody", "Santal 33", "Le Labo", "Sandalwood, cardamom, leather", "Creamy sandalwood with a leathery edge."),
    ("woody", "Bleu de Chanel", "Chanel", "Grapefruit, incense, cedar", "Fresh citrus over smooth, smoky woods."),
    ("woody", "Tam Dao", "Diptyque", "Sandalwood, cypress, cedar", "A quiet, creamy sandalwood."),
    ("woody", "Vetiver", "Guerlain", "Vetiver, tobacco, citrus", "A classic study of earthy vetiver root."),
    ("woody", "Encre Noire", "Lalique", "Vetiver, cypress, musk", "Dark, inky vetiver."),
    ("woody", "Molecule 01", "Escentric Molecules", "Iso E Super", "A single woody aroma molecule that smells different on everyone."),
    ("woody", "Philosykos", "Diptyque", "Fig leaf, fig wood, coconut", "Green fig leaves and creamy fig wood."),
    ("woody", "Dior Homme", "Dior", "Iris, cacao, vetiver", "Soft, powdery iris over woods."),
    ("chypre", "Mitsouko", "Guerlain", "Peach, oakmoss, spices", "One of the great classic chypres: peachy, mossy and mysterious."),
    ("chypre", "Aromatics Elixir", "Clinique", "Herbs, rose, patchouli", "An intense, herbal, mossy chypre."),
    ("chypre", "Coco Mademoiselle", "Chanel", "Orange, rose, patchouli", "A modern, fresh floral chypre."),
    ("chypre", "Aventus", "Creed", "Pineapple, birch, musk", "A fruity, smoky modern chypre."),
    ("chypre", "Femme", "Rochas", "Plum, spices, oakmoss", "A rich, fruity vintage chypre."),
    ("chypre", "Pour Monsieur", "Chanel", "Lemon, neroli, oakmoss", "A crisp, understated citrus chypre."),
    ("fougere", "Fougère Royale", "Houbigant", "Lavender, coumarin, oakmoss", "The perfume that gave the fougère family its name."),
    ("fougere", "Cool Water", "Davidoff", "Mint, lavender, sea notes", "A fresh aquatic fougère that defined an era."),
    ("fougere", "Azzaro Pour Homme", "Azzaro", "Lavender, anise, oakmoss", "A classic aromatic barbershop fougère."),
    ("fougere", "Sauvage", "Dior", "Bergamot, pepper, ambroxan", "A fresh, peppery modern fougère."),
    ("fougere", "Drakkar Noir", "Guy Laroche", "Lavender, rosemary, fir", "A dark, herbal fougère classic."),
    ("fougere", "Le Male", "Jean Paul Gaultier", "Lavender, mint, vanilla", "A sweet, creamy lavender fougère."),
    ("gourmand", "Angel", "Mugler", "Praline, patchouli, vanilla", "The perfume that started the gourmand family."),
    ("gourmand", "La Vie Est Belle", "Lancôme", "Iris, praline, vanilla", "Sweet, joyful praline and iris."),
    ("gourmand", "Black Opium", "Yves Saint Laurent", "Coffee, vanilla, white flowers", "Coffee and vanilla with white flowers."),
    ("gourmand", "Flowerbomb", "Viktor&Rolf", "Jasmine, rose, patchouli", "A sweet explosion of flowers."),
    ("gourmand", "Candy", "Prada", "Caramel, benzoin, musk", "Smooth caramel and soft resins."),
    ("leather", "Cuir de Russie", "Chanel", "Birch tar, iris, leather", "Elegant, smoky leather."),
    ("leather", "Tuscan Leather", "Tom Ford", "Raspberry, saffron, leather", "Rich, fruity, suede-like leather."),
    ("leather", "Bandit", "Robert Piguet", "Leather, galbanum, oakmoss", "A bold, green, leathery classic."),
    ("leather", "Fahrenheit", "Dior", "Violet leaf, leather, nutmeg", "An unusual violet-and-leather scent."),
    ("leather", "Knize Ten", "Knize", "Leather, citrus, spices", "One of the classic leather fragrances."),
    ("oud", "Oud Wood", "Tom Ford", "Oud, sandalwood, cardamom", "A smooth, approachable introduction to oud."),
    ("oud", "Oud Satin Mood", "Maison Francis Kurkdjian", "Oud, rose, vanilla", "Velvety oud wrapped in rose and vanilla."),
]

# group, name, where to find it, families, description
NOTES = [
    ("Flowers", "Rose", "Flower market or garden", "Floral, Oud & Attar", "The queen of perfume flowers: fresh, honeyed, sometimes spicy."),
    ("Flowers", "Jasmine (Mogra)", "Flower sellers, temple garlands", "Floral", "Heady, sweet and a little animalic, especially at night."),
    ("Flowers", "Tuberose (Rajnigandha)", "Flower market", "Floral", "Creamy, buttery and intense."),
    ("Flowers", "Orange blossom", "Orange flower water in the kitchen", "Floral, Fresh", "Sweet, honeyed, clean white flower."),
    ("Flowers", "Lavender", "Dried lavender, herb shops", "Fougère, Fresh", "Herbal, clean and calming."),
    ("Flowers", "Champa (Frangipani)", "Temple trees, flower sellers", "Floral", "Creamy, fruity and tropical."),
    ("Flowers", "Ylang-ylang", "Essential oil shops", "Floral", "Rich, banana-like, exotic flower."),
    ("Flowers", "Iris", "Orris root powder, perfume counters", "Floral, Woody", "Powdery, earthy, like soft lipstick."),
    ("Flowers", "Marigold (Genda)", "Garlands, flower market", "Floral", "Green, herbal and slightly bitter."),
    ("Woods", "Sandalwood (Chandan)", "Temple paste, incense, soap", "Woody, Oud & Attar", "Creamy, milky, soft wood."),
    ("Woods", "Vetiver (Khus)", "Khus mats and coolers, khus syrup", "Woody, Fresh", "Earthy, smoky, rooty and cooling."),
    ("Woods", "Cedar", "Pencil shavings, wooden chests", "Woody", "Dry, clean, pencil-like wood."),
    ("Woods", "Patchouli", "Essential oil shops, incense", "Woody, Chypre, Gourmand", "Dark, earthy, damp-forest smell."),
    ("Woods", "Oud (Agarwood)", "Attar shops, bakhoor", "Oud & Attar", "Deep, resinous, animalic wood. Prized and complex."),
    ("Spices", "Cardamom (Elaichi)", "Kitchen", "Amber, Woody", "Fresh, cool and sweetly spicy."),
    ("Spices", "Saffron (Kesar)", "Kitchen", "Amber, Leather, Oud & Attar", "Honeyed, leathery, hay-like."),
    ("Spices", "Cinnamon (Dalchini)", "Kitchen", "Amber, Gourmand", "Warm, sweet and woody spice."),
    ("Spices", "Clove (Laung)", "Kitchen", "Amber", "Sharp, warm, a little medicinal."),
    ("Spices", "Black pepper", "Kitchen", "Fougère, Woody", "Dry, zingy, fresh spice."),
    ("Spices", "Nutmeg (Jaiphal)", "Kitchen", "Amber, Leather", "Warm, sweet and woody."),
    ("Citrus", "Bergamot", "Earl Grey tea", "Fresh, Chypre", "The classic perfume citrus: bright with a floral edge."),
    ("Citrus", "Lemon (Nimbu)", "Kitchen", "Fresh", "Zesty and clean. Smell the peel, not the juice."),
    ("Citrus", "Sweet orange", "Fruit seller", "Fresh", "Juicy, sunny and sweet."),
    ("Citrus", "Grapefruit", "Fruit seller", "Fresh, Woody", "Bitter-sweet, sparkling citrus."),
    ("Citrus", "Lime (Kaffir lime)", "Kitchen, Thai groceries", "Fresh", "Sharp, green and aromatic."),
    ("Resins & Balms", "Frankincense (Loban)", "Temple smoke, puja shops", "Amber, Woody", "Clean, peppery, church-like smoke."),
    ("Resins & Balms", "Benzoin", "Puja shops", "Amber, Gourmand", "Sweet, vanilla-like resin."),
    ("Resins & Balms", "Myrrh", "Ayurvedic and puja shops", "Amber", "Bitter, earthy, ancient resin."),
    ("Resins & Balms", "Labdanum", "Perfume counters (amber scents)", "Amber, Chypre", "Leathery, warm, sticky resin."),
    ("Edible", "Vanilla", "Vanilla pod or essence", "Gourmand, Amber", "Creamy, sweet, comforting."),
    ("Edible", "Tonka bean", "Baking shops", "Gourmand, Fougère", "Almond, hay and vanilla."),
    ("Edible", "Cocoa", "Cocoa powder", "Gourmand", "Dark, bitter-sweet chocolate."),
    ("Edible", "Coffee", "Fresh coffee beans", "Gourmand", "Roasted, bitter, energising."),
    ("Edible", "Honey", "Kitchen", "Gourmand, Floral", "Sweet, waxy, a little animalic."),
    ("Edible", "Almond", "Kitchen", "Gourmand", "Sweet, nutty, marzipan-like."),
    ("Green & Earthy", "Mint (Pudina)", "Kitchen, garden", "Fresh, Fougère", "Cool, green and sharp."),
    ("Green & Earthy", "Tulsi (Holy basil)", "Home or temple plant", "Fresh", "Clove-like, peppery herb."),
    ("Green & Earthy", "Fig leaf", "Fig tree", "Woody, Fresh", "Green, milky and coconutty."),
    ("Green & Earthy", "Green tea", "Kitchen", "Fresh", "Soft, green and calming."),
    ("Green & Earthy", "Petrichor (Mitti)", "First rain on dry earth", "Oud & Attar, Woody", "The smell of rain on dry soil."),
    ("Green & Earthy", "Oakmoss", "Perfume counters (chypres)", "Chypre, Fougère", "Damp, forest-floor moss."),
    ("Musk & Clean", "Musk", "Perfume counters, laundry and soaps", "Fresh, Floral", "Soft, clean, skin-like warmth."),
]

# name, season, description, how it is made/used
ATTARS = [
    ("Mitti", "Monsoon", "The smell of the first rain on dry earth, captured from baked clay.", "Baked clay distilled into sandalwood oil in Kannauj."),
    ("Ruh Gulab", "All year", "Pure rose attar, linked with weddings and hospitality.", "Distilled from fresh damask roses."),
    ("Ruh Khus", "Summer", "Green, earthy, cooling vetiver.", "Distilled from wild vetiver roots."),
    ("Kewra", "Summer", "Sweet, green and cool. Also used to flavour food.", "From fragrant pandanus flowers."),
    ("Shamama", "Winter", "A dense, warming blend of many herbs, spices and resins, aged for months.", "Many botanicals distilled and aged together."),
    ("Motia (Bela)", "Summer", "Fresh, sweet jasmine.", "From Arabian jasmine flowers."),
    ("Chameli", "Summer", "Classic, sweet jasmine.", "From jasmine flowers."),
    ("Kesar (Zafran)", "Winter", "Warm, honeyed saffron.", "Saffron in a sandalwood base."),
    ("Hina", "Winter", "Warm, earthy, spicy and slightly smoky blend.", "A traditional blend including henna flowers and spices."),
    ("Majmua", "Summer", "A soft, refreshing blend.", "A traditional blend that includes kewra and vetiver notes."),
    ("Chandan", "All year", "Creamy, soothing sandalwood: the base of many attars.", "Sandalwood oil."),
    ("Kadam", "Monsoon", "Sweet, fresh monsoon flower.", "From kadam tree flowers."),
    ("Champa", "Summer", "Creamy, fruity, temple-flower scent.", "From champak flowers."),
    ("Oud", "Winter", "Deep, resinous, prized agarwood.", "Oil distilled from resin-rich agarwood."),
]


def slug(text):
    return "".join(c if c.isalnum() else "_" for c in text.lower()).strip("_").replace("__", "_")


def families():
    examples = {}
    for fam, name, maker, *_ in PERFUMES:
        examples.setdefault(fam, []).append(name)
    items = []
    for fid, label, plain, notes, feel, attars in FAMILIES:
        famous = " · ".join(examples.get(fid, [])[:5])
        meta = {"Smells like": plain, "Key notes": notes, "Feels": feel, "Famous examples": famous}
        if attars:
            meta["Indian attars"] = attars
        items.append({
            "id": f"family_{fid}",
            "challenge_id": "explore_scent_families",
            "name": f"Get to know {label}",
            "category": label,
            "filter_group": "Scent families",
            "difficulty": "beginner",
            "about": f"{plain} Famous examples include {famous}.",
            "howToSteps": [
                f"At a perfume counter, ask to try a {label.lower()} scent, for example {examples.get(fid, ['one of the examples'])[0]}.",
                "Spray a paper strip and smell it now, after 10 minutes and after an hour.",
                "Write down one word for how it makes you feel.",
            ],
            "tags": ["scent", "family", fid],
            "keywords": [label.lower(), "perfume", "fragrance family"],
            "metadata": meta,
        })
    return {"challenge_id": "explore_scent_families", "version": 1, "items": items}


def perfumes():
    items, seen = [], set()
    for fam, name, maker, notes, about in PERFUMES:
        pid = f"perfume_{slug(maker)}_{slug(name)}"
        assert pid not in seen, pid
        seen.add(pid)
        items.append({
            "id": pid,
            "challenge_id": "explore_iconic_perfumes",
            "name": name,
            "category": maker,
            "filter_group": FAMILY_LABEL[fam],
            "difficulty": "beginner",
            "about": about,
            "howToSteps": [
                "Find a tester at a perfume counter, or ask a friend who owns it.",
                "Spray a paper strip first, then your wrist if you like it.",
                f"Notice how it changes: try to pick out {notes.split(', ')[0].lower()}.",
            ],
            "tags": ["scent", "perfume", fam],
            "keywords": [name.lower(), maker.lower(), FAMILY_LABEL[fam].lower()],
            "metadata": {"Family": FAMILY_LABEL[fam], "Key notes": notes, "Made by": maker},
        })
    return {"challenge_id": "explore_iconic_perfumes", "version": 1, "items": items}


def notes():
    items = []
    for group, name, where, fams, about in NOTES:
        items.append({
            "id": f"note_{slug(name)}",
            "challenge_id": "explore_scent_notes",
            "name": f"Smell {name[0].lower()}{name[1:]}",
            "category": name,
            "filter_group": group,
            "difficulty": "beginner",
            "about": about,
            "howToSteps": [
                f"Find it: {where.lower()}.",
                "Smell it slowly, then again after a short break.",
                "Try to describe it in three words.",
            ],
            "tags": ["scent", "note"],
            "keywords": [name.lower(), "note", "ingredient"],
            "metadata": {"Find it": where, "Found in families": fams},
        })
    return {"challenge_id": "explore_scent_notes", "version": 1, "items": items}


def attars():
    items = []
    for name, season, about, made in ATTARS:
        items.append({
            "id": f"attar_{slug(name)}",
            "challenge_id": "explore_indian_attars",
            "name": f"Try {name} attar",
            "category": name,
            "filter_group": season,
            "difficulty": "beginner",
            "about": about,
            "howToSteps": [
                "Visit an attar shop or ask for a sample. Most let you smell first.",
                "Dab a tiny amount on your wrist with the glass stick; attars are oil and very strong.",
                "Smell it again after an hour. Attars change slowly on skin.",
            ],
            "tags": ["scent", "attar", "india"],
            "keywords": [name.lower(), "attar", "ittar", "kannauj"],
            "metadata": {"Traditionally worn": season, "How it's made": made, "Tradition": "Kannauj, Uttar Pradesh and across India"},
        })
    return {"challenge_id": "explore_indian_attars", "version": 1, "items": items}


if __name__ == "__main__":
    for filename, data in [
        ("scent_families.json", families()),
        ("famous_perfumes.json", perfumes()),
        ("scent_notes.json", notes()),
        ("indian_attars.json", attars()),
    ]:
        names = [i["name"] for i in data["items"]]
        assert len(names) == len(set(names)), filename
        (OUT / filename).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(filename, len(data["items"]))
