# Spec Delta

## Purpose

Defines the short tutorial that teaches the battle basics, so a new player knows how to act without outside help, and how it can be shown again.

## ADDED Requirements

### Requirement: The tutorial shows automatically once
The tutorial SHALL appear automatically at the start of the first battle the game ever runs on a machine, and SHALL NOT appear automatically again once it has been dismissed.

#### Scenario: First battle ever
- **WHEN** a battle starts and the tutorial has never been seen
- **THEN** the tutorial overlay is shown over the battle and the battle is paused behind it

#### Scenario: Later battles and runs
- **WHEN** a battle starts after the tutorial was seen, in this run or a later one
- **THEN** no tutorial is shown

#### Scenario: Continuing a run
- **WHEN** a continued run starts its first battle and the tutorial was never seen
- **THEN** the tutorial is shown once

### Requirement: The tutorial covers the battle basics
The tutorial SHALL explain, in short pages, that the turn bar fills and the player acts when it is full, what Attack and Block do, that Attack is used by pressing it and then clicking an enemy, and that statuses can be inspected.

#### Scenario: Pages
- **WHEN** the tutorial is open
- **THEN** it shows at most 5 pages, each readable in a few seconds, with Next, Back and Skip controls and the current page number

### Requirement: Dismissing marks it seen
Closing the tutorial by finishing it or by skipping it SHALL record it as seen and resume the game.

#### Scenario: Skip
- **WHEN** the player skips the tutorial on page 1
- **THEN** it closes, the battle resumes and the tutorial is recorded as seen

### Requirement: The tutorial can be replayed on request
A Tutorial button on the main menu and on the in-run pause menu SHALL show the tutorial again at any time, regardless of whether it was seen, without changing the recorded state.

#### Scenario: From the main menu
- **WHEN** the player presses Tutorial on the main menu
- **THEN** the tutorial pages are shown and closing them returns to the main menu

#### Scenario: From the pause menu in a battle
- **WHEN** the player presses Tutorial on the pause menu
- **THEN** the tutorial is shown above the pause menu and closing it returns to the pause menu

### Requirement: The tutorial never changes battle rules
Showing the tutorial SHALL NOT alter battle state, timing or outcomes; the battle SHALL stay paused while the tutorial is visible and continue exactly where it was afterwards.

#### Scenario: Turn bars during the tutorial
- **WHEN** the tutorial is open
- **THEN** no turn bar advances and no action is performed

### Requirement: A missing or unreadable settings file is safe
If the settings file is missing it SHALL be treated as "not seen". If it cannot be written, the tutorial SHALL still appear at most once per game session.

#### Scenario: Unwritable settings
- **WHEN** the settings file cannot be written and the tutorial was shown this session
- **THEN** it does not appear automatically again in this session
