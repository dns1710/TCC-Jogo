# Spec Delta

## ADDED Requirements

### Requirement: Battles use the act's background
Each act SHALL be able to define the background its battles are drawn on. A battle SHALL use its act's background when one is defined, and the forest background otherwise.

#### Scenario: Act with a background
- **WHEN** a battle starts in an act that defines a battle background
- **THEN** that background is shown behind the fight

#### Scenario: Act without a background
- **WHEN** a battle starts in an act with no battle background
- **THEN** the forest background is shown
