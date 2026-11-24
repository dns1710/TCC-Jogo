# Spec Delta

## Purpose

Defines the background drawn behind the map so the map screen matches the look of each act and stays readable.

## ADDED Requirements

### Requirement: The map uses the act's background
The map SHALL draw the background defined by the current act, scaled to fill the screen and darkened so the map stays readable, and the background SHALL stay fixed while the map scrolls.

#### Scenario: Act 2 map
- **WHEN** the map is shown in Act 2
- **THEN** the ice background is drawn behind it, filling the screen

#### Scenario: Scrolling
- **WHEN** the player drags the map sideways
- **THEN** the background does not move

### Requirement: A default background replaces the gradient
When the current act defines no map background, the map SHALL use a darkened forest background. The grey to brown gradient SHALL NOT be used.

#### Scenario: Act without a background
- **WHEN** the map is shown for an act whose map background is empty
- **THEN** the darkened forest is shown

### Requirement: Map elements stay readable
Rooms, connection lines and the top bar SHALL stay clearly distinguishable from the background in every act.

#### Scenario: Bright background
- **WHEN** the map is shown over the ice background
- **THEN** rooms and lines are still easy to tell apart from the background
