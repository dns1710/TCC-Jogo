# Spec Delta

## Purpose

Defines what a shop sells: how many relics it stocks, which rarities it rolls, and what each relic costs, so shop size reacts to how the run is going and prices follow item strength.

## ADDED Requirements

### Requirement: Shop stocks 3 to 5 relics
A shop SHALL stock 3, 4 or 5 relics, chosen by a weighted roll whose weights depend on the run's difficulty score.

#### Scenario: Strong run
- **WHEN** a shop is generated with a difficulty score at or above the high threshold
- **THEN** the stock size is rolled from the high-score weights, which favor 3 relics

#### Scenario: Weak run
- **WHEN** a shop is generated with a difficulty score at or below the low threshold
- **THEN** the stock size is rolled from the low-score weights, which favor 5 relics

#### Scenario: Middle run
- **WHEN** a shop is generated with a score between the thresholds
- **THEN** the stock size is rolled from the middle weights, which favor 4 relics

#### Scenario: Small pool
- **WHEN** fewer relics are available than the rolled size
- **THEN** the shop stocks every relic that is available and no more

### Requirement: Shop rarity weights
Each stocked relic SHALL be rolled by rarity using configured weights, with mythic relics weighted higher than in version 2, and a relic SHALL NOT be stocked twice in the same shop or if the player already holds it.

#### Scenario: Mythic visibility
- **WHEN** many shops are generated with the default weights
- **THEN** about a quarter of them offer at least one mythic relic

### Requirement: Price follows rarity
A relic's price SHALL be rolled inside the price band of its rarity, the bands SHALL NOT overlap, and a mythic relic's price SHALL be at least about three times the average common price.

#### Scenario: Band ordering
- **WHEN** a common, an uncommon, a rare and a mythic relic are priced
- **THEN** every possible common price is below every possible uncommon price, and so on up to mythic

#### Scenario: Mythic is a splurge
- **WHEN** a mythic relic is stocked
- **THEN** its price is at least 170 gold with the default bands

### Requirement: Shop shows the real stock size to DDA
The shop SHALL record how many relics it stocked so the difficulty system can tell whether the player bought everything on offer.

#### Scenario: Stock recorded
- **WHEN** a shop is generated with 4 relics
- **THEN** the run records 4 as the number the shop offered

### Requirement: Shop numbers are data
The stock-size weights, score thresholds, rarity weights and price bands SHALL be read from configuration resources.

#### Scenario: Changing a band
- **WHEN** the uncommon price band is edited without code changes
- **THEN** the next generated shop prices uncommon relics inside the new band
