# Spec Delta

## Purpose

Defines the visual feedback combat provides, and guarantees that it is presentation only and never alters combat rules, timing or results.

## ADDED Requirements

### Requirement: Enemy deaths are animated without delaying the battle
When an enemy dies it SHALL fade and shrink out visually. The enemy SHALL still be removed from battle logic (the died event and removal from targeting and turn order) at the same moment as before the animation existed.

#### Scenario: Last enemy dies
- **WHEN** the last enemy takes lethal damage
- **THEN** the died event and the battle-over handling occur at the same time as without the animation
- **AND** its sprite fades out visually afterwards

### Requirement: The player's turn is cued
While the player can act, the turn bar and the ATTACK and BLOCK buttons SHALL show a soft pulse, and the pulse SHALL stop when the player has acted.

#### Scenario: Ready and acted
- **WHEN** the player's bar becomes full
- **THEN** the pulse starts
- **AND** it stops once an action is used

### Requirement: Gaining block gives feedback
When a fighter gains block, its stats row SHALL flash briefly and a "+N" popup SHALL show the amount actually gained.

#### Scenario: Block with Ashen
- **WHEN** an Ashen fighter's 9 block becomes 4
- **THEN** the popup shows +4

### Requirement: Attacks have anticipation within their existing time
An enemy's attack dash SHALL ease in with a short pull back, and the total action duration SHALL NOT change.

#### Scenario: Duration preserved
- **WHEN** an enemy performs a melee attack
- **THEN** it completes after the same time as before this change, within 0.05 seconds

### Requirement: Heavy hits are emphasized
A hit that removes at least 25% of the target's maximum health SHALL use a stronger shake and flash than ordinary hits.

#### Scenario: Big hit
- **WHEN** a hit removes 30% of a fighter's maximum health
- **THEN** the shake strength is larger than for a hit removing 5%

### Requirement: Feedback never changes combat
Visual feedback SHALL NOT change damage, block, statuses, turn bar timing, event order or battle outcomes, and SHALL pause when the game is paused.

#### Scenario: Paused
- **WHEN** the game is paused during an effect
- **THEN** the effect pauses with it and combat state is unchanged
