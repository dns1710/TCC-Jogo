# Spec Delta

## Purpose

Defines damage modifiers that add dice instead of percentages, so a bonus scales with the size of the die being rolled rather than with a growing number.

## ADDED Requirements

### Requirement: Brittle adds one die of the hit's size
A Brittle actor SHALL roll one extra die of the same size on the next hit it takes that was rolled with dice, then Brittle ends. A 1d6 hit becomes 2d6, and a 2d8 hit becomes 3d8.

#### Scenario: Player weapon hit on a Brittle enemy
- **WHEN** a Brittle enemy is hit by a 1d6 weapon
- **THEN** the weapon's damage includes one extra d6 and the enemy is no longer Brittle

#### Scenario: Enemy hit on a Brittle player
- **WHEN** a Brittle player is hit by an enemy attack rolled as 1d8
- **THEN** the hit includes one extra d8 and the player is no longer Brittle

### Requirement: Flat damage does not use Brittle
Damage that is not rolled with dice, including Thorns, flat item bonuses and Poison, Burn and Scorch ticks, SHALL NOT add a die and SHALL NOT end Brittle.

#### Scenario: Thorns hit on a Brittle enemy
- **WHEN** a Brittle enemy takes Thorns damage
- **THEN** the damage is unchanged and the enemy stays Brittle

### Requirement: The extra die is one die only
The extra die SHALL be a single die of the hit's size, SHALL NOT be added to the flat attack bonus, and SHALL NOT stack when Brittle is applied again.

#### Scenario: Brittle applied twice
- **WHEN** Brittle is applied twice and the actor takes a die hit
- **THEN** exactly one extra die is rolled

### Requirement: Item bonuses are dice
Item effects that deal damage, grant block or heal SHALL state their amount in dice, never as a flat number or a percentage of damage. Stat bonuses on gear (+BLOCK, +ATTACK, +SPEED) and status stack counts stay as numbers.

#### Scenario: Tooltip states dice
- **WHEN** the tooltips of Bulwark Maul, Hunter's Mercy, Pine-Tar Gloves, Emberweave Tunic, Cinderbrand and Carrion Thurible are read
- **THEN** they state dice, not a flat amount or a percentage of damage
