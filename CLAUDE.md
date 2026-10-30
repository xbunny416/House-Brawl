# Junkyard Brawl — working notes for Claude

Read this first in every session. Design spec: [docs/PROJECT_BIBLE.md](docs/PROJECT_BIBLE.md). History in `docs/`:
[PROGRESS.md](docs/PROGRESS.md) (build order, one row per PR), [DECISIONS.md](docs/DECISIONS.md) (the owner's choices
and every call made where the bible is silent — read the matching entry before changing how a system behaves) and
[STUDIO_TESTING.md](docs/STUDIO_TESTING.md) (how to test each system in Studio, debug switches, playtest notes).

## Status

- **Built:** every build-order item (Phases 1–3) except 2.9 Tutorial and 3.5 Badges (skipped by the owner), the
  owner's fix list (`docs/reference/README.md`, 2026-10-19), and since then: the bartender NPC, lobby arm wrestling
  and chess, the walk-up spin wheel, the store art (`docs/store`), a smaller, more detailed iron-and-wood lobby with a
  style-roll coach NPC, and the three old arenas rebuilt. **Shinjuku** (a Tokyo street block on the ground in the
  style of Jujutsu Shenanigans' map, open edges you can fall off) is now the only arena: furnished walk-in buildings
  sized to the avatar with breakable walls, framed windows and two-tone faces (`maps/lib/Rooms`), rooftop gear
  (`maps/lib/Roofs`), many-part furniture and a fountain (`maps/lib/Decor`), ForgeGUI art on its billboards, murals
  and posters (`maps/lib/Art`), lifts, a crane and a rooftop Ferris wheel, 72 prop spots with props that fit each
  place. Its buildings stream in by distance from a `District` folder (about 16,900 instances). Menus use the slate
  palette (`Ui/Kit`).
- **Playtested:** Phase 1 ("all clear" 2026-10-16), the animations, 3.1 (from Studio logs). Everything else is built
  but not playtested; 3.11 (low-end mobile) not tried on a phone.
- **Owner-side** ([docs/LAUNCH.md](docs/LAUNCH.md), `lune run tools/launch-check`): the VIP pass and the developer
  products (StyleSlot included), their ids in `Config.Monetization`; audio ids (`Config/Audio.luau`, all 0 = silent,
  then `lune run assets/build`); the maturity form (paid random items: the style roll and the wheel); upload
  GameStrings.csv; the owner's UserId in `Config.Dev.AllowedUserIds`. DataStores only work in Studio once the place is
  published (File → Publish to Roblox).
- **Next:** playtest fixes and whatever the owner asks for.

## Standing owner decisions

Easy to break by accident; the reasons and dates are in DECISIONS.md.

- **Classic is the only mode** (`Config.Modes.Order`); Casual stays defined but out of the rotation, so the vote is
  map-only.
- **Shinjuku is the only arena:** Broken Highway, Junkyard Isles and Neon Motel stay built (layouts, generated
  models, specs, `ServerStorage.Arenas`) but `Enabled = false` in `Config.Maps.List`. Don't delete them or switch them
  back on unasked.
- **The lobby is run-only:** punch, charge, ability, dash and grab work only while `RoundStatus` is `Playing`.
- **Private servers earn nothing:** no Coins, XP, stats, quests, leaderboard scores or daily rewards.
- **Removed — don't bring back unasked:** parties, the Leaderboard menu screen (lobby boards only), victory emotes and
  the Emote Pack pass, the Training Yard, level unlocks and Shop-sold styles (styles come from the style roll).
- **On screen** the soft currency is **Coins** and the Locker is the **Inventory**; code, data and string keys keep
  the names Scrap and Locker.
- **Paid random items** (style roll, wheel): every outcome and its exact odds are in view before paying; paid spins
  only where `PlayerPolicyService` allows them.
- The developer panel is Studio-only (`Config.Dev.AllowedUserIds` is empty).

## How this repo works

The game is **code-first**: all Luau lives in `src/` and is synced into Roblox Studio with
[Rojo](https://rojo.space). Cloud sessions (claude.ai/code) have **no Studio MCP connection**, so they write code and
rely on CI; visual building, screenshots and playtests happen in Studio (owner, or a local Claude Code session with the
Roblox Studio MCP server).

**Local setup (owner):** install [Rokit](https://github.com/rojo-rbx/rokit), `rokit install` (Rojo, Selene, StyLua,
Lune at the versions in `rokit.toml`), `rojo plugin install`; `rojo serve`, open a place in Studio, click **Connect**
in the Rojo plugin (restart `rojo serve` after a new file is added to `default.project.json`, or a new arena model
never syncs). In game settings enable **Studio Access to API Services** (DataStores); turn on automatic translation
in the Creator Dashboard. Without Rojo: open the `.rbxlx` from the latest CI run's `JunkyardBrawl-place` artifact.

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
| `assets/` | — | The templates game code clones (VFX, sounds, animations, models), built from Config by `assets/build.luau` |
| `assets/generated/` | `ReplicatedStorage.Assets` | `Assets.rbxmx` generated from `assets/` (committed) |
| `tools/` | — | Lune helpers shared by tests and the map generator |
| `tests/` | — (not synced) | Lune runner `tests/run.luau`, specs in `tests/specs/*.spec.luau` |
| `docs/` | — | Design bible, progress log, decisions, Studio testing notes, launch checklist |

`Shared/Util/Loader` boots every ModuleScript in `Services/` (server) or `Controllers/` (client): all `Init()` run
first in `Priority` order, then each `Start()` runs in its own thread.

```sh
stylua src tests maps tools assets  # format (CI runs stylua --check)
selene src                  # lint
scripts/typecheck.sh        # strict type-check with luau-lsp + Roblox API types
lune run tests/run          # syntax-compile every src/*.luau + run specs
lune run maps/build         # regenerate maps/generated/*.rbxmx after editing maps/layouts (a spec checks this)
lune run assets/build       # regenerate ReplicatedStorage.Assets after editing assets/ or the Config it reads
lune run tools/launch-check  # list the ids / placeholders still unset before release (report only)
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
  `Localization.format(key, args)` (a spec fails on a key missing from the CSV). After adding keys, upload the CSV to
  the game's localization table in the Creator Dashboard so automatic translation picks them up.
- **Networking:** every remote is declared in `src/shared/Net/Definitions.luau`. Client → server remotes list `Args`
  validators from `Net/Guard` (NaN/inf-safe, length-capped) and get a per-player rate limit (`Config.Net`, overridable
  per remote). Server code uses `Net.onServerEvent` / `Net.onServerInvoke`, never RemoteEvents directly. Never use
  server → client invokes.
- **Player data:** only change it through `Services/DataService` (`addScrap`, `spendScrap`, `addXP`,
  `incrementStat`, `update`, `processReceipt`) so the owning client is synced and analytics are logged. New template
  fields are filled in automatically; renames/removals need a migration (`src/server/Data/Migrations.luau`, bump
  `VERSION` in `src/shared/Data/Template.luau`). Clients read their copy via `Controllers/DataController`.
- **Maps:** generated from `maps/layouts/*.luau` by `lune run maps/build`; never hand-edit `maps/generated/`. Shaped
  pieces come from `maps/lib/Pieces` (lobby furniture `Furniture`, arena furniture `Decor`, walk-in buildings `Rooms`,
  rooftop gear `Roofs`); moving parts are `Arena.mover` models (`Shared/MoverRules`) that clients move and `MoverService` reads for
  hazards. Gameplay markers are tagged parts (`SpawnPoint`, `PropSpot`, `ExplosiveSpot`, `StructureSpot` with a
  `StructureType` attribute, `LobbySpawn`), visible in Edit mode and hidden by `Services/MapService` at runtime; the
  lobby's join pad is a visible `QueueZone` part. Each arena platform is a `Platform`-tagged Model (Persistent
  streaming, `CanFall` attribute). Sign text comes from GameStrings keys (`LocKey` attribute on the label). For a
  final art pass a map can switch to a hand-built model (export it to `maps/<Name>.rbxmx`, point
  `default.project.json` at it, remove it from `maps/build.luau`). **Directions:** the Builder's North = +Z, East = +X
  are a mirror image of a compass (facing +Z, +X is on your *left*): tell the owner left / right as you face the
  lobby's bar (+Z), never "east / west" (`LeftWall` = +X, `RightWall` = −X).
- **Input:** gameplay code never reads raw keys. It listens to `Controllers/InputController` (`ActionBegan` /
  `ActionEnded` with an action from `Config.Controls.Actions`; `getDevice()` / `DeviceChanged` for key hints). A new
  action needs a keyboard and a gamepad binding, a `Controls.<Action>` string, and a touch button in
  `Config.Controls.Touch.Layouts` if mobile players use it (a spec checks sizes and overlaps on many screens).
- **Combat:** every hit goes through `Services/CombatService`, which owns one `Server/Combat/Fighter` per combatant
  (player characters register automatically; anything else, like the dummy, calls `CombatService.register`). UI
  reads the character attributes `HP` (modes with HP) and `Percent`; listen to `CombatService.KnockedOut` for KOs.
- **Styles:** slots, the equipped slot, spins and locks go through `Services/StyleService` (`spin`, `equipSlot`,
  `lockSlot`, `addSlot`, `equippedOf`); the rules (`Shared/StyleRules`: odds, pick, pity, spin checks) are shared
  with the Styles screen (`Controllers/StyleRollController` + `Ui/StyleRollView`). Saved `Styles.Equipped` = the
  equipped slot's style; combat reads it through `Formulas.resolveAttack`.
- **Shop:** purchases go through `Services/ShopService` (`Buy` remote → `CosmeticService.grant`); what is for sale,
  prices and the daily rotation are `Shared/ShopRules`, shared with the Shop UI so both show the same price.
- **Robux:** purchases go through `Services/MonetizationService`, the only place that sets
  `MarketplaceService.ProcessReceipt` (products granted with `DataService.processReceipt`, once per PurchaseId).
  Clients prompt (`Prompt…Purchase`); the server grants what Roblox confirms. Ids, prices and the Robux tab order:
  `Config.Monetization`; offers, perk cosmetics, receipts → product: `Shared/MonetizationRules`. VIP / Premium:
  `MonetizationService.has(player, perk)` (clients: the Player attributes of the same names). A cosmetic's
  `Exclusive` names its source: a perk, or "Robux" (a product whose `Cosmetic` is that item). Ask
  `Services/PlayerPolicyService.allows(player, feature)` (`Shared/PolicyRules`) before adding paid random items, paid
  trading or external links.
- **Animations** are scripted R15 poses: clips in `Shared/Animation/Clips` (sampled by the pure
  `Shared/Animation/Pose`), played on every client by `Controllers/AnimationController`. Server code triggers a
  one-shot with `Server/Visuals/Animate.play(character, clip, except?)` when an action really happens; looping states
  come from replicated attributes (`Charging`, `HeldProp`); hits from `CombatHit` (hitstun, hit-stop); the always-on
  Motion layer (lean, air pose) and the in-round Stance from each character's movement. A style's clips are
  `Config.Styles.List[id].Animations`; an uploaded animation can replace any clip via `Config.Animations.AssetIds`
  (the `roblox-animation` skill makes them in Studio).
- **Lobby menu screens** (Shop, Inventory, Styles, Settings, Quests; the Daily reward and the owner's Server menu)
  register with `Controllers/MenuController.addScreen(text, order, gui, onOpen)`: a left-edge button (none when
  `text` is nil), one screen open at a time, closed while fighting; the Menu action (M / D-pad Up) closes the open
  screen or opens the first one; `open` / `openNamed(name, arg)` pass `arg` to `onOpen` (e.g. a tab). Tabs use
  `Kit.tabRow`. A lobby object can open one: add a target (tag, part, screen name, arg) to
  `Controllers/LobbyPromptController`.
- **Rounds:** `Services/RoundService` owns the loop, the scoreboard (`Server/Round/Scoreboard`), the lobby join pad
  (`Server/Round/Queue`: only players on it go into a round) and round stats. UI reads attributes: Workspace
  `RoundState`, `RoundEndsAt` (vs `Workspace:GetServerTimeNow()`), `RoundMode`, `RoundMap`, `PlayersNeeded`,
  `PlayersQueued`; Player `RoundStatus`, `QueueStatus` (`In` / `AFK` / `Off`), `Lives`, `KOs`, `Falls`. Rewards and
  quests hook `RoundService.RoundEnded`. Private servers: `Services/PrivateServerService` (`isPrivate`, `ballot`,
  `roundTime`; Workspace `PrivateServer`, `PrivateOwnerId`, `PrivateMode`, `PrivateMap`, `PrivateRoundTime`);
  anything that grants progress (stats, quests, badges, leaderboards, playtime rewards) checks
  `PrivateServerService.countsProgress()`.
- **Settings** (Settings menu values) are read and changed through `Controllers/SettingsController`; the server
  validates each change with `Shared/Settings` (`Services/SettingsService`). New numeric settings need a range in
  `Config.Data.SettingRanges`.
- **Vendored code** (`src/server/Vendor/`) is never edited and is excluded from StyLua/Selene/luau-lsp.
- **Analytics:** log through `Services/Analytics` helpers (`scrapEarned`, `scrapSpent`, `onboardingStep`,
  `mapVoted`, `roundModePicked`, `styleUsed`, `roundFinished`, `robuxPurchase`, `custom`).
- Pure logic (formulas, reward math, validation) goes in modules with no Roblox-instance dependencies so Lune specs can
  test it; add specs for every formula. Specs load game modules through `tests/roblox.luau`, a fake DataModel built
  from `default.project.json`, so modules keep normal `require(script.Parent.X)` requires.
- Filter all player-written text with TextService before others see it.
- Never delete or replace large parts of the place without asking the owner.
- Only free Creator Store assets / Studio AI generation; ask before using anything paid.

## Roblox Studio Project Rules

The owner's rules (2026-10-30). *Now:* notes say where the code differed when they were added.

### Architecture & Code Standards
- Use pure native Luau. No Wally, no external packages. *Now:* `Vendor/ProfileStore` (player data) predates this.
- Never use legacy globals: use `task.wait()`, `task.delay()`, `task.defer()`, never `wait()`, `spawn()`, or
  `delay()`.
- Use `Debris:AddItem()` or `task.defer()` for object cleanup to prevent memory leaks.
- Always separate Server (ServerScriptService) and Client (StarterPlayerScripts). Never trust client input.

### UI Design Rules
- When writing UI via script, never use pure gray/default styling.
- Always use `AnchorPoint = Vector2.new(0.5, 0.5)`. *Now:* 44 of the client's 58 `AnchorPoint` uses differ.
- Use `UDim2.fromScale()` for positioning and size. Never hardcode large Offset pixel values.
- Always add `UICorner` (Radius 8-12px) and `UIPadding` (12-16px) to frames.
- Color palette standard: Dark mode slate backgrounds (`#1E1E24`), vibrant accent colors for buttons/bars. Done in
  `Kit.Colors` (`#2D2E3B` buttons, a `#FF7A1A` accent with dark `OnAccent` text); the loading screen and the touch
  buttons keep copies.
- Animate UI using `TweenService` with `Enum.EasingStyle.Quad` or `Back` for responsive feel.

### Assets, VFX & Animations
- Never generate raw ParticleEmitters, Sounds, or Rigs with empty IDs (nor emitters with default white textures).
- VFX: Clone templates from `ReplicatedStorage.Assets.VFX`, call `:Emit(count)`, and tween scale/transparency.
- Audio: Clone from `ReplicatedStorage.Assets.Sounds`, randomize `PlaybackSpeed` (0.9–1.1), and play.
- Animations: Load `Animation` objects from `ReplicatedStorage.Assets.Animations` onto `Humanoid.Animator`.
- Models: Clone props/weapons from `ReplicatedStorage.Assets.Models` and position/weld via script.
- *Done:* `ReplicatedStorage.Assets` is generated from `assets/` (`lune run assets/build`; a spec checks it). `VFX`:
  bursts, the launch smoke, flash parts, the dash and cosmetic trails, the KO starburst (cloned by `VfxController`,
  `CrumbleController`, `CosmeticService`). `Sounds`: one per `Config.Audio` slot with an id (none yet: the game is
  silent), cloned by `SoundController` at a random speed in `Config.Audio.Pitch`. `Animations`: one per uploaded clip
  in `Config.Animations.AssetIds` (none yet: clips are the scripted poses above), loaded onto the Animator. After
  changing those ids, run `lune run assets/build`. `Models`: props and structures (their Config box with the
  `Shared/ItemShapes` look welded on; `PropService`, `StructureService`), weapons and hats / back items (from Config
  part lists; `Server/Visuals/Attached` positions and welds them on the character).

## GitHub workflow (automated)

- Develop on the session's `claude/...` branch. One feature per PR.
- **CI** (`.github/workflows/ci.yml`) on every PR: StyLua check → Selene → luau-lsp strict type-check → Lune (syntax +
  specs) → Rojo build (uploads `JunkyardBrawl.rbxlx` as the `JunkyardBrawl-place` artifact).
- **Auto-merge:** when CI is green, PRs from `claude/*` branches are squash-merged and the branch is deleted. To stop
  one, open it as a **draft** or add the **`no-automerge`** label.
- After a merge, start the next feature from fresh `main` on the same branch name
  (`git fetch origin main && git checkout -B <branch> origin/main`).
- Before pushing, run the commands above locally; a red CI blocks the merge.
- With every PR: add a row to `docs/PROGRESS.md`, put new choices in `docs/DECISIONS.md` (and how to test them in
  `docs/STUDIO_TESTING.md`), and keep the Status above short and current.

## Known limits

- Clients simulate their own character, so exploiters can ignore knockback, and the dash's once-per-jump air rule is
  checked on the client (the server enforces cooldowns, hitstun and the dash's i-frames). Server-side movement checks
  are a later hardening task.
- Movers (lifts, swings, slides) move only on clients; the server's copy stays at rest, so a prop dropped on a lift
  doesn't ride it.
- Camera sensitivity is saved but can't be applied: Roblox doesn't let scripts change it.
- The animations were tuned without seeing them: angles may need flipping or softening after a playtest.
- Studio: `Config.Dev.StudioMinPlayers = 1` runs solo rounds (stand on the join pad by the ARENA door); the developer
  panel opens with ` (Backquote) or the DEV button; PvP needs Test → Clients and Servers → 2 players.
