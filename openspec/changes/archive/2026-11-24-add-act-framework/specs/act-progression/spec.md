# Spec Delta

## Purpose

Defines how a run is split into acts, each with its own content, boss and transition, so the game can grow beyond a single map while keeping progress, saves and carry-over consistent.

## ADDED Requirements

### Requirement: A run is an ordered sequence of three acts
A new run SHALL start in Act 1 and consist of three acts played in order. Each act SHALL define its own battle pool, event pool, background and transition text.

#### Scenario: New run starts in Act 1
- **WHEN** the player starts a new run
- **THEN** Act 1's map is generated using Act 1's pools and background

### Requirement: Maps use the current act's content
Every room generated for an act, and every room changed during that act (reroll, difficulty conversion, tier upgrade), SHALL draw battles and events from the current act's pools.

#### Scenario: Reroll draws from the current act
- **WHEN** the player rerolls a room into a battle during Act 2
- **THEN** the battle comes from Act 2's pool

### Requirement: Beating an act boss advances the run
When the player defeats an act's boss and it is not the last act, the system SHALL show that act's transition screen, fully heal the player, and generate the next act's map starting from its first floor.

#### Scenario: Act 1 boss defeated
- **WHEN** the player wins the Act 1 boss battle
- **THEN** the Act 1 transition screen with lore text is shown
- **AND** the player's health is set to maximum
- **AND** the next map is Act 2's, starting at floor 0

#### Scenario: Last act boss defeated
- **WHEN** the player wins the Act 3 boss battle
- **THEN** the win screen is shown and no further act is generated

### Requirement: Progress carries over between acts
Gold, relics (owned and equipped) and remaining rerolls SHALL carry over to the next act unchanged.

#### Scenario: Carry-over
- **WHEN** the player moves from Act 1 to Act 2 holding 120 gold, 5 relics and 2 rerolls
- **THEN** the player begins Act 2 with 120 gold, the same 5 relics and 2 rerolls

### Requirement: First-battle reward is Act 1 only
The weapon-and-gear reward for the opening battle SHALL be given only in Act 1. The first battle of Acts 2 and 3 SHALL give the normal battle reward.

#### Scenario: Act 2 first battle
- **WHEN** the player wins the first battle of Act 2
- **THEN** the reward is a regular battle reward, not the starting weapon and gear choice

### Requirement: Saves remember the act
Saving and continuing a run SHALL restore the current act, its map and the player's position in it. A save made before acts existed SHALL load as Act 1.

#### Scenario: Continue mid-Act 2
- **WHEN** the player saves while on Act 2 floor 5 and later continues
- **THEN** the run resumes in Act 2 with the same map and position

#### Scenario: Legacy save
- **WHEN** a save with no act information is continued
- **THEN** the run resumes as Act 1
