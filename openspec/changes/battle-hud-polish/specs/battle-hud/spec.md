# Spec Delta

## Purpose

Defines how the battle HUD presents the player's actions and state so the next step is always clear and legible, while leaving how battles work unchanged.

## ADDED Requirements

### Requirement: Action buttons look like buttons
The ATTACK and BLOCK buttons SHALL have a visible shape and distinct looks for normal, hover, pressed and disabled, and SHALL be disabled-looking whenever the player cannot act.

#### Scenario: Not the player's turn
- **WHEN** the player's turn bar is not full
- **THEN** both buttons look disabled and cannot be pressed

#### Scenario: The player's turn
- **WHEN** the player's turn bar becomes full
- **THEN** both buttons look enabled

### Requirement: Armed attack is visible
After ATTACK is pressed, the ATTACK button SHALL stay highlighted and a "Pick a target" hint SHALL be visible until the attack is used on an enemy or BLOCK is used, then both SHALL clear.

#### Scenario: Arming and using
- **WHEN** the player presses ATTACK and then clicks an enemy
- **THEN** the highlight and hint show after the first press and are gone once the attack is used

#### Scenario: Switching to block
- **WHEN** the player presses ATTACK and then BLOCK
- **THEN** the highlight and hint clear

### Requirement: Right mouse button cancels an armed attack
While an attack is armed, pressing the right mouse button SHALL cancel it: the pending attack is dropped, the highlight, hint and attack cursor clear, no action is used and the player's turn bar stays full so another action can be chosen. With no attack armed, the right mouse button SHALL do nothing.

#### Scenario: Cancelling
- **WHEN** the player presses ATTACK and then the right mouse button
- **THEN** the attack is cancelled, the cursor, highlight and hint return to normal, and the player can still act this turn

#### Scenario: Nothing armed
- **WHEN** the player presses the right mouse button with no attack armed
- **THEN** nothing happens

### Requirement: The HUD is readable on every battle background
Labels, bars and icons in the HUD SHALL stay legible on the forest, ice and fire backgrounds.

#### Scenario: Ice background
- **WHEN** a battle is shown on the ice background
- **THEN** health, block and button text have enough contrast to read at real window scale

### Requirement: Existing HUD behavior is unchanged
Pressing ATTACK then an enemy SHALL still use the attack on that enemy, pressing BLOCK SHALL still use block on the player, buttons SHALL still be disabled when the player cannot act, and stats and statuses SHALL still update as before.

#### Scenario: Attack and block still work
- **WHEN** the player presses ATTACK and clicks an enemy, then later presses BLOCK
- **THEN** the enemy takes the attack and the player gains block exactly as before this change
