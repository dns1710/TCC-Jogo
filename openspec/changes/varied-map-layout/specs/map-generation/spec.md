# Spec Delta

## MODIFIED Requirements

### Requirement: Map has a fixed single-region layout
The system SHALL generate one map per run with 14 floors with 7 room slots per floor (an odd number, so the start and boss sit in the middle slot). Floor 0 SHALL contain exactly one active room, in the middle slot.

#### Scenario: Map dimensions
- **WHEN** a new map is generated
- **THEN** the map has 14 floors of 7 slots each
- **AND** floor 0 has exactly one active room, in the middle slot

## ADDED Requirements

### Requirement: Routes branch and merge
The start room SHALL connect to 3 or 4 rooms on floor 1. Routes MAY split and merge on later floors, and every map SHALL contain at least 4 distinct routes from the start room to the boss.

#### Scenario: Branching at the start
- **WHEN** a new map is generated
- **THEN** the start room has 3 or 4 connections

#### Scenario: Several routes
- **WHEN** a new map is generated
- **THEN** at least 4 distinct paths lead from the start room to the boss

### Requirement: Floors are partly filled
Each floor from 1 to 12 SHALL have between 3 and 5 active rooms out of its 7 slots.

#### Scenario: Floor occupancy
- **WHEN** a new map is generated
- **THEN** every floor from 1 to 12 has 3, 4 or 5 active rooms

### Requirement: No straight-lane routes
Routes SHALL change slots along the way: no route from floor 1 to floor 12 stays in a single slot for every floor, and at least 35% of all connections between floors 1 and 12 change slot.

#### Scenario: No straight line
- **WHEN** a new map is generated
- **THEN** no route stays in one slot from floor 1 to floor 12
- **AND** at least 35% of those connections link rooms in different slots

### Requirement: Lines only meet at shared rooms
Connection lines SHALL touch only at rooms they share. No two lines SHALL intersect anywhere else, no line SHALL pass within 8 pixels of a room that is not one of its ends, and two lines leaving or entering the same room SHALL be at least 12 degrees apart so they never run on top of each other. The start SHALL connect only to rooms in the inner 5 lanes and the floor before the boss SHALL use only those lanes, so the lines out of the start and into the boss are shallow.

#### Scenario: No crossing lines
- **WHEN** a new map is generated and its lines are drawn between room positions
- **THEN** every pair of lines that do not share a room is disjoint

#### Scenario: Overlapping lines
- **WHEN** two lines share a room
- **THEN** they leave it at least 12 degrees apart

#### Scenario: Lines and unrelated rooms
- **WHEN** a map is generated
- **THEN** no line passes within 8 pixels of a room that is not one of its two ends

### Requirement: Rooms are placed organically
Each room's position SHALL be offset from its slot position by a random amount within `PLACEMENT_RANDOMNESS` (at most half of it in each direction on each axis), and no two active rooms SHALL be closer than 14 pixels. The start and the boss SHALL be placed 30 pixels further out than the grid (before floor 1 and after floor 12) and SHALL not be offset.

#### Scenario: Offsets and spacing
- **WHEN** a new map is generated
- **THEN** every room is within the allowed offset of its grid position
- **AND** no two active rooms are closer than 14 pixels
