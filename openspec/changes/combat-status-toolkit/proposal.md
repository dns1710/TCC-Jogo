# Proposal

## Why

Acts 2 and 3 need enemies that control, expose and wear down the player, not just hit harder. Today there are only Burn, Poison, Thorns and flat stat statuses. Speed Down writes the turn-bar rate directly, so a second slow or a freeze would overwrite it. Nothing makes a target take extra damage, ignore block, halve block gains, or burn with stacking intensity. These building blocks must exist before any Ice or Fire enemy is built.

## What Changes

- Turn-bar slows are tracked per source and combined, so Speed Down, Freeze and future effects stack without overwriting each other.
- Add five statuses, each readable and usable by enemies and the player:
  - **Freeze:** the turn bar stops for 1.5 seconds of battle time, then the actor is immune to Freeze for 4 seconds (no chain-locking).
  - **Brittle:** the next hit taken deals 50% more damage, then the status ends.
  - **Scorch:** a stacking burn; at the end of each of its owner's actions it deals damage equal to its stacks, then loses one stack.
  - **Ashen:** block the owner gains is halved (rounded down) for its next 3 actions.
  - **Sunder:** the next hit the owner takes ignores its block, then the status ends.
- Placeholder status icons (recolored copies of existing icons) so the statuses are visible until final art lands.
- Bosses can be marked immune to Freeze.

Out of scope: any enemy that uses these statuses (separate changes), tuning of other statuses, final status art.

## Capabilities

### New Capabilities
- `combat-statuses`: how slows combine, and what Freeze, Brittle, Scorch, Ashen and Sunder do.

### Modified Capabilities

None. The existing `combat-pacing` spec's Speed Down requirements keep their behavior; only how the rate is combined changes.

## Impact

- Code: `scenes/player/player.gd`, `scenes/enemy/enemy.gd` (rate modifiers, damage hooks), `statuses/status_speed_down.gd`, `effects/block_effect.gd`; new status scripts and resources in `statuses/`; new `art/arte nao tao verdadeira/` icons.
- Tests: new `tools/verify_combat_statuses.tscn`; existing `verify_combat_pacing` must keep passing.
- Needed by: `act2-ice-enemies`, `act2-boss-krampus`, `act3-fire-enemies`, `act3-boss-fire-dragon`. Independent of `enemy-summoning-and-minions`.
- Art: 5 status icons (see `art/ART_REQUESTS.md`).
