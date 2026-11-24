# Proposal

## Why

Combat already has some feedback (screen shake on hits, damage popups, a white hit flash, a scale-in for spawned enemies), but several moments are abrupt or silent: enemies vanish the instant they die, the player's turn bar filling gives no cue, gaining block has no feedback, and enemy attacks start without any anticipation. Small, purely visual effects will make fights readable and satisfying without touching any rule or timing.

## What Changes

- **Enemy death:** a short fade and shrink played on a visual copy, so the enemy is removed from battle logic at exactly the same moment as today.
- **Turn bar ready cue:** the player's bar and the ATTACK and BLOCK buttons pulse softly while the player can act.
- **Block feedback:** a brief flash on the stats row and a "+N" popup when block is gained, by the player or an enemy.
- **Attack anticipation:** enemy dashes get a small ease-in pull back inside their existing duration, so action length is unchanged.
- **Heavy hit emphasis:** a slightly stronger shake and flash when a hit takes a large share of health.
- A small shared helper for these tweens so new effects stay consistent.

Out of scope: new mechanics, new art or sounds, changing damage numbers, delays or turn order, and any change to AI, ATB or effect logic.

## Capabilities

### New Capabilities
- `combat-feedback`: the visual feedback combat gives for deaths, readiness, block and heavy hits, and the guarantee that it never changes combat behavior.

### Modified Capabilities

None.

## Impact

- Code: `scenes/enemy/enemy.gd` (death visual only), `scenes/player/player.gd`, `effects/block_effect.gd` (popup call), `scenes/ui/battle_ui.gd` or a small new node for the ready pulse, `scenes/enemy/melee_attack_action.gd` and older attack actions (tween easing only), a new helper script under `scenes/ui/` or `global/`.
- Tests: new `tools/verify_combat_feedback.tscn`; all combat suites must still pass unchanged.
