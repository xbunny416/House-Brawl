# Decisions and interpretations

In the order they were made; a later entry overrides an earlier one (e.g. parties, victory emotes and the level
unlocks were removed later). Add new decisions at the end.

Where the bible is silent or ambiguous, these choices were made (all are Config values unless noted):

- **Placement rewards:** 1st place gets Win (+50/+100); 2nd–3rd get Top3. `Economy.WinnerAlsoGetsTop3` flips this.
- **Participation:** the 60 s rule covers the completion reward too, and only non-AFK time counts. AFK at round end
  pays nothing. KO and Perfect Dodge Scrap are paid regardless of time played.
- **Bonus cap:** VIP + Premium apply to Scrap, the friend bonus to XP; each currency's bonus is capped at +60%. The
  live-event multiplier (double-Scrap weekends) and the private-server scale (0 since 2026-10-17: private servers pay
  nothing) are applied outside the cap.
- **Codes** live in the server-only `ServerScriptService.Server.ServerConfig` (not the shared Config) so clients
  cannot read unreleased codes. `LAUNCH` (250 Scrap) is a placeholder. **3.8:** a code gives Scrap and / or a cosmetic
  and may expire (`ExpiresAt`, unix time); keys are upper-case letters and digits (a spec checks every code). What the
  player types is tidied (spaces dropped, upper-case) and checked by the pure `Server/Codes/CodeRules`; used codes are
  saved per player (`Codes`), so each works once. `RedeemCode` is a RemoteFunction limited to 24 characters and one try
  every 2 s (burst 3) against guessing. Nothing is given in private servers (the code stays unused). Scrap is logged as
  Gameplay, sku `Code.<CODE>`, plus a `CodeRedeemed` event. Codes are typed on the Settings screen's Promo code tab
  (a Codes screen until 2026-10-19), which the lobby's jukebox opens (`LobbyPromptController` target).
- **Structures** take each attack's Classic HP damage in every mode.
- New tunables not in the bible: attack windups (Punch and charged punch 0.05 s since the 1st playtest, needed for "dodge
  before the hit lands"), punch chain reset 1 s, hitbox latency padding 0.5 studs, launch angle 30°, throw arc +14 studs/s, throw
  cooldown 0.5 s, grab cooldown 0.3 s, results screen 8 s, minimum 2 players to start a round, platform fall 4 s.
- Robux prices in Config are reference only; live prices come from the Creator Dashboard. Pass/product/badge/group
  ids are 0 until created.
- **Controls (1.5):** Shift Lock toggles on Right Shift only (Left Shift is Run since 2026-10-17; it was Dash), by rewriting the `BoundKeys` value of
  Roblox's MouseLockController at runtime. Whether Shift Lock may be used at all (`ShiftLockAllowed`) is set by the server
  (`StarterPlayer.EnableMouseLockOption`, SettingsService). Camera zoom 8–30 studs (8 keeps it third-person; bible only gave max 30).
  Mobile buttons are placed around Roblox's own jump button (kept, not replaced): base size 17% of the screen's
  shorter side, 64–104 px, Attack 1.15×; the `ButtonLayout` setting picks a layout from
  `Config.Controls.Touch.Layouts` (only `Default` so far). Camera shake wobbles at 18 Hz and only moves the camera
  (never turns it). Setting ranges: volumes 0–1, camera sensitivity 0.25–2.
- **Combat (1.6):** knockback uses the victim's Percent *after* the hit (Smash-style). Launch direction = attacker →
  victim on the ground plane, 30° up. Whoever simulates the victim runs the launch (`Shared/Combat/Launch`): the
  victim's own client for players, the server for dummies; the Humanoid is PlatformStand (no steering) and held
  upright facing the attacker until hitstun is over and it has landed (max 3 s). An attack is lost if its attacker
  is hit during the windup; no punching while charging; a hit cancels a charge; the charge cooldown starts on release
  and a cancelled charge has none. Heavy hits (charged punch, punch finisher) shake the victim's camera (1.0) and the
  attacker's (0.4). (The 1.6 Shove on right-click and its drag-cancel were replaced by the charged punch, 2026-10-17.)
  The equipped style's multipliers already apply; the Wrecker parry comes with styles (2.2). PvP only between two
  players in the arena; the dummy can always be hit. The dummy respawns 2 s after a KO or falling 4 studs.
- **Dash (1.7):** the client moves at once (LinearVelocity, 48 studs/s for 0.25 s = 12 studs, level, along the move
  direction or else the facing) and sends `Dash`; the server grants invulnerability from when the intent arrives, accepting it up
  to 0.15 s before the cooldown ends (`Dash.CooldownTolerance`, network jitter). A dash cancels a charge, and a
  dash after hitstun ends a launch (recovery). One Perfect Dodge per dash; dodged hits give no KO credit. The bonus
  applies to every victim of the dodger's next landed swing, then is used up.
- **Rounds (1.8):** a KO kills the character and Roblox respawns it after `Players.RespawnTime` (= RespawnDelay 3 s);
  RoundService then moves it into the arena with a fresh fighter and a 2 s shield (ForceField look). Resetting your
  character in the arena is a fall. Classic standings at time-out: fighters still in (most KOs, then fewest falls)
  above the eliminated (later = higher); Casual: score, then KOs, then fewest falls; ties share a placement. Only
  active (non-AFK) time counts toward the 60 s; AFK players (no input 45 s, reported by `Activity` pings) sit out the
  next round. Casual: a lobby player who stands on the join pad joins 3 s later (see the lobby rework below).
  "Completed" = still in the server at the end (eliminated Classic players included). The Wins stat counts only
  wins that would earn placement rewards (60 s active, not AFK). Spectators (Classic: out of lives) watch a fighter
  still in; the server streams that fighter's area to them (`ReplicationFocus`).
  Spectate cycles with Z / X, D-pad or the bar's arrows. The 1.4 Studio arena-preview pad was removed (rounds
  replace it).
- **Owner's choices (2026-10-16):** thrown props fly the way the character faces (not the camera); an explosive
  barrel's blast hurts everyone in range including its thrower; gamepad Menu = D-pad Up and Scoreboard = D-pad Down
  (Roblox keeps Start / Select); the developer panel stays Studio-only for now (`Config.Dev.AllowedUserIds` empty).
- **Props (1.9):** the server picks the nearest free prop within GrabRange (measured to the prop's edge) and welds it
  above the head (massless, no collisions); grabbing again drops it in front. While holding, the Punch intent throws
  (CombatService interceptor) and charging is blocked; throws break the spawn shield. A spot's timer (20 s / 30 s for
  barrels) starts when its prop is taken; dropped props despawn 8 s after the drop like thrown ones. Flights are
  server-owned and swept every frame (sphere casts): the first fighter hit takes the class blow (thrower's Perfect
  Dodge bonus applies), anything else ends the flight; the thrower is never hit by their own flying prop. Attack boxes
  light barrels (3 s fuse, credited to the attacker); explosions light other barrels in range. Prop KOs count
  `PropKOs` (and `ChairKOs` for chairs) from the last hit's source. Walk-speed modifiers multiply (charge, carry).
- **Structures (1.10):** blockout sizes / colors are new Config values (car 4.6×3.6×9, vending machine 4×7×3, barrier
  stack 8×3×2.4). Thrown props deal their class's Classic damage, barrel blasts 25 within radius + half the
  structure's largest side. A structure darkens up to 55% as it loses HP. Drops pop out around it and vanish after
  `Structures.DropDespawnTime` (30 s, new) unless picked up; the 40-prop cap still applies, so a full arena drops
  fewer. The player who lands the breaking hit gets `StructuresBroken`. Respawns are skipped if the arena changed.
- **Crumbling (1.11, reworked after the 1st playtest):** the server only sets attributes: `Crumbling` (warning) and,
  after WarningTime, `Falling` together with CanCollide off on every platform part, so players, props and structures
  drop into the void (KO at KillY, credited to their last attacker within 6 s); it is removed after FallTime. Each
  client draws it (`CrumbleController`): a red `Highlight` flashing every 0.25 s and a smooth ±0.25-stud shake, then
  the platform sinking 45 studs and fading out. The first version (server-side shake + unanchored welded fall)
  looked choppy and tumbled. The schedule counts from the round start (os.clock); a round ending stops it.
  `CrumbleService.crumbleNext()` crumbles one at once (developer panel).
- **1st playtest fixes (2026-10-16):** throws now launch a fresh server-owned copy of the held prop (the held one is
  part of the thrower's client-simulated character, so the server could not give it velocity); grabbing takes server
  ownership of the loose prop before welding; a "[E] Grab" prompt shows when a free prop is in reach (props carry a
  `Held` attribute while held) and Studio logs why a grab found nothing. Fighters (players and dummies) are in the
  `Fighters` collision group, which does not collide with itself: no body-pushing someone along or off a ledge by
  walking into them (the "stacking push"), and dashes pass through players. Windups 0.05 s, dash 12 studs, camera
  shake 1 stud + 1.5° tilt over 0.35 s (removed again before each camera update, so it never drifts), attacker shake
  0.6. Ragdoll / tumble on big launches came with the animations step (2.6: the Tumble clip).
- **2nd playtest fixes (2026-10-16):** throws were "really off": the server used its lagged view of the thrower and
  full gravity dropped a 90 studs/s throw ~6 studs over 30 studs. Now the client sends its facing and position with
  Punch (position used when within `Props.ThrowOriginTolerance` = 8 studs of the server's view), thrown props feel
  `ThrowGravityScale` = 25% gravity while flying (the server adds the rest back each frame), and `ThrowAimAssist`
  bends a throw toward a fighter within 15° / 80 studs of the facing (Angle 0 turns it off). Broken Highway's pillars
  now belong to their platform models, so they sink with a crumbling platform instead of staying behind. The owner
  re-tested and reported "all clear".
- **Fighting styles (2.2; since 2026-10-19 styles come from the style roll — see "Owner's fix list, step 3"):** the equipped style's numbers have applied since 1.6 (`Formulas.resolveAttack`). New: the
  Wrecker parry — the Ability key opens a 0.2 s window (its own 1.2 s cooldown; it was on Shove until 2026-10-17); a
  punch or charged punch landing in it misses and its knockback (no damage) goes back onto the attacker from the parrier, credited to the parrier and
  scaled by ReflectMultiplier (source "Parry", so it can't be parried back). Thrown props and blasts are not parried.
  Order of defences: spawn shield, parry, dash. Styles unlock free at their UnlockLevel (on load and on
  `DataService.LeveledUp`); buying with Scrap comes with the Shop (2.4). `EquipStyle` only switches to an owned style
  and not while Playing / Respawning in a round. Weapons are welded blockout parts from `Config.Styles.Weapons`
  (Massless, CanCollide / CanQuery / CanTouch off: visual only, attack boxes hit the body). The style picker UI is
  part of the Locker (2.3); until then the developer panel's Style buttons own + equip any style.
- **Cosmetics + Locker (2.3):** the launch catalog (6 skins, 6 hats, 4 dash trails, 4 KO effects, 4 victory emotes) lives
  in `Config.Cosmetics.Items` with blockout visuals: skins recolor `BodyColors` (the avatar's own colors are kept as
  attributes and restored when the skin comes off), hats are welded parts on the Head (`Server/Visuals/Attached`,
  shared with style weapons), dash trails are a `Trail` on the root that `CombatService.Dashed` switches on for the
  dash, KO effects are a particle burst (at the victim for HP KOs; around the scorer for ring-outs, whose victims are
  in the void). Victory emotes play as scripted clips (2.6); back items and name plates have no items yet (their
  Locker tabs stay hidden). `PremiumGold` (Premium) and `GoldTrail` (VIP) are exclusive: never sold for Scrap, granted
  in 3.1. Cosmetics can change any time; styles not mid-fight. The Locker opens from a new left-edge menu
  (`MenuController`, hidden while fighting). The developer panel's "All cosmetics" grants everything for testing.
- **Shop (2.4):** every Scrap item is always for sale (Styles tab, one tab per cosmetic slot); the **Daily deals** tab
  (bible: 4 cosmetics every 24 h UTC) sells its items at `DailyRotation.Discount` = 20% off (new; the bible gives no
  reason to visit the daily tab otherwise). The daily picks are a shuffle of the Scrap cosmetics seeded by the UTC day
  number (Park–Miller, exact in doubles), so every server and client agrees without saving or sending anything.
  Exclusive (VIP / Premium) items show in the slot tabs as "VIP only" / "Premium only" and are never sold; the
  default style is never sold; styles are never discounted and still unlock free at their level. The client sends
  the price it showed: if the rotation changed in between, the server refuses (`PriceChanged`) instead of charging
  a different price. Buying never equips; the confirmation offers Equip. The Robux tab (Scrap packs, passes, premium
  cosmetics) comes with 3.1. The Menu action now belongs to `MenuController`: it closes the open screen, or opens
  the Shop (gamepad: selects the first menu button). The developer panel's "+5000 Scrap" (`Config.Dev.GiveScrap`) is
  for testing purchases.
- **Charged punch + Ability key (owner, 2026-10-17):** "remove push right click action, just only punch and charge
  punch"; the Wrecker parry goes on "other key". So the Shove is gone: right-click is left to Roblox's camera turn.
  Pressing Attack punches at once (the chain, unchanged); still holding it `Charged.HoldTime` = 0.25 s later starts a
  charge (`Charge` remote "Start", `Charging` attribute, wind-up pose, 40% slower), and letting go throws the charged
  punch (the old Shove's numbers: 14 HP / 11%, KB scale 1.6, up to ×1.5 for 0.8 s of charge, 1.2 s cooldown; weapon
  styles swing). The charge has its own cooldown, so it can follow a punch at once; a press that throws a held prop
  never charges. Internally the attack is "Charged" everywhere (Config, Formulas, Fighter, kill-feed source). New
  `Ability` action — F, gamepad Y, a touch button shown only for styles with an ability (labelled Parry) — runs the
  equipped style's move: `Config.Styles.List[id].Ability` (Wrecker: `Parry` 0.2 s, `Cooldown` 1.2 s; others none).
  Casual already had unlimited lives (no HP, endless respawns, nobody is eliminated) — confirmed to the owner.
- **Key panel (owner, 2026-10-17):** "about keys like dash, unique skill, can you shift these into bottom right";
  bindings stay (owner: keep Q dash, Shift run). `ActionPanelController`: bottom-right slots for Run (lit while
  running, fill = stamina, dimmed below RunResume), Dash (fill = cooldown, dimmed below a dash's stamina cost) and the
  style's Ability (only when it has one; fill from the server's `AbilityReadyAt` character attribute), each with its
  key / gamepad glyph (KeyHint). Shown on keyboard / mouse and gamepad, hidden on touch (the touch buttons are in that
  corner; touch keeps the dash ring in the bottom bar, which now hides it otherwise) and while spectating.
  `MovementController.isRunning()` tells the panel whether Run is held / toggled.
- **Music + SFX (2.8):** every sound is a slot in `Config.Audio` holding a Roblox audio asset id; all are 0 (silent)
  until the owner picks free Creator Store audio (a code session can't browse or upload audio). `SoundController`
  (client) plays: the lobby track, or the arena's track (by map id) while the player is in the running round
  (fighting, respawning, spectating; lobby players keep the lobby track), crossfading over 1.5 s; the tension layer on
  top in the last `Round.TensionTime` = 30 s; the victory sting on `RoundResults`. World sounds (3D, heard within 140
  studs) from the same signals as the effects: hits by the attacker's weapon (`CombatHit` now carries it: Punch /
  BatHit / ShovelHit / WrenchHit; heavy hits ChargedHit; thrown props PropHit; parries Parry), Dash / Grab / Throw /
  Parry from `Animate`, KO boom + a short cheer, explosions, structures smashing (wood / metal / glass by material),
  the Perfect Dodge chime, the crumble rumble and collapse. UI: a click on every menu button (not the touch action
  buttons), a coin sound for round Scrap, a level-up fanfare. Volumes = the slot's volume × the Music / SFX setting;
  repeated effects vary their pitch. Pure choices in `Lib/AudioRules` (spec-tested).
- **VFX + Low Graphics (2.7):** every effect is drawn on the client (`VfxController`; crumbling in
  `CrumbleController`), numbers in `Config.Vfx`. From `CombatHit`: an impact flash and sparks in the victim's Percent
  color, more sparks the higher the Percent (8 → 30 at 150%), thrown away from the attacker; a smoke trail on
  launches with `trail` for the hitstun. From the new `Effect` remote (`Server/Visuals/Effects.play(kind, position,
  data)`): `KO` — a comic starburst with "POW!" at the victim (HP KO) or "K.O.!" around the scorer (ring-out), plus a
  screen-edge flash: red on the knocked-out player's screen, gold on the scorer's; `KOBurst` — the KO-effect cosmetic
  (moved off the server); `Explosion` — fireball, neon ring shockwave, smoke and debris (replaces Roblox's
  `Explosion` instance); `Break` — chunks in the structure's color and material plus dust; `PerfectDodge` — a blue
  flash with "PERFECT!" (and a blue edge flash for the dodger). Dash streak: a client Trail on every dash unless a
  dash-trail cosmetic already draws one. Crumbling: dark cracks on the warning platform, a dust cloud and chunks when
  it falls. Particles use Roblox's built-in textures (no assets). Low Graphics (saved setting; dev panel "Low gfx
  on/off" until the Settings menu in 3.10) turns off particles, flying debris (structures still drop 3 chunks), the
  Lighting post-effects (Bloom, color grading) and shadows, all locally; flashes, starbursts and edge flashes stay.
- **Stamina (owner, 2026-10-17):** "player can now run and dash with limited stamina, anyone". `Config.Combat.Stamina`:
  100 max, running ×1.5 speed costs 20/s while actually moving (server sees the root's flat speed > 2 studs/s), a
  dash costs 25, it refills at 30/s once nothing was spent for 0.8 s; running stops at 0 and resumes at 20 while Run
  is held. The state lives in the pure Fighter (`spendStamina`, `setRunHeld`, `tickStamina`; dash spends inside
  `Fighter.dash`), so a reset or respawn refills it; CombatService ticks player fighters every 0.1 s, switches the
  "Run" walk-speed modifier and sets the `Stamina` attribute (whole numbers) for the HUD bar and the client's dash
  pre-check. Dash cooldown 2.5 s → 0.6 s so stamina is the real limit. Controls: Left Shift held (Dash is Q only
  now), gamepad left-stick press and a touch Run button (left of Attack) run until you stop moving
  (`MovementController`); a reset keeps Run held, a new character starts walking.
- **Animations (2.6):** scripted, not uploaded assets (the bible allows "scripted"; nothing can be uploaded from a
  code session and paid packs are out). Each frame before rendering, the joints a clip uses are turned through their
  rest offset — `Motor6D.C0`, or an `AnimationConstraint`'s `Attachment0` — never `Transform`, which Roblox's default
  walk / idle animations write; those keep playing on top, so the legs keep walking and arms still swing a little.
  R15 and R6 rigs both work (R6 joint names are mapped; turns are applied in the parent part's axes). History: the
  first version wrote `Transform` in `Stepped` and the owner saw "no animation at all"; Studio's own log
  (`%LOCALAPPDATA%\Roblox\logs`, `[FLog::CreatorOutput]` lines) then showed "no R15 joints found" on the owner's
  character, so joints are found by name across those formats and `Config.Dev.LogAnimations` prints which joints
  a character has (or what it has instead). Angles: X swings a limb forward / tilts the body back, Y turns left, Z
  swings a right limb out (a left limb with −Z); Root offsets crouch or bob the whole body. Nothing replicates, so every client poses every
  character from the same signals. The attacker sees their own swing when the server's Animate event comes back
  (one round trip, like the hit itself); only the dash plays at once on the dasher's client. Punch chains: Brawler
  Jab → Cross → Uppercut; Slugger and Wrecker SwingRight → SwingLeft → Smash; Scrapper low SweepRight → SweepLeft →
  Smash. A hit with hitstun ≥ 0.6 s (the Tumble length) plays the tumble — backflips around the root for the whole
  hitstun, the "ragdoll" from the 1st playtest — shorter hits a 0.6 s recoil; dashing out of a launch ends it. The
  round's winners (placement 1, not AFK) play their equipped victory emote 1 s after the round (they are back in
  the lobby, under the results panel); equipping an emote in the Locker plays it once as a preview. A real
  animation made later in Studio can replace any clip: put its id in `Config.Animations.AssetIds`.
  **Dynamic pass (owner, 2026-10-17: "animation work but still look not good and no dynamic"):** per-key easing
  (`Pose.ease`: Smooth, Linear, In, Out, Back) — every attack is a short wind-up ("Out"), a strike that overshoots
  ~10% and settles ("Back"), a hold, a smooth recovery, with the hips, root (lunge / dip), head and a stepping foot
  joining in; hit-stop freezes the attacker's and victim's clips 0.05 s (0.09 s heavy) on every landed hit; an
  always-on Motion layer (`Shared/Animation/Motion`) leans bodies into their movement (12° forward at running speed,
  8° roll into strafes, smoothed) and tucks legs / spreads arms in the air; a `Stance` loop raises the guard while
  standing still in a round (fades out with speed); hits recoil away from the attacker (`Hit` front, `HitBack`,
  `HitLeft`, `HitRight`); the tumble tucks into a ball. Numbers in `Config.Animations` (HitStop, Motion). Rigs are
  found once per character (retry every 1 s while not streamed in); the Studio log says whether constraint joints
  are kinematic.
- **Arenas (2.5):** the bible only names Junkyard Isles ("stacked car and container islands over toxic sludge") and
  Neon Motel ("sinking motel rooftops, flickering retro neon, pool on one roof"), so both follow Broken Highway's
  numbers (see the bible §3.2 "Every arena"): 1 centre + 4 sides + 2 ledges, gaps 8–14, ledges ≤ 6 above the
  centre, 12 spawns, 14 prop spots, 4 structures, 4 barrels, KillY 60 below. The maps spec checks these rules for
  every arena. Shared code is `maps/lib/Arena.luau` (platform models, markers, KillY); each layout adds its own
  decor and scenery. New structure types keep the bible's HP tiers: CrushedCarStack 100, ScrapPile 60 (Isles),
  IceMachine 80, LawnChairStack 60 (Motel). Tall decor is at platform corners (crane mast) or walk-through
  (crane arm, MOTEL sign tubes, buildings and scenery under the platforms); the pool water and rim are
  walk-through. `NeonFlicker`-tagged parts blink on the client (`NeonFlickerController`; candidates for the Low
  Graphics setting in 2.7). All three maps are enabled, so every vote offers all of them. After the owner's first
  look ("Neon Motel a bit too dark") the Night preset is brighter and the motel's neon parts and roof lamps carry
  PointLights.
- **Bigger arenas (owner, 2026-10-17: "make map twice bigger, more layers too, round time 4 min"):** every arena's
  platforms are twice the size, and the gaps stay 8–14 (a jump + dash; doubling them would make them uncrossable).
  Four layers per arena (`Arena` kinds): 2 **Low** platforms (28×28, about 6 below a side, beyond it), the base
  (Center + 4 Sides), 4 corner **Ledges** (+6) plus a raised **Deck** on the centre (+6, 28–36 × 18–20, a 12-stud ramp on
  each end; `Arena.Deck`) and 2 **Peaks** (18–20 square, +12) beyond the NE / SW ledges. Every climb is ≤ 6 studs
  (the default jump reaches ~7), so the maps spec checks height bands per kind and that every platform is reachable
  from the centre and back. Counts grew with the area: 13 platforms, 16 spawns (≥ `World.MaxPlayers`), 24 prop spots,
  8 structures, 6 explosive barrels (one per Side and Low). Decor written for the first size is placed with
  `Builder.spread(2, ...)` (positions doubled, objects not stretched); parapets, the pool (now 20×24), the water tower
  and the billboard are sized from their platform. New decor: exit signs on the highway peaks, tire towers and junk
  rafts in the junkyard, antenna roofs (blinking red beacon), vent roofs and lamp-lit low roofs at the motel. Crumbling
  is unchanged (from 1:00, every 20 s), so a 4:00 round drops 9 of the 12 outer platforms. `Round.RoundTime` = 240;
  private servers choose 2 / 3 / 4 / 5 min (`PrivateRoundTimes`). Not playtested yet: check the ramps (they should
  rise toward the deck), every jump, and whether 16 spawns over the bigger area feel too empty for small servers.
- **Lobby rework (owner, 2026-10-16):** "I need an area for players to be in to start the round — right now every
  player has to play, no time to shop", "delete the Training Yard too", and "a closed-space lobby, hideout mixed with
  bar style, not open like this". So:
  * **The Hideout** (`maps/layouts/Hideout.luau`, map id `Hideout`) replaces the Rust Diner rooftop: an enclosed
    92 × 68-stud room with a 22-stud ceiling. North: bar counter (Shop, `ShopCounter`), bartender (`ShopNPC`), bottle
    shelves, map vote TVs hanging over the bar, mode TVs on the counter ends, neon title sign. East: steel ARENA door
    (`ArenaDoor`) with the join pad. West: lockers, jukebox, quest board. South: leaderboard screens, spawns, street
    door. Pool table, booths, high tables, crates, barrels, warm hanging lamps (PointLights) under a shadow-casting
    ceiling. Same KillY rule (40 below the floor). The lighting preset is still Dusk (global): the inside is lit by
    its lamps and Ambient — check the brightness in Studio. The vote TVs are dark casings with glowing CRT screens
    (Neon `CrtGlow` + a soft light); the first version's off-white casings glared under the bar lamps, which now
    hang between the TVs with dim amber bulbs (owner: "the TV panel should light instead").
  * **Join pad** (`QueueZone`, 14 × 18 studs, `Server/Round/Queue`): only players standing on it (root over the
    footprint, up to `Round.Queue.Height` = 10 studs above, for jumps) and not AFK are queued. `MinPlayers` now counts
    queued players; the vote opens when enough are on the pad and goes back to Waiting if they step off. Only players
    on the pad see the vote panel and vote; stepping off drops your vote. Everyone queued when the vote ends goes in;
    everyone else stays in the lobby (status `Lobby`, not spectating) and can shop. Casual: stepping on the pad during
    a round joins it after 3 s; Classic: the pad queues you for the next one. Returning fighters land on the normal
    spawns (walk back to the pad to play again). AFK players on the pad show `QueueStatus = AFK` and a "move to show
    you're here" line. Developer "Start now" still needs someone on the pad.
  * **Training Yard removed** (its markers, sign and lobby chair spot). The practice dummy is now a developer-panel
    tool ("Dummy" under Spawn: one dummy in front of you, replacing the previous; it respawns at its place unless the
    ground there is gone). The lobby prop-spot tag is `LobbyPropSpot` (none placed). The tutorial (2.9) needs a new
    plan.
- **HUD (1.12):** `HudController` (top bar, kill feed, bottom bar) replaced the 1.8 status line. Kill feed sits top-right
  (bible said top-center, which already holds the timer and the vote panel); lines fade after 6 s, max 5, and name
  the prop when a prop made the KO. Top bar info: Classic = fighters with lives left, Casual = your score. Vitals
  show only while you are in the round; the bottom bar hides while spectating. Key hints: key name on keyboard
  (`GetStringForKeyCode`, "Click" / "Right-click" for mouse), glyph image on gamepad (`GetImageForKeyCode`), none on
  touch. The scoreboard is hold-to-show (Tab / D-pad Down, no touch button per the bible) and disables Roblox's
  player list; it orders fighters like the round (Classic lives → KOs → falls, Casual score → KOs).
- **Developer panel (1.13):** `DevService` runs `DevCommand`s only for `DevRules.isAllowed` players (Studio:
  everyone while `AllowInStudio`; live: `AllowedUserIds`, empty by the owner's choice) and marks them with the
  `DevAccess` attribute, which makes the client build the panel. "Start now" lowers the players needed to 1 until
  that round starts; forced map / mode apply to the next vote result only. Set HP never goes below 1 (no KO from the
  panel); spawned props despawn like structure drops (30 s untouched). Spawning a prop for another player and the
  other Phase 3 tools (Scrap, levels, unlocks) are step 3.9. The K / L Studio keys were replaced by panel buttons.
  **3.9:** the bible's full list (§6): a **Target** button at the top cycles through the players in the server (you
  first); every player command then acts on that player (Percent / HP, spawn a prop or the dummy in front of them,
  Scrap / XP, level, styles, cosmetics, perks, Robux products, daily / quest / code tests) — `DevCommand` carries
  the target's UserId and the server falls back to the sender if they left. New: "+1000 XP" (`Dev.GiveXP`, level-ups
  apply), Level 1 / 5 / 12 / 25 / 50 (`Dev.LevelPresets`; `DataService.setLevel`, XP 0, fires `LeveledUp` so the rank
  title and style unlocks follow — RewardService now updates `Rank` on every level change), "All styles". Still
  Studio-only in live servers until the owner's UserId goes in `Dev.AllowedUserIds`.
- **Round rewards (2.1):** `RewardService` pays every player still in the server when `RoundEnded` fires, through
  `Server/Round/Payout` → `Formulas.roundPayout` (the 1.1 rules), then `DataService.addScrap` (sku "RoundReward",
  logged as a Gameplay source) and `addXP`. Bonus inputs: VIP = game pass ownership (cached per session),
  Premium = `MembershipType`, friends = other players in the server you are friends with (`IsFriendsWithAsync`),
  private server = `PrivateServerId` with an owner (reserved servers do not count). The rank title is the player
  attribute `Rank` (a rank id, set on load and after rewards). The results panel shows "+Scrap · +XP", level-ups and
  a new rank; the profile block (top left, since 2026-10-19) shows coins, level · rank and XP. Lifetime stats were already counted in 1.8.
- **Walk-up Shop and Locker (owner, 2026-10-17):** picked over 3.2 as the next step. `LobbyPromptController`
  puts a ProximityPrompt on the bartender's `Torso` (tag `ShopNPC`: "Shop · Bartender") and the locker booth's `Back`
  wall (tag `Locker`: "Locker · Locker booth"), 12 studs, no hold, no line of sight needed. Keys: E / gamepad B
  (`Config.Controls.Prompts`), the Grab keys — nothing to grab in the lobby, and a shown prompt takes the key press
  first; touch taps the prompt. The prompts are made on the client (opening a screen needs no server) and re-made
  when a streamed-out part comes back; they hide while a menu screen is open or the player is fighting. They use
  Roblox's default prompt look until the art pass. The left-edge menu still opens both screens anywhere in the lobby.
- **Performance + localization (3.11):** done in code, without a phone to profile on — measure on a real low-end
  device (Studio's Device Emulator doesn't show phone speed). Animation posing is the per-frame client cost that grows
  with players, so `AnimationController` now poses other characters every frame only within
  `Performance.AnimationLod.Near` (60 studs) and in view, every `FarEvery` (2) frames up to `Far` (150), every
  `OffscreenEvery` (4) frames off screen or further, not at all past `Cull` (300); Low Graphics multiplies the
  distances by 0.6; each rig has a random phase so the skipped work spreads over frames; your own character is always
  posed (`Client/Lib/AnimationLod`, spec-tested). Once per player (`GraphicsAutoChecked` setting), 10 s after loading
  the client measures its frame rate for 20 s and turns Low Graphics on below 40 FPS with a notice
  (`PerformanceController`; players can turn it off again). Neon flicker stays steady under Low Graphics. Earlier
  steps already keep small parts' shadows off, cap props at 40, stream the world, make arena platforms Persistent and
  run effects only on clients. Localization: every string the code shows is in GameStrings (the literal-key spec, and
  a new spec failing on any `Text = "..."` with letters in code), every string with `{n}` has an Example for
  translators (new spec), and the one unused string (`Notify.Welcome`) is gone. Automatic translation still needs the
  CSV uploaded to the Creator Dashboard (owner).
- **Settings, loading screen, How to play (3.10):** the Settings screen (3rd in the left-edge menu since 2026-10-19, in tabs) changes every
  setting through `SettingsController` (server-checked): music / SFX volume with − / + buttons in steps of
  `Data.VolumeStep` = 0.1 (no drag slider: the buttons work the same with mouse, touch and gamepad), camera shake and
  low graphics On / Off, and the touch button layout (shown on touch only when `Controls.Touch.Layouts` has more than
  one). Camera sensitivity stays in the saved data but isn't shown: a game script can't change Roblox's camera
  sensitivity (forking the PlayerModule's camera input would be the only way), so a note points to Roblox's own menu.
  "Tutorial replay": the tutorial is skipped (owner), so Settings has a **How to play** page (a tab since 2026-10-19) instead — six rule lines
  and the controls for the current device (`KeyHint` boxes: key names / gamepad glyphs; touch gets a note); no reward.
  The **loading screen** is `src/first/LoadingScreen.client.luau` (mapped to ReplicatedFirst): it removes Roblox's
  default screen, shows the title, a random tip (`Tip.1`–`Tip.8`) and "Loading...", stays at least
  `World.Loading.MinTime` = 1.5 s and until `game:IsLoaded()` and the player's `Level` attribute (set when the data
  loads), at most 20 s, then fades out (0.6 s). Its colors repeat Kit's (the client modules aren't loaded yet).
- **Owner's fix list, step 1 — cleanup (2026-10-19):** parties are gone (the owner: "delete parties") — server,
  client, remotes, tags and strings; `Round/SpawnPlan` stays and spreads every fighter as a group of one. The
  Leaderboard menu screen is gone ("only the boards in the lobby"). **Classic only**: `Config.Modes.Order` = {
  Classic } (Casual stays defined, out of the rotation), so the vote is map-only — the vote panel and the private
  server's Server menu hide a row with one choice, private servers can't pick Casual, and the two counter TVs that
  were mode-vote screens are now `NewsScreen` TVs (for the "TV news" item). **The lobby is run-only**: CombatService
  ignores Punch / Charge Start / Ability / Dash and PropService ignores Grab unless the player's `RoundStatus` is
  `Playing`; the client doesn't send them, hides the touch Attack / Grab / Dash / Ability buttons and the key panel's
  Dash / Ability slots outside a round (Run stays). The developer panel's practice dummy can only be hit in the arena
  now (spawn it there during a round). Tip 7 and the How to play rules no longer mention parties or Casual.
- **Owner's fix list, step 2 part 1 — UI (2026-10-19):** the owner asked for "left menu = Shop, Inventory, Settings,
  Quests; also coins", "daily reward pops up on login; quests can be checked there" and "Settings: visual, audio,
  promo code", and answered "Rename Scrap to Coins" (on screen) and "Inventory = the Locker renamed". So: the
  left-edge menu is Shop (1), Inventory (2), Settings (3), Quests (4); the private server's owner still gets Server
  (9) at the end. Above it, top left, `ProfileController` shows a gold coin with the balance in big numbers
  (`HudFormat.thousands`: "12,500") and COINS under it, "Level 12 · Raider" and an XP bar ("340 / 500 XP", "Max level"
  at the cap); it hides while fighting, like the menu, and replaces the HUD's top-right profile chip. The Daily reward
  has no menu button (`addScreen(nil, ...)`): it still opens itself once a session when a reward waits, and the Daily
  reward and Quests screens share a tab row (same panel size), so each is one tap from the other. Settings has four
  tabs (`Settings.Tab.*`): Visual (camera shake, low graphics, button layout, the sensitivity note), Audio (music /
  SFX volume), Promo code (the old Codes screen, which is gone; the lobby jukebox opens Settings on this tab) and How
  to play (the old page, no Back button). Strings: every "Scrap" in GameStrings' text is "Coins" ("Coin Pack S / M /
  L"); names that only contain the word stay (Scrapper, Apex Scrapper, Scrap Metal, Scrap Burst, the JOE'S SCRAP
  sign); "Locker" is "Inventory" (the lobby's "Locker booth" and LOCKER sign stay, it is a place). Keys, data fields,
  Config and code keep Scrap / Locker, so saves and analytics don't change. The Shop's Styles tab goes with the
  style roll (step 3).
- **Owner's fix list, step 2 part 2 — watching and key hints (2026-10-19):** "'game in progress' and spectate mode"
  and "small light-grey key hints at the bottom of the UI, more when near something interactive". **Game in progress**
  (`GameInProgressController`): while a round runs, a lobby player sees a card under the menu buttons
  (`MenuController.addWidget`) with a blinking red live dot, the arena, the time left and how many are still fighting
  (Playing or Respawning), and **Watch**: `SpectateController.watch(true)` turns the camera onto a fighter like a
  Classic spectator (spectate bar, Z / X or D-pad to switch); the character stays in the lobby and can still walk.
  The server's `Spectate` handler now also streams the arena (`ReplicationFocus`) to players whose status is Lobby
  while the round is Playing. Watching ends with **Stop watching**, the round ending, or the player's status leaving
  Lobby; watchers hear the arena's music. **Key hints** (`HintBarController`): one row along the very bottom edge,
  light grey (`Kit.Colors.Hint`) 14 px text after each action's key box (KeyHint: key names, gamepad glyphs), not on
  touch and not while a menu screen is open. Which hints show is the pure `Client/Lib/HintRules` over
  `Config.Controls.Hints`: lobby = Run, Menu, plus one hint per ProximityPrompt in reach (its key is Grab's, its text
  the prompt's, e.g. "[E] Shop"); fighting / respawning = "Punch · hold to charge", Scoreboard (Run / Dash / Ability
  are already on the bottom-right key panel, and "[E] Grab" by a prop in the bottom bar); spectating or watching =
  "Switch fighter" (Z + X), Scoreboard. To make room, the bottom HUD bar, the stamina bar, the key panel and the
  spectate bar sit 14 px higher.
- **Owner's fix list, step 3 — style roll (2026-10-19):** the owner's answers (README): "a spin costs Scrap, plus 1
  free spin a day; a pity counter guarantees the rarest style", "a roll replaces the style in the active slot … a slot
  can be locked", "one equip slot to start", "extra style slots are bought with Robux", "Slugger = Uncommon, Scrapper =
  Rare, Wrecker = Legendary (Brawler stays the default)", "rolling replaces the level unlocks". Numbers (my picks, all
  `Config.Styles.Roll`): odds Uncommon 70 / Rare 25 / Legendary 5 % (styles of one rarity would share it equally);
  `PityAt` 50 (the 50th spin since the last Legendary is a Legendary; the counter shows "Pity: n / 50"); `SpinPrice`
  250 Coins, so a Legendary costs about 20 spins = 5,000 Coins on average (Wrecker was 6,000 in the Shop); free spin
  resets at 00:00 UTC; `Slots` Start 1, Max 4, `OverflowScrap` 1000 (a slot bought when already at 4 — two purchases at
  once — pays Coins instead, never nothing). Brawler (Common) isn't in the odds: everyone starts with it and new slots
  hold it. The roll is server-side (`StyleService.spin`: `Random`, `StyleRules.pick`), checked in this order: not
  while fighting, the equipped slot isn't locked, then Free = today's free spin unused and not a private server
  (nothing is earned there), Paid = `PlayerPolicyService.allows(player, "PaidRandomItems")` and enough Coins
  (`spendScrap`, Shop sink, sku "StyleSpin"); analytics `StyleSpin` (kind, style, rarity). **Paid random item rules**
  (README): every outcome and its exact odds are on the page before a spin; where the policy restricts paid random
  items (or can't be read: safe default) the page offers the free spin only and says why; the maturity questionnaire
  must now say "paid random items: yes" (docs/LAUNCH.md). **Data v2:** `Styles` = { Slots, Locked, Active, Equipped
  (= the active slot's style, kept for every reader), Pity, FreeSpinDay }; migration 1 → 2 puts the equipped style in
  slot 1 and drops the other owned styles (no live players yet). **UI:** the roll page (`Ui/StyleRollView`, like `docs/reference/style-roll.jpg`) is its own **Styles**
  screen since the owner's "prefer style as separate ui instead of within inventory" (`StyleRollController`: the
  third left-menu button, a 0.86 × 0.84 panel up to 1200 × 700; it was the Inventory's first tab in #55): slot cards on the left (style in its rarity color,
  EQUIPPED / tap to equip, Lock / Locked, "+ Style slot" with the live Robux price or "Coming soon"), the equipped
  style's name, rarity and description in the middle with the Spin button ("SPIN · FREE" / "SPIN · 250 Coins"), the
  free-spin countdown and the pity line, and the odds list on the right (rarity bars with percentages, each style's
  own chance). A spin runs a 1.4 s reel through the style names that slows down and lands on the server's answer
  ("You rolled Wrecker!", "Pity! …"). The Shop's Styles tab, level unlocks, `UnlockLevel` and style prices are gone;
  `EquipStyle` became `EquipStyleSlot`. Developer panel (Styles + items): style buttons put that style in the
  equipped slot, "Free spin", "Pity next" (pity = PityAt − 1), "+1 style slot" (the product's grant, overflow
  included); "All styles" is gone.
- **Victory emotes removed (owner, 2026-10-19: "remove victory emotes"):** the `VictoryEmote` cosmetic slot is gone
  from `Config.Cosmetics.Slots` (so from the Inventory, the Shop's slot tabs, the daily rotation and the day-7 pick)
  with its 8 items, their scripted clips (Flex, JunkDance, Taunt, Champion, Robot, Salute, AirGuitar, Backflip) and
  `Animations.EmoteDelay`; round winners no longer emote in the lobby and equipping no longer previews. The **Emote
  Pack** game pass only sold 4 of those emotes, so it is gone too (`GamePasses`, `RobuxOrder`, the `EmotePack` perk,
  its strings); VIP and Premium are the perks left. Data v3 (`Migrations.Steps[2]`) removes the emote ids from
  `Cosmetics.Owned` and `Cosmetics.Equipped.VictoryEmote`. The pose sampler still allows equal key times (the snap
  that the Backflip used), now tested with a small made-up clip. Older decisions below that mention emotes or the
  Emote Pack describe what was built then.
- **Owner's fix list, step 4 part 1 — the bigger lobby (2026-10-19):** "lobby 50% bigger", "rebuilt in code in the
  reference style" (docs/reference: lobby-lounge.jpg, lobby-bunk-corner.jpg) and "sit on chairs / couches". **Redone
  the same day** after the owner looked: "i want design like ref not pick it into studio … rn it look too blocky item
  no detail like ref" and "lobby too big shrink down a lil" (asked: they meant the style only, not copies). So the
  room is 115 × 85 × 26 (1.25× the first one; 138 × 102 × 28 for a day), the copied objects (bunk beds, kitchen
  counter, vending machines) are gone, and the furniture comes from `maps/lib/Furniture`: each piece is many small
  parts in Roblox materials (tufted sofas and armchairs with rolled arms, piping and tapered gold legs; booth benches
  with channel tufting; stools with round leather seats on gold poles — the Seat is an invisible block in the cushion;
  black marble tables with gold rims and pedestals; floor lamps with drum shades and trim rings; stepped gold pendant
  lamps on chains; wall sconces; pillars with gold bands and corner strips; wainscoting with framed raised panels, a
  wood cap and a gold rail; bottles with necks and caps; a pool table with rails, pockets and turned legs), plus a
  mirrored back bar with framed cabinet doors, a framed counter front with a rounded marble edge and a gold foot rail,
  crown molding, gold strips under the beams, TV bezels / knobs / grilles, wood frames with gold corners on the
  leaderboards, a panelled street door. Smooth curved shapes would need meshes (free Creator Store or Studio's AI
  models, inserted by the owner); `Builder` part specs take `Yaw` so a whole piece turns with its facing. Before the
  redo (#58) the room was 138 × 102 studs and 28 high; every area kept its place (bar north, ARENA door + join pad
  east, Inventory / Codes / Quests west, leaderboards + spawns south) and the same tags, so prompts, the queue and the
  boards work unchanged; the join pad keeps its 14 × 18 size. The look follows the pictures, built from parts:
  plaster walls over dark wood wainscoting, dark wood pillars with white wall lamps (lit on the east / west walls),
  wood ceiling beams, a light carpet (wood planks in the bar); the lounge has a dark rug with a gold ring, a round black
  marble table, a red 3-seat sofa and two armchairs, two floor lamps and potted topiaries. The old brick walls and
  neon trim are gone; signs still glow. **Seats:** `Builder.seat` makes `Seat`s tagged `LobbySeat`
  with CanTouch off (bumping into a sofa never sits you down; a sofa cushion, booth bench seat or stool is a square
  block turned only around Y, because a sitter stands along the seat's up axis). `SeatController` puts a Sit prompt on
  each (within `Controls.Prompts.SitDistance` = 7 studs; hidden while taken, while you sit, with a menu open or while
  fighting) and sends `Sit`; `SeatService` sits you down if it is a free lobby seat, you're alive, not sitting, not
  fighting, and within SitDistance + `SitTolerance` (4). Jump to stand up. Seats are never on the join pad, so a
  sitting player is never taken into a round. 24 seats: 3 sofa + 2 armchair cushions, 8 booth seats, 7 bar stools,
  4 high-table stools. Not playtested yet: brightness (Dusk preset + ~30 warm lights), sitting heights.
- **Future lighting (owner, 2026-10-19: "yes switch to future lighting"):** the reference's soft lamp shadows come from
  Roblox's Future lighting. Roblox has replaced `Lighting.Technology` with `LightingStyle` (Realistic = the Future look,
  Soft) and `PrioritizeLightingQuality`; Studio no longer shows Technology (the owner: "no technology in lighting"),
  so `default.project.json` sets `LightingStyle` = Realistic (and `GlobalShadows`; PrioritizeLightingQuality stays off
  so weak devices may trade quality for speed). #60 had set the old Technology = Future. Lights from `Builder.light` still don't cast shadows unless asked: only the
  lobby's main lamps do (`Furniture.pendant` and `Furniture.floorLamp`, 10 lights), tagged `ShadowLight`; the maps
  spec fails above 12, since shadowed lights cost frame time. Low Graphics now also turns those lamp shadows off on
  that client (`VfxController`, along with `GlobalShadows`). Roblox scales the lighting down by itself on weak
  devices. If `rojo serve` doesn't change it in an open place, set Lighting → LightingStyle → Realistic by hand once.
- **Owner's fix list, step 4 part 2 — TV news and the board look (2026-10-19):** "TV showing fun news" and the
  reference's leaderboard boards. **News** (`NewsController`): both `NewsScreen` TVs (the counter ends) show the same
  "JUNKYARD NEWS" channel drawn on a SurfaceGui: a red banner with a blinking LIVE dot, a big headline that changes every
  `World.News.Interval` = 8 s after 0.15 s of static, a ticker of every headline scrolling at `TickerSpeed` = 40 px/s,
  and faint scanlines. Headlines (`Client/Lib/NewsRules`) are the 12 fun stories `News.1`–`News.12` with a live story
  after each of the first ones: the last round's winner and arena (`RoundResults`), one of today's daily deals with
  its price (ShopRules), the all-time Wins leader (`Leaderboards`); nothing updates while the player is fighting.
  **Boards** (`LeaderboardController`): the title is the map's cream sign with a gold underline (part 1); each row is
  rank · round avatar headshot (`GetUserThumbnailAsync`, cached, none for Studio test players) · name · value with
  thousands separators (right-aligned); the top 3 rows are taller with rounded outlines and gold / silver / bronze rank
  numbers and values (`HudFormat.medal`, `Kit.Colors.Gold` / `Silver` / `Bronze`), rows 4–10 plain; your own name is
  in the accent color; a small "All time" / "This week" line on top. `Leaderboard.Row` is gone.
  **Big TVs (2026-10-20, owner: "about 3 big tv, screen only show in 2 small"):** the three `VoteScreen` TVs over the bar
  show the same news channel, with a screen over it when there is a round to show: during the map vote TV n shows map
  n of the ballot (`VoteState`, sent to everyone) with its votes and "Stand on the ARENA pad to vote · time left";
  during a round the middle TV shows "LIVE MATCH", the arena, time left and fighters still in, and how to watch.
- **Owner's fix list, step 5 — bigger arenas, closing crumble (2026-10-20):** asked how to make the maps "2× bigger"
  again, the owner picked "double every platform" (over adding an outer ring of platforms). Each layout still lists its
  platforms at the 2026-10-17 size; `Arena.grow(platforms, 2)` doubles every platform (and its deck: size, ramp length,
  ramp width, offset; height stays 6) and moves it away from the platform it is reached from (the nearest one listed
  before it) by exactly what the two grew along each axis where they are apart, scaling the offset along an axis where
  they overlap — so every gap (8–14) and every climb (≤ 6) is unchanged and the maps spec's gap / height / reachability
  checks pass as before. `Arena.growContents` doubles every spawn, prop, barrel and structure spot's distance from its
  platform's centre (structures keep their size). Decor written for the first arena now spreads ×4 (`2 * GROWTH`), the
  2026-10-17-size parts (Broken Highway's guardrails, cracks and pillars, Neon Motel's parapets, vent roofs and low-roof
  lamps) ×2, the Neon Motel pool is 40 × 48, the Junkyard crane is rebuilt so its arm reaches from the mast over the
  centre island at any size, and the sludge / flood water below is 2800 wide. Sizes: Broken Highway's centre 240 × 160,
  sides 96 × 96, ledges 48 × 48, peaks 40 × 40, lows 56 × 56; the arenas are about 450–590 studs across (still well away
  from the lobby). **Crumble closing in:** `CrumbleRules.pick` takes a random platform from the outer ring — the standing
  platforms within `Round.Crumble.RingWidth` = 40 studs of the farthest one from the arena centre (`CrumbleService`
  passes each platform's flat distance from `Maps.ArenaOrigin`) — so the far peaks and lows fall first, then the ledges
  and sides, and the centre last. Timing is unchanged (from 1:00, every 20 s, 2 platforms always remain), so a 4:00 round
  still drops most of the outer platforms. Not playtested: whether 4:00 and 16 spawns suit the bigger maps.
- **Owner's fix list, step 6 — the lobby spin wheel (2026-10-20):** the owner's answer: "1 free spin a day plus extra
  spins for Scrap" (a paid random item: exact odds, hidden where restricted, declared on the maturity form). My picks
  (`Config.Retention.Wheel`, all tunable): 200 Coins a paid spin; prizes in wheel order with exact chances — 50 Coins
  30%, 150 XP 15%, 100 Coins 20%, a free style spin 10%, 250 Coins 12%, a random cosmetic 5%, 500 Coins 6%, 1,000 Coins
  2% (about 180 Coins' worth on average, a mild Coins sink). **Server** (`WheelService`, `SpinWheel` remote): checks in
  order: not a private server (nothing is earned there), not fighting, then Free = `Wheel.FreeDay` before today (UTC),
  Paid = `PlayerPolicyService.allows(player, "PaidRandomItems")` and enough Coins (`spendScrap`, Shop sink, sku
  "WheelSpin"); rolls with `Random` (`WheelRules.pick`) and pays: Coins (`addScrap`, Gameplay, sku "Wheel.<id>"), XP
  (`addXP`), StyleSpin (`Styles.BonusSpins` + 1: the style roll's free spin is ready while there are bonus spins, after
  the day's own one), Cosmetic (`WheelRules.cosmeticFor`: a random one sold for Coins the player doesn't own, else
  `CosmeticFallbackScrap` = 500); analytics `WheelSpin` (kind, prize, cosmetic); `WheelSpun` (index, name) to every
  client. **Lobby** (`maps/layouts/Hideout`, west wall between two pillars, z −25.5): a wood backboard with a gold rim, a
  pointer and a "SPIN TO WIN" sign; the `Rotor` holds a black face, 8 pie slices (each two right-angled wedges placed
  with `Builder` part `Axes`, attribute `Segment`), gold pegs and a hub. `WheelController` paints the slices in the prize
  colours and, on every `WheelSpun`, turns each Rotor about its hub's axis (4 s, 4 turns, ease-out) so the prize lands
  under the pointer. **Screen** (`WheelController`, opened by the walk-up prompt on the Backboard and as the third tab of
  the Daily reward / Quests tab row; no menu button): on the right so the wheel stays in view; every prize with its colour
  and exact chance, the Spin button (SPIN · FREE / SPIN · 200 Coins / no free spin left), the free-spin countdown, the
  paid-spin price or why paid spins aren't offered, and a highlight that runs down the list and lands on the server's
  answer ("You won 250 Coins!"). Data: `Wheel = { FreeDay }`, `Styles.BonusSpins` (new template fields; `DataService`
  now reconciles again after migrations so a rebuilt table gets fields added later). Dev panel → Daily → "Wheel spin"
  makes today's free spin ready again. docs/LAUNCH.md's maturity note now names wheel spins too.
  **No screen (owner, 2026-10-20: "make spin wheel separated from quests, no click UI, have to walk to spin, make prize
  show in wheel too"):** the Screen above and its Daily reward / Quests tab are gone; you spin at the wheel. In front of
  it, on the mat, a `SpinButton` (gold base, wood post, gold housing, a big red `Button`) carries the client-made prompt
  (`WheelController`, `Config.Controls.Prompts` keys and range): "Free spin" while today's free spin is ready (the button
  glows Neon for that player), else "Spin · 200 Coins" held `Wheel.PaidHoldTime` = 1 s (no accidental spending) under
  "Next free spin in h:mm:ss", or — where PolicyService doesn't allow paid random items — only the countdown (pressing
  says why); in a private server "Spin" (pressing says the wheel only works in public servers). **Odds on the wheel:**
  each slice has an invisible `Label` part (same `Segment`, facing the room, its up toward the rim) on which the client
  writes the amount ("1,000"; "+1" for the style spin, "?" for the mystery cosmetic), what it is (`Wheel.Slice.<Kind>`)
  and its exact chance in gold — every outcome and its odds are in view before a spin. **One spin at a time:** the
  server refuses another spin (`Busy`) for `Wheel.SpinTime` (4 s, the turn) + `NextSpinDelay` (2 s) after one; the
  prompt hides meanwhile. `WheelSpun` now also carries the spinner's UserId: when the wheel lands, the winning slice
  blinks on every client and the spinner gets a notice ("You won 250 Coins!", the cosmetic by name); refusals are
  notices too. The wheel model streams in whole (`Atomic`) so every slice and label is there at once.
- **The bartender (owner, 2026-10-20: "bartender no animation just make look alike npc not just block"):** the lobby's
  block figure (box legs, torso, ball head) is replaced by a real Roblox character. The map keeps only invisible anchors
  in the `ShopNPC` model: `Spot` (on the floor 3.5 studs behind the counter, facing the room) and `Torso` (where
  `LobbyPromptController` puts the Shop prompt, so the prompt works even if the character can't be built).
  `Services/NpcService` (server, Start) builds the character there with `Players:CreateHumanoidModelFromDescription`
  (R15): the avatar of `Config.World.Bartender.UserId` when it is set and the web call works, otherwise the built-in
  bartender — the default body with each part coloured (white shirt sleeves, dark vest, trousers, dark shoes, skin head
  and hands; the BodyColors is removed so it can't put the limb colours back), a default face if the head has none,
  and welded decor parts (apron bib + apron, red bow tie, a round rust bandana with a knot at the back, a moustache).
  No animation, as asked: the root is anchored, the name and health bar are hidden, and it isn't registered with
  CombatService (only players and the dev dummy are fighters); `AnimationController` only poses players. Studio
  Output shows `[Npc]`. Not seen in Studio yet: the decor's fit on the default head / torso sizes.
  **Phrases** (the fix list's "bartender phrases", without the animation): `BartenderController` shows the bartender's
  lines in a speech bubble over its head (a cream rounded box with a tail, a `BillboardGui` in the player's PlayerGui
  adorned to the head, or to the Torso anchor if the character isn't there; it pops in, types itself out, shrinks
  away). Only the local player sees their bartender's lines (nothing goes through the server; two players at the bar
  each get their own). When and what is the pure `Client/Lib/BartenderRules` over `Config.World.Bartender.Talk`:
  coming within `Distance` = 20 studs greets (at most once per `GreetCooldown` = 90 s); after a round you fought in
  (your row in `RoundResults`), the next time you are near you get a Won line (placement 1) or a Lost line instead,
  once; staying near brings an Idle line every `IdleEvery` 15–28 s, never over a line still showing; opening the Shop
  near the bar (`MenuController.openName()` turns "Shop") says a Shop line and a Coins purchase there
  (`ShopController.Bought`) a Thanks line. A line stays 2.5 s + 0.05 s a character, 3–7 s (`ReadTime`). Pools and
  sizes: Greet 6, Idle 14 (the 13th and 14th, about the arm-wrestling and chess tables, came with them; tips: the centre never falls, the crumble eats the edges, barrels, Perfect Dodge, charging,
  percent; the wheel, daily deals, the jukebox's promo codes; jokes), Shop 4, Thanks 4, Won 4, Lost 4 — strings
  `Bartender.<Pool>.<n>` (a spec checks every pool has exactly its count). No alcohol: the bar serves root beer.
- **Lobby arm wrestling (owner, 2026-10-20: "arm wrestling first", of the optional "chess and arm-wrestling minigames"):**
  my picks, all in `Config.World.ArmWrestle` (tunable): no Coins at stake (nothing to farm or gamble), a win counts
  toward the new lifetime stat `ArmWrestleWins` (not in private servers, not against the bot; no quest or leaderboard
  uses it yet) and the table's champion streak. **Table** (`Furniture.armWrestleTable`, `maps/layouts/Hideout`
  `ARM_WRESTLE` = (0, −10), the open middle between the lounge and the pool table, on a small rug under a pendant):
  dark wood top (surface 3.2 studs up) with a gold edge and centre line, two leather elbow pads, two red pin pads where
  a beaten hand lands, gold grip pegs for the free hands, two posts on feet out to the sides (the sitters' legs fit
  under the top), and two stools (seat top 2.0) facing each other along X, each 0.5 studs to its sitter's left so the
  right hands meet over the middle. The model is tagged `ArmWrestleTable` (its `Top` part carries the board); each
  stool's Seat is tagged `ArmWrestleSeat` with `Side` 1 (west) / 2 (east) and stays a `LobbySeat`, so `SeatController`
  shows its prompt — "Arm wrestle" instead of "Sit" — and `SeatService` seats players as usual. **Rules** (pure
  `Shared/ArmWrestleRules`, spec-tested): Waiting until both seats are taken → Countdown (`CountdownTime` 3 s) → the
  Pull (`PullTime` 15 s): each `ArmWrestleTap` (the Attack action, or the touch PUSH button) moves `Progress` (−1 … 1)
  `PushPerTap` = 0.05 toward the presser; presses count through a per-side token bucket (`TapRate` 10 a second, burst
  `TapBurst` 3), so autoclickers gain nothing over a quick finger; ±1 is a pin and wins at once, otherwise the side
  ahead when time runs out (dead even = a draw); the Result shows `ResultTime` 3 s, then the next countdown starts
  while both stay seated. Standing up (jump) during a countdown or a pull cancels it, with no result. The champion is
  the last winner with their wins in a row at that table, forgotten when they leave the server. **Server**
  (`ArmWrestleService`): one match per table, the seats' `Occupant` changes and the presses drive it, a 0.1 s tick
  moves it on; it mirrors the match onto the table model's attributes (`State`, `Progress`, `EndsAt` in
  `Workspace:GetServerTimeNow()`, `Player1` / `Player2`, `Winner`, `Champion`, `Streak`) and each wrestler's character
  (`ArmWrestle` = their own view of the progress). **Client** (`ArmWrestleController`): for the two wrestlers a bottom panel ("You" against the other in their side colours,
  the bar from their own side, the countdown, "PUSH! 12s" with the Attack key's box and "Mash to push!", or a big
  PUSH button on touch, then "You win!" / "You lose!" / "Draw!", and between matches "Table champ: name · n in a row"). There
  was a floating board over the table for everyone until the owner asked to remove it (2026-10-20: "remove floating
  label on minigame"); the champion line moved into the panel. **Pose** (`Shared/Animation/ArmWrestle`, a layer in
  `AnimationController` while `ArmWrestle` is set): the right upper arm reaches forward and down to the elbow pad, the
  forearm stands up to the clasp and leans up to 65° toward the winner's left (the hands go down on the loser's
  side), the waist leans in and twists into the push, the arms tremble while it's close, the left hand rests by its
  peg. Tuned without Studio, like the other clips: the reach depends on the avatar's size, and Roblox's own sit
  animation still plays under it. Developer panel → Spawn → "Arm wrestle bot": sit at the table first; a practice bot
  takes the empty seat (no character) and presses `Dev.ArmWrestleBotTaps` = 6 times a second; it leaves when you stand
  up. The bartender has a 13th idle line pointing at the table.
- **Lobby chess (owner, 2026-10-20: "continue with chess"):** my picks, in `Config.World.Chess` (tunable): 5 minutes a side
  plus 3 seconds a move (a lobby game can't stall: an idle player's flag falls), the west seat always plays White
  (switch seats to switch colours), a rematch starts `NewGameDelay` = 10 s after a game while both stay, and no Coins at
  stake — a win counts toward the new `ChessWins` stat (not in private servers, not against the bot). **Rules**
  (pure `Shared/ChessRules`, shared by server and client): 64-square boards (index = rank × 8 + file + 1), FEN in and
  out, every rule (castling not out of / through / into check, en passant, promotion to Q / R / B / N, check,
  checkmate, stalemate, insufficient material, the 50-move rule, threefold repetition by position key); `chess.spec`
  checks it against the standard perft counts (start position to depth 3, Kiwipete to 2, positions 3 and 4 to 3,
  position 5 to 2). **Game flow** (pure `Shared/ChessMatch`): Waiting → Playing as soon as both seats are taken →
  Over; clocks run on the side to move (`Clocks` + `TurnStartedAt`, `Increment` per move); results Checkmate,
  Resigned, Time (a draw when the other side can't mate), Left (standing up mid-game loses), Stalemate,
  Insufficient, FiftyMoves, Repetition, Agreed (a draw offer lapses when the other side moves instead). **Server**
  (`ChessService`): one match per table, the seats' `Occupant`, `ChessMove` (from, to, promotion; checked against the
  legal moves) and `ChessAction` (Resign / OfferDraw / AcceptDraw) from the seated players, a 0.2 s tick; table
  attributes `State`, `Fen`, `Player1` / `Player2` (seats), `White` / `Black` (the game's players, kept after one stands
  up), `Clock1` / `Clock2`, `TurnStartedAt`, `LastMove`, `Check`, `DrawOffer`, `Result`, `Winner`, `EndsAt`. **Lobby**
  (`maps/layouts/Hideout` `CHESS` = (−22, 15), on a rug under a pendant — the lobby's 12th shadow-casting lamp, the
  maps spec's cap): `Furniture.chessTable` — a dark wood table with a gold edge on a pedestal, a wood-framed board
  (`Board` part, `SquareSize` 0.55) of 64 squares (palette `ChessLight` / `ChessDark`, a1 dark, ranks toward +X,
  files a → h toward +Z), two stools facing each other along X (`ChessSeat`, `Side`, still `LobbySeat`s: the prompt
  says "Play chess"). **Client** (`ChessController`): the pieces on the lobby board for everyone — built from parts
  (pawn, rook with merlons, knight facing the other side, bishop, queen, king with a cross; cream / dark), only
  changed squares rebuilt — with the last move tinted and a checked king marked red; and for the two players the board screen (its floating board over the table was removed at the owner's
  request, 2026-10-20: "remove floating label on minigame") (the board
  from their side, pieces as cream / dark tokens with the outline chess symbols ♔♕♖♗♘♙ — none of them an emoji —
  or letters with `PieceLetters`; tap a piece for its moves: dots, rings on captures; tap the square; a promotion
  picker; coordinates on the edge squares; both clocks, red under 20 s; status: your move / they're thinking / check
  / their draw offer / the result and the next game's countdown; Resign (tap twice) and Offer / Accept draw; a
  gamepad starts on your king). Developer panel → Spawn → "Chess bot": sit at the table first; a bot takes the other
  seat and plays a random legal move `Dev.ChessBotDelay` = 1 s after yours. The bartender's 14th idle line points at
  the table. Review fixes (same day): while your game is on, jumping is off (`ContextActionService` sinks
  `CharacterJump`; jump height 0 hides the touch jump button) and the screen says "Resign to leave the table" — standing
  up mid-game loses, so a stray key would have lost it; both tables' clients drop their boards and pieces when the
  table leaves (`GetInstanceRemovedSignal`: the lobby streams out during a round, streaming radius 256, arenas 800
  studs away).   the table. Not checked in Studio yet: whether the chess symbols render on every device (if they show as boxes,
  set `PieceLetters = true`), the 3D pieces' look, and the board screen on a phone.
- **Detailed props and structures (owner, 2026-10-20: "improve map … more detail in every item"):** the first part of
  the arena rebuild (the owner picked one arena first, Broken Highway, with moving parts). Each item keeps its Config
  box as an invisible part that does everything a rule touches — collisions, attack boxes and explosions,
  grabbing (distance to its edge), carrying (the hold weld is found by name), throwing (a fresh server-owned copy,
  dressed again), physics, despawning, structures falling with their platform — and `Server/Visuals/ItemDetail.dress`
  welds the look onto it: massless parts with CanCollide / CanTouch / CanQuery off (named "Detail"; parts under 1
  cubic stud cast no shadow). The look is pure data in `Shared/ItemShapes` (Shape, Size, At from the item's centre
  with −Z its front, Turn, Upright / Facing for cylinders, a colour or a Tint of the item's colour, material,
  transparency, reflectance, Lit) and `ItemShapes.offset` places a shape; the items spec checks every corner of
  every shape is inside the item's box (0.2 studs of slack), so what you see is what you hit. Props (all 11): a folding
  chair, a bucket with rim / bands / handle, a tyre with treads, rim, hub and lug nuts, a striped traffic cone, a crate
  with edge beams and braces, a CRT TV with screen, knobs and antenna, steel drums with hoops / lid / bung (the
  explosive one adds a yellow hazard band and black diamonds, and its paint — `Lit` — glows when lit:
  `ItemDetail.light`), a fridge with two doors and handles, a car door with its window and mirror, a vending machine
  chunk with shelves, cans and a glass shard. Structures (Broken Highway's, the others come with their arenas): the
  wrecked car (body, hood, trunk, caved roof on pillars, glass, three wheels and a bare drum, bumpers, lights,
  grille, rust), the vending machine (cabinet, lit sign, glass front over 16 cans on 4 shelves, buttons, coin slot,
  pickup bin) and the road barrier stack (two barriers with reflective panels and amber lamps). Damage now darkens
  every visible part of a structure (`Structure.Paint`).
- **Broken Highway rebuilt with shapes and moving parts (owner, 2026-10-20: "improve map to more dynamic not just flat
  platform, more layer, more detail in every item"; picked "shaped + moving parts" and "one arena first"):** the
  platforms, gaps, heights and spots stay (every rule of the maps spec still holds); each platform gets real shape
  from `maps/lib/Pieces` (wedge ramps between levels, stairs with nosing strips, steel railings, jersey road barriers
  with reflectors, columns, lamp posts — every other one lit —, tyre stacks, crates, shipping containers with ribs and
  doors, a bus, a planter with a dead tree, rebar), all inside the platform's model so it crumbles with it. Centre:
  deck guardrails and lane dashes; a diamond-plate catwalk at +14 on four columns over the deck, 4 steps of 2 up from
  the deck, a bridge north to the lift's top stop; the swinging sign's frame (posts and a beam, a DANGER sign); a
  broken flyover ramp on the south-west rising to +8 and ending in mid-air on two pillars, with rebar; a container
  tower (+6, +12; a crate to start); a fallen container (+6) with a crate; 5 barrier lines; a planter; 0.5-high
  sidewalks along the long edges with 8 lamp posts. East: a toll plaza — two booths on kerb islands (crate → roof),
  barrier arms, a canopy at +11 on 8 columns with neon strips and a TOLL PLAZA sign, crate stacks at its edge to climb
  it. West: a collapsed road slab up to +6 with rebar, a crashed bus (+5.5), a barrier, lamps. North: a parking deck
  slab at +7 (6 studs of headroom under it) on 6 columns, a ramp up, railings, parking lines, crates and tyres on top.
  South: a bus shelter (roof +5.5, glass back wall, bench), a billboard ("BRAWL TONIGHT · NO REFUNDS") on posts, a
  barrier. Ledges: low walls along the two outer edges (the corner stays open for the jump to the peak) and a crate.
  Peaks: a white rim and a floodlight. Lows: a 3-tyre stack and a barrier. Every road platform has a kerb; scenery adds
  six ruined overpass pillars with tilted road slabs standing in the sludge. **Moving parts** (`Shared/MoverRules`,
  pure + spec): an arena's Movers folder holds Mover-tagged models (`Arena.mover`: an invisible "Pivot" part as the
  PrimaryPart, Persistent streaming, never on a platform so they never crumble) with attributes Kind ("Lift" /
  "Slide": travel by Offset and back, Pause at each end, eased; "Swing": ±Angle about the Pivot's X or Z axis), Period
  and Phase. The server never moves them; every client moves its copy each physics step from
  `Workspace:GetServerTimeNow()` (`MoverController`: smooth, no network traffic) and gives each part its speed so a
  character standing on it rides along. `MoverService` works out where each Hazard-tagged part is from the same rules
  and knocks a fighter it touches along the swing (`Config.Maps.Movers`: 75 studs/s tipped 0.45 up, 0.6 s hitstun,
  once a second per fighter) through the new `CombatService.push` — no damage, no Percent, no KO credit (a fall still
  counts for whoever hit them last), spawn shields and dashes let it pass, and a CombatHit with no attacker (source
  "Hazard") gives the tumble, sparks and the thud. Broken Highway's movers: a lift (8 × 8 diamond-plate pad from the
  centre's floor to the catwalk bridge, +13, 11 s round trip with 3 s stops), the swinging sign (a broken EXIT sign on
  chains under the beam, ±55°, 3.6 s; it sweeps across the deck at head height) and a sliding bridge (a flatbed flush
  with the centre and South in the 10-stud gap between them, sliding 80 studs along it, 14 s). Limits: the server's
  copy stays at rest, so a prop dropped on the lift doesn't ride it. **New spec checks** (all arenas): nothing solid
  (CanCollide) stands within 6 studs above a spawn, prop or barrel spot or a structure's footprint, and a lift's or
  slide's whole path runs into nothing — the first run found the centre's tilted underside slab poking up to 2 studs
  through the road around x 55–84 (since 1.4), now lowered by what its tilt raises it. Junkyard Isles and Neon Motel
  come next in the same style after the owner's look.
  **Connected, sky roads, abyss, smog (owner, same day: "want more layer structure and outer platforms more connected,
  even connected still can crumble; change the neon fall void and the sky"; asked: a "dark abyss", and a sky that
  "matches the arena style, but not this clear like now"):** `Layout.Bridges` lists 15 bridges — the ring East ↔
  LedgeNE / LedgeSE, West ↔ LedgeNW / LedgeSW, North ↔ LedgeNE / LedgeNW, South ↔ LedgeSE / LedgeSW, each side ↔ its
  low platform, LedgeNE ↔ PeakNE and LedgeSW ↔ PeakSW, and the centre ↔ East / West / North (South already has the
  sliding bridge). `Arena.bridgeEnds` finds where a bridge meets each platform (straight across the gap at `Along`
  for side-by-side platforms, corner to corner diagonally), and each platform's `decorate` builds its own half up to
  the middle with `Pieces.span` (a sloped deck with kerbs, a dashed centre line and girders, `Bridge` attribute "A-B")
  in arena-origin coordinates (`B.within` back from the platform's top), so the half is part of that platform's model:
  when it crumbles, its half falls and the other half is left as a broken stub. Slopes stay walkable (the low and
  peak bridges are the steepest, about 31°). **Sky roads** (`Layout.SkyRoads`): elevated highways 8 wide from the
  catwalk's north-east and south-west corners (+14) to the far corners of the peaks (+12), cut by `Arena.splitRoad`
  into one piece per platform they pass over (centre, corner ledge, peak; each cut in the middle of the gap), each
  piece on two pillars on its own platform; a crumbling ledge breaks the road there. To make room, the catwalk's
  railings open at those corners, the swinging sign's posts moved out to z ±26 (beam 53 long) and the end lamps to
  x ±110. **The abyss** replaces the green neon sludge: five 2800-wide sheets of mist below KillY, darker and more
  solid with depth (12 / 40 / 80 / 130 studs below, the last solid black), and the six ruined pillars reach 200 studs
  down into it. **The sky:** a new `Smog` lighting preset (Broken Highway only; Junkyard Isles keeps `Dusk` until its
  rebuild): the sun low at 17:51 behind a dense brown-orange haze (Atmosphere density 0.42, haze 2.6), a slightly
  desaturated grade and Roblox's dynamic clouds (`Clouds` in a preset: cover 0.78, density 0.65, rust tint;
  `MapService.applyLighting` makes / updates `Workspace.Terrain.Clouds`, and turns them off for presets without).
  The maps spec's marker check now tests rotated parts exactly (separating axes; the first version's bounding boxes
  made a long diagonal road look like it covered a ledge's prop spot); new checks: every bridge has one half on each
  of its platforms at a slope of at most 35°, and each sky road starts on the catwalk, ends on a peak and its pieces
  join and are carried by their platforms.
  **Then (owner, same day: "didn't expect many roads to connect — more structure, I mean like higher places"; on
  connections: "some short, some long, some gaps, not too boring"):** the sky roads are gone (and `Arena.splitRoad`
  with them; the catwalk's railings and the end lamps' new places stay), and `Layout.Bridges` keeps six — short:
  centre ↔ East, centre ↔ North, West ↔ LowWest, LedgeNE ↔ PeakNE; long: North ↔ LedgeNE (79), West ↔ LedgeSW (39) —
  every other neighbour is a jump again. Height comes from structures instead: a third container on the tower (+18;
  each level leaves room to stand and jump up 6), the parking garage's roof deck (+14 over its east half, on columns,
  a ramp up from +7, railings), a control booth on the toll canopy (roof about +17; a crate beside it), a broken
  overpass pier on West beside the collapsed slab's high end (a +12 deck on two columns, rebar), a service catwalk
  along the billboard's foot (+7; a crate stack) and a steel sign deck on four posts on every corner ledge (+7 above it;
  a crate). The maps spec's bridge check now runs for every arena that lists bridges: one half on each platform, a
  slope of at most 35°, at least two short and one long bridge, and no more than 8.
- **Junkyard Isles rebuilt the same way (owner, 2026-10-20: "if done, continue Junkyard Isles and Neon Motel the same
  way"):** the platforms, gaps and spots stay. **Structures:** `ItemShapes` gains the crushed car stack (three flattened
  cars, each with a window band, wheels and a bumper, turned against each other, two steel straps) and the scrap pile
  (a rusty mound of two wedges and a block with pipes, bent sheets, a tyre, a drum and a gear). **Shapes and higher
  places** (`maps/lib/Pieces` plus a `carBlock` and `scaffoldDeck` in the layout): centre — a junk tower (container +6,
  a second container across it +12, a crushed-car block +17; a crate to start), a car crusher (+8 with a hydraulic
  frame, a squashed car and a ramp up), four junk heaps (plus-shaped rusty mounds 3.5–4 up with a wreck on top), and a
  magnet crane (mast and arm along the north side); East — a container stack (+6 / +12) under a four-legged container
  crane whose top walkway is +18 (railing), and a side container (+6); West — a stepped pile of crushed cars in four
  layers (+10); North — a scaffold beside the old crane: decks at +5, +10 and +15, each next to the one below, with the
  crane cab on the top one; South — a two-storey wheelhouse (+5, then +9.4) with a smokestack and a container on the
  deck; ledges — two tyre towers on their side corners (the outer corner stays open); peaks — tyre piles; rafts — a
  tyre stack. **Movers:** `Magnet` (a swing about Z: ±40°, 4.2 s, the disc at head height sweeping 11 studs each way at
  (−20, 88); Hazard), `Elevator` (a lift beside the junk tower, +11 to the second container, 10 s), `Raft` (a plank
  raft sliding 90 studs along the 12-stud centre–South gap, about level with both, 16 s). **Bridges:** gangways (the new
  `Pieces.span` style "Gangway": diamond plate with yellow railings on posts) — short centre ↔ East / West, South ↔
  LowSouth, LedgeSW ↔ PeakSW; long East ↔ LedgeNE and North ↔ LedgeNW (46 each); `Arena.bridges(layout, platform,
  build)` now builds any layout's halves (Broken Highway uses it too). **Void and sky:** the same dark abyss as Broken
  Highway, with five towers of crushed cars rising out of it; the drifting drums lost their green; the new `Rust` preset
  — a stormy rust sunset (sun just setting at 18:03, grey-violet clouds at cover 0.72 / density 0.78 lit orange, a
  dusty rust haze).
- **Neon Motel rebuilt the same way (owner, 2026-10-20):** the platforms, gaps and spots stay. **Structures:**
  `ItemShapes` gains the ice machine (cabinet, a glowing blue header, the bin door with a chrome handle, a vent
  grille, the coin box, feet, ice cubes on top) and the lawn chair stack (two stacks of plastic chairs, three and two,
  each a seat, a tilted back, arms and legs). **Higher places** (the layout's `hut`, `stiltDeck` and `waterTank` plus
  `maps/lib/Pieces`): main roof — two raised roof sections (+3 with skylights and an AC unit), a machine room (+7.4) with a
  steel deck on legs over half its roof (+13) carrying a wooden water tank you can stand on (+18), the service lift's
  shaft beside it, and a neon sign tower (two legs, a catwalk at +10 under a big flickering MOTEL sign with teal tubes;
  crates to climb); pool roof — a high-dive tower (decks +5 and +10 side by side, the high board out over the water)
  and a cabana (+5, pink canopy, loungers); West — a maintenance catwalk along the MOTEL sign (+7) and a stairwell hut
  (+6.4); North — a two-storey penthouse (+6.4, +11.8); South — a water tank on stilts (+8, tank top +13); ledges NE,
  NW and SE — a rooftop hut (+5.4, with a lit door). Crates lead up everywhere. **Movers:** `OpenSign` (a neon OPEN
  sign on chains under a frame on the main roof's east side: a swing about Z, ±50°, 3.8 s, at head height; Hazard,
  the new string `Map.NeonMotel.Sign.Open`), `ServiceLift` (+12 to the tank deck, 11 s), `WindowCleaner` (a platform
  sliding 84 studs along the 10-stud gap between the main roof and the pool roof, 15 s). **Bridges:** gangways —
  short centre ↔ West / South, East ↔ LowEast, LedgeNE ↔ PeakNE; West ↔ LedgeNW (22) and South ↔ LedgeSE (86). **Void
  and sky:** the dark abyss (a little more violet) replaces the flooded street, and the six sunken buildings with their
  neon signs now reach 165 studs further down into it; the `Night` preset gets heavy purple clouds (cover 0.8, density
  0.7). All three arenas are now rebuilt.
- **Social (3.7; parties removed 2026-10-19, see above):** parties lived in one server (`Server/Social/Parties`, pure; `PartyService` owns the state): up to 4,
  only the leader invites (anyone not in a party may, and becomes leader when someone accepts), invites last 30 s, a
  leaving leader passes the lead on, a party of one ends, the leader can remove members. What a party does (owner,
  2026-10-18, picked "queue together" + "spawn near each other"): when the leader stands on the join pad, members in
  the lobby who aren't AFK are queued too (RoundService's queue pass; Casual mid-round joins included), and at the
  round start each party takes the platform with the most free spawn points (`Round/SpawnPlan`; solos spread out;
  respawns are still random). No friendly-fire change. Clients read the Player attributes `PartyId` / `PartyLeader`:
  party members see each other's overhead names in `Party.Color` and a `[Party]` chat tag (only for their own party);
  `[VIP]` and the group's `[Crew]` tags show to everyone (`PlayerTagController`, one `OnIncomingMessage`). The Party
  screen (menu order 7) lists members and invitable players (friends marked) and the friend XP bonus you have now (the
  +10% per friend, max +30%, was already paid since 2.1). Group: `GroupRewardService` checks `GroupService
  :GetGroupsAsync` on join and every 120 s until paid, sets `GroupMember`, pays `Group.Scrap` once (saved in
  `Social.GroupRewardClaimed`, Onboarding transaction; waits for a public server); everything is off while
  `Retention.Group.GroupId` is 0. Party remotes accept negative UserIds (Studio test players).
- **Leaderboards (3.6):** six OrderedDataStores — `Leaderboard_<Stat>` (all-time) and `Leaderboard_<Stat>_W<week>`
  (weekly, a fresh store each Monday; `StorePrefix` in Config) for Wins, KOs and Level. All-time scores are the
  lifetime stats / level; weekly Wins / KOs are counted from `DataService.StatIncremented` into the player's
  `LeaderboardWeek`, and weekly Level = levels gained since the level they had when they first played that week (the
  bible says "weekly Level" without defining it). Every `RefreshInterval` (120 s) each player's changed scores are
  saved (also on leave and server close), then each board's top 50 is read (`GetSortedAsync`), display names come from
  `UserService:GetUserInfosByUserIdsAsync` (cached) and the boards go to every client in one `Leaderboards` event
  (well inside the DataStore budgets: at most 6 writes per player and 6 reads per 2 min). Nothing is saved from
  private servers. When DataStores fail (Studio without API access, or `UseMockInStudio`) the boards show the players
  in the server and say so. The lobby's three screens (tag `LeaderboardScreen`, attribute `Stat`) show the top 10,
  switching between all-time and this week every 10 s. (A Leaderboard menu screen with the top 50 existed until the
  owner's fix list removed it, 2026-10-19.)
  The player's own rank outside the top 50 isn't shown (an OrderedDataStore can't look it up cheaply).
- **Badges (3.5): skipped for now** (owner, 2026-10-17: "isn't badge have to pay first, and it not necessary rn").
  For later: Roblox lets each experience create a few badges a day for free (more cost Robux); the Config entries
  (`Retention.Badges`, BadgeId 0 = skipped) are ready for when they are made.
- **Quests (3.4):** the bible's numbers (`Config.Retention.Quests`: a pool of 7 daily quests, 3 a day; 1 weekly).
  Quests count lifetime stats: `DataService.incrementStat` fires `StatIncremented` and `QuestService` adds it to the
  player's active quests (a quest with a `Mode` counts only while a round of that mode runs: `RoundService
  .currentMode`, still set when Wins is counted at the round end). Each player's 3 daily quests are a shuffle seeded by
  the day and their UserId (Park–Miller, like the daily shop): different players get different quests, the same all
  day in every server, nothing saved but the progress (`Quests`: day, week, progress, done). Weeks start on Monday
  (the bible only says "reset 00:00 UTC"). A finished quest pays its Scrap at once (Gameplay, sku `Quest.<id>`) with
  a notice — no claim button. Because stats don't count in private servers, quests don't either. The Quests screen is
  4th in the left-edge menu (since 2026-10-19; tabbed with the Daily reward) and opens at the lobby's quest board too (`LobbyPromptController` target). Quest
  names / goals are `Quest.<Id>.Title` / `.Desc` strings.
- **Daily rewards (3.3):** the bible's numbers (`Config.Retention.LoginStreak`, `Playtime`). Saved per player in
  `Daily` (last claim day, streak day, today's playtime seconds and paid rewards; day numbers from
  `LoginStreak.ResetHourUTC`). The streak is claimed with a button (`ClaimDaily`), not paid on join, so the player
  sees the calendar; the screen opens by itself 3 s after the data loads when a reward is waiting (once a session,
  not while fighting). Day 7's "weekly rotating cosmetic" is a deterministic pick from the cosmetics sold for Scrap
  by week number (same for everyone, no saving); if the player owns it they get `FinalDayFallbackScrap` = 300 (new).
  After day 7 the streak starts again at day 1. Playtime counts only non-AFK time (`RoundService.isAFK`, the same
  45 s rule as rounds), ticks every 15 s and is saved, so leaving and rejoining the same day keeps it; each reward
  sends a notice. Neither is paid in private servers (`PrivateServerService.paysRewards`); the screen says so. Scrap
  is logged as `TimedReward` (skus `LoginStreak.Day<n>`, `Playtime`). The Server menu moved to the end of the
  left-edge menu (order 9). Since 2026-10-19 the Daily reward has no menu button (it pops up, and is a tab of Quests).
- **Private servers (3.2):** the bible's three controls only (the owner skipped the extras question; no solo start,
  so a private server can't be used to farm rewards alone: rounds still need `MinPlayers` on the pad). The owner's
  choices live in their saved data (`PrivateServer`: Mode, Map, RoundTime), so they follow the owner to every private
  server they own; they apply once the owner's data loads (friends who start the server without the owner get the
  defaults until then) and from the next vote / round. A locked mode or picked map is the only option on the ballot
  (the vote panel shows one choice); round lengths are `Config.Round.PrivateRoundTimes` = 2:00 / 3:00 / 5:00 (new,
  the bible gave no values; 3:00 = `RoundTime` is the default). **Owner, 2026-10-17: "make private server only for
  play and test, no cash or level etc gain in this"** — so `Economy.PrivateServerRewardScale` = 0 (no round Scrap /
  XP, so no levels) and `Economy.PrivateServerProgress` = false (no lifetime stats: `PrivateServerService
  .countsProgress()` gates RoundService's and StructureService's `incrementStat`; quests, badges, leaderboards and
  playtime rewards must ask it too). Robux purchases, the Shop and the dev panel still work. The results line reads
  "Private server: nothing is earned here"; the join notice and Server menu say the same (both fall back to a
  percentage text if the scale is ever raised again). Before that change: rewards used
  `Economy.PrivateServerRewardScale` 50%
  (2.1 already applied it), now asked from `PrivateServerService.isPrivate` so the Studio simulation pays 50% too.
  Every player gets a `Notify` on joining a private server. The Server menu is the third left-edge button, visible
  only to the owner. Studio: dev panel "Private on/off" (Round section) makes the playtest a private server owned by
  you; it is refused outside Studio.
- **Monetization (3.1):** everything is built switched off: every pass / product id in `Config.Monetization` is 0
  until the owner creates them (Creator Dashboard → Monetization), and an item with id 0 shows "Coming soon" in the
  Shop. Perks (VIP, EmotePack, Premium) are what a player has right now: passes are checked with
  `UserOwnsGamePassAsync` when the data loads (3 tries, 2 s apart: `WebRetries`) and set at once by
  `PromptGamePassPurchaseFinished`; Premium is `MembershipType` (re-read on `PlayerMembershipChanged`). Perk
  cosmetics are saved into `Cosmetics.Owned` while the perk is there and taken back (and unequipped) once it is known
  to be gone (a refund, Premium ending); a failed check changes nothing. Robux cosmetics (new, bible "Premium
  cosmetics 99–399 R$": Inferno skin 149, Lightning Trail 99, Galaxy Burst KO effect 199) are products granted for
  good. The Emote Pack's 4 emotes (bible gave no names): Robot, Salute, Air Guitar, Backflip (the backflip snaps
  180° → −180° at the top so it ends upright; equal key times are now allowed in clips). VIP name tag: other VIP
  players' overhead name turns gold ("[VIP] name", `VIPColor`); chat: a gold "[VIP]" prefix (TextChatService
  `OnIncomingMessage`, owned by `PlayerTagController`; party / group tags join it in 3.7). The Robux tab (last tab)
  lists `RobuxOrder` plus a Roblox Premium card (`PromptPremiumPurchase`); exclusive items in the slot tabs open the
  prompt for what they come with. After a purchase the server sends a `Notify` thank-you (`NoticeController`, the
  first user of that remote; args can carry `{ Key = ... }` to localize names on the client). Analytics:
  `robuxPurchase` (kind, key, Robux) plus `scrapEarned` with the IAP transaction for Scrap packs. PolicyService is
  read once per player (`PlayerPolicyService`, attributes `PolicyPaidRandomItems` / `PolicyPaidTrading`); nothing
  at launch needs it. Developer panel "Robux" section: switch VIP / Emote Pack / Premium on or off for the session
  and get what any product gives (no receipt), to test while the ids are 0.
