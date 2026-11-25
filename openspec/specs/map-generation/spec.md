# map-generation Specification

## Purpose

Defines the shape and guarantees of the map generated at the start of a run, so every run presents a navigable, fair path from the first room to the boss.

## Requirements

### Requirement: Map has a fixed single-region layout
The system SHALL generate one map per run with 14 floors with 3 room slots per floor. Floor 0 SHALL contain exactly one active room, in the middle slot.

#### Scenario: Map dimensions
- **WHEN** a new map is generated
- **THEN** the map has 14 floors of 3 slots each
- **AND** floor 0 has exactly one active room, in the middle slot

### Requirement: Every active room is reachable and leads to the boss
Every active room SHALL be reachable from the start room by following connections, and every active room other than the boss SHALL have at least one connection to a room on the next floor.

#### Scenario: No unreachable rooms
- **WHEN** a new map is generated
- **THEN** every active room can be reached from the start room

#### Scenario: No dead ends
- **WHEN** a new map is generated
- **THEN** every active non-boss room connects forward to at least one active room on the next floor
- **AND** following connections from any active room always ends at the boss

### Requirement: Paths never cross
Connections between two consecutive floors SHALL NOT cross each other.

#### Scenario: Crossing check
- **WHEN** a new map is generated
- **THEN** no two connections between the same pair of consecutive floors swap slot order

### Requirement: Single boss on the last floor
The map SHALL contain exactly one boss room, on the last floor in the middle slot, with a tier-3 battle assigned.

#### Scenario: Boss placement
- **WHEN** a new map is generated
- **THEN** exactly one active room has the boss type
- **AND** that room is on floor 13 in the middle slot with a tier-3 battle

### Requirement: Fixed room types on key floors
The first room SHALL be a tier-0 monster battle, every active room on the floor before the boss SHALL be a campfire, and every active room on the middle floor (floor 6) SHALL be a treasure room.

#### Scenario: Key floors
- **WHEN** a new map is generated
- **THEN** the start room is a monster room with a tier-0 battle
- **AND** all active rooms on floor 12 are campfires
- **AND** all active rooms on floor 6 are treasure rooms

### Requirement: First and last floors are protected from room changes
Rooms on the first and last floor SHALL NOT be changed by the player's reroll or by difficulty-driven room conversion; rooms on all other floors at or beyond the player's current floor MAY be.

#### Scenario: Reroll on a protected floor
- **WHEN** the player attempts to reroll a room on floor 0 or floor 13
- **THEN** the room is left unchanged and no reroll is consumed

#### Scenario: Difficulty conversion skips protected floors
- **WHEN** difficulty adjustment looks for rooms to convert
- **THEN** rooms on floor 0 and floor 13 are never candidates

### Requirement: Project loads without script errors
With the map generator restored, starting the project SHALL produce no script parse or load errors.

#### Scenario: Headless boot
- **WHEN** the project is started headless and left running briefly
- **THEN** no script error is printed
