# Spec Delta

## Purpose

Defines how each Act 3 (Fire) enemy fights and how Act 3's battles are drawn, so Fire combat poses distinct tactical choices (what to kill first, when to block, when not to attack).

## ADDED Requirements

### Requirement: The Campfire spawns and heals Fire Spirits
The Campfire (the existing `enemies/living_flame/` Campfire, with Flames as the Fire Spirit) SHALL have no attack. It SHALL spawn a Fire Spirit whenever fewer than 2 are alive (no more often than every 2 of its actions) and SHALL heal its living Spirits for 6 when any is damaged. Fire Spirits SHALL be bound to it and fizzle when it dies. A Spirit's attack SHALL apply Burn to the player.

#### Scenario: Spawn rule
- **WHEN** the Campfire acts with 1 Spirit alive and no spawn in its last 2 actions
- **THEN** it spawns a second Spirit

#### Scenario: Fizzle
- **WHEN** the Campfire dies with 2 Spirits alive
- **THEN** each Spirit dies after its next action and the battle then ends

#### Scenario: Healing
- **WHEN** a Spirit has taken damage and the Campfire acts
- **THEN** the Campfire heals living Spirits for 6, not above their maximum

### Requirement: The Fire Salamander scorches attackers
While its hide is up, each time the Salamander takes damage the player SHALL gain 1 Scorch stack. After every third of its actions the hide SHALL be down until its next action, during which attacks do not scorch.

#### Scenario: Hide up
- **WHEN** the player damages a Salamander with its hide up
- **THEN** the player gains 1 Scorch stack

#### Scenario: Hide down
- **WHEN** the Salamander has just completed its third action
- **THEN** damaging it does not apply Scorch until it acts again

### Requirement: Fire Imps frenzy
Each time a Fire Imp dies, every living Fire Imp SHALL gain 1 Speed Up stack, up to 3 stacks each.

#### Scenario: Imp dies
- **WHEN** one of three imps is killed
- **THEN** the other two each gain 1 Speed Up stack

### Requirement: The Ashen Warrior breaks defenses and rallies
The Ashen Warrior's Sunder Strike SHALL deal damage and apply Sunder to the player. Rally SHALL give every living ally 1 Attack Up and SHALL only be used when it has an ally and has not been used in its last 4 actions.

#### Scenario: Sunder Strike
- **WHEN** the Warrior hits the player with Sunder Strike
- **THEN** the player has Sunder and the next hit ignores block

#### Scenario: Rally conditions
- **WHEN** the Warrior has no living ally, or used Rally within 4 actions
- **THEN** it does not use Rally

### Requirement: The Phoenix is reborn once
The first time the Phoenix would die it SHALL instead become an ash pile with 5 health that does not attack, and SHALL revive with 60% of its maximum health after 6 seconds of battle time unless the pile is killed. A revived Phoenix that dies, or a killed ash pile, SHALL stay dead.

#### Scenario: Revival
- **WHEN** the Phoenix is reduced to 0 health and the ash pile survives 6 seconds
- **THEN** the Phoenix returns with 60% health and acts normally

#### Scenario: Killing the ash
- **WHEN** the ash pile is killed before 6 seconds pass
- **THEN** the Phoenix is permanently dead

#### Scenario: No second rebirth
- **WHEN** a revived Phoenix is reduced to 0 health
- **THEN** it dies and does not become ash again

### Requirement: The Magma Golem telegraphs a Slam
The Magma Golem SHALL start with 15 block. Its Prepare action SHALL add 8 block and warn the player, and its next action SHALL be a Slam that deals heavy damage and applies Ashen to the player.

#### Scenario: Prepare then Slam
- **WHEN** the Golem prepares
- **THEN** it gains 8 block, a warning is shown, and its next action is the Slam
- **AND** after the Slam the player has Ashen

### Requirement: Act 3 has its own battle pool
Act 3 SHALL use its own battle pool with at least 3 tier 0, 4 tier 1, 2 tier 2 and 1 tier 3 (the Fire Dragon) battles, and SHALL show the Fire battle background. Tier 0 to 2 battles SHALL be made of Fire enemies only.

#### Scenario: Pool contents
- **WHEN** Act 3's pool is inspected
- **THEN** every tier has at least the required number of battles and each tier 0 to 2 battle contains only Fire enemies

#### Scenario: Boss floor
- **WHEN** Act 3's boss floor is reached
- **THEN** its tier 3 battle exists (the Fire Dragon, see `fire-dragon-boss`) and is never empty
