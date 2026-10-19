# Junkyard Brawl — launch checklist

Everything left before release, in order. The code side is done. Run `lune run tools/launch-check` at any time to
list the IDs and placeholders still unset in the code. This list follows the bible's launch checklist (§9).

## 1. Publish and game settings (Studio)

- [ ] **File → Publish to Roblox** (creates the experience). DataStores (saving, leaderboards) only work once the place
      is published.
- [ ] Game Settings → Security: **Allow Studio Access to API Services** on (for testing saves in Studio).
- [ ] Game Settings → Places: **Max players 12** (matches `Config.World.MaxPlayers`).
- [ ] Game Settings → Avatar: **R15** (the animations are made for R15; R6 also works).
- [ ] Devices: Computer, Phone, Tablet and Console all on (every control works on touch, keyboard and gamepad).
- [ ] Save the place after Rojo syncs, so the chat switch to TextChatService sticks.

## 2. Robux items, group, optional badges (Creator Dashboard → your experience)

Create these, then send the IDs to Claude (or paste them into the files named).

| Item | Type | Price | Goes in |
| --- | --- | --- | --- |
| VIP | Game pass | 299 R$ | `Config.Monetization.GamePasses.VIP.Id` |
| Emote Pack | Game pass | 149 R$ | `GamePasses.EmotePack.Id` |
| Scrap Pack S / M / L | Developer products | 49 / 149 / 399 R$ | `Products.ScrapPackS/M/L.Id` |
| Inferno skin | Developer product | 149 R$ | `Products.InfernoSkin.Id` |
| Lightning Trail | Developer product | 99 R$ | `Products.LightningTrail.Id` |
| Galaxy Burst KO effect | Developer product | 199 R$ | `Products.GalaxyBurst.Id` |
| Style slot | Developer product | 99 R$ | `Products.StyleSlot.Id` |

- [ ] Passes need an image (512×512). Products don't.
- [ ] Optional: a Roblox **group** for the community → `Config.Retention.Group.GroupId` (members get a [Crew] chat
      tag and 150 Scrap once).
- [ ] Optional, skipped for now: **badges** (Welcome, First KO, First Win …) → `Config.Retention.Badges`.

## 3. Music and sounds (Studio → Toolbox → Audio, free Creator Store audio only)

- [ ] Pick tracks and sounds, right-click → Copy Asset ID, and paste into `src/shared/Config/Audio.luau` (or send
      them to Claude). The bible asks for: lobby retro synthwave, a gritty chiptune-rock track per arena, a tension
      layer for the last 30 s, a victory sting, plus hits, dash, KO, explosion, smash, UI click and coin sounds.
      `lune run tools/launch-check` lists the empty slots.

## 4. Store page (Creator Dashboard → Places / Experience details)

- [ ] **Title:** Junkyard Brawl
- [ ] **Genre:** Fighting
- [ ] **Icon** 512×512: a bold character mid-punch on a scrap heap with the logo. Readable at small size, no text
      besides the name.
- [ ] **Thumbnails** 1920×1080 (up to 10). Take screenshots in Studio (Play, then the Roblox screenshot key or
      Windows' Snipping Tool) of:
  1. a crowded brawl on Broken Highway, someone flying off the edge with the K.O.! burst;
  2. Neon Motel at night with the MOTEL sign and the pool roof;
  3. Junkyard Isles with the crane and a thrown chair mid-air;
  4. the lobby bar (Shop counter, vote TVs, join pad);
  5. the Shop / Locker with cosmetics.
- [ ] **Description** (draft, edit freely):

  > Knock your rivals off floating scrapyards in a chaotic, cartoony brawler!
  >
  > - Punch, charge power punches, dash and Perfect Dodge
  > - Grab chairs, crates and tires and throw them; barrels explode!
  > - Platforms crumble as the round goes on: stay on your feet
  > - Classic (3 lives, last one standing) or Casual (endless respawns, score knock-offs)
  > - 3 arenas: Broken Highway, Junkyard Isles and Neon Motel
  > - Spin for fighting styles: Slugger, Scrapper and the Legendary Wrecker with a parry (free spin every day)
  > - Skins, hats, dash trails, KO effects and victory emotes
  > - Daily rewards, quests, leaderboards and parties with your friends
  >
  > Use code LAUNCH for free Scrap! (rename the code before launch)

- [ ] **Maturity & Compliance questionnaire**: answer it honestly. What the game has: unrealistic, cartoon fighting
      with no blood or gore; text chat (TextChatService, filtered by Roblox); paid items (passes, products) and
      **paid random items: yes** — style spins cost Coins, which can be bought with Robux (the odds are shown in game
      and paid spins are hidden where Roblox restricts them); no trading. This usually lands on a Mild label.
- [ ] Social links (optional): Discord / YouTube. The game doesn't show external links in-game (PolicyService rules
      would apply if it did).
- [ ] Optional: a short trailer or teaser video.

## 5. Translation

- [ ] Creator Dashboard → Localization: upload `src/localization/GameStrings.csv` to the game's localization table
      and turn on automatic translation. Re-upload whenever strings are added.

## 6. Tests before launch (bible §9)

- [ ] **Private beta with 10+ players**: set the experience to Friends (or a private server) and play a few full
      rounds of both modes. Watch the Developer Console (F9 → Server) for red errors.
- [ ] **Mobile**: a small phone and a tablet. Check that the buttons fit and don't overlap, the menus fit on screen,
      and the frame rate is OK (Low Graphics should switch itself on if it's low).
- [ ] **Console / gamepad**: open menus with D-pad Up, move with the D-pad / stick, A to press, B to leave a
      prompt. Check every screen can be reached and closed.
- [ ] **Saving stress test**: earn Scrap, buy something, leave, rejoin (same and different server) — everything
      kept; join from two devices at once — the second server takes over cleanly ("opened in another server").
- [ ] **Robux test**: in Studio (published place), buying is a free test purchase. Buy a Scrap pack and the VIP
      pass, and check the Scrap and the Gold Trail arrive.
- [ ] **Launch code ready**: rename `LAUNCH` in `src/server/ServerConfig.luau` and set its reward (or add an
      `ExpiresAt`).

## 7. Launch day

- [ ] Experience → Settings → **Public**.
- [ ] Watch Creator Dashboard → Analytics (economy events, round length, retention) and the error report.
- [ ] Tell Claude about bugs or balance changes: most numbers live in `src/shared/Config`.
