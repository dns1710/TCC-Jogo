# Proposal

## Why

The item pool is 39 items and almost all are stat sticks. Nothing the player can equip interacts with the statuses added in the last acts (Freeze, Brittle, Sunder, Scorch, Ashen) except Lighter and Snowballs. Mythic has only 2 items (Needle, Red Mantle), and because drops roll a rarity first and then pick uniformly inside it, those two repeat constantly in tier-2 rewards, chests and shops. Enemies now inflict statuses on the player, but the player has no way to defend against, exploit or convert them.

The existing item art is also incomplete for this content: five shipped statuses (Freeze, Brittle, Ashen, Scorch, Sunder) still use placeholder icons under `art/arte nao tao verdadeira/`.

## What Changes

- Add **24 items**: 2 common, 7 uncommon, 8 rare, 7 mythic (7 weapons, 4 helmets, 4 armor, 9 trinkets). Pool goes from 12/14/11/2 to 14/21/19/9 (common/uncommon/rare/mythic).
- Add one new status, **Ward**: negates the next debuff applied to its owner, then ends. No second status is added.
- Add three small engine hooks the items need:
  - **A**: `StatusHandler` gets a `status_added` signal, a `remove_status(id)` helper and a Ward interception point in `add_status`.
  - **B**: `Events.player_attacked(targets)` emitted by the attack action, so non-weapon items can react to hits (today only the equipped weapon gets `on_attack_hit`).
  - **C**: player-side `slow_immune`, a player `before_death` hook, and a one-shot "next turn bar starts at X%" carry-over consumed by `reset_atb`.
- Register every new item in the reward, treasure and shop pools, with the existing rarity rules (tier-2 rewards and chests never offer commons).
- **Art (first-class deliverable):** original 16x16 icons for all 24 items, a 10x10 icon for Ward, and real 10x10 icons replacing the five placeholder status icons. Art follows a written art direction (palette, outline, light source, per-rarity visual language) and passes a review checklist before items are wired in.
- Extend `tools/verify_item_pools.gd` and add a headless check for the new hooks, Ward and each item's behaviour.

No existing item, rarity or drop weight is changed. Nothing is **BREAKING**.

## Capabilities

### New Capabilities
- `ward-status`: the Ward status, its interception rule, expiry, UI and tooltip.
- `item-engine-hooks`: the generic hooks items rely on (status added/removed signals, status removal helper, player attacked event, player slow immunity, player before-death, turn-bar carry-over).
- `item-catalog-expansion`: the 24 new items, their slots, rarities, stats and behaviours, and their placement in the drop pools.
- `dice-damage-modifiers`: Brittle and item damage bonuses expressed as extra dice instead of percentages (added after playtesting found the numbers too high).
- `combat-text-cascade`: floating damage, healing and status text cascades instead of overlapping (playtest quality-of-life).
- `item-status-art`: art direction, size, format, naming and review requirements for item and status icons, including the replacement of the five placeholder status icons.

### Modified Capabilities
<!-- none: openspec/specs/ is empty, so there is no existing capability to modify -->

## Impact

- **Code:** `scenes/status_handler/status_handler.gd`, `custom_resources/actions/action_attack.gd`, `global/events.gd`, `scenes/player/player.gd`, `custom_resources/status.gd` (only if Ward needs a flag), plus new scripts under `relics/weapon|helmet|armor|trinket/` and `statuses/status_ward.*`.
- **Data:** 24 new `.tres` relic resources; `scenes/run/run.tscn` `battle_relic_pool`, `scenes/treasure/treasure.tscn` `treasure_relic_pool`, `scenes/shop/shop.tscn` `shop_relics`; five existing status `.tres` files get new icons.
- **Art:** 24 item PNGs (16x16) in `art/verdadeira arte/items/`, 6 status PNGs (10x10) in `art/verdadeira arte/status/`, with `.import` files.
- **Difficulty system:** unchanged, but rarity assignments feed its relic score (1/3/5/8), so rarity must be confirmed with the design table before shipping.
- **Out of scope:** act-weighted drop pools, rebalancing existing items, enemy changes, a second new status.
