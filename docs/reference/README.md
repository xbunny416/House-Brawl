# Owner's reference pictures (2026-10-19)

Screenshots from other Roblox games, sent by the owner as **style references only**. Recreate the look in this
game's own code and parts; never copy models or assets out of another game.

| File | What to take from it |
| --- | --- |
| `leaderboard-boards.png` | The lobby leaderboard look: three tall dark boards side by side, a bold cream title with a thin gold underline, rows of rank · avatar headshot · name · value (right-aligned, thousands separators). The top 3 rows have rounded outlines and colored rank numbers: gold, silver, bronze; rows 4–10 are plain. |
| `style-roll.png` | The fighting-style roll (replaces buying styles): "Current style" name and description, the rarity tiers with their exact odds, a big Spin button, spins left, a pity counter, and style slots down the left side (equipped, empty slots to buy, a lock on a slot). |
| `lobby-lounge.png` | Furniture style for the lobby: dark wood-panel walls with gold trim, red sofa and armchairs, a round black marble table on a gold base over a dark rug with a gold ring, floor lamps with white shades, a vending machine with colorful shelves, a potted topiary plant. |
| `lobby-bunk-corner.png` | More lobby furniture: metal bunk beds, a kitchen counter with a sink, a microwave and a coffee machine, a cork board with pinned notes. |

## Owner's answers (2026-10-19)

- **Style roll spins:** a spin costs Scrap, plus 1 free spin a day; a pity counter guarantees the rarest style after
  enough spins. No Robux spin packs for now.
- **Rolled style:** a roll replaces the style in the active slot (like the reference). Extra slots are bought; a slot
  can be locked so a roll can't replace it. One equip slot to start.
- **Roster:** the existing styles as rarity tiers: Slugger = Uncommon, Scrapper = Rare, Wrecker = Legendary (Brawler
  stays the default). Rolling replaces the level unlocks. More styles may come later.
- **Lobby furniture:** rebuilt in code (in the map layout) in the reference style.

## Rules to respect

- **Paid random items:** Scrap can be bought with Robux, so Roblox counts Scrap spins (style roll, a paid spin wheel)
  as paid random items. Show every outcome and its exact odds before a spin, hide paid spins where Roblox restricts
  them (`PlayerPolicyService.allows(player, "PaidRandomItems")`), and declare them on the maturity questionnaire.
  Free spins don't count.
- **No reward for liking the game:** Roblox doesn't allow rewarding likes or favorites, and scripts can't check them.
  The group-join reward is fine (`Config.Retention.Group.GroupId`).
- **Free private servers:** set on the Creator Dashboard (Monetization → Private Servers); the code already makes them
  test-only (no Scrap, XP or stats).

## Owner's fix list (2026-10-19, being done in the owner's local CLI session)

- Delete parties; no leaderboard menu screen, only the boards in the lobby.
- UI: left menu = Shop, Inventory, Settings, Quests; also coins, "game in progress" and spectate mode.
- Daily reward pops up on login; quests can be checked there.
- Shop: wearable cosmetics, daily shop, Robux for coins and passes.
- Settings: visual, audio, promo code.
- Lobby: run only (no dash, no punch).
- Style: RNG roll, 1 equip slot + paid slots.
- Small light-grey key hints at the bottom of the UI, more when near something interactive.
- Classic mode only (no mode vote).
- Lobby 50% bigger and interactive: sit on chairs / couches, a spin wheel.
- Maps 2× bigger; the crumble closes in toward the centre over time.
- Optional: bartender phrases with an animation; chess and arm-wrestling minigames in the lobby.
- TV showing fun news.
- Free private servers, still test-only.
- Group join reward (no like reward, see above).
