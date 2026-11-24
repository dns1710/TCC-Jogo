# Spec Delta

## Purpose

Defines the control, vulnerability and damage-over-time statuses that enemies and the player can inflict on each other, so combat has more to read and react to than raw damage.

## ADDED Requirements

### Requirement: Turn-bar slows combine by source
An actor's turn-bar fill rate SHALL be its speed multiplied by every active slow, each tracked by its source. One slow ending SHALL NOT cancel another.

#### Scenario: Two slows at once
- **WHEN** an actor has 2 Speed Down stacks and is also frozen
- **THEN** its rate is zero while frozen
- **AND** when the freeze ends its rate returns to the Speed Down rate, not to full speed

### Requirement: Freeze stops the turn bar briefly
A frozen actor's turn bar SHALL not advance for 1.5 seconds of battle time. After the freeze ends the actor SHALL be immune to Freeze for 4 seconds. Applying Freeze during the freeze or the immunity SHALL have no effect. Actors marked immune to Freeze are never frozen.

#### Scenario: Freeze runs out
- **WHEN** the player is frozen at the start of a bar that is 40% full
- **THEN** the bar stays at 40% for 1.5 seconds and then resumes

#### Scenario: No chain freeze
- **WHEN** Freeze is applied again 2 seconds after a freeze ended
- **THEN** nothing happens

#### Scenario: Boss immunity
- **WHEN** Freeze is applied to a boss marked immune
- **THEN** the boss's turn bar is unaffected

### Requirement: Brittle makes the next hit hurt more
A target with Brittle SHALL take 50% more damage from the next hit it receives, after which Brittle ends. Applying Brittle again while it is active SHALL not stack.

#### Scenario: Next hit
- **WHEN** a target with Brittle takes a hit of 8 damage
- **THEN** it takes 12 damage and no longer has Brittle

#### Scenario: Reapplied
- **WHEN** Brittle is applied twice before any hit
- **THEN** the next hit still deals only 50% more

### Requirement: Scorch burns with growing intensity
Scorch SHALL stack. At the end of each of its owner's actions it SHALL deal damage equal to its stacks and then lose one stack.

#### Scenario: Decay
- **WHEN** an actor with 3 Scorch stacks completes actions
- **THEN** it takes 3, then 2, then 1 damage and the status ends

#### Scenario: Stacking
- **WHEN** 2 stacks are added to an actor that has 1
- **THEN** it has 3 stacks

### Requirement: Ashen halves block gains
While an actor has Ashen, block it gains SHALL be halved, rounded down, for its next 3 actions.

#### Scenario: Gaining block
- **WHEN** an Ashen actor would gain 9 block
- **THEN** it gains 4 block

#### Scenario: Expiry
- **WHEN** the actor completes 3 actions
- **THEN** Ashen ends and block gains are normal

### Requirement: Sunder ignores block once
A target with Sunder SHALL take the next hit it receives ignoring all its block, after which Sunder ends.

#### Scenario: Blocked hit
- **WHEN** a target with 10 block and Sunder takes 6 damage
- **THEN** it loses 6 health and its block is untouched by that hit
- **AND** Sunder ends

### Requirement: Statuses are readable
Each of these statuses SHALL show an icon with its stacks or remaining time, and a tooltip stating its numbers.

#### Scenario: Tooltip
- **WHEN** the player inspects Brittle
- **THEN** the tooltip states that the next hit deals 50% more damage
