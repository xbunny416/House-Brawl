# Junkyard Brawl — Project Bible

The source-of-truth design spec. Every tunable number here lives in the Config module in code; if they differ, update
this file in the same PR as the Config change.

## 1. Core specs

- **Title:** Junkyard Brawl
- **Genre:** Indie PvP platform fighter (knock-off / ring-out brawler)
- **Pitch:** A retro, slightly-apocalyptic free-for-all where you punch, shove and hurl junk (chairs, crates, TVs,
  fridges) to knock rivals off crumbling floating platforms. Short, chaotic rounds with two modes: **Classic** (HP +
  falling) and **Casual** (no HP, knockback % only).
- **Core loop**
  - Every few seconds: punch, shove, dash-dodge, grab loose props or smash structures for props, throw them to launch
    rivals off the edge.
  - Per session: win rounds, KO streaks, finish daily quests, earn Scrap and XP to unlock fighting styles and cosmetics.
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

- **Scrap** — the only soft currency. Earned from KOs, placement, participation, daily rewards, quests, codes. Spent on
  styles and cosmetics. Robux buys premium cosmetics and Scrap packs. No stat upgrades for sale.
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

- **Classic:** 100 HP, 3 lives (stocks). Lose a life at 0 HP or by falling below KillY. Last fighter standing wins; at
  time-out most KOs wins (tiebreak: fewest falls).
- **Casual:** no HP, unlimited respawns. Score = KOs − falls. Highest score at time-out wins.
- Round 3:00. Intermission/vote 15 s. Respawn delay 3 s. Spawn shield 2 s (breaks if you attack).

### Attacks

| Attack | Damage / Percent | Knockback | Hitbox (studs, in front) | Cooldown |
| --- | --- | --- | --- | --- |
| Punch (3-hit chain) | 8 HP / 6% per hit | 3rd hit ×1.5 KB | 4×4×5 | 0.35 s between hits, 0.8 s after 3rd |
| Shove (heavy) | 14 HP / 11% (×1.75 base) | AttackKBScale 1.6; charge up to 0.8 s for up to ×1.5 KB; 40% slow while charging | 5×5×6 | 1.2 s |
| Dash | — | 18 studs in 0.25 s, level (no gravity), 0.25 s invulnerability, once in the air per jump; ends a launch after hitstun (recovery) | — | 2.5 s |

### Reward distribution

- Must be in the round ≥ 60 s for placement rewards. AFK (no input 45 s) = no rewards.
- Paid out by the server at round end, multiplied by VIP / Premium / friend bonuses (additive, max +60% total).

### 2.2 Rebirth

Not used. Long-term goals are levels/ranks, styles, cosmetics and leaderboards.

### 2.3 Shop (side-grades and cosmetics only)

| Style | Weapon | Unlock | Changes |
| --- | --- | --- | --- |
| Brawler | Fists | Free default | Punch and Shove as above |
| Slugger | Baseball bat | 1,500 Scrap or Level 5 | Damage ×1.15, +2 studs reach, attack speed ×0.8 |
| Scrapper | Shovel | 3,000 Scrap or Level 12 | Wide sweep hitbox 7×4×5, Damage ×0.9, Shove KB ×1.1 |
| Wrecker | Wrench + hubcap shield | 6,000 Scrap or Level 25 | Shove becomes a 0.2 s parry that reflects knockback; Punch Damage ×0.95 |

- **Cosmetics** (Scrap or Robux): skins, hats, back items, dash trails, KO effects, victory emotes, name-plate frames.
  Common 300–800 Scrap; Rare 1,200–2,500 Scrap; Premium = Robux only.
- **Daily rotating shop:** 4 cosmetics rotate every 24 h (UTC).

### 2.4 Pets & eggs

Not used. No pets, eggs, or paid random items.

## 3. World

### 3.1 Streaming & zones

- One Lobby hub + 3 rotating arenas at launch. Each arena: floating platforms over a void (KillY) with toxic sludge or
  fog far below.
- Lobby → (vote) → arena via server-side teleport of characters within the same place. After the round, everyone
  returns to the Lobby. Arenas live in ServerStorage; only the active one is in Workspace.
- All maps free. Players enter the arena only when the server starts a round. Late joiners spectate until next round
  (Casual: may join mid-round after the 3 s respawn).

| Zone | Description |
| --- | --- |
| Lobby — "Rust Diner" rooftop | Shop, Locker, Quest board, leaderboards, Training Yard |
| Map 1 — Broken Highway | Shattered overpass chunks, abandoned cars, road signs |
| Map 2 — Junkyard Isles | Stacked car and container islands over toxic sludge |
| Map 3 — Neon Motel | Sinking motel rooftops, flickering retro neon, pool on one roof |

### 3.2 Visual & spatial guidelines

**Lobby (Rust Diner):** center — retro diner counter with the Shop NPC (scavenger mechanic), map/mode vote screens as
old CRT TVs, big neon "JUNKYARD BRAWL" sign. Perimeter — Locker booth, Quest board (cork board), leaderboard
billboards, Codes jukebox, Training Yard ramp with a dummy and a small gap to practise dashing.

**Broken Highway arena:**

- Central main platform 60×40; 4 side platforms 24×24; 2 high ledges 12×12. Gaps 8–14 studs (always crossable with
  jump + dash). KillY 60 studs below the lowest platform. 12 spawn points around the edges of all platforms.
- 14 loose prop spots (chairs, crates, tires, buckets, TVs, barrels), respawn 20 s.
- 4 breakable structures: wrecked car (HP 100), vending machine (HP 80), road barrier stack (HP 60) — each drops 2–4
  props, respawn 45 s.
- 1 explosive barrel spot per side platform, respawn 30 s.
- **Crumbling platforms:** from 1:00 into the round, every 20 s one random outer platform flashes red and shakes for
  3 s, then falls. The central platform never falls; at least 2 platforms always remain. Clear 3 s warning (shake,
  crack VFX, rumble SFX).

**Art & performance:**

- Low-poly retro post-apocalypse, fun and chaotic (not grim). Faded 80s/90s palette: rust orange, teal, dusty pink,
  off-white, neon accents. Materials: SmoothPlastic, Metal, CorrodedMetal, Concrete, Neon (sparingly). Chunky comic
  shapes.
- Late-afternoon dusk, orange sky, dusty haze (Atmosphere density ~0.35), light fog, faint toxic-green glow from below.
  Neon Motel is night.
- Low draw calls (reuse meshes, no high-tri unions, CastShadow off on small props), cap 40 active props per arena,
  "Low Graphics" setting disables particles and post-effects. StreamingEnabled ON (target 256, min 128). Arena
  platforms use ModelStreamingMode = Persistent.

### 3.3 Combat rules

- **No NPC enemies.** Only the Training Yard dummy (stands still, shows Percent, respawns 2 s after falling 4+ studs
  below its spot or reaching 0 HP; anyone can hit it, also in the Lobby).
- **Classic:** 100 HP, 3 lives, 3 s respawn with 2 s spawn shield. Out of lives = spectate until round end.
- **Casual:** no HP, Percent shown above head and in HUD, unlimited respawns, Percent resets to 0% on respawn.
- **KO credit:** last player who hit you within 6 s before you fell.
- PvP always on in arenas, off in the Lobby. No friendly-fire exceptions (parties fight each other too).

**Props (grab & throw):**

- Grab range 6 studs (server-checked). Hold 1 prop. Holding replaces Punch with Throw and blocks Shove.
- Throw speed 90 studs/s, slight arc. Thrown props despawn 8 s after landing.

| Class | Examples | Damage / Percent | KB scale | Carrier slow |
| --- | --- | --- | --- | --- |
| Light | chair, bucket, tire | 10 HP / 8% | 1.0 | none |
| Medium | crate, TV, barrel | 18 HP / 14% | 1.3 | 15% |
| Heavy | fridge, car door, vending machine chunk | 28 HP / 22% | 1.7 | 30% |
| Explosive barrel | — | 25 HP / 20% in 10-stud radius | 1.5 | — (explodes on impact or 3 s after being hit) |

- Getting hit while carrying drops the prop.
- Breakable structures take damage from any attack or thrown prop and break into 2–4 random props.

## 4. Assets

### 4.1 3D (Studio AI generation, part-built models, or Creator Store)

- One server-side Combat module drives all styles; each style is a Config data entry (damage, reach, speed, hitbox,
  animations, sounds). Weapons are welded accessory models, not Tools (mobile buttons stay consistent).
- Weapons: baseball bat, shovel, wrench, hubcap shield (each < 1,500 triangles).
- Props: folding chair, wooden crate, tire, bucket, CRT TV, oil barrel, explosive barrel, fridge, car door, traffic
  cone.
- Structures: wrecked car, vending machine, road barrier stack, broken road signs, billboards.
- Launch cosmetics: 6 skins, 6 hats, 4 dash trails, 4 KO effects, 4 victory emotes.

### 4.2 Animation (R15; Creator Store, Animation Capture, or scripted)

Punch chain jab/cross/uppercut (0.3 s each); Shove charge + two-hand shove (0.5 s); bat/shovel/wrench swings (0.45 s);
Dash lean (0.25 s); Grab crouch-lift (0.3 s) + carry idle/walk loop; overhead Throw (0.4 s); hit reaction / launched
tumble (0.6 s, loops in hitstun); 4 victory emotes (2 s).

### 4.3 VFX

Hit sparks scaling with Percent (white → yellow → red); smoke launch trail above 100%; comic "POW" KO starburst +
screen-edge flash; platform crumble (red edge, cracks, dust, debris); prop break (splinters / scraps / shards); retro
cartoon explosion with ring shockwave; dash streak and blue Perfect Dodge flash.

### 4.4 Sound (Creator Store audio)

- Music: Lobby retro synthwave; one gritty chiptune-rock track per arena; last-30 s tension layer; victory sting.
- SFX: punch / bat thwack / shovel clang / wrench bonk; grab, throw whoosh, smash (wood/metal/glass); KO boom + short
  crowd cheer; platform rumble/collapse; dash whoosh, Perfect Dodge chime; UI clicks, coin pickup, level-up fanfare.

## 5. UI / UX

### 5.1 Layout

AnchorPoint (0.5, 0.5), Scale coordinates (no fixed offsets), UIAspectRatioConstraint.

- **Mobile:** bottom-right arc — Attack (Punch/Throw), Shove, Grab, Dash around Roblox's Jump button (≥ 64 px
  targets: 17% of the screen's shorter side, 64–104 px, Attack 1.15× larger; Settings > Button Layout picks the
  arrangement). Shown only while touch is the player's input. Bottom-center — own
  Percent (Casual) or HP bar + lives (Classic), held-prop icon, dash cooldown ring. Top-center — round timer, mode
  badge, players alive / score, kill feed. Left edge (Lobby only) — Shop, Locker, Quests, Daily Reward, Leaderboard,
  Settings. Default thumbstick bottom-left.
- **PC:** same layout, touch buttons hidden, key hints next to HUD items, Tab = round scoreboard.
- **Console:** same layout, menus navigable with GuiService.SelectedObject highlights, gamepad glyphs auto-swap.

### 5.2 Controls & camera

| Action | PC | Gamepad | Mobile |
| --- | --- | --- | --- |
| Move | WASD | Left stick | Thumbstick |
| Jump | Space | A | Jump button |
| Punch / Throw | Left Click | X | Attack |
| Shove (hold to charge) | Right Click | Y | Shove |
| Grab / Drop | E | B | Grab |
| Dash | Q or Left Shift | RB | Dash |
| Scoreboard | Tab | Select | — |
| Menu | M | Start | — |

Third-person follow, zoom 8–30 studs (no first person), Shift Lock allowed on PC and toggled with Right Shift (Left
Shift is Dash). Small camera shake on heavy hits (0.6 studs, 0.25 s; toggle in Settings). Spectate camera cycles alive
players.

### 5.3 Screens

Loading, Lobby HUD, Map & Mode vote, Round HUD, Results / MVP, Spectate, Shop (Daily, Styles, Cosmetics, Robux),
Locker, Daily Quests, Daily Reward calendar, Leaderboards, Party panel, Codes, Settings (camera sensitivity,
music/SFX volume, low graphics, camera shake, button layout), Tutorial overlay, Purchase confirmations, Developer test
panel.

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
| Emote Pack | Game pass | 149 R$ | 4 extra victory emotes |
| Scrap Pack S | Dev product | 49 R$ | 500 Scrap |
| Scrap Pack M | Dev product | 149 R$ | 2,000 Scrap |
| Scrap Pack L | Dev product | 399 R$ | 6,000 Scrap |
| Premium cosmetics / bundles | Dev product | 99–399 R$ | Skins, KO effects, trails |

- **Premium perks:** +10% Scrap, one exclusive Premium skin, Premium Payouts via engagement.
- **Private servers:** 100 R$/month. Owner can lock mode, pick map, set round length. Rewards at 50%.
- Nothing sold for Robux gives a combat advantage. Paid random items must show all outcomes and odds (none at launch).
  PolicyService hides paid random items / paid trading where not allowed and respects other policy flags.

## 8. Retention & social

- **Onboarding (first 2 min):** spawn in Training Yard: move → punch dummy → shove it off a ledge → grab a chair and
  throw it → dash across a gap. Reward 200 Scrap + "Rookie" title, then auto-join next round. Returning players skip
  (replay button in Settings). First round: tips for grabbing and dashing.
- **Login streak (7 days):** 50 / 75 / 100 / 150 / 200 / 250 Scrap, Day 7 = weekly rotating cosmetic. Missing a day
  resets to Day 1.
- **Playtime:** +25 Scrap every 10 minutes online, up to 6 times per day.
- **Quests:** 3 daily (75–150 Scrap each, e.g. "KO 5 players with a chair", "Win 1 Classic round", "Perfect Dodge 10
  times", "Break 8 structures"), 1 weekly (600 Scrap). Reset 00:00 UTC.
- **Badges:** Welcome, First KO, First Win, Ring-Out Rookie (100 ring-outs), Chair Master (50 chair KOs), Demolition
  (500 structures), Survivor (win Classic without losing a life), Level 10 / 25 / 50 / 100.
- **Leaderboards:** global all-time and weekly Wins, KOs, Level (OrderedDataStore); in-server scoreboard; lobby
  billboards.
- **Social:** party system (up to 4), friend bonus +10% XP per friend in server (max +30%), group join reward
  150 Scrap + group chat tag.
- **Codes & events:** one-use codes validated on the server (stored in Config); seasonal map remixes, double-Scrap
  weekends, event-only cosmetics.

## 9. Build plan

- **Phase 1 — Core loop playable:** Config, data saving, Lobby blockout, Broken Highway, movement + Punch + Shove +
  Dash, knockback/Percent, Classic and Casual rules, round manager (vote → round → results), grab/throw props,
  breakable structures, crumbling platforms, basic HUD on mobile/PC/gamepad.
- **Phase 2 — Progression & content:** Scrap/XP rewards, levels and ranks, 3 extra styles, cosmetics + Locker, Shop
  with daily rotation, Junkyard Isles + Neon Motel, VFX/SFX pass, animations, Training Yard tutorial.
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
