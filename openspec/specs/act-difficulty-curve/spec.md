# act-difficulty-curve Specification

## Purpose

Defines how enemy strength grows across the three acts so progress through the run feels harder in a predictable, tunable way.

## Requirements

### Requirement: Acts are defined in order of strength
Act 1 SHALL keep the baseline enemy strength, and each later act SHALL have an enemy health scale and attack bonus greater than or equal to the previous act, with at least one of them greater.

#### Scenario: Monotonic curve
- **WHEN** the three act resources are loaded
- **THEN** health scale and attack bonus never decrease from act 1 to act 3 and each act differs from the previous one

### Requirement: Scaling values are act data
Each act resource SHALL carry `enemy_health_scale`, `enemy_attack_bonus` and `boss_extra_dice` with defaults that leave enemies unchanged.

#### Scenario: Missing values
- **WHEN** an act resource does not set the scaling values
- **THEN** enemies in that act spawn with their base stats

### Requirement: Boss growth is reported
The scaling check SHALL print, for each act after the first, how much the average hit of bosses and of regular enemies grows compared with act 1, so the curve can be judged.

#### Scenario: Growth printed
- **WHEN** the scaling check runs
- **THEN** it prints the average-hit growth of bosses and of regular enemies for acts 2 and 3

### Requirement: Worst-case boss hit stays survivable
The worst-case single hit of each boss in the act it is fought in (all dice at maximum plus Brittle's extra die) SHALL stay below the player's starting maximum health.

#### Scenario: Worst case printed
- **WHEN** the scaling check runs
- **THEN** it prints the worst-case boss hit per act and fails if one reaches the player's starting maximum health
