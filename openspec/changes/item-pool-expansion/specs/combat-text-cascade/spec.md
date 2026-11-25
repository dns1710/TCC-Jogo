# Spec Delta

## Purpose

Defines how floating combat text (damage, healing and status names) is laid out so several numbers on one actor stay readable instead of drawing on top of each other.

## ADDED Requirements

### Requirement: Popups of one actor cascade
Floating text spawned for the same actor SHALL appear at the actor and push that actor's older popups up by one line, so no two live popups of an actor share the same position.

#### Scenario: Several hits at once
- **WHEN** three popups are spawned for one actor within the same moment
- **THEN** they are shown at least one line apart, newest lowest and oldest highest

### Requirement: Actors do not affect each other's text
Popups of different actors SHALL NOT push or reposition one another.

#### Scenario: Two enemies hit together
- **WHEN** two different enemies each receive a popup
- **THEN** each popup stays at its own enemy
