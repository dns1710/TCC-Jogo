# Spec Delta

## Purpose

Defines how enemies add allies during a battle, how those allies end when their summoner falls, and the reusable action patterns enemies are built from, so summoning enemies and bosses behave consistently.

## ADDED Requirements

### Requirement: Enemies can be spawned mid-battle
An enemy action SHALL be able to spawn another enemy into a free battle slot. The spawned enemy SHALL appear with a short animation and begin with an empty turn bar. There SHALL be at most 5 enemies alive at once; spawning with no free slot SHALL do nothing.

#### Scenario: Spawn into a free slot
- **WHEN** a summoner with 2 enemies in the battle spawns a minion
- **THEN** a third enemy appears in an unoccupied slot and starts acting after its own bar fills

#### Scenario: Battle is full
- **WHEN** 5 enemies are alive and another spawn is attempted
- **THEN** no enemy is added

### Requirement: Minions fizzle when their summoner dies
Each spawned enemy SHALL remember its summoner. When the summoner dies, every living minion SHALL die after completing its next action, or after 6 seconds if it has not acted by then, showing a fizzle message.

#### Scenario: Summoner killed
- **WHEN** the player kills a summoner while two of its minions are alive
- **THEN** each minion acts once more (or 6 seconds pass) and then dies

#### Scenario: Minion killed first
- **WHEN** a minion dies while its summoner is alive
- **THEN** the summoner is unaffected and may summon again

### Requirement: Battle ends when no enemy remains
A battle SHALL end in victory when every enemy, minions included, is dead.

#### Scenario: Only minions left
- **WHEN** the summoner is dead and its minions have fizzled
- **THEN** the battle ends in victory

### Requirement: Heal-allies action
A heal-allies action SHALL restore a set amount of health to every living ally of the actor (not itself), never above their maximum.

#### Scenario: Healing
- **WHEN** a healer with allies at 3 of 8 and 8 of 8 health heals 6
- **THEN** the first ally is at 8 of 8 and the second is unchanged

### Requirement: Telegraphed attacks
A telegraphed attack SHALL show a warning when prepared and SHALL be the actor's next action, so the player has one full turn-bar interval to react.

#### Scenario: Prepare then strike
- **WHEN** an enemy performs its prepare action
- **THEN** its warning is visible and its following action is the heavy hit

### Requirement: One-time threshold action
A threshold action SHALL become available when the actor's health first drops to a set share of its maximum, SHALL be performed once, and SHALL take priority over its ordinary actions.

#### Scenario: Threshold crossed
- **WHEN** an enemy drops to 50% health
- **THEN** its threshold action is its next action, and never used again
