# Spec Delta

## Purpose

Defines how quickly combat turns come around and how slowing effects work, so fights keep moving and slows feel tactical instead of stalling an enemy.

## ADDED Requirements

### Requirement: Turn bar fill requirement
An actor's turn bar SHALL fill when accumulated progress reaches 20, using the same requirement for the player and every enemy, defined in one place. Progress each second equals the actor's speed times its slow factor.

#### Scenario: Time to act
- **WHEN** an actor with speed 4 and no slow starts with an empty bar
- **THEN** it acts after 5 seconds

#### Scenario: Starting progress
- **WHEN** a battle starts
- **THEN** the player begins at 50% of the requirement and each enemy begins between 0% and 33% of it

### Requirement: Speed Down is a percentage slow
Each Speed Down stack SHALL multiply an actor's progress rate by 0.85. Stacks SHALL be unlimited, and the rate SHALL never reach zero.

#### Scenario: Three stacks
- **WHEN** an enemy with speed 4 has 3 Speed Down stacks
- **THEN** its progress rate is about 2.45 per second (4 × 0.85³)

#### Scenario: Low-speed enemy
- **WHEN** an enemy with speed 3 receives 2 stacks
- **THEN** it acts after about 9.2 seconds, not after 20 seconds

### Requirement: Speed Down expires
When an affected actor completes an action, it SHALL lose one Speed Down stack, and the status SHALL disappear at zero stacks.

#### Scenario: Decay
- **WHEN** an enemy with 3 stacks completes an action
- **THEN** it has 2 stacks

#### Scenario: Removal
- **WHEN** an enemy with 1 stack completes an action
- **THEN** the Speed Down status is removed

### Requirement: Speed Down is readable
The status tooltip SHALL show the current slow as a percentage and the number of stacks left.

#### Scenario: Tooltip
- **WHEN** the player opens the tooltip of a 2-stack Speed Down
- **THEN** it shows about 28% slower and 2 stacks left

### Requirement: Relic activation delay is bounded
Relic activation at the start and end of combat and turns SHALL wait 0.25 seconds per relic and SHALL NOT exceed 1.5 seconds in total per phase.

#### Scenario: Many relics
- **WHEN** 10 relics activate at the start of combat
- **THEN** the phase takes no more than 1.5 seconds
