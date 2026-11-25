# Spec Delta

## Purpose

Defines the generic combat hooks that equipped items rely on, so any item slot, not only the weapon, can react to statuses, attacks, lethal damage and turn-bar timing.

## ADDED Requirements

### Requirement: Status added and removed are observable
The game SHALL announce when a status is added to or removed from any actor, naming the actor and the status, and SHALL provide a way to remove a status by id.

#### Scenario: Status added event
- **WHEN** Scorch is applied to the player
- **THEN** a status-added event naming the player and Scorch is emitted

#### Scenario: Remove by id
- **WHEN** a status is removed by its id from an actor that has it
- **THEN** it disappears from the actor and a status-removed event is emitted

#### Scenario: Remove missing status
- **WHEN** a status is removed by an id the actor does not have
- **THEN** nothing changes and no event is emitted

### Requirement: Negated statuses are not announced as added
A status negated by Ward SHALL NOT produce a status-added event.

#### Scenario: Ward absorbs
- **WHEN** Ward negates Freeze on the player
- **THEN** no status-added event for Freeze is emitted

### Requirement: Player attacks are observable by every equipped item
After the player's attack resolves, the game SHALL announce the attack with its targets and the damage dealt, and every equipped item SHALL be able to react, not only the weapon.

#### Scenario: Trinket reacts to an attack
- **WHEN** the player attacks an enemy with a trinket that reacts to attacks equipped
- **THEN** the trinket's reaction runs once for that attack

#### Scenario: Weapon behaviour unchanged
- **WHEN** the player attacks with an existing weapon such as Poison Dagger
- **THEN** it applies its status exactly as before

### Requirement: Player can be immune to Speed Down
The player SHALL support slow immunity, under which Speed Down is not applied, matching the behaviour enemies already have.

#### Scenario: Slow immune player
- **WHEN** a slow-immune player receives Speed Down
- **THEN** the turn bar rate is unchanged

### Requirement: Lethal damage to the player can be vetoed
An equipped item SHALL be able to cancel a lethal hit on the player before death is declared, restoring health itself. If no item cancels it the player SHALL die as before.

#### Scenario: Veto succeeds
- **WHEN** a lethal hit lands and an item vetoes it
- **THEN** the player stays alive at the health the item set and no death event is emitted

#### Scenario: No veto
- **WHEN** a lethal hit lands and no item vetoes it
- **THEN** the player dies and the loss flow runs

### Requirement: Next turn bar can start partly filled
An item SHALL be able to request that the player's next turn bar start at a given fraction of full. The request SHALL apply after the current action's bar reset and SHALL be used once.

#### Scenario: Carry-over applied
- **WHEN** an item requests a 25% start and the player's action completes
- **THEN** the turn bar restarts at 25%, not 0%

#### Scenario: Carry-over used once
- **WHEN** the carry-over has been applied and a further action completes
- **THEN** the bar restarts at 0%

#### Scenario: Requests do not stack past full
- **WHEN** requests add up to more than 100%
- **THEN** the bar restarts at 100% and the player can act immediately
