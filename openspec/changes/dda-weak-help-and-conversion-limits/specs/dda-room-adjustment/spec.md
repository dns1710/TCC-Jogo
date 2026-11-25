# Spec Delta

## ADDED Requirements

### Requirement: Weak runs face easier battles
When a tier-1 battle is about to start and the difficulty score is at or below the weak-run threshold, the battle SHALL be replaced by a tier-0 battle of the same act. A tier-2 upgrade and this downgrade SHALL NOT both apply.

#### Scenario: Weak run
- **WHEN** the score is 30 and the next battle is a tier-1 battle
- **THEN** a tier-0 battle is played instead

#### Scenario: Average run
- **WHEN** the score is 50 and the next battle is a tier-1 battle
- **THEN** the tier-1 battle is played

### Requirement: Weak runs heal more at campfires
When the player rests at a campfire and the difficulty score, after the arrival reading, is at or below the campfire-low threshold, the rest SHALL heal the configured extra share of maximum health on top of the normal heal.

#### Scenario: Weak rest
- **WHEN** a player with score 25 and 40 maximum health rests with a normal heal of 30% and an extra 15%
- **THEN** the player heals 18 health, not 12

#### Scenario: Average rest
- **WHEN** a player with score 50 rests
- **THEN** only the normal heal applies

### Requirement: Conversions into battles are limited per act
The difficulty system SHALL convert at most the configured number of rooms per act into battles, counting every kind of conversion to a battle, and SHALL reset the count at the start of each act and save it with the run.

#### Scenario: Limit reached
- **WHEN** two rooms were already converted into battles in the current act and a strong score would convert another
- **THEN** no further room is converted into a battle in that act

#### Scenario: New act
- **WHEN** a new act starts
- **THEN** the count is zero again

### Requirement: Hoarded gold earns a shop
After a battle, when the player holds at least the hoarded-gold amount, no shop is reachable ahead and the hoarded-gold swap is unused this act, the difficulty system SHALL convert one upcoming battle into a shop. The swap SHALL be marked used only when a room was converted, and SHALL reset each act.

#### Scenario: Rich player
- **WHEN** a battle is won with 250 gold and no reachable shop
- **THEN** one reachable battle becomes a shop and the swap is used for this act

#### Scenario: Shop already ahead
- **WHEN** a battle is won with 250 gold and a shop is reachable
- **THEN** no room is converted

### Requirement: One emergency campfire per run
After a battle, when the player is at or below the emergency health share and the emergency campfire has not been used in this run, the difficulty system SHALL convert one upcoming battle into a campfire. The swap SHALL be marked used only when a room was converted, and SHALL NOT reset between acts.

#### Scenario: Nearly dead
- **WHEN** a battle is won with 15% health and the emergency swap is unused
- **THEN** one reachable battle becomes a campfire and the swap is used for the rest of the run

#### Scenario: Used already
- **WHEN** a battle is won with 10% health after the emergency swap was used in an earlier act
- **THEN** it is not used again
