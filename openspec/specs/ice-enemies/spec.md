# ice-enemies Specification

## Purpose

Defines how each Act 2 (Ice) enemy fights and how Act 2's battles are drawn, so Ice combat has distinct tactical problems instead of larger numbers.

## Requirements

### Requirement: Snow wolves fight as a pack
A Snow Wolf's attacks SHALL deal 1 extra damage for each other living wolf in the battle. The Snow Wolf Alpha SHALL be able to Howl, giving every living wolf one stack of Speed Up, at most once every 4 of its actions.

#### Scenario: Pack bonus
- **WHEN** a wolf attacks while 2 other wolves are alive
- **THEN** its attack deals 2 extra damage
- **AND** when the others are dead it deals none

#### Scenario: Howl limit
- **WHEN** the Alpha has just Howled
- **THEN** it does not Howl again until it has taken 4 more actions

### Requirement: The Ice-Crystal Spider punishes slowed targets
The Spider's Web SHALL apply 2 Speed Down stacks to its target. Its Crystal Bite SHALL deal 50% more damage to a target that has Speed Down.

#### Scenario: Bite on a slowed player
- **WHEN** the Spider bites a player with Speed Down
- **THEN** the bite deals 50% more damage than against an unslowed player

### Requirement: The Snow Golem stores and releases block
The Snow Golem SHALL gain 4 block at each Pack Snow action, up to 20. When it has 20 block its next action SHALL be Avalanche, a heavy hit that removes all its block.

#### Scenario: Reaching the cap
- **WHEN** the Golem has used Pack Snow five times without being broken
- **THEN** it has 20 block and its next action is Avalanche
- **AND** after Avalanche its block is 0

### Requirement: The Banshee controls and exposes
The Banshee's Haunt SHALL apply Brittle to the player. Her Frost Wail SHALL apply a short Freeze to the player, only while the player has Brittle, and at most once every 5 of her actions. She SHALL never Freeze a player who is already frozen or immune.

#### Scenario: Wail needs Haunt
- **WHEN** the player has no Brittle
- **THEN** the Banshee does not use Frost Wail

#### Scenario: Wail frequency
- **WHEN** the Banshee has just used Frost Wail
- **THEN** she cannot use it again for 5 actions

### Requirement: The Yeti telegraphs and enrages
The Yeti's Ground Pound SHALL be preceded by a visible preparation action and SHALL apply 2 Speed Down stacks. The first time its health falls to 50% or below it SHALL roar, gaining Attack Up and becoming immune to Speed Down for the rest of the fight.

#### Scenario: Roar
- **WHEN** the Yeti first drops to 50% health
- **THEN** its next action is Roar, it gains Attack Up, and Speed Down no longer affects it

### Requirement: Act 2 has its own battle pool
Act 2 SHALL use its own battle pool with at least 3 tier 0, 4 tier 1, 2 tier 2 and 1 tier 3 (Krampus) battles, and SHALL show the Ice battle background. Tier 0 to 2 battles SHALL be made of Ice enemies only.

#### Scenario: Pool contents
- **WHEN** Act 2's pool is inspected
- **THEN** every tier has at least the required number of battles and each tier 0 to 2 battle contains only Ice enemies

#### Scenario: Boss floor
- **WHEN** Act 2's boss floor is reached
- **THEN** its tier 3 battle exists (Krampus, see `krampus-boss`) and is never empty
