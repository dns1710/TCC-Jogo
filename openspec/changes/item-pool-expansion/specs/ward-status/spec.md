# Spec Delta

## Purpose

Defines Ward, a protective status that absorbs the next debuff applied to its owner, so items can defend the player against statuses that enemies inflict.

## ADDED Requirements

### Requirement: Ward absorbs the next debuff
A Ward on an actor SHALL negate the next debuff applied to that actor, then end. Debuffs are Freeze, Brittle, Sunder, Scorch, Ashen, Speed Down, Attack Down, Poison and Burn. A negated debuff SHALL NOT be added to the actor and SHALL NOT run its effect.

#### Scenario: Ward blocks Freeze
- **WHEN** the player has Ward and an enemy applies Freeze to the player
- **THEN** the player's turn bar keeps filling, Freeze is not added, and Ward is removed

#### Scenario: Ward ignores buffs
- **WHEN** the player has Ward and gains Attack Up or Speed Up
- **THEN** the buff is applied and Ward stays

#### Scenario: Only one debuff is absorbed
- **WHEN** the player has Ward and two debuffs are applied one after the other
- **THEN** the first is negated and the second is applied normally

### Requirement: Ward does not stack
Applying Ward to an actor that already has Ward SHALL leave exactly one Ward on it and SHALL NOT extend or accumulate it.

#### Scenario: Reapplied Ward
- **WHEN** an actor with Ward gains Ward again
- **THEN** the actor still shows a single Ward that absorbs a single debuff

### Requirement: Ward persists through the combat
Ward SHALL remain on its owner until it absorbs a debuff or the combat ends, and SHALL NOT expire from time or from actions taken.

#### Scenario: Ward kept across turns
- **WHEN** the player takes several actions without receiving a debuff
- **THEN** Ward is still present

#### Scenario: Ward cleared between combats
- **WHEN** a combat ends
- **THEN** Ward is not carried into the next combat

### Requirement: Absorbed debuffs are reported
When Ward absorbs a debuff the game SHALL announce which status was absorbed and on which actor, so items can react to it.

#### Scenario: Absorb event
- **WHEN** Ward absorbs Brittle on the player
- **THEN** a status-absorbed event carrying the Brittle status and the player is emitted exactly once

### Requirement: Ward is readable on screen
Ward SHALL be shown in the status row with its own icon and a tooltip stating that it blocks the next debuff.

#### Scenario: Tooltip text
- **WHEN** the player inspects the Ward status
- **THEN** the tooltip says the next debuff will be negated
