# Spec Delta

## Purpose

Defines how the game estimates how the player is doing and adjusts upcoming rooms in response, so difficulty adaptation is predictable, persistent across saves, and consistent across acts.

## ADDED Requirements

### Requirement: One difficulty score with recorded changes
The system SHALL keep a single difficulty score from 0 to 100, starting at 50, and every change to it (battle result, campfire, relic pickup, event outcome) SHALL go through one operation that records the reason and amount.

#### Scenario: Relic pickup changes the score
- **WHEN** the player gains an uncommon relic
- **THEN** the score rises by that rarity's amount, stays within 0 to 100, and the change is recorded with its reason

### Requirement: Campfire is scored before resting
The campfire score SHALL be based on the player's health when entering the campfire, before any heal. High health SHALL raise the score and low health SHALL lower it.

#### Scenario: Arriving hurt
- **WHEN** the player enters a campfire at 30% health and then rests
- **THEN** the score decreases based on the 30% reading, not on the post-rest health

### Requirement: Conversions happen at most as often as their flags allow
Each kind of conversion that is limited to once per act (such as swapping a shop for a battle) SHALL be marked used only when at least one room was actually converted.

#### Scenario: Nothing to convert
- **WHEN** a conversion is triggered but no eligible room exists
- **THEN** no room changes and the once-per-act flag stays available

#### Scenario: Conversion succeeds
- **WHEN** a shop is converted into a battle
- **THEN** that conversion cannot trigger again in the same act

### Requirement: Flags reset each act and persist in saves
All DDA flags SHALL reset at the start of every act and SHALL be saved and restored with the run. The difficulty score itself SHALL carry across acts.

#### Scenario: New act
- **WHEN** Act 2 begins after a shop conversion was used in Act 1
- **THEN** the shop conversion is available again and the score is unchanged

#### Scenario: Continue
- **WHEN** a run is saved with a flag used and later continued
- **THEN** the flag is still used

### Requirement: Room changes take effect immediately
A DDA room conversion SHALL change the room's type and contents as soon as it is decided, and any save made afterwards SHALL contain the change. The conversion animation SHALL be purely visual and SHALL only play when the map is shown.

#### Scenario: Save right after a conversion
- **WHEN** a battle is won, a conversion is decided, and the run is saved immediately
- **THEN** the saved map already contains the converted room

#### Scenario: Conversion while the map is hidden
- **WHEN** a conversion is decided during a reward screen
- **THEN** the room data changes at once and the animation plays the next time the map is shown
