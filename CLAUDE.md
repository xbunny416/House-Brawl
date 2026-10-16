# Junkyard Brawl — working notes for Claude

Read this first in every session. Full design spec: [docs/PROJECT_BIBLE.md](docs/PROJECT_BIBLE.md).

## Status at a glance

- **Build order approved** by the owner on 2026-10-15, with maps built from code (blockouts from layout data, art
  pass later) and data saving via ProfileStore.
- **Current phase:** Phase 1. **Waiting on:** the owner's Studio playtest of 1.1–1.5 (lobby + Broken Highway
  blockouts, data saving, input on PC / gamepad / Device Emulator touch, camera zoom, Shift Lock, camera shake).
  **Next step after that:** 1.6 Combat core.

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
| `src/server/` | `ServerScriptService.Server` | `Main.server.luau` + `Services/` (one module per system) |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | `Main.client.luau` + `Controllers/` (input, HUD, camera, VFX) |
| `src/client/Lib/` | `...Client.Lib` | Pure client logic tested by specs (action map, touch layout, camera shake) |
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
  `StructureSpot` with a `StructureType` attribute, `LobbySpawn`, `Training*`), visible in Edit mode and hidden by
  `Services/MapService` at runtime. Each arena platform is a `Platform`-tagged Model (Persistent streaming,
  `CanFall` attribute). Sign text comes from GameStrings keys (`LocKey` attribute on the label). For a final art
  pass a map can switch to a hand-built model: export it from Studio to `maps/<Name>.rbxmx`, point
  `default.project.json` at it, and remove it from `maps/build.luau`.
- **Input:** gameplay code never reads raw keys. It listens to `Controllers/InputController` (`ActionBegan` /
  `ActionEnded` with an action from `Config.Controls.Actions`; `getDevice()` / `DeviceChanged` for key hints). A new
  action needs a keyboard and a gamepad binding, a `Controls.<Action>` string, and a touch button in
  `Config.Controls.Touch.Layouts` if mobile players use it (a spec checks sizes and overlaps on many screens).
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
- [ ] **1.6 Combat core** — Punch chain, charged Shove, server hitboxes, HP/Percent, knockback + hitstun, KO credit
      (6 s), launch trail flag.
- [ ] **1.7 Dash + Perfect Dodge** — server-timed i-frames, air dash once per jump, dodge bonus.
- [ ] **1.8 Rounds + modes** — vote (map + mode, 15 s) → teleport → Classic / Casual rules → results → lobby; respawn,
      spawn shield, spectate, late joiners, AFK + 60 s participation tracking.
- [ ] **1.9 Props** — spawn spots, grab/carry/throw (server-checked range and rate), weight classes, explosive barrel,
      40-prop cap, despawn.
- [ ] **1.10 Breakable structures** — HP, prop drops, respawn.
- [ ] **1.11 Crumbling platforms** — 3 s warning, fall, rules (center never falls, ≥ 2 remain).
- [ ] **1.12 Basic HUD** — HP + lives / Percent, timer, mode badge, kill feed, dash ring, held prop, Tab scoreboard,
      spectate view; mobile / PC / gamepad.
- [ ] **1.13 Developer panel (minimal)** — *moved up from Phase 3* so testing is faster: force map/mode, start/end
      round, trigger crumble, spawn prop, set Percent/HP. Server-checked UserId allowlist. Extended in Phase 3.

### Phase 2 — Progression & content

- [ ] 2.1 Round rewards (Scrap/XP, streaks, placement, anti-farm, bonuses) + levels and rank titles
- [ ] 2.2 Fighting styles: Slugger, Scrapper, Wrecker (parry) + welded weapon models
- [ ] 2.3 Cosmetics system + Locker
- [ ] 2.4 Shop (styles, cosmetics, 24 h UTC daily rotation)
- [ ] 2.5 Junkyard Isles + Neon Motel maps (+ night lighting preset)
- [ ] 2.6 Animations (R15)
- [ ] 2.7 VFX pass + Low Graphics setting
- [ ] 2.8 Music + SFX (per-map tracks, last-30 s tension layer)
- [ ] 2.9 Training Yard tutorial + first-round tips

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
| 2026-10-16 | 1.5 InputController (one action map: keyboard/mouse, gamepad, touch arc around the jump button), CameraController (zoom 8–30, Shift Lock on Right Shift, camera shake), validated settings changes (SettingsService/SettingsController), Studio input log + debug keys; LF line endings | 1.5 |

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
- New tunables not in the bible: attack windups (Punch 0.1 s, Shove 0.15 s, needed for "dodge before the hit
  lands"), punch chain reset 1 s, hitbox latency padding 0.5 studs, launch angle 30°, throw arc +14 studs/s, throw
  cooldown 0.5 s, grab cooldown 0.3 s, results screen 8 s, minimum 2 players to start a round, platform fall 4 s.
- Robux prices in Config are reference only; live prices come from the Creator Dashboard. Pass/product/badge/group
  ids are 0 until created.
- **Controls (1.5):** Shift Lock toggles on Right Shift only (Left Shift is Dash), by rewriting the `BoundKeys` value of
  Roblox's MouseLockController at runtime. Camera zoom 8–30 studs (8 keeps it third-person; bible only gave max 30).
  Mobile buttons are placed around Roblox's own jump button (kept, not replaced): base size 17% of the screen's
  shorter side, 64–104 px, Attack 1.15×; the `ButtonLayout` setting picks a layout from
  `Config.Controls.Touch.Layouts` (only `Default` so far). Camera shake wobbles at 18 Hz and only moves the camera
  (never turns it). Setting ranges: volumes 0–1, camera sensitivity 0.25–2.

## Known bugs / open items

- None in code yet.
- **Right-click** (Shove) is also Roblox's hold-to-rotate camera button, so turning the camera with the mouse starts a
  Shove. Decide in 1.6 whether a camera drag cancels the charge (or keep it: a whiffed Shove is harmless).
- **Gamepad Start / Select** (Menu / Scoreboard in the bible) may be kept by Roblox (Start opens the Roblox menu,
  Select toggles UI navigation). Check in the gamepad playtest (`[Input] Menu began` in Output); if they never
  arrive, pick other buttons in `Config.Controls.Gamepad` (owner's call).
- **Tab** also toggles Roblox's player list until the scoreboard (1.12) turns the core player list off.
- **Camera sensitivity** is saved and validated but not applied: Roblox does not let scripts change mouse/gamepad
  sensitivity. Needs a custom approach in 3.10.
- **Studio input debug:** `Config.Dev.LogInput` prints every action and device change to Output in Studio playtests;
  `Config.Dev.StudioKeys` adds K (test camera shake) and L (toggle the saved Camera Shake setting). Studio only; the
  developer panel (1.13) replaces the keys. Test touch with Studio's Device Emulator (a phone in landscape).
- **Data in Studio:** with "Studio Access to API Services" off, ProfileStore uses an in-memory store and prints
  "Roblox API services unavailable - data will not be saved". Turn it on to test real saving
  (`Config.Data.UseMockInStudio = true` forces the in-memory store even with access on).
- **Arena gaps** of 9–12 studs need the dash (step 1.7); until then only the 8–9 stud gaps are jumpable.
- **Falling off the arena** currently returns you to the lobby (MapService default); the round system (1.8) will
  take over with lives/respawns.
- **Studio arena preview:** `Config.Dev.StudioArenaPreview` loads Broken Highway in Studio playtests and adds a
  teal teleport pad in front of the lobby spawns. Set it to nil to turn it off. Never active in live servers.
- **Owner's Roblox UserId** is needed for `Config.Dev.AllowedUserIds` before live testing of the developer panel.
