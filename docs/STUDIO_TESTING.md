# Studio testing notes

How to test each system in Studio, debug switches, playtest history and known limits. Written when each feature was
built, so the oldest notes may name screens that have moved since (the Locker is the Inventory, codes are on
Settings → Promo code, styles come from the style roll).

- **1st playtest (2026-10-16), owner's notes:** couldn't grab/throw props (fixed: see [DECISIONS.md](DECISIONS.md)), hits felt delayed
  and walking into players "stacked" pushes (windups cut, fighters no longer collide), dash too far (12 studs now),
  camera shake not noticeable (stronger + tilt), crumbling looked funny (client-drawn now), barrels worked. An orange
  "asset is not approved for the requester" warning (rbxassetid://135644804609151) is not from our code (no asset
  ids in `src/`); most likely an item on the tester's avatar. To re-check after the fixes: grab + throw, hit feel,
  crumble look, camera shake. Remaining hit delay seen by the attacker is mostly Roblox replication of the victim's
  client-simulated movement (victim → server → attacker); a server-owned launch is the next lever if still too slow.
- **Knockback tuning:** `Config.Combat.Knockback` (force), `Launch.MaxTime`, `Hitstun`. Exploiters can ignore
  knockback on their own character (clients simulate it — a Roblox limit); server-side movement checks are a later
  hardening task.
- **Rounds in Studio:** `Config.Dev.StudioMinPlayers = 1` lets a round start with you alone: stand on the join pad by
  the ARENA door (vote → arena → results → walk back to the pad ...); stay off it to remain in the lobby. Output
  shows `[Round]` lines (state changes, KOs, joins, winner). PvP needs two players: Test > Clients and Servers >
  2 players. A solo Classic round ends when you lose your 3 lives; a solo Casual round runs the full 4:00.
- **Studio combat debug:** `Config.Dev.LogCombat` prints every hit and KO; `Config.Dev.ShowHitboxes` flashes each
  attack box (red hit, grey miss). Studio only.
- **3.1 playtest (2026-10-17, Studio logs):** every perk toggle granted and took back its items, products gave Scrap /
  items, the Robot emote played after a round, no errors from the new code. Found in the logs: CameraController.Init
  failed on every client since 1.5 (`DevEnableMouseLock` can't be set by a LocalScript), which stopped the camera
  shake from ever binding — the 1st playtest's "camera shake not noticeable" was this, not the strength (now fixed:
  re-check how strong it feels). The place was on legacy chat (`ChatVersion` 0, its ChatScript errors in Studio);
  the project now sets TextChatService, so after `rojo serve` syncs it **save the place**. Not ours: the
  `rbxassetid://203785492` "asset type does not match" warning (not in `src/`, `maps/` or the place: likely an avatar
  item), UIBlox `FoundationProvider` and `RoundedCorner8` StyleRule warnings (Roblox's own UI).
- **Robux items need the owner:** create the VIP (299 R$) game pass and the 7 developer
  products (Scrap Pack S / M / L 49 / 149 / 399 R$; Inferno 149, Lightning Trail 99, Galaxy Burst 199; Style slot 99) on the Creator
  Dashboard, then put their ids in `Config.Monetization`. Until then the Shop shows "Coming soon" and the VIP bonus
  is off (Premium and friend bonuses already apply). Studio test: dev panel → Robux → "VIP on/off" (Gold Trail in
  the Locker, +25% Scrap; the gold name tag shows to *other* players: 2-player test), product buttons (Scrap or the
  item, and a notice). Output shows `[Monetization]`. Switching a perk off — or joining without it — takes its items
  back, including ones the dev "All cosmetics" button granted. In Studio, rewards are paid from solo rounds too
  (Output: `[Rewards]`).
- **All screens are plain first versions** (`src/client/Ui/Kit`: HUD, vote, results, spectate bar, scoreboard); the
  art / VFX passes restyle them. The lobby's CRT-TV vote screens from the bible are an art-pass item. The dash ring
  fills bottom-to-top (a true radial ring needs an image asset).
- **Props and structures are detailed** (since 2026-10-20, `Shared/ItemShapes`): the box from `Config.Props.Types` /
  `Config.Structures.Types` still does all the colliding and turns invisible; every prop and all seven structure types
  have their look. A lit barrel glows, explosions are a client-drawn cartoon blast (2.7). Carry pose and throw animation
  are scripted clips (2.6). Flights are simulated by the server (props are server-owned while flying), so throws
  look slightly delayed on high ping.
- **Camera sensitivity** is saved and validated but not used or shown: Roblox does not let scripts change mouse /
  gamepad sensitivity, so the Settings screen points players to Roblox's own menu (3.10). A custom camera input (a
  forked PlayerModule) would be the only way to offer it in-game.
- **Studio input debug:** `Config.Dev.LogInput` prints every action and device change to Output in Studio playtests.
  Test touch with Studio's Device Emulator (a phone in landscape).
- **Developer panel (Studio):** press ` (Backquote, `Config.Dev.PanelKey`) or click DEV (top left). Round: start now
  (starts the vote with one player on the join pad, or closes it), end now, crumble a platform; next map / mode (or
  back to the vote); spawn any prop or the practice dummy in front of you; set your own Percent (0 / 100 / 200) or
  HP (100 / 50 / 10); own + equip any fighting style, all styles, every cosmetic; +5000 Scrap, +1000 XP, set level;
  switch VIP / Premium on or off and get any Robux product; daily / quest / code tests; test camera shake
  and switch the Camera Shake / Low Graphics settings. "Target: Me" at the top: tap it to act on another player (2-player
  test). Output shows `[Dev]` lines (with "on <player>" for a target).
- **Data in Studio:** with "Studio Access to API Services" off — or while the place isn't published to Roblox (the
  owner's place wasn't on 2026-10-18: "You must publish this place to the web to access DataStore") — ProfileStore uses
  an in-memory store and prints "Roblox API services unavailable - data will not be saved". Publish the place (File →
  Publish to Roblox) and turn API access on to test real saving
  (`Config.Data.UseMockInStudio = true` forces the in-memory store even with access on).
- **Arena gaps** of 8.5–12 studs (all three arenas) need a jump + air dash (1.7); worth confirming every gap in the
  playtest, and the 6-stud climbs: base → ledges, ledges → peaks (diagonal gaps 8.5–10) and lows → sides. Neon Motel is the first night map: check it is not
  too dark (Night preset + neon).
- **Perfect Dodge feedback:** the blue flash and "PERFECT!" pop-up came with 2.7; the chime comes with 2.8. Studio's
  Output shows `PERFECT DODGE`. Rounds count them (stat + standings); the +5 Scrap is paid with round rewards (2.1).
- **Dash movement is client-side** (clients simulate their character), so the once-per-jump air rule is enforced by
  the client; the server enforces the cooldown and hitstun, which gate the invulnerability and Perfect Dodge.
- **Owner's Roblox UserId** is needed for `Config.Dev.AllowedUserIds` before live testing of the developer panel.
- **Settings test (Studio):** the loading screen shows on Play (title, a tip, "Loading...") and fades out once you
  load. Settings (left menu): − / + change music / SFX volume (hear it once audio ids are set), Camera shake and Low
  graphics switch On / Off and stay after rejoining (with saving on); How to play shows the rules and your controls.
- **Codes test (Studio):** Settings (menu) → Promo code tab → type `launch` → +250 Scrap;
  again → "already used"; a made-up code → "doesn't exist". Dev panel → Daily → "Reset codes" to use it again. Output
  shows `[Codes]`.
- **Group perks** need a group: put its id in `Config.Retention.Group.GroupId` ([Crew] chat tag, one-time 150 Scrap).
- **Leaderboards test (Studio):** with API access off the boards say "this server only" and list you from your stats
  (lobby screens on the south wall); play a round and they update within 2 min. With
  "Studio Access to API Services" on, scores are saved to the real boards. Output shows `[Leaderboards]`.
- **Quests test (Studio):** open Quests (menu or walk up to the quest board, west wall): 3 daily quests and the weekly
  one at 0. Play a solo round — KOs, falls and rounds finished count (`[Quests]` in Output when one completes, with a
  notice and the Scrap). Dev panel → Daily → "Finish quest" completes the next one; "Next day" starts the daily ones
  over.
- **Daily rewards test (Studio):** on join the Daily reward screen opens with Day 1 waiting: Claim → +50 Scrap.
  Dev panel → Daily → "Next day" then Claim again for Day 2 ... (Day 7 gives this week's cosmetic); press "Next day"
  twice before claiming to see the streak reset. "+10 min" pays a playtime reward (notice) up to 6 a day; real
  playtime pays every 10 active minutes. Output shows `[Daily]`.
- **Private server test (Studio):** dev panel → Round → "Private on/off": a notice says nothing is earned there, and a
  **Server** button appears on the left. Lock the mode / pick the map / pick 2:00, then stand on the join pad: the
  vote offers only your choices and the round timer starts at 2:00; `[Rewards]` in Output pays nothing and stats don't change. Rejoin and turn
  it on again: your choices are remembered (with Studio API access on). Output shows `[PrivateServer]`.
- **Walk-up test (Studio):** walk to the bartender behind the bar counter (north) — a "Shop" prompt shows within 12
  studs; press E (gamepad B, or tap it) and the Shop opens. Same at the style coach (by the jukebox) for the
  Styles screen and at the quest board (by the ARENA door) for the Quests. The
  prompts disappear while a screen is open. If the bartender's prompt is hard to reach from the counter, the range
  is `Config.Controls.Prompts.MaxDistance`.
- **Animations are scripted poses** (2.6), tuned blind: angles may need flipping or softening after the first
  playtest (e.g. an arm swinging the wrong way). Real animations can replace any clip later via
  `Config.Animations.AssetIds` (made in Studio's Animation Editor or free Creator Store ones).
- **Shop test (Studio):** dev panel → "+5000 Scrap" → Shop: buy a daily deal (20% off), a style (then Equip), check
  the Scrap chip drops; buying something you own or can't afford is refused with a message. Output shows `[Shop]`.
- **Audio ids are all 0 (silent).** To hear music and sounds: Studio → Toolbox → Audio (free Creator Store audio), right-click a
  sound → Copy Asset ID, paste it into the matching slot in `src/shared/Config/Audio.luau` (or send the ids to Claude).
  Bible: lobby retro synthwave, a gritty chiptune-rock track per arena, a tension layer, a victory sting.
- **Less-luxury lobby (2026-10-27):** after `rojo serve` picks up the new `Hideout.rbxmx`, look at the lounge, the bar
  and the booths: iron instead of gold, wood instead of marble, a concrete floor. The concrete is darker than the old
  light carpet, so check the room isn't too dim (raise a pendant's range or brightness in `maps/layouts/Hideout`, or
  the Dusk preset's `Ambient` in `Config.Lighting`, if it is).
- **New lobby layout (2026-10-27):** the room is 98 × 72; left / right below are as you face the bar. Spawn: you land
  in the middle of the room facing the bar, with no plate under you; coming back from a round several players land
  spread over the spawn, not on top of each other. Check: the three leaderboards in the middle of the
  left wall fill in (Wins, KOs, Level from left to right) and their rows fit the smaller boards, and the pool
  table in front of them doesn't hide the rows; the arm-wrestling table stands in front of the quest board; the
  style coach stands left of the ARENA door by the
  jukebox in a red tracksuit (Output `[Npc] built the Coach`) and his prompt opens Styles; the spin wheel (right wall)
  spins and lands on the prize it says, with open floor in front of it; the
  chess table's armchairs (right side of the bar floor) seat both players and a game starts; all three booths
  seat six and the high tables can be sat at. The old locker booth and codes
  jukebox are gone (Inventory and Promo code from the menu); the jukebox is decor.
- **Lobby lighting and detail (2026-10-28):**
  - *The bar:* it should look a little dimmer at the counter and noticeably dimmer on the back bar behind the
    bartender.
  - *The concrete floor:* lit by six green ceiling lamps. If it is too dark or too bright, change the `F.ceilingLamp`
    range / brightness in `ceiling()` in `maps/layouts/Hideout`. For the bar, change the counter lamps' `F.pendant`
    values.
  - *The platform:* the bar end is now a raised platform. Walk up the two steps in the middle and check you don't get
    stuck on them. Check the railings either side block you, the bartender stands on the platform behind the counter
    (his Shop prompt still shows), and the stools, booths, high tables and the chess armchairs all still seat you.
  - *The fans:* the two fans over the concrete turn slowly (Output: `[Movers] CeilingFan1: Spin`), on a second client
    too.
  - *New decor:* the boarded windows glow with the dusk, plus the brick patches, the two posters (readable titles),
    the fuse box by the street door, the arcade cabinets (left wall by the teal barrel, right wall next to the wheel),
    the air duct and pipes, and the floor slabs with stains and a drain.
  - *Low Graphics:* it turns the ceiling lamps' shadows off.
  - *Gloomier (same day):* the room should feel dim, with warm pools of light under the lamps and the neon standing
    out. If it is too dark to see players or the floor, raise `Ambient` in the `Dusk` preset (`Config.Lighting`) a
    little first; if only one area is too dark, raise its lamps instead.
- **Town, the only arena (2026-10-28; Small City until the owner asked for the Jujutsu Shenanigans look, then Shinjuku
  until 2026-10-30):** the older entries below say Shinjuku; it is the same arena.
  - *If no round starts* and Output says `[Maps] Town is enabled but ServerStorage.Arenas has no Town model`: stop
    `rojo serve` (Ctrl+C), start it again and click Connect in the Rojo plugin (the map's file is new: Shinjuku became
    Town). `ServerStorage.Arenas` should hold Town plus the three old arenas, and no Shinjuku model (delete a leftover
    one if the place still has it).
  - *Starting a round:* stand on the join pad. The vote shows one map, Town, and the round loads it on a sunny day.
  - *Where you are:* a Tokyo street block. The main street runs along the north edge; south of it stand the twin
    towers either side of the avenue, the skybridge between them.
  - *Fighting:* props respawn on their spots (some on the roofs, the skybridge and the cafe) and you can throw them,
    and breakables (vending machines, wrecked cars, the ice machine by the mart, a barrier stack) break and drop
    props. A life ends at 0 HP or by falling off the edge. Check that rounds still end: the last one standing, or
    most KOs at time-out.
  - *Climbing (ladders are Roblox trusses: walk into one to climb):* the towers' outside ladders go up to their roofs
    (or walk up inside); also the arcade and mall roofs, and the cafe's stair to its roof.
  - *The edges:* open, with no walls (see below).
  - *Look:* the towers' billboards (CURSED COLA, TOKYO NIGHTS), the utility poles and wires, crosswalks, the shop
    row's signs, the graveyard, the purple jail with its barred cell, the courthouse columns, the cherry trees.
  - *Old arenas:* Broken Highway, Junkyard Isles and Neon Motel are still in `ServerStorage.Arenas` but never voted
    for. To play one again, set its `Enabled = true` in `src/shared/Config/Maps.luau`. The developer panel's map list
    shows only enabled maps.
- **Breakable walls and walk-in buildings (2026-10-28):**
  - *Walls:* punch a building wall about four times and it breaks. Glass goes in one punch, and a thrown prop or a
    barrel breaks walls too. The next round brings them all back.
  - *Buildings:* walk into the towers (ramps up to the roof, the skybridge on the 9th floor), the cafe, ramen shop,
    mart, arcade, mall, bowling alley, shops, jail, comedy club, court and mansion.
  - *Trash cans:* they stand on the main street and by the mart and shops; grab one and throw it.
  - *Check:* headroom inside (storeys are 7), frame rate on a phone (the arena is about 3,500 parts), Output
    `[Walls] N breakable wall pieces` with `Config.Dev.LogCombat`.
- **Open edges, no school strip (2026-10-28):** the school, gym, schoolyard and shrine are gone; the district ends a
  short pavement past the main street (north), and you spawn on the streets and in the plaza.
  - *Falling:* walk or get knocked off any edge (also off a tower roof toward the edge): you fall past the cliff into
    the dark mist and lose a life (the kill feed shows a fall, and the last attacker gets the KO).
  - *Check:* no invisible wall anywhere along the edge; nothing to land on below; props thrown off the edge disappear
    and respawn on their spots.
  - *Look:* from the edge, the soil and rock face under the street going down into the mist (no gap between the
    street slab and the rock). The arena is about 3,400 instances now.
- **Shinjuku built up and furnished (2026-10-28):** every block off the streets and the plaza now has buildings.
  Where things are, with north (+Z) as the main street:
  - *Moving parts (watch them turn, and ride them):*
    - *Glass lifts:* on the towers' north faces (by the doors onto the main street). Stand on one and it takes you to
      the roof in about 11 s, waits, then comes back down. You step off over the low roof wall.
    - *Building site (south-east corner):* the hoist on the steel frame's east side goes up to the 24 deck. The crane
      jib turns once a minute; climb the yellow mast (a truss) and jump onto the jib.
    - *Department store roof (south-west, behind the shops):* the Ferris wheel turns (walk-through decor). The carousel
      turns too: stand on it and you ride round.
    - *Pachinko parlor roof (north-west, by the west tower):* the sign spins.
  - *Inside:* walk through every building. Each one has furniture on every floor:
    - The towers' offices, the karaoke booths, the hotel rooms.
    - The yokocho's tiny bars (doors off the lane; its stair is at the row's west end).
    - The car park's decks with cars, the department store's floors, the fire station's engines and bunks.
    - The jail's cells, the club's tiered seats, the apartments' flats.
    Punch a partition: it breaks like a wall.
  - *Climbing:* ladders onto the gas station's canopy, the yokocho's roof, the fire station's drill tower, the water
    tower, the parking rack, the site office and the steel frame's levels. The pagoda's eaves step up. The gangway
    goes from the car park roof to the karaoke tower's roof; the deck over the apartments' lane has a ramp from the
    side street.
  - *Check:*
    - Nothing in a doorway or on a stair.
    - Props land on the car park's 2nd deck, the department store's 2nd floor and roof, the hotel roof and the site's
      first deck.
    - Frame rate, especially on a phone: about 6,600 instances, up from 3,400.
- **Shinjuku sized to the avatar, more throwables (2026-10-28):**
  - *Size:* walk through doors and up stairs with your own avatar, and a tall body type if you have one.
    - Doors are 8 high, ceilings 9.5 and stairs 3.5–4 wide, so your head never touches a doorframe.
    - Cars, trees and poles look life-size next to you, and the wrecked car you can break is as big as the parked ones.
  - *Throwables:* 72 spots now (about 60 more props in a round). Each place has its own:
    - Stools and lanterns in the ramen shop and the yokocho.
    - Speakers in the karaoke booths.
    - Bowling balls and a pin in the bowling alley.
    - Baskets in the mart and the shops, mannequins in the mall and the department store.
    - Suitcases in the hotel, gas cans at the pumps.
    - Office chairs and plants in the towers.
    - Cinderblocks and cones at the building site.
    Grab and throw a few: each has its own look (no grey boxes).
  - *Check:* every spot fills at round start (up to `Config.Props.MaxActive` = 80). Also check that the frame rate
    holds with that many props.
- **Shinjuku detail and polish (2026-10-28):**
  - *Look at:*
    - the buildings' ledges at each floor and the cornices at the roofs; the lights glowing under every ceiling
      inside;
    - the AC units on the flats' balconies and the hotel's side wall; the neon corner signs; antennas and dishes on
      the roofs;
    - the street lamps, the traffic signals over the crossings, road signs, hydrants, post boxes, the plaza's
      bollards, the banners outside the ramen shop and the yokocho, the phone booth by the police box;
    - the yellow line along the map's edge.
  - *Check:*
    - Nothing new blocks a doorway or a pavement you run along.
    - Ledges and cornices don't cross a window or a door.
    - The frame rate holds, especially on a phone: about 7,600 instances, up from 6,600.
- **Shinjuku less blocky, more inside (2026-10-28):**
  - *Outside:* look at the window sills, the corner columns, the plaster and brick walls, the tiled eaves along the
    yokocho, the red tile roof on the mansion, the court's pediment and the paler pavements. Break a wall under a
    window: its sill goes with it.
  - *Inside:* walk through every building. Look for the office cabinets and whiteboards, the hotel's nightstands, the
    flats' kitchens and TVs, the karaoke screens, the goods on the mart's shelves, the bars' bottle shelves, the stage
    lights and the temple's candles.
  - *Check:* the frame rate on a phone (about 8,500 instances now).
- **Shinjuku: more arena detail (2026-10-28):**
  - *Look at:*
    - the stop lines and drains on the roads; the delivery vans on the side streets;
    - the scooters by the mart and the shops, the bicycles by the plaza; the new trees, benches and vending machines;
    - the drainpipes, the yokocho's projecting neon signs, the murals on the bowling alley;
    - the billboards on the shop row, mart and arcade roofs; the curtains in the hotel's and flats' windows;
    - the plaza's clock and sculpture, the umbrellas on the lane deck, the temple's rope, the jail yard's hoop, the
      site's green net and floodlight.
  - *Check:*
    - The road dashes don't cross a crosswalk.
    - The vans and vending machines don't block a doorway or a pavement you run along.
- **Shinjuku: more detail (2026-10-28):**
  - *Look at:* the fins up the towers and the hotel, the lantern strings over the main street, the planters on the
    balconies, the goods racks outside the shops, the hedges and jets in the plaza.
  - *Check:* ride a tower lift and make sure no fin passes through it. Watch the frame rate, now close to 9,000
    instances.
- **Shinjuku: ten times the detail, streamed (2026-10-29):**
  - *Look at:* the fountain in the plaza (three tiers, water curtains, four spouts; wade into the basin), the café
    tables, sofas, beds, desks and vending machines, and the counters, kitchens, shelves, TVs and toilets inside the
    buildings. Compare them with the lobby's furniture.
  - *Streaming:* in a round, look across the district: far buildings may show as simple stand-ins and fill in as you
    get closer. Nothing should be missing near you, and spawning on a roof should never drop you through it.
  - *Phones:* play a round on a phone (or Studio's device emulator with Low graphics) and watch the frame rate; the
    arena is now about 13,900 parts. If it stutters, tell Claude which place: the dress pass can skip upstairs rooms.
- **Shinjuku art (2026-10-30):**
  - *Look at:* the CURSED COLA and TOKYO NIGHTS billboards on the towers' south faces, the three roof billboards (the
    cola one, TOKYO NIGHTS, DEMON RAMEN), the three murals on the bowling alley's street wall (a wave with koi, a
    tiger and an oni, a neon city), and the posters on the blank walls (the yokocho's back, the shops' backs, the
    jail's yard side, the walls facing the south drop).
  - *Check:* each picture fills its board, the right way up, with nothing important cut off; each headline is easy to
    read across the top of its billboard. A blank board means Roblox hasn't served the image: say which one.
- **Spawns bring the fight together (2026-10-30):**
  - *Start:* run a round with 2 players (Test → Clients and Servers → 2). Both should start a street or so apart,
    not at opposite ends of the district. Run a few rounds: the meeting place should change each time.
  - *Respawn:* get knocked out while the other player stands still. You should come back about 40–130 studs from
    them (a short run, not on top of them). With `StudioMinPlayers = 1` (alone) you respawn anywhere.
- **VFX from ReplicatedStorage.Assets (2026-10-30):**
  - *Setup:* restart `rojo serve` (a new file in `default.project.json`), then check the Explorer shows
    `ReplicatedStorage.Assets.VFX` with its templates.
  - *Look at* (they should look as before): hit sparks and the impact flash, the smoke trail behind a fighter launched
    hard, the POW / K.O.! starburst, an explosive barrel's fireball, ring and smoke, a structure breaking (chunks and
    dust), the PERFECT! text on a Perfect Dodge, the dash streak, and a dash-trail cosmetic's colours.
  - *Check:* no errors in Output mentioning `Assets` or `VFX`.
- **More on the streets (2026-10-30):**
  - *Look at:* walk the main street, the second street and the avenue: yellow tactile paving along the pavements
    (pads at the crosswalks), a diamond and an arrow in each lane before a crossing, patches and puddles near the
    kerbs, white guardrails at the corners, cabinets, planters, ashtrays and hydrant signs by the kerb, and a blue
    sign gantry over each of the three streets.
  - *Check:* every crosswalk is open at both ends (no guardrail across it); you can still get from the road onto the
    pavement between the corners; nothing blocks a shop door; props and spawns on the streets are clear.
- **Rooftop gear (2026-10-30):**
  - *Look at:* from a tower roof (ladder or lift), the roofs below: condensers, vents, skylights, solar panels, ducts
    and exhaust fans along the edges, seams across the big roofs, lightning rods on the tall ones.
  - *Check:* climb up every ladder and ramp onto a roof: nothing blocks the top. Props on roofs land in the open
    middle. Ride a tower lift to the roof: it never passes through anything.
- **Models from ReplicatedStorage.Assets (2026-10-30):**
  - *Look at* (they should look as before): props in the arena and lobby (chairs, trash cans, TVs, barrels …) sitting
    whole on their spots, their detail parts on the box, not left at the map's centre; pick one up, throw it, watch
    the details stay on. Breakable structures (vending machines, wrecked cars …): whole, they darken as they are hit,
    they break. A lit explosive barrel glows.
  - *Worn:* equip a style with a weapon (bat, shovel …) and a hat and back item from the Inventory: each sits on the
    hand / head / back and moves with the character; switching or unequipping replaces or removes it.
  - *Check:* `ReplicatedStorage.Assets.Models` has Props, Structures, Weapons and Cosmetics; no Output errors.
- **Sounds and animations from ReplicatedStorage.Assets (2026-10-30):**
  - *Now:* every audio slot and uploaded clip is empty, so `Assets.Sounds.Sfx`, `Assets.Sounds.Music` and
    `Assets.Animations` are empty folders and the game stays silent, with scripted poses. No errors in Output.
  - *Once ids are in:* put an id in `Config/Audio.luau` (e.g. `Click`), run `lune run assets/build`, and the
    template appears; menu buttons click, a little higher or lower each time. Music fades between lobby and arena.
- **Menus in the slate palette (2026-10-30):**
  - *Look at:* the loading screen, then each lobby menu (Shop, Inventory, Styles, Settings, Quests, the Daily
    reward): dark slate panels with an orange outline, slate buttons, the open tab and chosen items orange with dark
    text. The coins / XP block on the left: the XP number readable over the orange fill. In a round: the HP and
    stamina bars, the mode badge (dark text on orange), and on a phone (or the device emulator) the touch buttons.
  - *Check:* no menu keeps the old warm brown; no white text sits on orange.
- **Shinjuku buildings less blocky (2026-10-30):**
  - *Look at:* any building's windows from the street: a frame head on top, a sill below, glazing bars dividing the
    glass, the glass set back in the wall. The towers' faces should read as bands (dark strips between the window
    rows); other buildings have a slightly darker strip above and below their windows, a dark stone band along the
    foot, and a light cap along the roof edge.
  - *Check:* break a window and the wall above one: the glazing bars and the head go with them (nothing left
    floating). Walk through a doorway: no base course across it. Watch the frame rate on a phone (about 16,100
    parts now).
