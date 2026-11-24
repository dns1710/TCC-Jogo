# dda-relic-scoring Specification

## Purpose

Defines how the difficulty adjustment (DDA) counts relics so the score and swap thresholds stay calibrated when relic drops become rarer.

## Requirements

### Requirement: Points per relic picked up
The DDA score SHALL gain the configured points for each relic picked up, by rarity.

#### Scenario: Rare relic
- **WHEN** the player takes a rare relic
- **THEN** the score rises by the configured rare value

### Requirement: Consumed relics keep their points
Consuming a relic (for example Phoenix Feather) SHALL NOT reduce the score already earned for it.

#### Scenario: Feather used
- **WHEN** a held relic is consumed during combat
- **THEN** the DDA score is unchanged by the consumption

### Requirement: Held-relic thresholds use the live count
Checks that compare the number of relics held (battle shop swap, shop all bought, treasure shop swap) SHALL use the current count at the moment of the check.

#### Scenario: Count after consumption
- **WHEN** a relic was consumed before the check
- **THEN** the count used excludes that relic

### Requirement: Shop "bought everything" matches the shop size
The DDA setting for "bought everything the shop offered" SHALL equal the number of relics a shop offers.

#### Scenario: Two-relic shop
- **WHEN** a shop offers 2 relics and the player buys both
- **THEN** the shop-swap check treats it as having bought everything on offer

### Requirement: Relic-count thresholds are calibrated by simulation
The relic-count thresholds in the DDA configuration SHALL be chosen with the reward simulation so that, in the act where they separate players (act 1), the share of runs reaching each threshold is within 10 percentage points of the share before the drop-rate change.

#### Scenario: Calibration check
- **WHEN** the reward simulation is run with the old and the new rewards
- **THEN** the act-1 share of runs reaching the battle shop-swap and treasure shop-swap counts differs by 10 points or less
