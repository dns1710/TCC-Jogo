# Spec Delta

## Purpose

Defines the camp frame of the game: the scout, the rainstorm and the scoutmaster running the RPG, shown through a short opening, remarks when the difficulty changes, and an ending, using as little text as possible.

## ADDED Requirements

### Requirement: A short skippable opening starts each new run
Starting a New Run SHALL show an opening of at most 4 lines that sets the scene (a rainstorm at the camp, the scoutmaster proposing an RPG) and then starts the run. It SHALL be skippable with one click or key press and SHALL NOT be shown when a run is continued.

#### Scenario: New run
- **WHEN** the player starts a New Run
- **THEN** the opening is shown, and finishing or skipping it starts the run

#### Scenario: Continue
- **WHEN** the player continues a saved run
- **THEN** no opening is shown

### Requirement: The scoutmaster comments when difficulty is adjusted
When the difficulty adjustment converts at least one upcoming room, the scoutmaster SHALL make a one-line remark when the change becomes visible on the map: one set of lines when the adjustment makes the game harder (a room turned into a battle) and a different set when it makes it easier (a room turned into a campfire or a shop). No remark SHALL appear when no room changed.

#### Scenario: Making it harder
- **WHEN** the adjustment turns a shop or campfire into a battle
- **THEN** a harder-direction remark such as "things are going too smoothly" appears

#### Scenario: Going easier
- **WHEN** the adjustment turns a battle into a campfire or shop
- **THEN** an easier-direction remark such as "maybe I have been too harsh" appears

#### Scenario: Nothing changed
- **WHEN** the adjustment finds no room to convert
- **THEN** no remark appears

### Requirement: Remarks are short and never block play
A remark SHALL be one line, SHALL disappear by itself within a few seconds or on a click, SHALL NOT pause or block map input, and the same line SHALL NOT appear twice in a row.

#### Scenario: Repeat avoidance
- **WHEN** two harder-direction adjustments happen in a row
- **THEN** the two remarks are different lines

### Requirement: Victory plays a short ending sequence
The win screen SHALL play an ending sequence of about 10 seconds that closes the camp frame: the victory message with the character portrait, the rain stopping, a scoutmaster epilogue of at most 3 lines (the game is over, the scout may sleep, no duties in the morning) and the portrait dimming on the last line. The exit button (Main Menu) SHALL appear when the sequence ends.

#### Scenario: Victory
- **WHEN** the player beats the final boss
- **THEN** the sequence plays in order: victory message, rain stops, epilogue lines one at a time, portrait dims, exit button appears

#### Scenario: Skipping
- **WHEN** the player clicks or presses a key during the sequence
- **THEN** it jumps to its end state (rain stopped, full epilogue shown, portrait dimmed, exit button visible)

#### Scenario: Never trapped
- **WHEN** the sequence is playing, skipped or finished
- **THEN** the player can always reach the exit button within the sequence length at most

### Requirement: Narrative text stays minimal
The total narrative added by this capability SHALL stay within the limits above (opening at most 4 lines, remarks one line each, epilogue at most 3 lines), and in-world text such as events and act lore SHALL be unchanged.

#### Scenario: No extra dialogue
- **WHEN** a full run is played
- **THEN** the only added text is the opening, the remarks and the epilogue
