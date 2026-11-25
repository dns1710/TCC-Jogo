# Spec Delta

## Purpose

Keeps gold scarce enough that shop prices and gold events force choices, by scaling every gold payout with one configured factor and keeping the difficulty system's gold thresholds in line.

## ADDED Requirements

### Requirement: One income scale for every payout
Gold paid out by battles, bosses, treasure chests, positive event outcomes SHALL be multiplied by a single configured income scale, rounded to a whole number.

#### Scenario: Battle gold
- **WHEN** a battle that pays 60 to 70 gold is won with an income scale of 0.5
- **THEN** the reward screen offers 30 to 35 gold

#### Scenario: Event costs unchanged
- **WHEN** an event choice costs 40 gold
- **THEN** it still costs 40 gold whatever the income scale is

### Requirement: Starting gold is set directly
A new run SHALL start with the configured starting gold, which is not multiplied by the income scale.

#### Scenario: Starting gold
- **WHEN** a new run starts with an income scale of 0.5 and a configured starting gold of 50
- **THEN** the player starts with 50 gold

### Requirement: Gold-giving relics follow the scale
A relic that pays gold on its own SHALL pay an amount in line with the income scale.

#### Scenario: Golden Clover
- **WHEN** the player wins a battle holding Golden Clover with an income scale of 0.5
- **THEN** the extra gold it adds is about half of the version 2 amount

### Requirement: Gold thresholds track the economy
The difficulty system's gold thresholds (the gold needed to offer a shop after a hard fight and the gold under which the player counts as broke) SHALL be set relative to the same income scale.

#### Scenario: Broke check
- **WHEN** the income scale is 0.5
- **THEN** the broke threshold is half its version 2 value

### Requirement: Economy is simulated before it ships
The chosen income scale, prices and thresholds SHALL be checked with the reward simulation, which reports gold at each shop visit, relics bought per visit, mythic affordability and unspent gold at the end of a run.

#### Scenario: Simulation report
- **WHEN** the reward simulation is run
- **THEN** it prints median gold at a shop visit in units of an average common price, the share of visits where the player cannot buy everything, and the share of mythic offers the player can afford
