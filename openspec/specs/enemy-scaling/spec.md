# enemy-scaling Specification

## Purpose

Lets each act raise enemy health, attack and boss dice through data, so later acts stay challenging without editing individual enemy definitions.

## Requirements

### Requirement: Act health scale
Enemies spawned in an act SHALL have their maximum and starting health multiplied by the act's health scale, rounded up.

#### Scenario: Scaled health
- **WHEN** an enemy with 20 base health spawns in an act with scale 1.25
- **THEN** its maximum and current health are 25

#### Scenario: Default scale
- **WHEN** an enemy spawns in an act with scale 1.0
- **THEN** its health equals its base health

### Requirement: Act attack bonus
Enemies spawned in an act SHALL add the act's attack bonus to the flat part of their dice-based attacks.

#### Scenario: Bonus applied
- **WHEN** an enemy with a 1d4 attack and attack stat 0 spawns in an act with bonus +2
- **THEN** its attacks deal 3 to 6 damage before modifiers

### Requirement: Boss extra dice
Boss enemies SHALL roll the act's boss extra dice in addition to their normal attack dice, using the same die size.

#### Scenario: Boss in a scaled act
- **WHEN** a boss with a 1d6 attack spawns in an act with 1 extra boss die
- **THEN** its attacks roll 2d6

#### Scenario: Non-boss unaffected
- **WHEN** a regular enemy spawns in an act with 1 extra boss die
- **THEN** its attack dice are unchanged

### Requirement: Brittle uses the scaled die
Brittle on a player hit by a scaled enemy SHALL add one die of the same size as the attack's die.

#### Scenario: Scaled boss hit while Brittle
- **WHEN** a boss attack rolled with 2d6 hits a Brittle player
- **THEN** one additional d6 is added

### Requirement: Shared definitions are not modified
Scaling SHALL apply only to the spawned enemy's own stats, never to the shared enemy resource.

#### Scenario: Two acts in a row
- **WHEN** an enemy type is spawned in act 2 and later in act 1 of a new run
- **THEN** the act 1 enemy has its original base health
