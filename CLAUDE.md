# Junkyard Brawl — working notes for Claude

Read this first in every session. Full design spec: [docs/PROJECT_BIBLE.md](docs/PROJECT_BIBLE.md).

## Status at a glance

- **Build order approved** by the owner on 2026-10-15, with maps built from code (blockouts from layout data, art
  pass later) and data saving via ProfileStore.
- **Phase 1 (core loop) is built and playtested** (1.1–1.13; two rounds of owner playtest fixes, "all clear" on
  2026-10-16). **Phase 2 in progress:** 2.1 Round rewards, 2.2 Fighting styles, 2.3 Cosmetics + Locker and 2.4 Shop
  are built (2.2–2.4 not yet playtested; the Wrecker parry needs two players). Owner's lobby rework (2026-10-16):
  enclosed hideout bar lobby, join pad to enter rounds, no Training Yard. 2.5 Junkyard Isles + Neon Motel are built
  (owner looked: Motel brightened, lobby TVs fixed). 2.6 Animations (scripted R15) work in the owner's Studio (dynamic
  pass, charged punch, stamina added 2026-10-17). 2.7 VFX + Low Graphics and 2.8 Music + SFX (silent until the
  owner picks audio ids) are built, not yet playtested.
  2.9 Tutorial skipped for now (owner). **Phase 3 in progress:** 3.1 Game passes, dev products, Premium perks and
  PolicyService are built and switched off until the owner creates the passes / products and sends their ids (test
  with the dev panel's Robux buttons meanwhile). Walk-up Shop / Locker prompts added (owner's pick). 3.2 Private
  server settings are built (not yet playtested). Arenas doubled in size with four layers and rounds are 4:00 (owner,
  2026-10-17). 3.3 Daily login streak + playtime rewards, 3.4 Daily + weekly quests and 3.6 Leaderboards are built
  (not yet playtested); 3.5 Badges skipped for now (owner). 3.7 Party system + friend XP bonus + group reward + chat
  tags, 3.8 Codes, 3.9 Full developer panel and 3.10 Settings menu + loading screen + How to play are built (not
  yet playtested). 3.11 Low-end mobile performance pass + localization check built (not yet
  tested on a phone). **Next step:** 3.12 Launch checklist support. The place must be published (File → Publish to
  Roblox) for DataStores to work in Studio.

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
| `src/first/` | `ReplicatedFirst` | `LoadingScreen.client.luau` (runs before everything else) |
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
- **Robux:** Robux purchases go through `Services/MonetizationService`, the only place that sets
  `MarketplaceService.ProcessReceipt` (products are granted with `DataService.processReceipt`, once per PurchaseId).
  Clients prompt (`PromptGamePassPurchase` / `PromptProductPurchase` / `PromptPremiumPurchase`); the server grants
  what Roblox confirms. Ids, prices and the Robux tab order are `Config.Monetization`; the rules (offers, perk
  cosmetics, receipts → product) are `Shared/MonetizationRules`. Ask `MonetizationService.has(player, perk)` for VIP /
  EmotePack / Premium (clients: the Player attributes of the same names). A cosmetic's `Exclusive` names where it
  comes from: a perk, or "Robux" (a product whose `Cosmetic` is that item). Region rules: ask
  `Services/PlayerPolicyService.allows(player, feature)` (`Shared/PolicyRules`) before adding paid random items,
  paid trading or external links.
- **Animations** are scripted R15 poses: clips in `Shared/Animation/Clips` (sampled by the pure `Shared/Animation/Pose`),
  played on every client by `Controllers/AnimationController`. Server code triggers a one-shot with
  `Server/Visuals/Animate.play(character, clip, except?)` when an action really happens; looping states come from
  replicated attributes (`Charging`, `HeldProp`); hits come from `CombatHit` (with the hitstun, and hit-stop); the
  always-on Motion layer (lean, air pose) and the in-round Stance come from each character's movement. A style's
  clips are `Config.Styles.List[id].Animations`; an uploaded animation can replace any clip via
  `Config.Animations.AssetIds`.
- **Lobby menu screens** (Shop, Locker, later Quests, Daily Reward, Settings ...) register with
  `Controllers/MenuController.addScreen(text, order, gui, onOpen)`: a left-edge button, one screen open at a time,
  closed while fighting; the Menu action (M / D-pad Up) closes the open screen or opens the first one. A lobby
  object can open one too: add a target (tag, part, screen name) to `Controllers/LobbyPromptController`.
- **Rounds:** `Services/RoundService` owns the loop, the scoreboard (`Server/Round/Scoreboard`), the lobby join pad
  (`Server/Round/Queue`: only players on it are taken into a round) and round stats. UI reads attributes: Workspace
  `RoundState`, `RoundEndsAt` (compare with `Workspace:GetServerTimeNow()`), `RoundMode`, `RoundMap`,
  `PlayersNeeded`, `PlayersQueued`; Player `RoundStatus`, `QueueStatus` (`In` / `AFK` / `Off`), `Lives`, `KOs`,
  `Falls`. Rewards and quests hook `RoundService.RoundEnded`. Private servers: `Services/PrivateServerService` (`isPrivate`,
  `ballot`, `roundTime`; Workspace `PrivateServer`, `PrivateOwnerId`, `PrivateMode`, `PrivateMap`,
  `PrivateRoundTime`). Nothing is earned in private servers: anything that grants progress (stats, quests, badges,
  leaderboards, playtime rewards) checks `PrivateServerService.countsProgress()`.
- **Settings** (Settings menu values) are read and changed through `Controllers/SettingsController`; the server
  validates each change with `Shared/Settings` (`Services/SettingsService`). New numeric settings need a range in
  `Config.Data.SettingRanges`.
- **Vendored code** (`src/server/Vendor/`) is never edited and is excluded from StyLua/Selene/luau-lsp.
- **Analytics:** log through `Services/Analytics` helpers (`scrapEarned`, `scrapSpent`, `onboardingStep`,
  `mapVoted`, `roundModePicked`, `styleUsed`, `roundFinished`, `robuxPurchase`, `custom`).
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
- [x] 2.5 Junkyard Isles + Neon Motel maps (+ night lighting preset)
- [x] 2.6 Animations (R15)
- [x] 2.7 VFX pass + Low Graphics setting
- [x] 2.8 Music + SFX (per-map tracks, last-30 s tension layer)
- [ ] 2.9 Tutorial + first-round tips — **skipped for now (owner, 2026-10-17)**; the Training Yard it was planned in
      was removed with the lobby rework. Ideas offered: contextual tips, or a practice room in the bar.

### Phase 3 — Monetization, retention & polish

- [x] 3.1 Game passes, dev products (idempotent receipts), Premium perks, PolicyService
- [x] 3.2 Private server settings (owner controls; no rewards since 2026-10-17)
- [x] 3.3 Daily login streak + playtime rewards
- [x] 3.4 Daily + weekly quests
- [ ] 3.5 Badges — **skipped for now (owner, 2026-10-17: "not necessary right now")**; the Config entries stay
      (BadgeId 0 = skipped)
- [x] 3.6 Leaderboards (all-time + weekly) + lobby billboards
- [x] 3.7 Party system + friend XP bonus + group reward + chat tags
- [x] 3.8 Codes
- [x] 3.9 Full developer panel
- [x] 3.10 Settings menu, loading screen, tutorial replay (a How to play page while the tutorial is skipped)
- [x] 3.11 Low-end mobile performance pass + localization check
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
| 2026-10-16 | Owner's lobby rework: enclosed hideout bar lobby "The Hideout" (bar counter = Shop, vote TVs over the bar, ARENA door, lockers, jukebox, quest board, leaderboard screens, pool table, booths, lamps) replacing the Rust Diner rooftop; Training Yard removed (practice dummy is now a dev panel "Dummy" button); join pad: only players standing on it (not AFK) start the vote, vote and are taken into a round (Casual: stepping on joins mid-round), everyone else stays in the lobby; QueueStatus / PlayersQueued attributes, pad status lines on the HUD, vote panel only on the pad | #21 |
| 2026-10-16 | 2.5 Junkyard Isles (dusk: scrap-heap centre, container stack, car pile, crane barge, barge, tire-stack ledges, sludge) + Neon Motel (night: motel roofs, pool roof, MOTEL sign roof, water-tower and billboard ledges, flooded street) arenas from layout code, shared maps/lib/Arena builder (Broken Highway output unchanged), 4 new structure types, NeonFlickerController, both maps in the vote; arena rules checked for every map | #22 |
| 2026-10-16 | Owner's look at 2.5 + lobby: Neon Motel brighter (Night preset: moonlight 2, purple ambient, less fog; neon parapets, MOTEL sign and billboard cast light; 4 roof lamps; flicker switches their light too); lobby TVs now dark casings with glowing CRT screens, bar lamps moved between the TVs with dim amber bulbs | #23 |
| 2026-10-16 | 2.6 Animations (scripted R15, bible §4.2): clips for the punch chain, bat / wrench swings, shovel sweeps, overhead smash, Shove charge + push, Wrecker parry, dash lean, grab, carry loop, throw, hit recoil, launch tumble (backflips through the hitstun) and the 4 victory emotes; pure Pose sampler; AnimationController layers them over the default animations on every client (blend in / out, joints the Animator leaves alone go back to rest); Animate remote + server hooks (CombatService, PropService), ShoveCharging attribute, hitstun in CombatHit; winners emote in the lobby after a round, equipping an emote previews it; optional uploaded animations per clip | #24 |
| 2026-10-16 | Animation fix ("no animation at all"): clips now turn joints through Motor6D.C0 every frame before rendering (the default animations overwrote the Transform writes); Studio `[Anim]` log (Config.Dev.LogAnimations) | #25 |
| 2026-10-16 | Animation fix 2: the owner's characters had no R15 Motor6Ds (Studio log: "no R15 joints found"); joints are now found as R15 or R6 Motor6Ds (R6 names mapped, turns applied in the parent part's axes) or AnimationConstraints (turned through Attachment0), and Studio logs which joints a character has (or what it has instead) | #26 |
| 2026-10-17 | Charged punch replaces the Shove (owner): tap Attack to punch, keep holding to charge, let go for the charged punch (Charge remote, Charging attribute, own cooldown); right-click is camera only; new Ability action (F / Y / touch "Parry" for Wrecker only) runs the style's move (Wrecker parry, own cooldown); "Shove" renamed "Charged" through Config, Formulas, Fighter, CombatService, remotes, clips (Charge loop, PowerPunch, PowerSwing), strings, specs and bible | #27 |
| 2026-10-17 | Stamina (owner): running (Left Shift held; gamepad left-stick press and a touch Run button run until you stop) at ×1.5 speed costs 20/s while moving, a dash costs 25 (dash cooldown 2.5 s → 0.6 s), refill 30/s after 0.8 s; stamina in the pure Fighter (spec-tested), CombatService ticks it, Run remote + speed modifier, Stamina attribute, HUD stamina bar; Dash moved to Q only | #28 |
| 2026-10-17 | Dynamic animation pass (owner: "look not good and no dynamic"): per-key easing (Out / Back overshoot), every attack reworked as wind-up → snappy strike → hold → recovery with hips, lunges, head and footwork; hit-stop on landed hits; always-on Motion layer (lean into movement and strafes, air tuck); in-round fighting Stance; directional hit recoils; tucked tumble; rig lookup throttled; Config.Animations HitStop / Motion; specs | #29 |
| 2026-10-17 | 2.7 VFX + Low Graphics: client VfxController (hit sparks + impact flash in Percent colors, launch smoke, POW / K.O.! starburst + red / gold screen-edge flash, client KO-effect cosmetic, cartoon explosion with ring shockwave, structure break chunks + dust, blue Perfect Dodge flash, dash streak), crumble cracks / dust / debris, Effect remote + Server/Visuals/Effects, Config.Vfx, Low Graphics (particles, debris, post-effects, shadows off; dev panel toggle), pure VfxRules + specs | #30 |
| 2026-10-17 | 2.8 Music + SFX: Config.Audio slots (all silent until the owner picks Creator Store audio ids), SoundController (lobby / per-arena music with crossfade, last-30 s tension layer, victory sting; 3D hit sounds by weapon, charged / prop / parry hits, dash, grab, throw, KO boom + cheer, explosion, wood / metal / glass smash, Perfect Dodge chime, crumble rumble / collapse; UI click, coin, level-up), weapon in CombatHit, pure AudioRules + specs | #31 |
| 2026-10-17 | Bottom-right key panel (owner): Run / Dash / Ability slots with keys or gamepad glyphs and cooldown fills (stamina, dash cooldown, server AbilityReadyAt), on keyboard and gamepad (touch keeps its buttons and the dash ring); tutorial 2.9 skipped for now by the owner | #32 |
| 2026-10-17 | 3.1 Monetization: MonetizationService (ProcessReceipt → idempotent DataService.processReceipt: Scrap packs, Robux cosmetics; VIP / Emote Pack passes checked on load + bought in-server; Premium + membership changes; perk attributes; perk cosmetics granted / taken back), Shop Robux tab (live prices, Roblox prompts, Premium card, "Coming soon" while ids are 0), VIP gold name tag + [VIP] chat tag, Emote Pack emotes (Robot, Salute, Air Guitar, Backflip), 3 Robux cosmetics, Notify notices, PlayerPolicyService + PolicyRules, dev panel perk toggles + product grants, RewardService bonuses from MonetizationService; specs | #33 |
| 2026-10-17 | 3.1 playtest (Studio logs): CameraController.Init had failed since 1.5 (a LocalScript can't set `DevEnableMouseLock`), so camera shake never ran; Shift Lock permission is now set by the server (SettingsService → StarterPlayer.EnableMouseLockOption). Chat switched to TextChatService (`default.project.json`: the place was on legacy chat, whose ChatScript errors in Studio and which the [VIP] chat tag can't use) | #34 |
| 2026-10-17 | Walk-up Shop and Locker (owner): ProximityPrompts on the bartender (Shop) and in the locker booth (Locker), client-made from the lobby tags, E / gamepad B / tap (`Config.Controls.Prompts`), hidden while a menu is open or fighting; MenuController `openNamed` / `isOpen`; input spec | #35 |
| 2026-10-17 | 3.2 Private servers: PrivateServerService (owner check, settings saved in the owner's data, Workspace attributes, 50% reward notice; Studio simulation), owner-only Server menu (mode: vote / Classic / Casual, map: vote / any arena, round length 2:00 / 3:00 / 5:00), PrivateServerSetting remote, RoundService ballot + round length from it, RewardService scale from it, dev "Private on/off", pure PrivateServerRules + specs | #36 |
| 2026-10-17 | Private servers for play and testing only (owner): no Scrap / XP (`PrivateServerRewardScale` 0) and no lifetime stats (`PrivateServerProgress` false, `PrivateServerService.countsProgress`), join notice / Server menu / results line say so | #37 |
| 2026-10-17 | Bigger arenas + 4:00 rounds (owner): all three arenas twice the size with four layers (low platforms, base, corner ledges + a raised centre deck with ramps, peaks): 13 platforms, 16 spawns, 24 prop spots, 8 structures, 6 barrels each; Arena `Deck` + Builder `spread` (decor laid out for the first size spreads without stretching); maps spec checks layers, climbs ≤ 6 and reachability; RoundTime 240, private round lengths 2 / 3 / 4 / 5 min | #38 |
| 2026-10-17 | 3.3 Daily rewards: DailyService (ClaimDaily remote: 7-day login streak, day 7 = the week's cosmetic or 300 Scrap; playtime +25 Scrap per 10 active minutes, 6 a day, saved across rejoins; nothing in private servers), Daily reward screen (day cards, claim, countdown, playtime line; opens itself when a reward waits), Daily data field, RoundService.isAFK, PrivateServerService.paysRewards, dev "Next day" / "+10 min", pure DailyRules + specs | #39 |
| 2026-10-17 | 3.4 Quests: QuestService (every lifetime stat counts toward today's 3 daily quests — a per-player pick of the 7 — and the weekly one, in the round's mode; done = Scrap at once + notice), Quests screen (progress bars, rewards, reset countdowns) from the menu and the lobby quest board (walk-up prompt), Quests data field, DataService.StatIncremented, RoundService.currentMode, dev "Finish quest" (+ "Next day" restarts daily quests), pure QuestRules + specs | #40 |
| 2026-10-17 | 3.6 Leaderboards (3.5 Badges skipped by the owner): LeaderboardService (all-time + weekly Wins / KOs / Level in OrderedDataStores, changed scores saved every 2 min and on leave / close, tops read + names looked up, Leaderboards remote; this-server fallback offline; nothing saved from private servers), LeaderboardWeek data, lobby screens (top 10, all-time / this week every 10 s), Leaderboard menu screen (top 50), pure LeaderboardRules + specs | #41 |
| 2026-10-18 | 3.7 Social: PartyService on pure Social/Parties (invite / join / leave / kick, up to 4, PartyId / PartyLeader attributes, invite popup), party members queued with their leader and spawned on one platform (Round/SpawnPlan), Party screen (members, invite list with friends, friend XP bonus line), party-colored name tags + [Party] / [Crew] chat tags (PlayerTagController), GroupRewardService (group check, one-time 150 Scrap, GroupMember attribute; off while GroupId is 0), Social data field; specs | #42 |
| 2026-10-18 | Party bar (top-left "Party 2/4" with avatar cards, #43) removed again at the owner's request ("go back to normal"); parties work as in 3.7 | #44 |
| 2026-10-18 | 3.8 Codes: CodeService (RedeemCode remote, codes in the server-only ServerConfig: Scrap and / or a cosmetic, optional expiry, once per player, not in private servers), Codes screen (menu + lobby jukebox prompt), Codes data field, dev "Reset codes", pure Codes/CodeRules + specs | #45 |
| 2026-10-18 | 3.9 Full developer panel: Target button (player commands act on any player in the server: Percent / HP, spawn prop / dummy, Scrap, unlocks, perks, daily / quests / codes), Progress section (+1000 XP, set level 1 / 5 / 12 / 25 / 50, all styles), DataService.setLevel, rank title follows every level change; DevCommand carries the target UserId | #46 |
| 2026-10-18 | 3.10 Settings menu (music / SFX volume − / +, camera shake, low graphics, touch button layout when there is a choice, camera sensitivity note) with a How to play page (rules + controls for the device), loading screen in ReplicatedFirst (title, random tip, waits for the game and the player's data, fades out), Config.Data.VolumeStep, Config.World.Loading | #47 |
| 2026-10-18 | 3.11 Performance + localization: animation detail levels (other characters posed every frame only up close and in view, every 2–4 frames further / off screen, not past 300 studs; Low Graphics closer), one-time frame-rate check turns Low Graphics on below 40 FPS (GraphicsAutoChecked setting), neon steady under Low Graphics, Config.Performance; specs: no hard-coded UI text, every {n} string has an Example, AnimationLod; unused Notify.Welcome removed | #48 |

## Decisions and interpretations

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
  Gameplay, sku `Code.<CODE>`, plus a `CodeRedeemed` event. The Codes screen is 8th in the left-edge menu and opens at
  the lobby's jukebox (`LobbyPromptController` target).
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
- **Fighting styles (2.2):** the equipped style's numbers have applied since 1.6 (`Formulas.resolveAttack`). New: the
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
  a new rank; the HUD's top-right chip shows level · rank · Scrap. Lifetime stats were already counted in 1.8.
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
- **Settings, loading screen, How to play (3.10):** the Settings screen (6th in the left-edge menu) changes every
  setting through `SettingsController` (server-checked): music / SFX volume with − / + buttons in steps of
  `Data.VolumeStep` = 0.1 (no drag slider: the buttons work the same with mouse, touch and gamepad), camera shake and
  low graphics On / Off, and the touch button layout (shown on touch only when `Controls.Touch.Layouts` has more than
  one). Camera sensitivity stays in the saved data but isn't shown: a game script can't change Roblox's camera
  sensitivity (forking the PlayerModule's camera input would be the only way), so a note points to Roblox's own menu.
  "Tutorial replay": the tutorial is skipped (owner), so Settings has a **How to play** page instead — six rule lines
  and the controls for the current device (`KeyHint` boxes: key names / gamepad glyphs; touch gets a note); no reward.
  The **loading screen** is `src/first/LoadingScreen.client.luau` (mapped to ReplicatedFirst): it removes Roblox's
  default screen, shows the title, a random tip (`Tip.1`–`Tip.8`) and "Loading...", stays at least
  `World.Loading.MinTime` = 1.5 s and until `game:IsLoaded()` and the player's `Level` attribute (set when the data
  loads), at most 20 s, then fades out (0.6 s). Its colors repeat Kit's (the client modules aren't loaded yet).
- **Social (3.7):** parties live in one server (`Server/Social/Parties`, pure; `PartyService` owns the state): up to 4,
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
  switching between all-time and this week every 10 s; the Leaderboard menu screen (5th) shows the top 50 with tabs.
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
  third in the left-edge menu and opens at the lobby's quest board too (`LobbyPromptController` target). Quest
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
  left-edge menu (order 9) so Quests / Daily / Leaderboard / Settings come first.
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
- **Robux items need the owner:** create the VIP (299 R$) and Emote Pack (149 R$) game passes and the 6 developer
  products (Scrap Pack S / M / L 49 / 149 / 399 R$; Inferno 149, Lightning Trail 99, Galaxy Burst 199) on the Creator
  Dashboard, then put their ids in `Config.Monetization`. Until then the Shop shows "Coming soon" and the VIP bonus
  is off (Premium and friend bonuses already apply). Studio test: dev panel → Robux → "VIP on/off" (Gold Trail in
  the Locker, +25% Scrap; the gold name tag shows to *other* players: 2-player test), product buttons (Scrap or the
  item, and a notice). Output shows `[Monetization]`. Switching a perk off — or joining without it — takes its items
  back, including ones the dev "All cosmetics" button granted. In Studio, rewards are paid from solo rounds too
  (Output: `[Rewards]`).
- **All screens are plain first versions** (`src/client/Ui/Kit`: HUD, vote, results, spectate bar, scoreboard); the
  art / VFX passes restyle them. The lobby's CRT-TV vote screens from the bible are an art-pass item. The dash ring
  fills bottom-to-top (a true radial ring needs an image asset).
- **Props are plain blocks** (size / material / color from `Config.Props.Types`) until the art pass; a lit barrel turns
  Neon, explosions are a client-drawn cartoon blast (2.7). Carry pose and throw animation
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
  switch VIP / Emote Pack / Premium on or off and get any Robux product; daily / quest / code tests; test camera shake
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
- **Codes test (Studio):** Codes (menu, or walk up to the jukebox on the west wall) → type `launch` → +250 Scrap;
  again → "already used"; a made-up code → "doesn't exist". Dev panel → Daily → "Reset codes" to use it again. Output
  shows `[Codes]`.
- **Party test (Studio, 2 players):** Test → Clients and Servers → 2 players. Player1: Party screen → Invite Player2;
  Player2: Join on the popup. Both see the other's name in blue and `[Party]` in chat. Player1 stands on the join pad
  while Player2 stays in the lobby: both go into the round, on the same platform. Leave / Remove work from the screen.
  Output shows `[Party]`. The group perks need a group: put its id in `Config.Retention.Group.GroupId`.
- **Leaderboards test (Studio):** with API access off the boards say "this server only" and list you from your stats
  (lobby screens on the south wall, and the Leaderboard menu); play a round and they update within 2 min. With
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
  studs; press E (gamepad B, or tap it) and the Shop opens. Same in the locker booth (west wall) for the Locker. The
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
