# Junkyard Brawl — working notes for Claude

Read this first in every session. Full design spec: [docs/PROJECT_BIBLE.md](docs/PROJECT_BIBLE.md).

## Status at a glance

- **Build order approved** by the owner on 2026-10-15, with maps built from code (blockouts from layout data, art
  pass later) and data saving via ProfileStore.
- **Phase 1 (core loop) is built and playtested** (1.1–1.13; two rounds of owner playtest fixes, "all clear" on
  2026-10-16). **Phase 2 in progress:** 2.1 Round rewards, 2.2 Fighting styles, 2.3 Cosmetics + Locker and 2.4 Shop
  are built (2.2–2.4 not yet playtested; the Wrecker parry needs two players). Owner's lobby rework (2026-10-16):
  enclosed hideout bar lobby, join pad to enter rounds, no Training Yard (not yet playtested). **Next step:** 2.5
  Junkyard Isles + Neon Motel maps.

## How this repo works

The game is **code-first**: all Luau lives in `src/` and is synced into Roblox Studio with
[Rojo](https://rojo.space). Cloud sessions (claude.ai/code) have **no Studio MCP connection**, so they write code and
rely on CI; visual building, screenshots and playtests happen in Studio (owner, or a local Claude Code session with the
Roblox Studio MCP server).

### Local setup (owner)

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in the repo (installs Rojo, Selene,
   StyLua, Lune at the versions in `rokit.toml`).
2. Install the Rojo Studio plugin (`rojo plugin install`).
3. Run `rojo serve`, open a place in Studio, click **Connect** in the Rojo plugin.
4. Game settings in Studio: enable **Studio Access to API Services** (for DataStores) and turn on automatic translation
   in the Creator Dashboard.
5. Alternative without Rojo: download the `JunkyardBrawl-place` artifact from the latest CI run and open the `.rbxlx`.

### Repo layout

| Path | Becomes in Studio | Contents |
| --- | --- | --- |
| `src/shared/` | `ReplicatedStorage.Shared` | Config, formulas, settings rules, types, networking, utilities |
| `src/server/` | `ServerScriptService.Server` | `Main.server.luau` + `Services/` (one module per system) + `Combat/`, `Round/`, ... (pure rules) + `Visuals/` (character models) |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | `Main.client.luau` + `Controllers/` (input, HUD, camera, VFX) |
| `src/client/Lib/` | `...Client.Lib` | Pure client logic tested by specs (action map, touch layout, camera shake, dash rules) |
| `src/client/Ui/` | `...Client.Ui` | `Kit`: shared look (colors, fonts) and builders for panels, labels, buttons |
| `src/localization/GameStrings.csv` | `LocalizationService.GameStrings` | Every player-facing string (Key, Source, Context, Example) |
| `src/server/Vendor/` | `ServerScriptService.Server.Vendor` | Third-party modules kept as published (see `licenses/`) |
| `maps/layouts/` | — | Map layouts as code (platform sizes, spots, decor) — the source of truth for blockouts |
| `maps/generated/` | `Workspace.Lobby`, `ServerStorage.Arenas.*` | `.rbxmx` models generated from the layouts (committed) |
| `tools/` | — | Lune helpers shared by tests and the map generator |
| `tests/` | — (not synced) | Lune runner `tests/run.luau`, specs in `tests/specs/*.spec.luau` |
| `docs/` | — | Design bible and other docs |

`Shared/Util/Loader` boots every ModuleScript in `Services/` (server) or `Controllers/` (client): all `Init()` run
first in `Priority` order, then each `Start()` runs in its own thread.

### Commands

```sh
stylua src tests            # format (CI runs stylua --check)
selene src                  # lint
scripts/typecheck.sh        # strict type-check with luau-lsp + Roblox API types
lune run tests/run          # syntax-compile every src/*.luau + run specs
lune run maps/build         # regenerate maps/generated/*.rbxmx after editing maps/layouts (a spec checks this)
rojo build default.project.json -o build/JunkyardBrawl.rbxlx
```

Files are LF on every OS (`.gitattributes`); StyLua's check and the maps spec fail on CRLF copies.

## Conventions (required)

- Every script starts with `--!strict`. Tabs, 120 columns, double quotes (StyLua enforces).
- **Server-authoritative:** clients send *intents* only ("I pressed punch"). The server checks cooldowns, distance,
  state and currency, decides hits/knockback, and replicates results. Never trust client positions or values beyond a
  sanity-checked tolerance.
- **All tunables in Config** (`src/shared/Config`). No magic numbers for prices, damage, cooldowns, rewards, odds or
  formulas anywhere else. Keep `docs/PROJECT_BIBLE.md` in sync when Config changes.
- **No hard-coded UI text:** every visible string is a key in `src/localization/GameStrings.csv`, shown with
  `Localization.format(key, args)`. A spec fails if code uses a key that is missing from the CSV. After adding keys,
  upload the CSV to the game's localization table in the Creator Dashboard so automatic translation picks them up.
- **Networking:** every remote is declared in `src/shared/Net/Definitions.luau`. Client → server remotes must list
  `Args` validators from `Net/Guard` (NaN/inf-safe, length-capped) and get a per-player rate limit
  (`Config.Net`, overridable per remote). Server code uses `Net.onServerEvent` / `Net.onServerInvoke`; it never
  touches RemoteEvents directly. Never use server → client invokes.
- **Player data:** only change it through `Services/DataService` (`addScrap`, `spendScrap`, `addXP`,
  `incrementStat`, `update`, `processReceipt`) so the owning client is synced and analytics are logged. New template
  fields are filled in automatically; renames/removals need a migration (`src/server/Data/Migrations.luau`, bump
  `VERSION` in `src/shared/Data/Template.luau`). Clients read their copy via `Controllers/DataController`.
- **Maps:** blockouts are generated from `maps/layouts/*.luau` by `lune run maps/build`; never hand-edit
  `maps/generated/`. Gameplay markers are tagged parts (`SpawnPoint`, `PropSpot`, `ExplosiveSpot`,
  `StructureSpot` with a `StructureType` attribute, `LobbySpawn`), visible in Edit mode and hidden by
  `Services/MapService` at runtime. The lobby's join pad is a visible `QueueZone`-tagged part (not a marker).
  Each arena platform is a `Platform`-tagged Model (Persistent streaming, `CanFall` attribute). Sign text comes from GameStrings keys (`LocKey` attribute on the label). For a final art
  pass a map can switch to a hand-built model: export it from Studio to `maps/<Name>.rbxmx`, point
  `default.project.json` at it, and remove it from `maps/build.luau`.
- **Input:** gameplay code never reads raw keys. It listens to `Controllers/InputController` (`ActionBegan` /
  `ActionEnded` with an action from `Config.Controls.Actions`; `getDevice()` / `DeviceChanged` for key hints). A new
  action needs a keyboard and a gamepad binding, a `Controls.<Action>` string, and a touch button in
  `Config.Controls.Touch.Layouts` if mobile players use it (a spec checks sizes and overlaps on many screens).
- **Combat:** every hit goes through `Services/CombatService`, which owns one `Server/Combat/Fighter` per combatant
  (player characters register automatically; anything else, like the dummy, calls `CombatService.register`). UI
  reads the character attributes `HP` (modes with HP) and `Percent`; listen to `CombatService.KnockedOut` for KOs.
- **Styles:** ownership and the equipped style go through `Services/StyleService` (`equip`, `equippedOf`); the rules
  (`Shared/StyleRules`: owns, unlockedAt) are shared with UI. Combat reads the equipped style through
  `Formulas.resolveAttack`.
- **Shop:** purchases go through `Services/ShopService` (`Buy` remote → `StyleService.grant` /
  `CosmeticService.grant`); what is for sale, prices and the daily rotation are `Shared/ShopRules`, shared with the
  Shop UI so both show the same price.
- **Lobby menu screens** (Shop, Locker, later Quests, Daily Reward, Settings ...) register with
  `Controllers/MenuController.addScreen(text, order, gui, onOpen)`: a left-edge button, one screen open at a time,
  closed while fighting; the Menu action (M / D-pad Up) closes the open screen or opens the first one.
- **Rounds:** `Services/RoundService` owns the loop, the scoreboard (`Server/Round/Scoreboard`), the lobby join pad
  (`Server/Round/Queue`: only players on it are taken into a round) and round stats. UI reads attributes: Workspace
  `RoundState`, `RoundEndsAt` (compare with `Workspace:GetServerTimeNow()`), `RoundMode`, `RoundMap`,
  `PlayersNeeded`, `PlayersQueued`; Player `RoundStatus`, `QueueStatus` (`In` / `AFK` / `Off`), `Lives`, `KOs`,
  `Falls`. Rewards and quests hook `RoundService.RoundEnded`.
- **Settings** (Settings menu values) are read and changed through `Controllers/SettingsController`; the server
  validates each change with `Shared/Settings` (`Services/SettingsService`). New numeric settings need a range in
  `Config.Data.SettingRanges`.
- **Vendored code** (`src/server/Vendor/`) is never edited and is excluded from StyLua/Selene/luau-lsp.
- **Analytics:** log through `Services/Analytics` helpers (`scrapEarned`, `scrapSpent`, `onboardingStep`,
  `mapVoted`, `roundModePicked`, `styleUsed`, `roundFinished`, `custom`).
- Pure logic (formulas, reward math, validation) goes in modules with no Roblox-instance dependencies so Lune specs can
  test it. Add specs for every formula. Specs load game modules through `tests/roblox.luau`, a fake DataModel built
  from `default.project.json`, so modules keep normal `require(script.Parent.X)` requires.
- Filter all player-written text with TextService before others see it.
- Never delete or replace large parts of the place without asking the owner.
- Only free Creator Store assets / Studio AI generation; ask before using anything paid.

## GitHub workflow (automated)

- Develop on the session's `claude/...` branch. One feature per PR.
- **CI** (`.github/workflows/ci.yml`) on every PR: StyLua check → Selene → luau-lsp strict type-check → Lune (syntax +
  specs) → Rojo build (uploads `JunkyardBrawl.rbxlx` as the `JunkyardBrawl-place` artifact).
- **Auto-merge:** when CI is green, PRs from `claude/*` branches in this repo are squash-merged automatically and the
  branch is deleted. To stop a PR from merging, open it as a **draft** or add the **`no-automerge`** label.
- After a merge, start the next feature from fresh `main` on the same branch name
  (`git fetch origin main && git checkout -B <branch> origin/main`).
- Before pushing, run the commands above locally; a red CI blocks the merge.

## Build order (approved 2026-10-15)

Each numbered item = one PR. After each: owner playtests in Studio (or a Studio-MCP session does), checks Output, and
any errors are fixed before the next item.

### Phase 1 — Core loop playable

- [x] **1.1 Config + Formulas** — every tunable from the bible in one Config module tree; pure formula module
      (knockback, hitstun, Percent, XP curve, ranks, streak multiplier, reward math) with Lune specs.
- [x] **1.2 Foundation** — typed remote layer with server-side rate limiting and argument validation, shared types,
      LocalizationTable (`GameStrings`) wiring, Analytics wrapper (so every later feature logs events as it is built).
- [x] **1.3 Data saving** — session-locked profiles, auto-save, BindToClose flush, retry/backoff, schema versions,
      purchase-receipt history (prevents duplicate grants). In-memory fallback when Studio has no API access.
- [x] **1.4 Maps framework + blockouts** — map layout data → builder that creates the Lobby (Rust Diner roof + Training
      Yard) and Broken Highway blockouts (exact sizes, gaps, spawn points, KillY, prop/structure spots); arenas live
      in ServerStorage, one active at a time; dusk lighting preset.
- [x] **1.5 Input + camera** — one action map for keyboard/mouse, gamepad and touch (mobile button arc ≥ 64 px), camera
      limits, Shift Lock, camera shake toggle.
- [x] **1.6 Combat core** — Punch chain, charged Shove, server hitboxes, HP/Percent, knockback + hitstun, KO credit
      (6 s), launch trail flag.
- [x] **1.7 Dash + Perfect Dodge** — server-timed i-frames, air dash once per jump, dodge bonus.
- [x] **1.8 Rounds + modes** — vote (map + mode, 15 s) → teleport → Classic / Casual rules → results → lobby; respawn,
      spawn shield, spectate, late joiners, AFK + 60 s participation tracking.
- [x] **1.9 Props** — spawn spots, grab/carry/throw (server-checked range and rate), weight classes, explosive barrel,
      40-prop cap, despawn.
- [x] **1.10 Breakable structures** — HP, prop drops, respawn.
- [x] **1.11 Crumbling platforms** — 3 s warning, fall, rules (center never falls, ≥ 2 remain).
- [x] **1.12 Basic HUD** — HP + lives / Percent, timer, mode badge, kill feed, dash ring, held prop, Tab scoreboard,
      spectate view; mobile / PC / gamepad.
- [x] **1.13 Developer panel (minimal)** — *moved up from Phase 3* so testing is faster: force map/mode, start/end
      round, trigger crumble, spawn prop, set Percent/HP. Server-checked UserId allowlist. Extended in Phase 3.

### Phase 2 — Progression & content

- [x] 2.1 Round rewards (Scrap/XP, streaks, placement, anti-farm, bonuses) + levels and rank titles
- [x] 2.2 Fighting styles: Slugger, Scrapper, Wrecker (parry) + welded weapon models
- [x] 2.3 Cosmetics system + Locker
- [x] 2.4 Shop (styles, cosmetics, 24 h UTC daily rotation)
- [ ] 2.5 Junkyard Isles + Neon Motel maps (+ night lighting preset)
- [ ] 2.6 Animations (R15)
- [ ] 2.7 VFX pass + Low Graphics setting
- [ ] 2.8 Music + SFX (per-map tracks, last-30 s tension layer)
- [ ] 2.9 Tutorial + first-round tips (the Training Yard it was planned in was removed with the lobby rework on
      2026-10-16: agree a new onboarding plan with the owner first)

### Phase 3 — Monetization, retention & polish

- [ ] 3.1 Game passes, dev products (idempotent receipts), Premium perks, PolicyService
- [ ] 3.2 Private server settings (owner controls, 50% rewards)
- [ ] 3.3 Daily login streak + playtime rewards
- [ ] 3.4 Daily + weekly quests
- [ ] 3.5 Badges
- [ ] 3.6 Leaderboards (all-time + weekly) + lobby billboards
- [ ] 3.7 Party system + friend XP bonus + group reward + chat tags
- [ ] 3.8 Codes
- [ ] 3.9 Full developer panel
- [ ] 3.10 Settings menu, loading screen, tutorial replay
- [ ] 3.11 Low-end mobile performance pass + localization check
- [ ] 3.12 Launch checklist support (owner-side: icon, thumbnails, maturity form, beta test)

## Progress log

| Date | Change | PR |
| --- | --- | --- |
| 2026-10-15 | Repo setup: Rojo project, toolchain, CI + auto-merge, Lune test runner, Loader, this file, project bible | #1 |
| 2026-10-15 | 1.1 Config tree (all bible tunables) + pure Formulas with specs; luau-lsp strict type-check in CI; `.rbxlx` artifact | #2 |
| 2026-10-15 | 1.2 Net layer (validated + rate-limited remotes), GameStrings localization, Analytics wrapper | #3 |
| 2026-10-15 | 1.3 DataService on vendored ProfileStore (session lock, autosave, receipts, migrations), client DataController | #4 |
| 2026-10-15 | 1.4 Lobby (Rust Diner) + Broken Highway blockouts generated from layout code, MapService (arena load/unload, lighting presets, falls, Studio preview pad) | #5 |
| 2026-10-16 | 1.5 InputController (one action map: keyboard/mouse, gamepad, touch arc around the jump button), CameraController (zoom 8–30, Shift Lock on Right Shift, camera shake), validated settings changes (SettingsService/SettingsController), Studio input log + debug keys; LF line endings | #6 |
| 2026-10-16 | 1.6 CombatService (Punch chain, charged Shove, server hitboxes, HP / Percent, knockback + hitstun, KO credit, trail flag) on a pure Fighter state machine; client knockback (Launch) + heavy-hit camera shake; right-drag cancels a Shove; Training Yard dummy; Studio hit log + hitbox flashes | #7 |
| 2026-10-16 | 1.7 Dash (client-moved, server-timed invulnerability, cooldown tolerance, once per stay in the air, ends a launch) + Perfect Dodge (one per dash, +25% knockback on the next hit within 2 s, `PerfectDodged` signal) | #8 |
| 2026-10-16 | 1.8 RoundService (Waiting → map + mode vote → Classic / Casual round → results), pure Vote + Scoreboard, respawn via Roblox respawn + spawn shield, spectate (ReplicationFocus), Casual late join + passive gain, AFK / active-time tracking, round stats + analytics; vote, results, spectate and status UI (Ui/Kit); Studio solo rounds | #9 |
| 2026-10-16 | 1.9 PropService (spots + respawn, grab / carry / drop / throw, server-swept flights, class blows, explosive barrels with fuse + chain, 40-prop cap, despawn), pure Carrier rules, CombatService refactor (shared blow path, hitWith / explode, Swung / Hit signals, interceptor, speed modifiers), Throw / Drop touch labels, prop + chair KO stats; gamepad Menu / Scoreboard on the D-pad | #10 |
| 2026-10-16 | 1.10 StructureService (structures on StructureSpots, damage from attack boxes / thrown props / blasts, darken with damage, break into drops, respawn 45 s, StructuresBroken stat), pure StructureRules, blockout sizes in Config, PropService.spawnLoose + Impact / Exploded signals | #11 |
| 2026-10-16 | 1.11 CrumbleService (from 1:00 every 20 s a random outer platform flashes red + shakes 3 s, then falls 4 s with everyone on it; center never falls, 2 always remain), pure CrumbleRules, RoundStarted signal, spawn points / prop spots skip crumbling platforms, structures fall with their platform | #12 |
| 2026-10-16 | 1.12 HUD (top bar: mode badge, timer, fighters left / score; kill feed; bottom bar: dash ring, HP + lives or Percent, held prop with key hints), hold-Tab scoreboard replacing Roblox's player list, KeyHint (key names / gamepad glyphs), pure HudFormat, KillFeed remote, prop names | #13 |
| 2026-10-16 | 1.13 Developer panel (Studio): DevService + DevRules allowlist, DevAccess attribute, panel (start / end round, crumble, next map / mode, spawn prop, set Percent / HP, camera shake checks), RoundService force / startNow / endNow, CombatService setPercent / setHealth; K / L keys removed. Phase 1 complete | #14 |
| 2026-10-16 | 2.1 RewardService (round payout: KO Scrap + streaks, Perfect Dodges, placement, completion, 60 s / AFK rules, VIP / Premium / friend bonuses, private-server scale; Scrap + XP + level-ups via DataService; rank attribute), pure Payout, RoundReward remote, results reward line, HUD profile chip | #15 |
| 2026-10-16 | 1st playtest fixes: throws launch a server-owned copy, grab takes ownership + "[E] Grab" prompt + Studio logs, fighters pass through each other (collision group), windups 0.05 s, dash 12 studs, stronger drift-free camera shake with tilt, client-drawn crumble (flash, shake, sink + fade) | #16 |
| 2026-10-16 | 2nd playtest fixes: throws aimed from the thrower's own view (facing + position, 8-stud tolerance), 25% gravity while flying, 15° aim assist; arena pillars belong to their platforms (crumble with them) | #17 |
| 2026-10-16 | 2.2 Fighting styles: Wrecker parry (0.2 s, reflects knockback onto the attacker), StyleService (level unlocks, EquipStyle, welded blockout weapons: bat, shovel, wrench + hubcap), shared StyleRules, DataService.LeveledUp, dev panel Style buttons | #18 |
| 2026-10-16 | 2.3 Cosmetics + Locker: launch catalog (skins, hats, dash trails, KO effects, victory emotes) with blockout visuals, CosmeticService (EquipCosmetic, skins / hats / trails / KO bursts), shared CosmeticRules, Visuals/Attached (shared with weapons), CombatService.Dashed, left-edge MenuController, Locker UI (styles + cosmetics), dev "All cosmetics" | #19 |
| 2026-10-16 | 2.4 Shop: ShopService (Buy remote: checks, spendScrap, grant; analytics), shared ShopRules (what is for sale, daily rotation of 4 cosmetics seeded by the UTC day at 20% off, purchase checks incl. price-changed), Shop UI (Daily deals with countdown, Styles, one tab per slot, purchase confirmation + Equip), MenuController screens (one open at a time, Menu action), dev "+5000 Scrap" | #20 |
| 2026-10-16 | Owner's lobby rework: enclosed hideout bar lobby "The Hideout" (bar counter = Shop, vote TVs over the bar, ARENA door, lockers, jukebox, quest board, leaderboard screens, pool table, booths, lamps) replacing the Rust Diner rooftop; Training Yard removed (practice dummy is now a dev panel "Dummy" button); join pad: only players standing on it (not AFK) start the vote, vote and are taken into a round (Casual: stepping on joins mid-round), everyone else stays in the lobby; QueueStatus / PlayersQueued attributes, pad status lines on the HUD, vote panel only on the pad | #PR |

## Decisions and interpretations

Where the bible is silent or ambiguous, these choices were made (all are Config values unless noted):

- **Placement rewards:** 1st place gets Win (+50/+100); 2nd–3rd get Top3. `Economy.WinnerAlsoGetsTop3` flips this.
- **Participation:** the 60 s rule covers the completion reward too, and only non-AFK time counts. AFK at round end
  pays nothing. KO and Perfect Dodge Scrap are paid regardless of time played.
- **Bonus cap:** VIP + Premium apply to Scrap, the friend bonus to XP; each currency's bonus is capped at +60%. The
  live-event multiplier (double-Scrap weekends) and the private-server 50% scale are applied outside the cap.
- **Codes** live in the server-only `ServerScriptService.Server.ServerConfig` (not the shared Config) so clients
  cannot read unreleased codes. `LAUNCH` is a placeholder.
- **Structures** take each attack's Classic HP damage in every mode.
- New tunables not in the bible: attack windups (Punch and Shove 0.05 s since the 1st playtest, needed for "dodge
  before the hit lands"), punch chain reset 1 s, hitbox latency padding 0.5 studs, launch angle 30°, throw arc +14 studs/s, throw
  cooldown 0.5 s, grab cooldown 0.3 s, results screen 8 s, minimum 2 players to start a round, platform fall 4 s.
- Robux prices in Config are reference only; live prices come from the Creator Dashboard. Pass/product/badge/group
  ids are 0 until created.
- **Controls (1.5):** Shift Lock toggles on Right Shift only (Left Shift is Dash), by rewriting the `BoundKeys` value of
  Roblox's MouseLockController at runtime. Camera zoom 8–30 studs (8 keeps it third-person; bible only gave max 30).
  Mobile buttons are placed around Roblox's own jump button (kept, not replaced): base size 17% of the screen's
  shorter side, 64–104 px, Attack 1.15×; the `ButtonLayout` setting picks a layout from
  `Config.Controls.Touch.Layouts` (only `Default` so far). Camera shake wobbles at 18 Hz and only moves the camera
  (never turns it). Setting ranges: volumes 0–1, camera sensitivity 0.25–2.
- **Combat (1.6):** knockback uses the victim's Percent *after* the hit (Smash-style). Launch direction = attacker →
  victim on the ground plane, 30° up. Whoever simulates the victim runs the launch (`Shared/Combat/Launch`): the
  victim's own client for players, the server for dummies; the Humanoid is PlatformStand (no steering) and held
  upright facing the attacker until hitstun is over and it has landed (max 3 s). An attack is lost if its attacker
  is hit during the windup; no punching while charging; a hit cancels a charge; the Shove cooldown starts on release
  and a cancelled charge has none. Heavy hits (Shove, punch finisher) shake the victim's camera (1.0) and the
  attacker's (0.4). Right-dragging the mouse 12 px while charging a right-click Shove cancels it (camera turn).
  The equipped style's multipliers already apply; the Wrecker parry comes with styles (2.2). PvP only between two
  players in the arena; the dummy can always be hit. The dummy respawns 2 s after a KO or falling 4 studs.
- **Dash (1.7):** the client moves at once (LinearVelocity, 48 studs/s for 0.25 s = 12 studs, level, along the move
  direction or else the facing) and sends `Dash`; the server grants invulnerability from when the intent arrives, accepting it up
  to 0.15 s before the cooldown ends (`Dash.CooldownTolerance`, network jitter). A dash cancels a Shove charge, and a
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
  (CombatService interceptor) and Shove is blocked; throws break the spawn shield. A spot's timer (20 s / 30 s for
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
  0.6. Ragdoll / tumble on big launches is deferred to the animations step (2.6).
- **2nd playtest fixes (2026-10-16):** throws were "really off": the server used its lagged view of the thrower and
  full gravity dropped a 90 studs/s throw ~6 studs over 30 studs. Now the client sends its facing and position with
  Punch (position used when within `Props.ThrowOriginTolerance` = 8 studs of the server's view), thrown props feel
  `ThrowGravityScale` = 25% gravity while flying (the server adds the rest back each frame), and `ThrowAimAssist`
  bends a throw toward a fighter within 15° / 80 studs of the facing (Angle 0 turns it off). Broken Highway's pillars
  now belong to their platform models, so they sink with a crumbling platform instead of staying behind. The owner
  re-tested and reported "all clear".
- **Fighting styles (2.2):** the equipped style's numbers have applied since 1.6 (`Formulas.resolveAttack`). New: the
  Wrecker parry — Shove Start opens a 0.2 s window (no charge; shares the Shove cooldown); a Punch / Shove landing in
  it misses and its knockback (no damage) goes back onto the attacker from the parrier, credited to the parrier and
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
  in the void). Victory emotes are data until animations (2.6); back items and name plates have no items yet (their
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
- **Lobby rework (owner, 2026-10-16):** "I need an area for players to be in to start the round — right now every
  player has to play, no time to shop", "delete the Training Yard too", and "a closed-space lobby, hideout mixed with
  bar style, not open like this". So:
  * **The Hideout** (`maps/layouts/Hideout.luau`, map id `Hideout`) replaces the Rust Diner rooftop: an enclosed
    92 × 68-stud room with a 22-stud ceiling. North: bar counter (Shop, `ShopCounter`), bartender (`ShopNPC`), bottle
    shelves, map vote TVs hanging over the bar, mode TVs on the counter ends, neon title sign. East: steel ARENA door
    (`ArenaDoor`) with the join pad. West: lockers, jukebox, quest board. South: leaderboard screens, spawns, street
    door. Pool table, booths, high tables, crates, barrels, warm hanging lamps (PointLights) under a shadow-casting
    ceiling. Same KillY rule (40 below the floor). The lighting preset is still Dusk (global): the inside is lit by
    its lamps and Ambient — check the brightness in Studio.
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
- **Round rewards (2.1):** `RewardService` pays every player still in the server when `RoundEnded` fires, through
  `Server/Round/Payout` → `Formulas.roundPayout` (the 1.1 rules), then `DataService.addScrap` (sku "RoundReward",
  logged as a Gameplay source) and `addXP`. Bonus inputs: VIP = game pass ownership (cached per session),
  Premium = `MembershipType`, friends = other players in the server you are friends with (`IsFriendsWithAsync`),
  private server = `PrivateServerId` with an owner (reserved servers do not count). The rank title is the player
  attribute `Rank` (a rank id, set on load and after rewards). The results panel shows "+Scrap · +XP", level-ups and
  a new rank; the HUD's top-right chip shows level · rank · Scrap. Lifetime stats were already counted in 1.8.

## Known bugs / open items

- None in code yet.
- **1st playtest (2026-10-16), owner's notes:** couldn't grab/throw props (fixed: see decisions), hits felt delayed
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
  2 players. A solo Classic round ends when you lose your 3 lives; a solo Casual round runs the full 3:00.
- **Studio combat debug:** `Config.Dev.LogCombat` prints every hit and KO; `Config.Dev.ShowHitboxes` flashes each
  attack box (red hit, grey miss). Studio only.
- **VIP bonus** stays off until the VIP game pass exists (`Config.Monetization.GamePasses.VIP.Id` is 0; step 3.1).
  Premium and friend bonuses already apply. In Studio, rewards are paid from solo rounds too (Output: `[Rewards]`).
- **All screens are plain first versions** (`src/client/Ui/Kit`: HUD, vote, results, spectate bar, scoreboard); the
  art / VFX passes restyle them. The lobby's CRT-TV vote screens from the bible are an art-pass item. The dash ring
  fills bottom-to-top (a true radial ring needs an image asset).
- **Props are plain blocks** (size / material / color from `Config.Props.Types`) until the art pass; a lit barrel turns
  Neon, explosions use Roblox's `Explosion` visual (no physics: `BlastPressure = 0`). Carry pose and throw animation
  come with 2.6. Flights are simulated by the server (props are server-owned while flying), so throws look slightly
  delayed on high ping.
- **Camera sensitivity** is saved and validated but not applied: Roblox does not let scripts change mouse/gamepad
  sensitivity. Needs a custom approach in 3.10.
- **Studio input debug:** `Config.Dev.LogInput` prints every action and device change to Output in Studio playtests.
  Test touch with Studio's Device Emulator (a phone in landscape).
- **Developer panel (Studio):** press ` (Backquote, `Config.Dev.PanelKey`) or click DEV (top left). Round: start now
  (starts the vote with one player on the join pad, or closes it), end now, crumble a platform; next map / mode (or
  back to the vote); spawn any prop or the practice dummy in front of you; set your own Percent (0 / 100 / 200) or
  HP (100 / 50 / 10); own + equip any fighting style; own every cosmetic; +5000 Scrap; test camera shake and switch
  the Camera Shake setting. Output shows `[Dev]` lines.
- **Data in Studio:** with "Studio Access to API Services" off, ProfileStore uses an in-memory store and prints
  "Roblox API services unavailable - data will not be saved". Turn it on to test real saving
  (`Config.Data.UseMockInStudio = true` forces the in-memory store even with access on).
- **Arena gaps** of 9–12 studs need a jump + air dash (1.7); worth confirming every gap in the playtest.
- **Perfect Dodge feedback** (blue flash, chime, "+5") comes with VFX/SFX/HUD (2.7, 2.8, 1.12); for now Studio's
  Output shows `PERFECT DODGE`. Rounds count them (stat + standings); the +5 Scrap is paid with round rewards (2.1).
- **Dash movement is client-side** (clients simulate their character), so the once-per-jump air rule is enforced by
  the client; the server enforces the cooldown and hitstun, which gate the invulnerability and Perfect Dodge.
- **Owner's Roblox UserId** is needed for `Config.Dev.AllowedUserIds` before live testing of the developer panel.
- **Shop NPC and Locker booth** in the lobby are not interactive yet (open the Shop / Locker from the left-edge menu).
  A ProximityPrompt needs its own key: E is Grab and X is Punch on gamepad. Worth doing with the lobby art pass.
- **Victory emotes** can be bought and equipped but play nothing until animations (2.6).
- **Shop test (Studio):** dev panel → "+5000 Scrap" → Shop: buy a daily deal (20% off), a style (then Equip), check
  the Scrap chip drops; buying something you own or can't afford is refused with a message. Output shows `[Shop]`.
