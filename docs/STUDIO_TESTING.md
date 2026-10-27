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
  studs; press E (gamepad B, or tap it) and the Shop opens. Same at the style coach (south-east corner) for the
  Styles screen and at the quest board (south wall) for the Quests. The
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
- **New lobby layout (2026-10-27):** the room is 98 × 72. Spawn: you land beside the ARENA door and join pad (south
  wall, opposite the bar). Check: the three leaderboards in the middle of the east wall fill in (Wins, KOs, Level from
  left to right); the style coach stands in the south-east corner by the jukebox in a red tracksuit (Output
  `[Npc] built the Coach`) and his prompt opens Styles; the spin wheel (back on the west wall) spins and lands on the
  prize it says; the chess table's armchairs (north-east, on the bar's wood
  floor) seat both players and a game starts; three booths and the high tables can be sat at. The old locker booth and
  codes jukebox are gone (Inventory and Promo code from the menu); the jukebox by the teal barrel is decor.
