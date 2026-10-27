# Junkyard Brawl — Project Bible

The source-of-truth design spec. Every tunable number here lives in the Config module in code; if they differ, update
this file in the same PR as the Config change.

## 1. Core specs

- **Title:** Junkyard Brawl
- **Genre:** Indie PvP platform fighter (knock-off / ring-out brawler)
- **Pitch:** A retro, slightly-apocalyptic free-for-all where you punch, charge up haymakers and hurl junk (chairs, crates, TVs,
  fridges) to knock rivals off crumbling floating platforms. Short, chaotic rounds with two modes: **Classic** (HP +
  falling) and **Casual** (no HP, knockback % only).
- **Core loop**
  - Every few seconds: punch, charge a power punch, dash-dodge, grab loose props or smash structures for props, throw them to launch
    rivals off the edge.
  - Per session: win rounds, KO streaks, finish daily quests, earn Scrap and XP; spin for fighting styles and buy cosmetics.
  - Over weeks: level and rank titles, new styles, new cosmetics, leaderboards, new maps, codes, limited-time events.
- **Engine & tooling:** Roblox Studio + Studio MCP, modern Luau (`--!strict`), Studio AI generation + Creator Store
  assets (no external software).
- **Audience:** teens and young adults 15+ (core 13–24), "Mild" maturity (cartoon violence, no blood).
  Mobile 60%, PC 35%, Console 5%.
- **Languages:** English source; Roblox automatic translation for the rest. All UI text uses LocalizationTable keys —
  no hard-coded strings in scripts.
- **Topology:** lobby + arena in the same server, free-for-all rounds, 8–12 players per server (target 10). Parties of
  up to 4 join the same server together.

## 2. Economy & progression

### 2.1 Currencies and rewards

- **Scrap** — the only soft currency. Shown to players as **Coins** (owner, 2026-10-19); code and data keep "Scrap". Earned from KOs, placement, participation, daily rewards, quests, codes. Spent on
  style spins and cosmetics. Robux buys premium cosmetics, Scrap packs and style slots. No stat upgrades for sale.
- **XP** — earned alongside Scrap; drives Level and Rank titles.

| Event (per round) | Scrap | XP |
| --- | --- | --- |
| KO (ring-out or HP KO) | +10 | +20 |
| Win round | +50 | +100 |
| Top 3 finish | +25 | +50 |
| Round completed (stayed to the end) | +15 | +40 |

- **Perfect Dodge:** dashing through an attack in the last 0.15 s before it lands = no damage/knockback, +5 Scrap, and
  the next hit within 2 s deals +25% knockback. Any hit inside a dash's 0.25 s invulnerability misses; only the first
  0.15 s counts as a Perfect Dodge (one per dash). The Scrap is paid with the round rewards.
- **KO streak multiplier:** starts x1.0, +0.1 per consecutive KO without being KO'd, caps x1.5, resets when KO'd or at
  round end. Applies to Scrap from KOs only.
- **Storage cap / conversion:** not used.
- **Levels:** cap 100. XP to next level = `floor(100 × Level^1.4)`.
- **Rank titles:** Scavenger (1), Raider (10), Wrecker (20), Rustlord (30), Warlord (40), Wasteland Legend (50),
  Junk King (75), Apex Scrapper (100).

### Damage & knockback (one system, two modes)

- **Percent** is the core value. Classic: Percent = damage taken this life `(100 − HP) × 1.5`. Casual: Percent is its
  own meter.
- **Knockback force** = `(BaseKB + (Percent / 100) × KBGrowth × AttackKBScale) × ModeMultiplier`
  - BaseKB = 30, KBGrowth = 70, ModeMultiplier: Classic 1.0, Casual 1.15
  - Uses the victim's Percent *after* the hit's damage. Applied as launch speed (studs/s), away from the attacker
    and 30° upward; a launched player cannot steer until hitstun is over and they land (max 3 s).
- **Damage (Classic)** = `AttackBaseDamage × StyleDamageMultiplier`
- **Percent gain (Casual)** = `AttackBasePercent × StyleDamageMultiplier`
- **Casual passive gain:** +1% every 5 s while alive. Percent cap 300%.
- **Hitstun** = `0.15 s + Percent × 0.002 s` (max 0.8 s). Players launched above 100% leave a trail.

### Modes and round rules

- **Classic is the only mode** (owner, 2026-10-19: "Classic mode only, no mode vote"); the vote is map-only.
  Casual stays in Config, out of the rotation.
- **Classic:** 100 HP, 3 lives (stocks). Lose a life at 0 HP or by falling below KillY. Last fighter standing wins; at
  time-out most KOs wins (tiebreak: fewest falls) among the fighters still in, who all rank above the eliminated
  (eliminated later = higher).
- **Casual:** no HP, unlimited respawns. Score = KOs − falls. Highest score at time-out wins (tiebreak: more KOs, then
  fewer falls). Equal records share a placement.
- Every KO you take is a fall (also resetting your character in the arena; the last attacker still gets the KO).
- Round 4:00 (owner, 2026-10-17; was 3:00). Intermission/vote 15 s (up to 3 enabled maps; ties random). Respawn delay 3 s. Spawn
  shield 2 s (breaks if you attack). Results 8 s. A round needs 2 active players; AFK players sit out the next round.
- **The lobby is run-only** (owner, 2026-10-19): punch, charged punch, ability, dash and grab only work while fighting
  in a round.

### Attacks

| Attack | Damage / Percent | Knockback | Hitbox (studs, in front) | Cooldown |
| --- | --- | --- | --- | --- |
| Punch (3-hit chain) | 8 HP / 6% per hit | 3rd hit ×1.5 KB | 4×4×5 | 0.35 s between hits, 0.8 s after 3rd |
| Charged punch (heavy; hold Punch) | 14 HP / 11% (×1.75 base) | AttackKBScale 1.6; keep holding Punch 0.25 s after a punch to charge, up to 0.8 s for up to ×1.5 KB; 40% slow while charging | 5×5×6 | 1.2 s |
| Dash | — | 12 studs in 0.25 s (owner playtest; was 18), level (no gravity), 0.25 s invulnerability, once in the air per jump; ends a launch after hitstun (recovery); costs 25 stamina | — | 0.6 s |

### Reward distribution

- Must be in the round ≥ 60 s for placement rewards. AFK (no input 45 s) = no rewards.
- Paid out by the server at round end, multiplied by VIP / Premium / friend bonuses (additive, max +60% total).

### 2.2 Rebirth

Not used. Long-term goals are levels/ranks, styles, cosmetics and leaderboards.

### 2.3 Styles (style roll) and Shop (cosmetics only)

Fighting styles come from the **style roll** (owner, 2026-10-19), not from levels or the Shop. The Styles screen (left menu):
1 free spin a day (00:00 UTC), more for 250 Scrap ("Coins") each; a spin puts a random style into the equipped slot
unless that slot is locked. Odds (shown before every spin): Uncommon 70% (Slugger), Rare 25% (Scrapper), Legendary 5%
(Wrecker); pity: the 50th spin without a Legendary is a Legendary. Everyone starts with 1 slot holding Brawler; more
slots are a Robux product (up to 4); locking a slot is free. Paid spins are a paid random item: hidden where Roblox's
policy restricts them, and declared on the maturity questionnaire.

| Style | Weapon | Rarity | Changes |
| --- | --- | --- | --- |
| Brawler | Fists | Common (the default, never rolled) | Punch and charged punch as above |
| Slugger | Baseball bat | Uncommon (70%) | Damage ×1.15, +2 studs reach, attack speed ×0.8 |
| Scrapper | Shovel | Rare (25%) | Wide sweep hitbox 7×4×5, Damage ×0.9, charged punch KB ×1.1 |
| Wrecker | Wrench + hubcap shield | Legendary (5%) | Ability key (F / Y / Parry button): a 0.2 s parry (cooldown 1.2 s) — a punch or charged punch landing in it misses and its knockback (not damage) hits the attacker instead; Punch Damage ×0.95 |

- **Cosmetics** (Scrap or Robux): skins, hats, back items, dash trails, KO effects, name-plate frames (victory emotes
  were removed by the owner, 2026-10-19).
  Catalog in `Config.Cosmetics.Items` (blockout visuals until the art pass). KO effects burst at the victim for HP KOs
  and around the scorer for ring-outs. Equipped in the Inventory.
  Common 300–800 Scrap; Rare 1,200–2,500 Scrap; Premium = Robux only (sold as developer products, or coming with the
  VIP pass or Roblox Premium: §7).
- **Daily rotating shop:** 4 cosmetics rotate every 24 h (UTC) and sell at 20% off (`DailyRotation.Discount`); the
  picks are the same for everyone (seeded by the day). Every Scrap item is always buyable in its own tab; exclusive
  VIP / Premium items never sell for Scrap.

### 2.4 Pets & eggs

Not used. No pets, eggs, or paid random items.

## 3. World

### 3.1 Streaming & zones

- One Lobby hub + 3 rotating arenas at launch. Each arena: floating platforms over a void (KillY) with toxic sludge or
  fog far below.
- Lobby → (vote) → arena via server-side teleport of characters within the same place. After the round, everyone
  returns to the Lobby. Arenas live in ServerStorage; only the active one is in Workspace.
- All maps free. Players enter the arena only when the server starts a round, and only if they stand on the lobby's
  **join pad** (in front of the ARENA door) when it starts; everyone else stays in the lobby (Shop, Inventory ...).
  Late joiners stay in the lobby too (Casual: stepping on the pad joins the running round after the 3 s respawn).

| Zone | Description |
| --- | --- |
| Lobby — "The Hideout" (enclosed hideout lounge) | Shop (bar counter), style coach (Styles), Quest board, leaderboards, spin wheel, join pad, seats |
| Map 1 — Broken Highway | Shattered overpass chunks, abandoned cars, road signs |
| Map 2 — Junkyard Isles | Stacked car and container islands over toxic sludge |
| Map 3 — Neon Motel | Sinking motel rooftops, flickering retro neon, pool on one roof |

### 3.2 Visual & spatial guidelines

**Lobby (The Hideout):** an enclosed hideout bar (owner's changes: a closed space, not the open Rust Diner rooftop,
no Training Yard, 2026-10-16; 25% bigger in the style of the reference pictures with detailed furniture, 2026-10-19;
a bit less luxury, 2026-10-27: worn iron, old brass and wood instead of gold and marble; the same day a new layout,
15% smaller — 98 × 72 studs, 26 high). Grey-green plaster walls over dark wood wainscoting with a wood rail, dark wood
pillars with iron bands and white wall lamps, wood beams, iron workshop pendant lamps, a concrete floor (wood planks
under the bar). North (the bar's wood floor) — the wood-topped bar counter with the Shop NPC
(the bartender: a standing Roblox character in a white shirt, dark vest, apron, bow tie and bandana, who talks in a
speech bubble: a greeting when you walk up, a line about your last round, tips and jokes while you hang around, and lines
when you open the Shop or buy something), bar stools, a mirrored back bar with bottle shelves, three big CRT TVs over the bar (each shows one map of the ballot with its votes during the vote,
the middle one the live match during a round, the news otherwise) and news TVs on the counter ends (a "JUNKYARD NEWS"
channel: fun headlines mixed with live news — the last winner, today's deal, the Wins leader — and a scrolling
ticker), the "JUNKYARD BRAWL" sign; two booths on the left side (as you face the bar), a long booth for six in the
right-hand corner with the chess table in front of it, high tables with stools in front of the bar stools. Left wall
— three dark leaderboard boards in the middle (cream title, gold underline; rows of rank, avatar headshot, name and
value with thousands separators, the top 3 outlined in gold / silver / bronze) with the pool table and the
arm-wrestling table in front of them; a barrel and a dartboard at the bar end, the teal barrel in the corner. Right
wall — the spin wheel in the middle (walk up and press the red button in front of it; each slice shows its prize and
chance) with a worn dark rug with a rust ring, a round wood table on an iron base and two floor lamps with white drum
shades in front of it, a potted tree. South (the ARENA wall, opposite the bar) — the steel ARENA door with the
glowing join pad in front of it; left of it the
style coach (a standing Roblox character in a red tracksuit with a headband and a whistle, under a STYLES sign: walk
up for the Styles screen, the style roll) by a jukebox (decor) and the street door in the corner; right of it the
cork quest board and crates in the corner. Middle — open floor from the ARENA door to the bar; players spawn in the
centre of the room, facing the bar (no visible spawn pad); potted trees in black pots. The arm-wrestling table has two stools facing each other: sit down opposite someone, wait out
a 3-second countdown, then mash Attack — or tap PUSH on a phone — to push the clasped hands over to your side; a pin
wins at once, otherwise whoever is ahead after 15 seconds; the wrestlers' panel shows the match and, between matches,
the table champion's wins in a row; no Coins at stake, wins count toward a lifetime arm-wrestling stat. The chess
table sits between two armchairs: sit down opposite someone (the seat nearer the right wall plays White); a board screen
shows the game from your side — tap a piece to see where it can go, tap the square to move; full chess rules, 5
minutes each plus 3 seconds a move, resign or offer a draw; the pieces stand on the lobby board for everyone to watch; a new game starts 10 seconds after one ends while
both stay; no Coins at stake, wins count toward a lifetime chess stat. Every sofa,
armchair, booth bench and
stool can be sat on: walk up and press Sit (E / gamepad B / tap); jump to stand up. Walk up to the bartender for the
Shop, to the style coach for the Styles screen and to the quest board for the Quests (a prompt: E / gamepad B / tap);
they also open from the left-edge menu, like the Inventory and Settings (Promo code tab).

**Broken Highway arena:**

- Four times the first size with four layers (owner: twice 2026-10-17, every platform doubled again 2026-10-20):
  central main platform 240×160 with a raised 72×40 overpass deck (+6, a ramp on each end); 4 side platforms 96×96;
  4 corner ledges 48×48 (+6); 2 peaks 40×40 (+12) beyond two ledges; 2 low slabs 56×56 (about 6 below a side). The
  other arenas grew the same way (every platform ×2, every gap kept). Gaps 8–14 studs (always crossable with jump + dash) and every climb
  at most 6 studs. KillY 60 studs below the lowest platform. 16 spawn points spread over the platforms.
- 24 loose prop spots (chairs, crates, tires, buckets, TVs, barrels), respawn 20 s.
- 8 breakable structures: wrecked car (HP 100), vending machine (HP 80), road barrier stack (HP 60) — each drops 2–4
  props, respawn 45 s.
- 1 explosive barrel spot per side and low platform, respawn 30 s.
- **Shaped, with moving parts (owner, 2026-10-20: "more dynamic, not just flat platforms, more layers, more detail"):**
  the centre has a steel catwalk at +14 over the deck (stairs from the deck, or the lift), a broken flyover ramp that
  ends in mid-air at +8, a two-high container tower (+6 / +12), a fallen container, concrete barrier lines, a planter
  with a dead tree, raised sidewalks with lamp posts; East is a toll plaza (booths, a canopy you can climb onto, +11),
  West a collapsed road slab (+6) and a crashed bus (+5.5), North a parking deck (+7, walk under it, ramp up), South a
  bus shelter (+5.5) and a billboard; ledges have low walls and crates, peaks a white rim and floodlights, the lows
  tyre stacks. **Moving parts:** a lift from the centre's floor up to the catwalk; a broken highway sign swinging on
  chains across the deck that knocks you off your feet (no damage); a flatbed sliding along the gap between the
  centre and South — walk across while it passes. **Connected, but not everywhere (owner, 2026-10-20: "some
  short, some long, some gaps, not too boring"):** short bridges join the centre to East and North, West to its low
  platform and the NE ledge to its peak; long ones join North to the NE ledge and West to the SW ledge; every other
  neighbour is a jump. Each bridge is two halves, one on each platform, so a crumbling platform takes its half and
  leaves a broken stub. **Higher places** (owner: "more structure — higher places"): a third container on the tower
  (+18), a roof deck on the parking garage (+14), a control booth on the toll canopy (about +17), a broken overpass
  pier on West (+12), a catwalk along the billboard (+7) and a sign deck on every corner ledge (+7 above it), each with
  crates or ramps to climb. **The void is a dark abyss** (mist fading to black; the green neon sludge is
  gone) with ruins of the old highway rising out of it, under a **smoggy sunset sky** (thick brown-orange haze, heavy
  rust-tinted clouds: the `Smog` lighting preset). The props
  and structures are detailed models (no more plain blocks).
- **Crumbling platforms:** from 1:00 into the round, every 20 s one platform flashes red and shakes for 3 s, then
  falls. The arena closes in toward the centre (owner, 2026-10-19): the next platform is a random one from the outer
  ring (within 40 studs of the farthest one still standing), so the far peaks and low slabs go first, then the
  ledges and sides. The central platform never falls; at least 2 platforms always remain. Clear 3 s warning (shake,
  crack VFX, rumble SFX).

**Junkyard Isles arena (rebuilt 2026-10-20 the Broken Highway way):** stacked car and container islands over the dark
abyss (the toxic sludge is gone; towers of crushed cars rise out of the dark) under a stormy rust sunset (the `Rust`
lighting preset: heavy grey-violet clouds lit orange). Higher places: on the scrap-heap centre a junk tower (+6, +12,
+17; the junk elevator rides to +12), a car crusher (+8, ramp up) and four junk heaps; East's two-high container stack
under a container crane with a walkway at +18; West's stepped car pile (+10); North's scaffold beside the old crane
(+5, +10, +15, the crane cab on top); South's barge wheelhouse (+5, +9.4) and a deck container; tyre towers on the
ledges and peaks. Moving parts: the magnet crane's magnet swings along the centre's north side and knocks you
flying; the junk elevator; a junk raft slides along the gap between the centre and the South barge. Gangways (steel,
yellow railings): short from the centre to East and West, South to its raft, the SW tyre stack to its tower; long
from East to the NE tyre stack and North to the NW one; the rest are jumps. The crushed car stacks and scrap piles
are detailed models.

**Neon Motel arena (rebuilt 2026-10-20 the same way):** sinking motel rooftops over the dark abyss (the flooded street
is gone; the sunken neon buildings reach down into the dark) on a cloudy night (the `Night` preset now has heavy
purple clouds). Higher places: on the main roof two raised roof sections (+3), a machine room (+7) with a water-tank
deck (+13, the tank's top +18) and a service lift, and a neon sign tower with a catwalk (+10) under a big MOTEL sign;
the pool roof's high-dive tower (+5, +10 with a board over the water) and a cabana (+5); a catwalk along West's MOTEL
sign (+7) and a stairwell hut (+6); North's two-storey penthouse (+6.4, +11.8); South's water tank on stilts (+8,
tank top +13); huts on three ledges. Moving parts: a neon OPEN sign swinging on chains across the main roof's east side
(it knocks you flat), the service lift, a window cleaner's platform sliding along the gap between the main roof and
the pool roof. Gangways: short from the centre to West and South, East to its low roof, the water-tower roof to its
antenna roof; longer from West to the NW roof and South to the SE roof; the rest are jumps. Ice machines and lawn
chair stacks are detailed models.

**Every arena** follows the same rules as Broken Highway: four layers — 2 low platforms (4–9 below the centre), the
base level (one centre platform that never falls, with a raised deck ≤ 6 high and ramps, and 4 side platforms within
3 studs of it), 4 corner ledges (4–6 above) and 2 peaks (10–12 above) — every outer platform 8–14 studs from its
nearest neighbour, every platform reachable from the centre with climbs of at most 6 studs, 16 spawn points, 24 loose
prop spots, 8 breakable structures (HP 100 / 80 / 60 tiers), 1 explosive barrel spot per side and low platform, KillY
60 studs below the lowest platform, crumbling as above. Edge decor stays low so knockback carries
over it.

**Junkyard Isles arena** (dusk): a 96×96 scrap-heap centre island with a raised 28×20 scrap deck; a 40×56
shipping-container stack (east, "JOE'S SCRAP & SALVAGE"), a 44×44 car pile (west), a 48×40 crane barge whose crane arm
reaches over the centre (north) and a 56×36 barge (south); four 20×20 tire-stack ledges, two 18×18 tire towers (+12)
and two 28×28 junk rafts (low). Toxic green sludge below with junk mounds and floating barrels.
Structures: crushed car stack (HP 100) ×3, wrecked car (HP 100) ×2, scrap pile (HP 60) ×3.

**Neon Motel arena** (night): a 112×72 main motel roof with AC units, neon-trimmed parapets and a raised 28×18
roof-access deck; a 48×52 pool roof (east), a 44×44 roof under a giant flickering MOTEL / NO VACANCY sign (west),
52×40 and 48×40 lower roofs (north, south); a water-tower ledge, a billboard catwalk ledge and two vent-roof ledges;
two 18×18 antenna roofs (+12) and two 28×28 low roofs. Motel buildings sink into a flooded street below,
surrounded by dark towers with neon signs. Neon flickers now and then. Structures: vending machine (HP 80) ×2, ice
machine (HP 80) ×3, lawn chair stack (HP 60) ×3.

**Art & performance:**

- Low-poly retro post-apocalypse, fun and chaotic (not grim). Faded 80s/90s palette: rust orange, teal, dusty pink,
  off-white, neon accents. Materials: SmoothPlastic, Metal, CorrodedMetal, Concrete, Neon (sparingly). Chunky comic
  shapes.
- Late-afternoon dusk, orange sky, dusty haze (Atmosphere density ~0.35), light fog, faint toxic-green glow from below.
  Neon Motel is night. Lighting: **LightingStyle Realistic** (Roblox's Future look; owner, 2026-10-19;
  set in `default.project.json`): local lights light and shade properly; in the lobby the hanging and floor lamps cast soft shadows.
- Low draw calls (reuse meshes, no high-tri unions, CastShadow off on small props), cap 40 active props per arena,
  "Low Graphics" setting disables particles, post-effects and shadows (the sun's and the lobby lamps'). StreamingEnabled ON (target 256, min 128). Arena
  platforms use ModelStreamingMode = Persistent.

### 3.3 Combat rules

- **No NPC enemies.** Only the practice dummy, a developer-panel test target (stands still, shows Percent, respawns
  2 s after falling 4+ studs below its place or reaching 0 HP; anyone can hit it, also in the Lobby).
- **Classic:** 100 HP, 3 lives, 3 s respawn with 2 s spawn shield. Out of lives = spectate until round end.
- **Casual:** no HP, Percent shown above head and in HUD, unlimited respawns (unlimited lives), Percent resets to 0% on
  respawn.
- **Stamina** (everyone, every mode): 100. Running (×1.5 speed) costs 20/s while moving, a dash 25; it refills at
  30/s after 0.8 s without spending. Running stops at 0 and starts again at 20 if Run is still held. HUD bar above
  the bottom bar (orange below a dash's cost).
- **KO credit:** last player who hit you within 6 s before you fell.
- PvP always on in arenas, off in the Lobby. No friendly-fire exceptions (parties fight each other too). Fighters pass
  through each other (no body-pushing; dashes go through players).

**Props (grab & throw):**

- Grab range 6 studs (server-checked). Hold 1 prop. Holding replaces Punch with Throw and blocks charging.
- Throw speed 90 studs/s the way the character faces (owner's choice), with a slight arc under 25% gravity so long
  throws stay level, and a gentle aim assist toward a fighter within 15° (80 studs). Thrown and dropped props despawn
  8 s after landing. Max 40 props per arena.

| Class | Examples | Damage / Percent | KB scale | Carrier slow |
| --- | --- | --- | --- | --- |
| Light | chair, bucket, tire | 10 HP / 8% | 1.0 | none |
| Medium | crate, TV, barrel | 18 HP / 14% | 1.3 | 15% |
| Heavy | fridge, car door, vending machine chunk | 28 HP / 22% | 1.7 | 30% |
| Explosive barrel | — | 25 HP / 20% in 10-stud radius | 1.5 | 15% (explodes on impact or 3 s after being hit) |

- Getting hit while carrying drops the prop. A barrel's blast also hits its thrower, and lights other barrels in range.
- Breakable structures take damage from any attack (its Classic damage), thrown prop or barrel blast and break into
  2–4 random props from their drop table; drops nobody picks up vanish after 30 s.

## 4. Assets

### 4.1 3D (Studio AI generation, part-built models, or Creator Store)

- One server-side Combat module drives all styles; each style is a Config data entry (damage, reach, speed, hitbox,
  animations, sounds). Weapons are welded accessory models, not Tools (mobile buttons stay consistent).
- Weapons: baseball bat, shovel, wrench, hubcap shield (each < 1,500 triangles).
- Props: folding chair, wooden crate, tire, bucket, CRT TV, oil barrel, explosive barrel, fridge, car door, traffic
  cone.
- Structures: wrecked car, vending machine, road barrier stack, broken road signs, billboards.
- Launch cosmetics: 6 skins, 6 hats, 4 dash trails, 4 KO effects.

### 4.2 Animation (R15; Creator Store, Animation Capture, or scripted)

Punch chain jab/cross/uppercut (0.3 s each); charge wind-up + charged punch or swing (0.5 s); bat/shovel/wrench swings (0.45 s);
Dash lean (0.25 s); Grab crouch-lift (0.3 s) + carry idle/walk loop; overhead Throw (0.4 s); hit reaction / launched
tumble (0.6 s, loops in hitstun).

Built as **scripted** R15 poses (step 2.6): keyframed joint angles blended over Roblox's default walk / idle
animations on every client, triggered by the server when an action really happens. Weapon styles chain two swings
and an overhead smash (Scrapper's shovel sweeps low); the Wrecker's Ability is a parry pose with the hubcap; the
tumble backflips through the whole hitstun. Attacks wind up, strike with a small overshoot and hold; landed hits freeze attacker and
victim for a few frames (hit-stop); bodies lean into their movement, tuck up in the air, raise a guard when standing
still in a round, and recoil away from where a hit came from. Any clip can later be replaced by an uploaded
animation (Config.Animations.AssetIds).

### 4.3 VFX

Built in step 2.7, all drawn on the client (Config.Vfx). Hit sparks scaling with Percent (white → yellow → red); smoke
launch trail above 100%; comic "POW" KO starburst ("K.O.!" around the scorer for ring-outs) +
screen-edge flash; platform crumble (red edge, cracks, dust, debris); prop break (splinters / scraps / shards); retro
cartoon explosion with ring shockwave; dash streak and blue Perfect Dodge flash.

### 4.4 Sound (Creator Store audio)

- Built in step 2.8 as slots in Config.Audio (asset ids picked from free Creator Store audio; silent until filled).
- Music: Lobby retro synthwave; one gritty chiptune-rock track per arena; last-30 s tension layer; victory sting.
- SFX: punch / bat thwack / shovel clang / wrench bonk; grab, throw whoosh, smash (wood/metal/glass); KO boom + short
  crowd cheer; platform rumble/collapse; dash whoosh, Perfect Dodge chime; UI clicks, coin pickup, level-up fanfare.

## 5. UI / UX

### 5.1 Layout

AnchorPoint (0.5, 0.5), Scale coordinates (no fixed offsets), UIAspectRatioConstraint.

- **Mobile:** bottom-right arc — Attack (Punch/Throw; hold to charge), Ability (Wrecker only), Grab, Dash around Roblox's Jump button (≥ 64 px
  targets: 17% of the screen's shorter side, 64–104 px, Attack 1.15× larger; Settings > Button Layout picks the
  arrangement). Shown only while touch is the player's input. Bottom-center — own
  Percent (Casual) or HP bar + lives (Classic), held-prop icon, dash cooldown ring. Top-center — round timer, mode
  badge, players alive / score. Kill feed top-right (top-center is the timer and the vote panel). Left edge (Lobby
  only) — a coins + level / XP block, then Shop, Inventory, Styles, Settings, Quests (owner, 2026-10-19). Default thumbstick bottom-left.
- **PC:** same layout, touch buttons hidden, key hints next to HUD items and small light-grey hints along the
  bottom edge (lobby: Run, Menu and the walk-up prompt in reach; fighting: Punch / hold to charge, Scoreboard;
  spectating: switch fighter); bottom-right key panel (Run, Dash, the
  style's Ability) with keys and cooldowns, where touch players have their buttons; Tab = round scoreboard
  (replaces Roblox's player list).
- **Console:** same layout, menus navigable with GuiService.SelectedObject highlights, gamepad glyphs auto-swap.

### 5.2 Controls & camera

| Action | PC | Gamepad | Mobile |
| --- | --- | --- | --- |
| Move | WASD | Left stick | Thumbstick |
| Jump | Space | A | Jump button |
| Punch / Throw | Left Click | X | Attack |
| Charged punch | Hold Left Click | Hold X | Hold Attack |
| Ability (Wrecker parry) | F | Y | Parry |
| Grab / Drop | E | B | Grab |
| Dash | Q | RB | Dash |
| Run (stamina) | Hold Left Shift | Press left stick (runs until you stop) | Run button (tap: runs until you stop) |
| Scoreboard | Tab | D-pad Down | — |
| Menu | M | D-pad Up | — |

Third-person follow, zoom 8–30 studs (no first person), Shift Lock allowed on PC and toggled with Right Shift (Left
Shift is Dash). Camera shake on heavy hits (1 stud + 1.5° tilt, 0.35 s; toggle in Settings). Spectate camera cycles alive
players. Lobby players can watch a running round too (the "Game in progress" card under the menu → Watch).

### 5.3 Screens

Loading, Lobby HUD (coins + level block, left menu), Map vote, Round HUD, Results / MVP, Spectate, Shop (Daily,
Cosmetics, Robux), Inventory (the Locker renamed: cosmetics), Styles (the style roll), Daily Reward calendar + Daily Quests (one tab row),
Settings in tabs (Visual: camera shake, low graphics, button layout — camera sensitivity is Roblox's own setting;
Audio: music / SFX volume; Promo code; How to play), lobby leaderboard boards, Tutorial overlay, Purchase
confirmations, Developer test panel.

## 6. Technical rules

- **Server-authoritative:** server validates every action (distance, cooldowns, currency). Hit detection and knockback
  decided on the server; client predicts visuals only. Grab range, throw rate, dash and attack cooldowns all
  server-checked.
- **Safe data saving:** session locking + auto-save; never lose progress or duplicate items.
- **Cross-platform input:** every action on touch, keyboard/mouse, gamepad.
- **One Config module** holds every tunable (prices, HP, cooldowns, rewards, odds, formulas).
- **Filter player text** others can see via TextService (party names, any custom text).
- **Runs smoothly on low-end phones.**
- **AnalyticsService:** tutorial steps, purchases, currency earned/spent, round mode picked, round length, KOs per
  round, style used, map voted.
- **Developer test panel**, server-checked UserId allowlist in Config: give Scrap/XP, set level, unlock all
  styles/cosmetics, force map and mode, start/end round, trigger crumble, spawn any prop, set own or a player's
  Percent/HP.

## 7. Monetization

| Item | Type | Price | Contents |
| --- | --- | --- | --- |
| VIP | Game pass | 299 R$ | +25% Scrap, gold name tag + chat tag, exclusive gold dash trail |
| Scrap Pack S | Dev product | 49 R$ | 500 Scrap |
| Scrap Pack M | Dev product | 149 R$ | 2,000 Scrap |
| Scrap Pack L | Dev product | 399 R$ | 6,000 Scrap |
| Premium cosmetics / bundles | Dev product | 99–399 R$ | Skins, KO effects, trails. Launch: Inferno skin 149 R$, Lightning Trail 99 R$, Galaxy Burst KO effect 199 R$ |
| Style slot | Dev product | 99 R$ | One more style slot for the style roll (up to 4; 1 is free) |

- **Premium perks:** +10% Scrap, one exclusive Premium skin, Premium Payouts via engagement.
- **How it works (3.1):** the Shop's Robux tab lists the passes, Scrap packs and Robux cosmetics with their live price
  and a Roblox Premium card; each opens Roblox's purchase prompt, and the server grants what Roblox confirms
  (developer products once per purchase, confirmed only after the save). Pass and Premium items are owned while the
  player has the pass / Premium. VIP's gold name tag reads "[VIP] name" over the head and its chat tag is a gold
  "[VIP]" prefix. Ids live in `Config.Monetization` (0 = not created yet: "Coming soon").
- **Private servers:** 100 R$/month. Owner can lock mode, pick map, set round length (2:00, 3:00, 4:00 or 5:00) from a
  Server menu that only they see; the choices are saved with the owner and apply from the next round. Private servers
  are for play and testing only (owner, 2026-10-17): no Scrap, XP / levels or lifetime stats are earned there
  (everyone is told when they join); Robux purchases and the Shop still work. Rounds still need 2 players on the
  join pad.
- Nothing sold for Robux gives a combat advantage. Paid random items must show all outcomes and odds (none at launch).
  PolicyService hides paid random items / paid trading where not allowed and respects other policy flags (read once
  per player; unknown = not allowed; external links only where `AllowedExternalLinkReferences` lists the site).

## 8. Retention & social

- **Onboarding (first 2 min):** *to be redesigned* — the Training Yard it used (move → punch dummy → knock it off a
  ledge → grab a chair and throw it → dash across a gap) was removed with the lobby rework (2026-10-16). Still
  planned: reward 200 Scrap + "Rookie" title, returning players skip (replay button in Settings), first round: tips
  for grabbing and dashing.
- **Lobby spin wheel (owner, 2026-10-19):** a wheel on the lobby's west wall. 1 free spin a day (00:00 UTC), more
  for 200 Scrap ("Coins") each where Roblox allows paid random items. Prizes and exact odds (shown before every spin):
  50 Coins 30%, 150 XP 15%, 100 Coins 20%, a free style spin 10%, 250 Coins 12%, a random cosmetic not owned yet 5%
  (500 Coins if every Scrap cosmetic is owned), 500 Coins 6%, 1,000 Coins 2%. The wheel in the lobby turns for
  everyone and lands on each spin's prize. No screen (owner, 2026-10-20): every slice shows its prize and exact chance,
  you spin with the big red button in front of the wheel (a paid spin is held 1 s), one spin at a time, and the
  winner's slice blinks. Nothing in private servers; declared on the maturity questionnaire.
- **Login streak (7 days):** 50 / 75 / 100 / 150 / 200 / 250 Scrap, Day 7 = weekly rotating cosmetic (one of the
  cosmetics sold for Scrap, the same for everyone that week; 300 Scrap instead if already owned). Missing a day
  resets to Day 1. Claimed on the Daily reward screen (it opens by itself when a reward is waiting, and is a tab of Quests).
- **Playtime:** +25 Scrap every 10 minutes online (AFK time doesn't count; kept across rejoins that day), up to 6
  times per day.
- Daily and playtime rewards are not paid in private servers (play and testing only).
- **Quests:** 3 daily (75–150 Scrap each, e.g. "KO 5 players with a chair", "Win 1 Classic round", "Perfect Dodge 10
  times", "Break 8 structures"), 1 weekly (600 Scrap). Reset 00:00 UTC (weekly: Mondays). Each player gets their own
  3 of the 7 daily quests (the same all day); progress counts by itself and the Scrap is paid the moment a quest is
  done. Quests screen in the left-edge menu and at the lobby's quest board. Nothing counts in private servers.
- **Badges:** *(skipped for now by the owner, 2026-10-17)* Welcome, First KO, First Win, Ring-Out Rookie (100 ring-outs), Chair Master (50 chair KOs), Demolition
  (500 structures), Survivor (win Classic without losing a life), Level 10 / 25 / 50 / 100.
- **Leaderboards:** global all-time and weekly Wins, KOs, Level (OrderedDataStore; weekly Level = levels gained that
  week; weeks start on Monday); in-server scoreboard; lobby billboards (top 10, switching between all-time and this
  week); no Leaderboard menu screen (owner, 2026-10-19). Scores from private servers are not saved.
- **Social:** friend bonus +10% XP per friend in server (max +30%), group join reward 150 Scrap + group chat tag
  ([Crew]; the Scrap is paid once, in a public server). The party system was built in 3.7 and removed on 2026-10-19
  (owner). No reward for liking or favoriting the game (Roblox doesn't allow it).
- **Codes & events:** one-use codes validated on the server (stored in the server-only ServerConfig; Scrap and / or
  a cosmetic, optional expiry; redeemed on Settings' Promo code tab or at the lobby jukebox; not in private servers); seasonal map remixes, double-Scrap
  weekends, event-only cosmetics.

## 9. Build plan

- **Phase 1 — Core loop playable:** Config, data saving, Lobby blockout, Broken Highway, movement + Punch + charged punch +
  Dash, knockback/Percent, Classic and Casual rules, round manager (vote → round → results), grab/throw props,
  breakable structures, crumbling platforms, basic HUD on mobile/PC/gamepad.
- **Phase 2 — Progression & content:** Scrap/XP rewards, levels and ranks, 3 extra styles, cosmetics + Locker, Shop
  with daily rotation, Junkyard Isles + Neon Motel, VFX/SFX pass, animations, tutorial + first-round tips.
- **Phase 3 — Monetization, retention & polish:** game passes, dev products, private server settings, Premium perks,
  daily rewards, quests, badges, leaderboards, party system, codes, analytics, developer panel, low-end performance
  pass, localization check.
- **Launch checklist:** icon, thumbnails, description, maturity questionnaire, trailer/teaser, social links, private
  beta with 10+ players, mobile test (small phone + tablet), console navigation test, DataStore stress test
  (rejoin/server hop), launch code ready.

## 10. Agent workflow

- Before building, inspect the place and propose a build order; wait for approval.
- One feature at a time. After each: playtest, check Output, fix all errors before moving on.
- Check visuals/UI with screenshots; test mobile layout with device simulation.
- Studio AI generation or free Creator Store assets only; ask before any paid asset.
- Never delete or replace large parts of the place without asking.
- After each step, explain in plain language what changed and what to test.
- Keep CLAUDE.md as the progress log (done / next / known bugs).
- GitHub automation: every change goes through a PR that auto-merges when CI is green.
