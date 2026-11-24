# Spec Delta

## Purpose

Defines how finished runs are sent to the online leaderboard under the player's name and how the leaderboard is shown, without blocking the player when the network is unavailable.

## ADDED Requirements

### Requirement: Final score is submitted under the player name
At the end of every run, win or loss, the system SHALL submit one record containing the player name and total score.

#### Scenario: Submit on defeat
- **WHEN** the player dies with 180 points under the name "Ana"
- **THEN** a record with name "Ana" and score 180 is submitted

### Requirement: Submission never blocks the player
If submission fails or is slow, the score screen SHALL still be shown and the player SHALL be able to return to the main menu, with a visible message that the submission failed.

#### Scenario: Offline
- **WHEN** the run ends with no network
- **THEN** the score screen is shown, a "could not submit" message is displayed, and the main menu is reachable

### Requirement: Leaderboard shows best score per name
The leaderboard SHALL list players ranked by their best submitted score, showing rank, name and score.

#### Scenario: Same name twice
- **WHEN** "Ana" has submitted 180 and later 300
- **THEN** the leaderboard shows one entry for "Ana" with 300

### Requirement: Leaderboard reachable from the main menu
The main menu SHALL provide a button that opens the leaderboard and a way back, and SHALL show an error label when the leaderboard cannot be loaded.

#### Scenario: Load failure
- **WHEN** the leaderboard cannot be fetched
- **THEN** an error message is shown instead of entries
