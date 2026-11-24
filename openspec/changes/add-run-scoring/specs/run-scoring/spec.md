# Spec Delta

## Purpose

Defines how a run earns points, how the breakdown is stored and shown to the player, and how difficulty influences the total, so every run ends with an explainable score.

## ADDED Requirements

### Requirement: Score is built from itemized categories
The system SHALL award points in separate categories: rooms cleared, elite battles defeated, bosses defeated, acts cleared, flawless fights, high-health fight finishes, gold held at the end, relics owned (weighted by rarity), events completed, and a victory bonus. Point values SHALL be configurable without code changes.

#### Scenario: Clearing a room
- **WHEN** the player wins a battle in a regular room
- **THEN** the rooms-cleared category increases by one and its points are added at the current multiplier

#### Scenario: Victory
- **WHEN** the player beats the final boss
- **THEN** the victory bonus category is awarded once

### Requirement: Difficulty multiplier
Points earned from rooms, battles and events SHALL be multiplied by a factor from the current difficulty score: 0.75 at score 0 rising linearly to 1.5 at score 100.

#### Scenario: Strong player
- **WHEN** a room worth 10 base points is cleared at difficulty score 100
- **THEN** 15 points are awarded

#### Scenario: Struggling player
- **WHEN** the same room is cleared at difficulty score 0
- **THEN** 7.5 points are awarded, rounded as the category total is displayed

### Requirement: Score persists with the run
The score breakdown SHALL be saved with the run and restored on Continue.

#### Scenario: Continue keeps score
- **WHEN** a run with 240 points is saved and continued
- **THEN** the run resumes with 240 points and the same breakdown

### Requirement: Score screen at the end of every run
When a run ends by victory or defeat, the system SHALL show a score screen listing every category with its count, points and the multiplier applied, plus the total, before returning to the main menu.

#### Scenario: Defeat
- **WHEN** the player dies in Act 2
- **THEN** a score screen shows everything earned so far, with no victory or act-3 bonuses, and the total

#### Scenario: Victory
- **WHEN** the player wins the run
- **THEN** the score screen includes the victory bonus and the total

### Requirement: Player name is chosen before the run
Starting a new run SHALL require a player name of 1 to 16 characters, saved with the run.

#### Scenario: Empty name
- **WHEN** the player tries to start a new run with an empty name
- **THEN** the run does not start and the name field is highlighted

#### Scenario: Continue keeps name
- **WHEN** a run is continued
- **THEN** the same name is used for the final score
