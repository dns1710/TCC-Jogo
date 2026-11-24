# Spec Delta

## Purpose

Keeps every relic's power in line with its rarity so higher rarities feel better without any single relic defining the run by accident.

## ADDED Requirements

### Requirement: Relics respect their rarity budget
Every relic SHALL have a weighted stat total and weapon average at or below the budget of its rarity, unless it is listed as an exception.

#### Scenario: No unlisted outliers
- **WHEN** the balance report is run after this change
- **THEN** no relic is flagged over budget except those in the exception list

### Requirement: No relic is a trap
No relic of a rarity SHALL be worse on its own, in the balance simulator, than the common kit item in its slot, unless its description presents it as a combination piece.

#### Scenario: Heavy armor
- **WHEN** the relic ranking is run
- **THEN** Heavier Armor, Heavy Plate and Heavy Helmet each save at least as much HP per fight as the kit armor, or are listed as combination pieces

### Requirement: Exceptions are explicit
A relic that exceeds its budget on purpose SHALL be listed with the exceeded measure and a reason.

#### Scenario: Tradeoff item
- **WHEN** a relic has a large block bonus balanced by a speed penalty and is listed as an exception
- **THEN** the report does not flag it and shows the reason

### Requirement: Relic data is consistent
A relic with weapon dice SHALL define both die sides and dice amount, and every relic SHALL have an explicit rarity.

#### Scenario: Barbarian Armor
- **WHEN** the relic data is loaded
- **THEN** Barbarian Armor either has both weapon die fields set or neither

### Requirement: Item numbers keep the dice rule
Item effects that deal damage, grant block or heal SHALL state dice; gear stat bonuses and status stack counts SHALL remain numbers.

#### Scenario: Tuned effect
- **WHEN** a damage or block effect of a relic is tuned in this change
- **THEN** its tooltip and code express it as dice, not a flat amount

### Requirement: Tooltips match behavior
After tuning, each changed relic's tooltip SHALL describe its current numbers.

#### Scenario: Changed relic
- **WHEN** a relic's value is changed
- **THEN** its tooltip text states the new value and the verify scripts assert it
