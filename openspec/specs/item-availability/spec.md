# item-availability Specification

## Purpose

Defines what a new run starts with and which items can reach the player, so every item that exists can be found and runs begin from the same empty state.

## Requirements

### Requirement: A new run starts itemless
A new run SHALL begin with no relics owned and nothing equipped. The first items come from the first-battle reward.

#### Scenario: New run
- **WHEN** the player starts a new run
- **THEN** the relic inventory is empty and no weapon, helmet, armor or trinket is equipped
- **AND** the player's stats are the character's base stats

#### Scenario: Continued run
- **WHEN** a saved run is continued
- **THEN** the relics saved with it are restored unchanged

### Requirement: Every item can drop
Every item that is not marked as a starter item SHALL belong to at least one of the reward, treasure or shop pools, so it can be found in a run.

#### Scenario: Item in no pool
- **WHEN** an item that is not a starter item is in none of the three pools
- **THEN** the item pool check fails and names the item

#### Scenario: Legacy items
- **WHEN** the check scans the item folders
- **THEN** items in the retired legacy folder are ignored

### Requirement: Starter items are not offered as drops
An item marked as a starter item SHALL NOT be offered as a reward, chest item or shop item, and no item that should drop SHALL carry that mark.

#### Scenario: Starter flag
- **WHEN** an item is marked as a starter item
- **THEN** no reward, chest or shop offers it

#### Scenario: Droppable weapon
- **WHEN** the first-battle weapon reward is rolled
- **THEN** Hunter's Axe is eligible to appear

### Requirement: Treasure chests never offer commons
Treasure chests SHALL only offer uncommon, rare and mythic items, so common items are available through rewards and shops only.

#### Scenario: Common item
- **WHEN** a common item is in the reward and shop pools but not the treasure pool
- **THEN** the item pool check still passes for that item
