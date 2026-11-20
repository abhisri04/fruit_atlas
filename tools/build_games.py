"""Generate assets/data/games.json, the UPLYFA games catalogue.

Run from the repository root:  python tools/build_games.py

Card, board, traditional Indian, outdoor and party games people commonly
play. Descriptions are original summaries, not rulebook text. Each game uses
the hobby attribute schema (minus cost: games are not categorised by money)
so the hobby finder and My Hobbies can include it.
"""
import json
from pathlib import Path

CH = "play_great_games"
GROUPS = {
    "card": "Card Games",
    "board": "Board Games",
    "indian": "Traditional Indian Games",
    "outdoor": "Outdoor Games",
    "party": "Party & Indoor Games",
}
WHERE = {"home": "At home", "out": "Outdoors", "local": "In your neighbourhood"}
SETTING = {"home": "indoor", "out": "outdoor", "local": "either"}
LADDERS = {
    "card": ["Learn all the rules", "Win a game", "Teach it to a new player"],
    "board": ["Learn all the rules", "Win a game", "Teach it to a new player"],
    "indian": ["Learn the rules well", "Play with a new group", "Teach it to children"],
    "outdoor": ["Learn the rules well", "Play with a new group", "Organise a game yourself"],
    "party": ["Play at a gathering", "Host a round yourself", "Invent your own twist"],
}
STEPS = {
    "card": "Get a standard deck (or the game's own cards) and a few players.",
    "board": "Borrow, buy or find the game at a board-game café.",
    "indian": "Gather players and any simple materials needed.",
    "outdoor": "Find an open, safe space and enough players.",
    "party": "Gather a group and pick someone to explain the rules.",
}

G = []


def g(slug, group, name, players, minutes, time, where, energy, social, goals,
      about, tip, win=None, ladder=None, tags=""):
    G.append(dict(
        slug=slug, group=group, name=name, players=players, minutes=minutes,
        time=time, where=where, energy=energy, social=social,
        goals=goals.split(), about=about, tip=tip,
        win=win or f"Play a game of {name}",
        ladder=ladder or LADDERS[group], tags=tags.split()))


# ------------------------------------------------------------------ Cards
g("rummy", "card", "Rummy", "2–6", 30, "30 min", "home", "calm", "social", "connect relax",
  "Build sets and runs from your hand of 13 cards. One of India's best-loved family card games.",
  "Learn what counts as a pure sequence first.", ladder=["Learn all the rules", "Declare a winning hand", "Win three games in a row"], tags="india family")
g("twenty_nine", "card", "29 (Twenty-Nine)", "4", 30, "30 min", "home", "calm", "social", "connect learn",
  "A fast partnership trick-taking game played with 32 cards, hugely popular in Bengal, Kerala and beyond.",
  "Remember that jacks and nines are the highest-scoring cards.", tags="india partnership")
g("court_piece", "card", "Court Piece (Rang)", "4", 30, "30 min", "home", "calm", "social", "connect",
  "A team trick-taking game where the chosen trump suit (rang) decides everything. A North Indian favourite.",
  "Pair up across the table with your partner.", tags="india partnership")
g("mendicot", "card", "Mendicot (Mindi)", "4–6", 30, "30 min", "home", "calm", "social", "connect",
  "Win tricks that capture the tens. A classic in Gujarat, Maharashtra and Goa.",
  "Track which tens have already been played.", tags="india partnership")
g("bhabhi", "card", "Bhabhi (Get Away)", "3–8", 20, "20 min", "home", "calm", "social", "connect relax",
  "Get rid of all your cards. Whoever is left holding them is the 'bhabhi'. Loud, quick and family-friendly.",
  "Deal all the cards out evenly.", tags="india family")
g("bluff", "card", "Bluff (Cheat)", "3–8", 20, "20 min", "home", "calm", "social", "connect",
  "Play cards face down and claim what they are, truthfully or not. Call out the liars!",
  "Keep a straight face.", tags="party bluffing")
g("uno", "card", "Uno", "2–10", 30, "30 min", "home", "calm", "social", "connect relax",
  "Match colours or numbers and race to empty your hand, and don't forget to call it on your last card.",
  "Agree on house rules for stacking before you start.", tags="family party")
g("go_fish", "card", "Go Fish", "2–6", 15, "15 min", "home", "calm", "social", "connect relax",
  "Ask other players for cards to collect sets of four. A perfect first card game for kids.",
  "Deal five cards each; the rest is the pond.", tags="kids family")
g("crazy_eights", "card", "Crazy Eights", "2–7", 20, "20 min", "home", "calm", "social", "connect relax",
  "Match suits or ranks to shed your hand, and use eights as wild cards.",
  "Eights let you change the suit.", tags="family")
g("solitaire", "card", "Solitaire (Klondike)", "1", 15, "15 min", "home", "calm", "solo", "relax",
  "The classic one-player game: build the four suits from ace to king.",
  "Use a real deck or a free app.", win="Win a game of Solitaire", ladder=["Win three games", "Win without undo", "Win a draw-three game"], tags="solo")
g("spider_solitaire", "card", "Spider Solitaire", "1", 20, "20 min", "home", "calm", "solo", "relax learn",
  "Arrange cards into full same-suit runs from king down to ace. Start with one suit.",
  "Begin with the one-suit version.", win="Win a game of Spider Solitaire", ladder=["Win a two-suit game", "Win a four-suit game", "Win five four-suit games"], tags="solo")
g("hearts", "card", "Hearts", "4", 30, "30 min", "home", "calm", "social", "connect learn",
  "Avoid taking hearts and the queen of spades, or 'shoot the moon' and take them all.",
  "Pass three cards before each hand.", tags="trick-taking")
g("spades", "card", "Spades", "4", 45, "45 min", "home", "calm", "social", "connect learn",
  "A partnership game where spades are always trumps and you bid how many tricks you'll win.",
  "Bid carefully with your partner.", tags="trick-taking partnership")
g("bridge", "card", "Contract Bridge", "4", 90, "1–2 hr", "home", "calm", "social", "learn connect",
  "The deepest partnership card game: bid a contract, then play to make it.",
  "Start with a free beginner course or app.", win="Play a hand of Contract Bridge",
  ladder=["Learn basic bidding", "Play a full rubber", "Play at a bridge club"], tags="strategy partnership")
g("gin_rummy", "card", "Gin Rummy", "2", 30, "30 min", "home", "calm", "social", "connect relax",
  "A two-player rummy where you knock once your leftover cards are low enough.",
  "Deal ten cards each.", tags="two-player")
g("speed", "card", "Speed", "2", 10, "10 min", "home", "moderate", "social", "connect active",
  "A frantic two-player race to play cards one higher or lower. No turns!",
  "Split the deck evenly and set out the centre piles.", tags="fast two-player")
g("snap", "card", "Snap", "2–6", 10, "10 min", "home", "moderate", "social", "connect",
  "Turn cards over and shout 'Snap!' first when two match.",
  "Great with kids. Any deck works.", tags="kids fast")
g("old_maid", "card", "Old Maid", "2–8", 15, "15 min", "home", "calm", "social", "connect relax",
  "Pair up your cards and avoid being stuck with the odd queen at the end.",
  "Remove one queen from the deck first.", tags="kids family")
g("president", "card", "President (Scum)", "4–8", 30, "30 min", "home", "calm", "social", "connect",
  "Shed cards in rising combinations. Finishing order decides who's President next round.",
  "Twos are high in most versions.", tags="party")
g("canasta", "card", "Canasta", "4", 60, "1 hr", "home", "calm", "social", "connect learn",
  "A partnership rummy game played with two decks, building melds of seven called canastas.",
  "You'll need two decks with jokers.", tags="partnership")
g("cribbage", "card", "Cribbage", "2", 30, "30 min", "home", "calm", "social", "learn connect",
  "Score combinations of cards and peg points round a board. Clever, old and addictive.",
  "Use a pegboard or a free scoring app.", tags="two-player")
g("war", "card", "War", "2", 15, "15 min", "home", "calm", "social", "relax connect",
  "Flip cards and the higher card wins both. Pure luck and great for young children.",
  "Split the deck face down.", tags="kids")

# ------------------------------------------------------------------ Boards
g("monopoly", "board", "Monopoly", "2–6", 120, "1–3 hr", "home", "calm", "social", "connect",
  "Buy properties, build houses and hotels, and bankrupt your friends. The world's most famous property-trading game.",
  "Agree on a time limit, or the game can run long.", tags="classic family trading")
g("business_game", "board", "Business", "2–6", 90, "1–2 hr", "home", "calm", "social", "connect",
  "India's own property-trading board game, with cities like Mumbai and Delhi. A childhood classic.",
  "Pick a banker before you start.", tags="india classic family")
g("catan", "board", "Catan", "3–4", 75, "1–1.5 hr", "home", "calm", "social", "connect learn",
  "Collect and trade resources to build roads, settlements and cities on a new island. The modern classic.",
  "Use the beginner set-up from the rulebook for your first game.", tags="modern strategy trading")
g("ticket_to_ride", "board", "Ticket to Ride", "2–5", 60, "1 hr", "home", "calm", "social", "connect relax",
  "Claim railway routes across a map to connect cities. Easy to learn, great for families.",
  "Draw your destination tickets first.", tags="modern family")
g("carcassonne", "board", "Carcassonne", "2–5", 40, "40 min", "home", "calm", "social", "connect relax",
  "Lay tiles to build a medieval landscape of cities, roads and fields, and score with your followers.",
  "Place the start tile and draw one tile per turn.", tags="modern tiles")
g("pandemic", "board", "Pandemic", "2–4", 45, "45 min", "home", "calm", "social", "connect learn",
  "Team up to stop four diseases spreading around the world. Everyone wins or loses together.",
  "Start on the introductory difficulty.", tags="modern cooperative")
g("codenames", "board", "Codenames", "4–8", 20, "20 min", "home", "calm", "social", "connect learn",
  "Two spymasters give one-word clues to help their team find secret agents on a grid of words.",
  "Split into two teams with one spymaster each.", tags="party words")
g("dixit", "board", "Dixit", "3–8", 30, "30 min", "home", "calm", "social", "connect create",
  "Tell a story about a dreamlike picture card and see who guesses which one is yours.",
  "Clues that are too obvious or too vague both lose points.", tags="party creative")
g("splendor", "board", "Splendor", "2–4", 30, "30 min", "home", "calm", "social", "learn connect",
  "Collect gems to buy cards that make you richer, racing to attract nobles.",
  "Focus on cheap cards early.", tags="modern strategy")
g("azul", "board", "Azul", "2–4", 40, "40 min", "home", "calm", "social", "relax connect",
  "Draft colourful tiles to decorate a palace wall. Beautiful and quietly competitive.",
  "Watch out for tiles you're forced to take.", tags="modern pattern")
g("risk", "board", "Risk", "2–6", 180, "2–4 hr", "home", "calm", "social", "connect learn",
  "Command armies and conquer territories across a world map. A long game of strategy and dice.",
  "Try a shorter 'capital' or mission variant.", tags="classic strategy war")
g("cluedo", "board", "Cluedo (Clue)", "3–6", 45, "45 min", "home", "calm", "social", "connect learn",
  "Solve the murder: who did it, with what weapon and in which room?",
  "Keep a detective notepad as you go.", tags="classic deduction")
g("snakes_ladders", "board", "Snakes and Ladders", "2–4", 20, "20 min", "home", "calm", "social", "relax connect",
  "Race up ladders and slide down snakes. It began in ancient India as Moksha Patam.",
  "Any printed board and one dice will do.", tags="india classic kids")
g("ludo", "board", "Ludo", "2–4", 30, "30 min", "home", "calm", "social", "connect relax",
  "Race your four tokens home, knocking opponents back to start. Adapted from India's Pachisi.",
  "Roll a six to bring a token out.", tags="india classic family")
g("chinese_checkers", "board", "Chinese Checkers", "2–6", 30, "30 min", "home", "calm", "social", "relax connect",
  "Hop marbles across a star-shaped board into the opposite corner.",
  "Chain jumps for big moves.", tags="classic")
g("othello", "board", "Othello (Reversi)", "2", 20, "20 min", "home", "calm", "social", "learn",
  "Flip your opponent's discs by trapping them between yours. A minute to learn, a lifetime to master.",
  "Corners are the strongest squares.", tags="abstract strategy")
g("battleship", "board", "Battleship", "2", 30, "30 min", "home", "calm", "social", "relax connect",
  "Hide your fleet on a grid and call shots to sink your opponent's ships. Pen and paper works fine.",
  "Draw two 10×10 grids each.", tags="classic two-player")
g("jenga", "board", "Jenga", "2+", 15, "15 min", "home", "moderate", "social", "connect relax",
  "Pull blocks from a wooden tower and stack them on top without toppling it.",
  "Use one hand only for an extra challenge.", tags="dexterity party")
g("connect_four", "board", "Connect Four", "2", 10, "10 min", "home", "calm", "social", "relax learn",
  "Drop discs into a grid and be first to line up four in a row.",
  "Block your opponent's threes.", tags="classic two-player")
g("seven_wonders", "board", "7 Wonders", "3–7", 30, "30 min", "home", "calm", "social", "learn connect",
  "Draft cards over three ages to build an ancient civilisation and its wonder.",
  "Everyone plays at once, so it's quick even with seven.", tags="modern strategy")
g("wingspan", "board", "Wingspan", "1–5", 60, "1 hr", "home", "calm", "either", "relax learn",
  "Attract birds to your wildlife reserves in this beautifully illustrated engine-building game.",
  "Play a practice round with open hands.", tags="modern nature")
g("sushi_go", "board", "Sushi Go!", "2–5", 15, "15 min", "home", "calm", "social", "relax connect",
  "Pass hands of cute sushi cards and pick the best combinations. Quick and cheerful.",
  "Keep an eye on what others are collecting.", tags="modern family")
g("blokus", "board", "Blokus", "2–4", 20, "20 min", "home", "calm", "social", "learn relax",
  "Place your coloured pieces corner to corner and block everyone else.",
  "Get your big pieces down early.", tags="abstract family")
g("backgammon", "board", "Backgammon", "2", 30, "30 min", "home", "calm", "social", "learn connect",
  "One of the oldest board games. Race your checkers home with dice, strategy and a little luck.",
  "Learn the opening moves for each roll.", ladder=["Learn all the rules", "Win a game", "Learn the doubling cube"], tags="classic strategy")
g("checkers", "board", "Checkers (Draughts)", "2", 30, "30 min", "home", "calm", "social", "learn relax",
  "Jump diagonally to capture pieces and crown your kings.",
  "A chessboard works perfectly.", tags="classic two-player")
g("go_game", "board", "Go", "2", 60, "1 hr", "home", "calm", "social", "learn",
  "Place stones to surround territory in this ancient strategy game, simple to learn and endlessly deep.",
  "Start on a small 9×9 board.", ladder=["Play on a 9×9 board", "Win a 13×13 game", "Play a full 19×19 game"], tags="abstract strategy")

# ------------------------------------------------------------------ Traditional Indian
g("chaupar", "indian", "Chaupar (Pachisi)", "2–4", 60, "1 hr", "home", "calm", "social", "connect learn",
  "India's royal cross-and-circle race game, played on cloth boards with cowrie shells. The ancestor of Ludo.",
  "Use cowries or long dice to move.", tags="india heritage")
g("pallanguzhi", "indian", "Pallanguzhi", "2", 20, "20 min", "home", "calm", "social", "learn connect",
  "A South Indian mancala game of sowing seeds or shells round 14 pits.",
  "Tamarind seeds or shells make perfect counters.", tags="india heritage strategy")
g("aadu_puli", "indian", "Aadu Puli Attam (Lambs & Tigers)", "2", 20, "20 min", "home", "calm", "social", "learn",
  "One player's tigers hunt the other's lambs on a triangle board. Draw it on paper or in chalk.",
  "Draw the board, then use pebbles and seeds as pieces.", tags="india strategy")
g("gilli_danda", "indian", "Gilli-danda", "2+", 45, "45 min", "out", "active", "social", "active connect",
  "Strike a small wooden gilli into the air with the danda and hit it as far as you can.",
  "Play in an open field, away from windows and people.", tags="india outdoor")
g("kanche", "indian", "Kanche (Marbles)", "2+", 30, "30 min", "out", "moderate", "social", "connect relax",
  "Flick glass marbles to hit targets and win them. A street-corner classic.",
  "Draw a circle in the dirt and place the marbles.", tags="india outdoor kids")
g("gutte", "indian", "Gutte (Five Stones)", "1+", 15, "15 min", "local", "calm", "either", "relax",
  "Toss and catch small stones in increasingly tricky patterns.",
  "Find five smooth pebbles of similar size.", tags="india dexterity")
g("langdi", "indian", "Langdi", "6+", 30, "30 min", "out", "active", "social", "active connect",
  "Tag on one foot! Chasers hop to catch the runners. A Maharashtrian school favourite.",
  "Mark a square play area.", tags="india outdoor tag")
g("kith_kith", "indian", "Kith-kith (Hopscotch)", "1+", 20, "20 min", "out", "active", "either", "active relax",
  "Hop through a chalk grid and pick up your marker on the way back.",
  "Draw the grid with chalk and find a flat stone.", tags="india outdoor kids")
g("lattu", "indian", "Lattu (Spinning top)", "1+", 20, "20 min", "out", "moderate", "either", "learn relax",
  "Wind a string round a wooden top and launch it spinning. Then learn to pick it up while it spins.",
  "Wind the string tightly from the tip upwards.", win="Spin a lattu for 10 seconds", ladder=["Spin it every time", "Lift a spinning top onto your palm", "Win a top-fight"], tags="india skill")
g("raja_mantri", "indian", "Raja Mantri Chor Sipahi", "4", 15, "15 min", "home", "calm", "social", "connect relax",
  "Pick paper chits as King, Minister, Thief or Soldier, and the Minister must catch the Thief.",
  "Write four chits and fold them.", tags="india party kids")
g("vish_amrit", "indian", "Vish Amrit", "5+", 20, "20 min", "out", "active", "social", "active connect",
  "Tag with a twist: 'vish' freezes you and a teammate's 'amrit' sets you free.",
  "Choose the chaser and a safe area.", tags="india outdoor tag")
g("navakankari", "indian", "Navakankari (Nine Men's Morris)", "2", 20, "20 min", "home", "calm", "social", "learn",
  "Form lines of three to capture pieces. Old boards are carved into temple floors across India.",
  "Draw three nested squares joined at the middles.", tags="india heritage strategy")
g("ashta_chamma", "indian", "Ashta Chamma", "2–4", 30, "30 min", "home", "calm", "social", "connect relax",
  "A race game on a 5×5 chalk grid using cowrie shells as dice. A favourite in Andhra and Karnataka.",
  "Draw the grid and use four cowries or tamarind seeds as dice.", tags="india heritage")
g("chhupan_chhupai", "indian", "Chhupan Chhupai (Hide & Seek)", "3+", 30, "30 min", "local", "moderate", "social", "active connect",
  "Count, hide, seek and race back to 'dhappa' before you're caught.",
  "Set safe boundaries for hiding.", tags="india kids")

# ------------------------------------------------------------------ Outdoor
g("frisbee_catch", "outdoor", "Frisbee", "2+", 30, "30 min", "out", "active", "social", "active relax",
  "Throw and catch a flying disc in a park. Simple, sunny fun.",
  "Learn the backhand throw first.", win="Play frisbee catch for 30 minutes", ladder=["Catch 10 throws in a row", "Throw a forehand", "Play a game of Ultimate"], tags="park")
g("ultimate", "outdoor", "Ultimate Frisbee", "8–14", 60, "1 hr", "out", "active", "social", "active connect",
  "A fast team sport: pass the disc into the end zone without running while holding it.",
  "Self-refereed, so agree on 'spirit of the game' first.", tags="team sport")
g("volleyball", "outdoor", "Volleyball", "6–12", 60, "1 hr", "out", "active", "social", "active connect",
  "Keep the ball off the ground on your side with three touches to get it over the net.",
  "A rope works if you don't have a net.", tags="team sport")
g("throwball", "outdoor", "Throwball", "8–14", 45, "45 min", "out", "active", "social", "active connect",
  "Like volleyball but you catch and throw. Popular in Indian schools and colleges.",
  "Catch with both hands and throw within three seconds.", tags="india team sport")
g("tug_of_war", "outdoor", "Tug of War", "6+", 15, "15 min", "out", "active", "social", "active connect",
  "Two teams, one rope, all the strength you've got.",
  "Use a thick rope and soft ground.", tags="team")
g("dodgeball", "outdoor", "Dodgeball", "6+", 30, "30 min", "out", "active", "social", "active connect",
  "Throw soft balls to get opponents out, and dodge or catch to survive.",
  "Use soft balls and no head shots.", tags="team")
g("rounders", "outdoor", "Rounders", "8+", 45, "45 min", "out", "active", "social", "active connect",
  "Hit the ball and run around four bases before it's thrown back.",
  "Use a light bat and tennis ball.", tags="team bat-and-ball")
g("bocce", "outdoor", "Bocce", "2–8", 30, "30 min", "out", "calm", "social", "relax connect",
  "Roll heavy balls as close as you can to the little target ball.",
  "Flat grass or sand is ideal.", tags="lawn")
g("treasure_hunt", "outdoor", "Treasure Hunt", "3+", 60, "1 hr", "local", "moderate", "social", "connect create",
  "Follow written clues from spot to spot to find a hidden prize.",
  "Write rhyming clues that lead to the next hiding place.", win="Run or solve a treasure hunt", tags="party kids")
g("capture_flag", "outdoor", "Capture the Flag", "8+", 45, "45 min", "out", "active", "social", "active connect",
  "Sneak into the other team's half, grab their flag and get it home without being tagged.",
  "Mark the halves and two jail zones.", tags="team tag")
g("sack_race", "outdoor", "Sack Race", "4+", 15, "15 min", "out", "active", "social", "active connect",
  "Hop to the finish line inside a sack. Pure, giggly chaos.",
  "Use old jute or rice sacks on soft grass.", tags="sports-day")
g("lemon_spoon", "outdoor", "Lemon and Spoon Race", "4+", 15, "15 min", "out", "moderate", "social", "connect relax",
  "Race with a lemon balanced on a spoon held in your mouth. An Indian sports-day essential.",
  "Mark a start and finish line.", tags="india sports-day")
g("pickleball", "outdoor", "Pickleball", "2–4", 60, "1 hr", "local", "active", "social", "active connect",
  "A paddle sport mixing tennis, badminton and table tennis, and the fastest-growing game around.",
  "Many courts lend paddles to beginners.", tags="sport paddle")
g("tennis", "outdoor", "Tennis", "2–4", 60, "1 hr", "local", "active", "social", "active learn",
  "Rally a ball over the net with racquets. Book a public court and try a few games.",
  "Practise rallying before keeping score.", win="Play a set of tennis", tags="sport racquet")
g("mini_golf", "outdoor", "Mini Golf", "1–6", 60, "1 hr", "local", "calm", "social", "relax connect",
  "Putt a ball through quirky obstacles in as few strokes as possible.",
  "Find a mini-golf course or set one up at home with cups.", win="Play a round of Mini Golf", tags="outing")
g("statue", "outdoor", "Statue (Freeze)", "4+", 15, "15 min", "local", "moderate", "social", "connect relax",
  "Dance or move until the music stops, then freeze! Anyone who moves is out.",
  "One person controls the music.", tags="kids party")
g("chain_tag", "outdoor", "Chain Tag", "6+", 20, "20 min", "out", "active", "social", "active connect",
  "Everyone the chaser tags joins hands and becomes part of a growing chain.",
  "Choose a safe, open space.", tags="tag kids")
g("cornhole", "outdoor", "Cornhole (Bean Bag Toss)", "2–4", 30, "30 min", "out", "calm", "social", "relax connect",
  "Toss bean bags onto a slanted board and score by landing in the hole.",
  "Make DIY bags from cloth and rice and a cardboard target.", tags="lawn")

# ------------------------------------------------------------------ Party & indoor
g("dumb_charades", "party", "Dumb Charades", "4+", 30, "30 min", "home", "moderate", "social", "connect create",
  "Act out a film title without speaking while your team guesses. A Bollywood-night essential.",
  "Agree on gestures for 'words' and 'syllables'.", tags="india party films")
g("pictionary", "party", "Pictionary", "4+", 30, "30 min", "home", "calm", "social", "connect create",
  "Draw a word while your team races to guess it, with no letters or numbers allowed.",
  "Use a whiteboard or big sheets of paper.", tags="drawing party")
g("musical_chairs", "party", "Musical Chairs", "5+", 15, "15 min", "home", "active", "social", "active connect",
  "Circle the chairs while the music plays, and grab a seat when it stops.",
  "Use one chair fewer than players.", tags="party kids")
g("twenty_questions", "party", "Twenty Questions", "2+", 15, "15 min", "home", "calm", "social", "connect learn",
  "Guess the secret thing using only yes-or-no questions, with twenty tries.",
  "Start with 'animal, vegetable or mineral?'.", tags="words travel")
g("mafia", "party", "Mafia (Werewolf)", "6+", 45, "45 min", "home", "calm", "social", "connect",
  "Secret roles, night-time attacks and daytime accusations. Can the town find the mafia?",
  "Use playing cards to deal secret roles.", tags="social-deduction party")
g("two_truths", "party", "Two Truths and a Lie", "3+", 15, "15 min", "home", "calm", "social", "connect",
  "Share three facts about yourself; others guess which one is the lie.",
  "Great for getting to know new people.", tags="icebreaker")
g("would_you_rather", "party", "Would You Rather", "2+", 15, "15 min", "home", "calm", "social", "connect relax",
  "Pose impossible choices and defend your answers.",
  "Take turns asking.", tags="conversation")
g("hangman", "party", "Hangman", "2+", 10, "10 min", "home", "calm", "social", "learn relax",
  "Guess the hidden word letter by letter before the drawing is complete.",
  "Pen and paper is all you need.", tags="words")
g("tic_tac_toe", "party", "Tic-tac-toe", "2", 5, "5 min", "home", "calm", "social", "relax",
  "Get three in a row on a 3×3 grid. Then figure out why perfect play is always a draw.",
  "Draw the grid anywhere.", ladder=["Never lose a game", "Learn the winning openings", "Try 4×4 or Ultimate tic-tac-toe"], tags="paper")
g("dots_boxes", "party", "Dots and Boxes", "2", 15, "15 min", "home", "calm", "social", "learn relax",
  "Join dots to close boxes; complete a box and you go again.",
  "Draw a 5×5 grid of dots.", tags="paper strategy")
g("npat", "party", "Name Place Animal Thing", "2+", 20, "20 min", "home", "calm", "social", "learn connect",
  "Pick a letter and race to fill each column. The classic Indian school-bench game.",
  "Rule columns on paper and add your own categories.", tags="india words paper")
g("murder_mystery", "party", "Murder Mystery Party", "6+", 150, "2–3 hr", "home", "calm", "social", "connect create",
  "Everyone plays a character with secrets. Dress up, question each other and unmask the culprit.",
  "Download a free or paid party kit.", win="Host or attend a murder mystery party", tags="party roleplay")
g("escape_room", "party", "Escape Room", "2–6", 60, "1 hr", "local", "moderate", "social", "connect learn",
  "Solve puzzles as a team to escape a themed room before the clock runs out.",
  "Book a beginner room at a local venue.", win="Escape from an escape room", tags="outing puzzles")
g("bowling", "party", "Bowling", "1–6", 60, "1 hr", "local", "moderate", "social", "connect active",
  "Roll a ball down the lane and knock down all ten pins.",
  "Most alleys rent shoes and balls.", win="Bowl a full game", ladder=["Score over 100", "Bowl a strike", "Score over 150"], tags="outing")
g("darts", "party", "Darts", "2+", 30, "30 min", "home", "calm", "social", "relax connect",
  "Throw darts at a board, counting down from 301 to exactly zero.",
  "Hang the board at the right height, away from walkways.", tags="pub skill")
g("pool", "party", "Pool (Billiards)", "2–4", 30, "30 min", "local", "calm", "social", "connect learn",
  "Pot your balls and then the black. Angles, spin and patience.",
  "Find a table at a club or café.", tags="cue skill")
g("foosball", "party", "Foosball", "2–4", 15, "15 min", "local", "moderate", "social", "connect active",
  "Spin the rods to score goals in table football.",
  "Often found in cafés and colleges.", tags="table arcade")
g("passing_parcel", "party", "Passing the Parcel", "5+", 15, "15 min", "home", "calm", "social", "connect relax",
  "Pass a wrapped parcel while the music plays; whoever holds it when it stops unwraps a layer.",
  "Wrap a small prize in many layers.", tags="india party kids")
g("heads_up", "party", "Heads Up (Forehead guessing)", "3+", 15, "15 min", "home", "moderate", "social", "connect",
  "Hold a word to your forehead while friends give clues. Guess before time runs out.",
  "Use a phone app or written cards.", tags="party words")
g("air_hockey", "party", "Air Hockey", "2", 10, "10 min", "local", "active", "social", "connect active",
  "Slam the puck into your opponent's goal on a cushion of air.",
  "Find a table at an arcade or games café.", tags="arcade")


def build():
    seen, names, items = set(), set(), []
    for e in G:
        assert e["group"] in GROUPS, e["slug"]
        assert len(e["ladder"]) == 3, e["slug"]
        item_id = f"game_{e['slug']}"
        assert item_id not in seen, item_id
        assert e["win"] not in names, e["win"]
        seen.add(item_id)
        names.add(e["win"])
        items.append({
            "id": item_id,
            "challenge_id": CH,
            "name": e["win"],
            "category": e["name"],
            "filter_group": GROUPS[e["group"]],
            "difficulty": "beginner",
            "about": e["about"],
            "howToSteps": [STEPS[e["group"]], e["tip"], "Play one full game, start to finish."],
            "tags": e["tags"] + ["game"],
            "keywords": [e["name"].lower()],
            "metadata": {
                "Players": e["players"],
                "Time": e["time"],
                "Where": WHERE[e["where"]],
            },
            "attributes": {
                "setting": SETTING[e["where"]],
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
        "version": 1,
        "source_note": "Original summaries of widely played games. Generated by tools/build_games.py.",
        "items": items,
    }


if __name__ == "__main__":
    data = build()
    out = Path(__file__).resolve().parents[1] / "assets/data/games.json"
    out.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    counts = {}
    for item in data["items"]:
        counts[item["filter_group"]] = counts.get(item["filter_group"], 0) + 1
    print(len(data["items"]), "games:", counts)
