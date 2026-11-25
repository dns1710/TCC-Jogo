# Spec Delta

## MODIFIED Requirements

### Requirement: First and last floors are protected from room changes
Rooms on the first and last floor SHALL NOT be changed by the player's reroll or by difficulty-driven room conversion. The campfires on the floor before the boss SHALL NOT be changed by difficulty-driven room conversion. Rooms on all other floors at or beyond the player's current floor MAY be.

#### Scenario: Reroll on a protected floor
- **WHEN** the player attempts to reroll a room on floor 0 or floor 13
- **THEN** the room is left unchanged and no reroll is consumed

#### Scenario: Difficulty conversion skips protected floors
- **WHEN** difficulty adjustment looks for rooms to convert
- **THEN** rooms on floor 0 and floor 13 are never candidates

#### Scenario: Pre-boss campfire is fixed
- **WHEN** difficulty adjustment looks for campfires to convert and only the pre-boss campfires are reachable
- **THEN** no room is converted and the pre-boss campfires stay campfires
