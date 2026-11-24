# Spec Delta

## Purpose
Defines which enemy battles belong to each act's battle pool, so each act shows its intended enemies.

## ADDED Requirements

### Requirement: Campfire enemy appears in Act 1 only
The Campfire (Living Flame) battle SHALL be part of the Act 1 (Forest) tier 2 battle pool and SHALL NOT be part of the Act 3 (Fire) pool.

#### Scenario: Act 1 tier 2 draw
- **WHEN** a tier 2 battle is drawn in Act 1
- **THEN** the Campfire battle is one of the possible results, with the same weight and gold reward as before

#### Scenario: Act 3 tier 1 draw
- **WHEN** a tier 1 battle is drawn in Act 3
- **THEN** the Campfire battle is never returned, and the pool still returns a battle for every tier
