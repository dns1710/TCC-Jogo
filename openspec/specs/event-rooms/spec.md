# event-rooms Specification

## Purpose

Defines how event rooms choose which event the player sees, how an event plays out and reports its result, what events can change, and how often event rooms appear, so events stay varied, readable and easy to add.

## Requirements

### Requirement: Event is chosen on entering the room
An event room SHALL pick its event at the moment the player enters it, from the current act's event pool, using the run's seeded random source.

#### Scenario: Same seed, same events
- **WHEN** a run is saved before entering an event room and continued twice
- **THEN** both continues present the same event

### Requirement: No repeats within an act
Within one act, the player SHALL NOT be shown an event they have already seen in that act while unseen events remain in that act's pool.

#### Scenario: Unseen events remain
- **WHEN** the player enters a second event room in an act whose pool has 8 events and one was already seen
- **THEN** the event shown is one of the 7 unseen events

#### Scenario: Pool exhausted
- **WHEN** the player has seen every event in the act's pool and enters another event room
- **THEN** an event from the pool is shown (a repeat) and a warning is logged

### Requirement: Seen events reset each act and persist in saves
The list of seen events SHALL be saved with the run and SHALL reset when a new act begins.

#### Scenario: New act
- **WHEN** the player enters Act 2 after seeing 3 events in Act 1
- **THEN** the seen list is empty and Act 2's pool is used

#### Scenario: Continue
- **WHEN** a run with 2 seen events is saved and continued
- **THEN** those 2 events are still counted as seen

### Requirement: Each act has its own event pool of at least 6 events
Each act SHALL have its own event pool containing at least 6 distinct events.

#### Scenario: Pool sizes
- **WHEN** the three acts' event pools are inspected
- **THEN** each holds at least 6 events and every event has a title, text, and at least one choice with at least one outcome that has text

### Requirement: Events present choices with costs and outcomes
An event SHALL show its text and its choices as buttons. A choice SHALL be able to cost gold, health, rerolls, or all of the player's gold, and SHALL be disabled when the player cannot pay. A choice SHALL resolve to one of its outcomes by weight, or by a stat check against attack, block or speed.

#### Scenario: Cannot afford
- **WHEN** a choice costs 50 gold and the player has 30
- **THEN** that choice is disabled and the others stay available

#### Scenario: Weighted outcome
- **WHEN** a choice has two outcomes of equal weight and is picked many times
- **THEN** each outcome occurs about half the time

#### Scenario: Stat check
- **WHEN** a choice succeeds with chance 40% plus 8% per speed point and the player has speed 5
- **THEN** it succeeds 80% of the time

### Requirement: Every event shows an outcome screen
After the player picks a choice, the system SHALL show the outcome text, a line for each effect that happened (including costs), and a Continue button, and SHALL return to the map only when the player continues.

#### Scenario: Gamble result
- **WHEN** the player bets 50 gold and loses
- **THEN** the outcome screen shows the loss text and "-50 gold" and waits for Continue

#### Scenario: Leaving without effect
- **WHEN** the player picks a choice with no effects
- **THEN** the outcome screen still shows its text and a Continue button

### Requirement: Events can change the run
An outcome SHALL be able to change gold, current health, max health, max attack, max block, max speed, rerolls, the difficulty score, grant a random relic of a given rarity, and convert an upcoming room of one type into another. Health effects SHALL never reduce health below 1, and gold and rerolls SHALL never go below 0.

#### Scenario: Lethal damage
- **WHEN** an outcome deals 8 damage to a player with 5 health
- **THEN** the player is left with 1 health

#### Scenario: Relic reward
- **WHEN** an outcome grants a random uncommon relic
- **THEN** the player receives an uncommon relic they do not already own and the outcome screen names it

#### Scenario: Room conversion
- **WHEN** an outcome converts an upcoming monster room into a campfire
- **THEN** a reachable monster room becomes a campfire

### Requirement: Event room frequency
Randomly typed rooms SHALL be event rooms 18% of the time. Fixed rooms (start, boss, campfire floor, treasure floor) are unaffected.

#### Scenario: Frequency over many maps
- **WHEN** 1000 maps are generated
- **THEN** event rooms make up 18% (within 2 percentage points) of rooms that are randomly typed
