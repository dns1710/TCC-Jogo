# Spec Delta

## Purpose

Provides a fast headless way to compare relic loadouts against act enemies so tuning decisions are backed by numbers.

## ADDED Requirements

### Requirement: Simulate a loadout against an act
The simulator SHALL run a configurable number of fights of a chosen relic loadout against enemies of a chosen act and report results.

#### Scenario: Baseline run
- **WHEN** the simulator is run with the starting loadout, act 1 and 500 fights
- **THEN** it prints average turns to win, average HP lost per fight and win rate

### Requirement: Uses game numbers
The simulator SHALL read enemy health, dice and act scaling, and relic stats and dice, from the game resources rather than copies.

#### Scenario: Data change is picked up
- **WHEN** an enemy's health or a relic's weapon die is edited and the simulator is re-run
- **THEN** the report reflects the edit without any simulator code change

### Requirement: Reproducible
Given the same seed, loadout and act, the simulator SHALL print identical results.

#### Scenario: Same seed
- **WHEN** the simulator is run twice with the same seed
- **THEN** both outputs are identical

### Requirement: Compare two loadouts
The simulator SHALL print the difference in average HP lost and turns to win between two loadouts.

#### Scenario: Before and after a nerf
- **WHEN** it is run on a loadout with and without a tuned relic
- **THEN** it prints both results and their difference

### Requirement: Rank relics
The simulator SHALL rank every relic by the HP per fight it saves when added alone to the starting kit, grouped by rarity, and mark relics whose effects are not simulated.

#### Scenario: Ranking
- **WHEN** the simulator is run with the ranking option
- **THEN** it prints each rarity's relics sorted by HP saved, with a mark on relics reduced to their stats

### Requirement: Typical builds against progression targets
The simulator SHALL draw random builds like a run collects relics and print, per act, how much HP a typical build loses per regular fight against the targets 20-35% (act 1), 25-40% (act 2) and 30-45% (act 3).

#### Scenario: Targets printed
- **WHEN** the simulator is run without arguments
- **THEN** it prints the spread of HP lost per act and whether the median is inside or outside its target

### Requirement: Advisory only
The simulator SHALL NOT fail the project's verification suite on balance results.

#### Scenario: Out of target
- **WHEN** a loadout falls outside the proposed targets
- **THEN** the simulator prints a note and exits with code 0
