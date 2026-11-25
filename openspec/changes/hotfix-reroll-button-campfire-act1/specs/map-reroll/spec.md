# Spec Delta

## Purpose
Defines how the map's Reroll button reflects the player's remaining rerolls, so earned rerolls can always be spent.

## ADDED Requirements

### Requirement: Reroll button reflects the current reroll count
The Reroll button on the map SHALL be enabled if and only if the player has at least one reroll, regardless of how the count changed.

#### Scenario: Reroll gained from an event after running out
- **WHEN** the player has 0 rerolls (button disabled) and an event grants +1 reroll and the player returns to the map
- **THEN** the Reroll button is enabled and can start reroll mode

#### Scenario: Last reroll spent
- **WHEN** the player spends their final reroll on a room
- **THEN** the Reroll button becomes disabled

#### Scenario: Reroll count lost to an event
- **WHEN** an event removes rerolls leaving the player with 0
- **THEN** the Reroll button is disabled when the map is shown

#### Scenario: Run loaded from a save
- **WHEN** a saved run is loaded
- **THEN** the Reroll button state matches the saved reroll count
