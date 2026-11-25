# item-balance-report Specification

## Purpose

Gives designers one headless, reproducible table of every relic in the game with its budget status, so balance decisions come from data instead of memory.

## Requirements

### Requirement: Report lists every relic
The report SHALL list every relic resource found under `relics/` except the `1old` folder, grouped by rarity from common to mythic, with name, slot, rarity, stat total, weapon dice, average damage, effect text, statuses mentioned and a consumable marker.

#### Scenario: New relic appears without code changes
- **WHEN** a new relic resource is added under `relics/` and the report is run
- **THEN** the relic appears in the table under its rarity

#### Scenario: Retired relics are excluded
- **WHEN** the report is run
- **THEN** no relic from `relics/1old` appears

### Requirement: Stat total counts negatives
A relic's stat total SHALL be its ATTACK, BLOCK and SPEED bonuses summed, with negative bonuses subtracting.

#### Scenario: Speed penalty lowers the total
- **WHEN** a relic has +3 BLOCK and -1 SPEED
- **THEN** its reported stat total is 2

### Requirement: Weapon average damage
For a relic with weapon dice the report SHALL show the dice as `NdS` and the average damage `N*(S+1)/2`.

#### Scenario: 1d12 weapon
- **WHEN** a relic has one die of 12 sides
- **THEN** the report shows `1d12` and an average of 6.5

### Requirement: Budget compares a weighted stat total
The budget comparison SHALL use a weighted stat total in which a point of SPEED, ATTACK and BLOCK counts by what it is worth in combat (SPEED 1.0, ATTACK 0.7, BLOCK 0.3), while the table still shows the plain total.

#### Scenario: Block is cheap
- **WHEN** a relic gives +3 BLOCK and -1 SPEED
- **THEN** its weighted total is -0.1 and its plain total is 2

### Requirement: Budget flags
The report SHALL mark any relic whose weighted stat total or weapon average exceeds the budget of its rarity, unless the relic is a listed exception, and SHALL mark relics with inconsistent data.

#### Scenario: Above budget
- **WHEN** a common relic has a weighted stat total above the common budget
- **THEN** its row carries an over-budget flag naming the exceeded measure

#### Scenario: Listed exception
- **WHEN** an over-budget relic is in the exception list
- **THEN** its row shows the exception and its reason instead of an over-budget flag

#### Scenario: Dice sides without a dice amount
- **WHEN** a relic sets weapon die sides but no weapon dice amount
- **THEN** its row carries a data warning

### Requirement: Rarity summary and non-failing run
The report SHALL end with a per-rarity summary (relic count, average stat total, budget) and SHALL exit successfully even when relics are flagged.

#### Scenario: Flags do not fail the run
- **WHEN** one or more relics are flagged
- **THEN** the process exits with code 0 and the flags are visible in the output
