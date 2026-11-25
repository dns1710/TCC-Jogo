# Spec Delta

## Purpose

Controls how often battles, bosses and shops give the player relics, so builds form from fewer, more meaningful choices instead of a relic after every fight.

## ADDED Requirements

### Requirement: Regular battles drop relics by chance
A regular tier-1 battle SHALL offer a relic with the configured drop chance and SHALL always offer gold.

#### Scenario: Drop
- **WHEN** a tier-1 battle ends and the drop roll succeeds
- **THEN** the reward screen offers gold and one relic

#### Scenario: Miss
- **WHEN** a tier-1 battle ends and the drop roll fails
- **THEN** the reward screen offers gold only, increased by the configured miss bonus

### Requirement: Pity counter
The game SHALL count consecutive regular-battle misses within a run and SHALL guarantee a relic once the configured number of misses is reached; any drop SHALL reset the count.

#### Scenario: Guaranteed after misses
- **WHEN** the player has had the configured number of consecutive misses
- **THEN** the next regular battle offers a relic regardless of the roll

#### Scenario: Counter survives saving
- **WHEN** a run is saved and loaded between battles
- **THEN** the pity count is the same as before saving

### Requirement: Tier-2 battles always drop
A tier-2 battle SHALL always offer a relic using the tier-2 rarity weights.

#### Scenario: Tier-2 reward
- **WHEN** a tier-2 battle ends
- **THEN** the reward screen offers gold and one relic of uncommon or higher rarity

### Requirement: Boss relic choice
A boss battle SHALL offer several relics of different rarities and let the player take exactly one.

#### Scenario: Choose one
- **WHEN** a boss is defeated
- **THEN** the reward screen offers the configured number of relics including at least one rare or mythic, and taking one removes the others

### Requirement: First battle guarantee is unchanged
The first battle of a run SHALL still offer one weapon and one non-weapon common relic.

#### Scenario: First battle
- **WHEN** the first battle of a run ends
- **THEN** the reward offers a weapon (common or uncommon) and a common non-weapon relic regardless of the drop chance

### Requirement: Fewer, pricier shop relics
A shop SHALL offer the configured number of relics with prices multiplied by the configured factor.

#### Scenario: Shop stock
- **WHEN** a shop is generated with a count of 2 and a multiplier of 1.25
- **THEN** it offers 2 relics, each priced 1.25 times the base price it would have had before the change

### Requirement: Rates are data
Every number in these requirements SHALL be read from a reward configuration resource.

#### Scenario: Changing a rate
- **WHEN** the configured drop chance is edited without code changes
- **THEN** the next generated battle reward uses the new value
