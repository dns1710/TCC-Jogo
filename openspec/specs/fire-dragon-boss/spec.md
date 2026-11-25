# fire-dragon-boss Specification

## Purpose

Defines the Fire Dragon boss fight that closes the game, so the final act ends on a multi-phase encounter built around burning, telegraphed attacks and summoned allies.

## Requirements

### Requirement: The Fire Dragon is Act 3's boss
Act 3's tier 3 battle SHALL be the Fire Dragon alone, and Act 1's bosses SHALL no longer appear in Act 3. The Dragon SHALL be immune to Freeze.

#### Scenario: Boss floor
- **WHEN** the player reaches Act 3's boss floor
- **THEN** the battle is against the Fire Dragon

#### Scenario: Freeze immunity
- **WHEN** Freeze is applied to the Dragon
- **THEN** its turn bar is unaffected

### Requirement: Phase 1 attacks
While above 60% health the Dragon SHALL use Claw and a telegraphed Fire Breath, chosen by weight. Fire Breath SHALL be preceded by a visible warning and SHALL deal heavy damage and apply 2 Scorch stacks to the player.

#### Scenario: Breath telegraph
- **WHEN** the Dragon prepares Fire Breath
- **THEN** a warning is shown and its next action is the Breath, which applies 2 Scorch stacks

### Requirement: Phase 2 summons imps and roars
When the Dragon first falls to 60% health or below, its next action SHALL be a Roar that gives every living enemy 1 Attack Up (once). It SHALL then summon Fire Imps, keeping at most 2 alive and summoning again no sooner than 4 of its actions after the last summon.

#### Scenario: Roar once
- **WHEN** the Dragon first crosses 60% health
- **THEN** it roars once, and never roars again

#### Scenario: Summon cap
- **WHEN** 2 imps are alive, or it summoned within its last 4 actions
- **THEN** it does not summon

### Requirement: Phase 3 Ember Field
When the Dragon first falls to 30% health or below, it SHALL gain 2 stacks of Speed Up once, and from then on each time it completes an action the player SHALL gain 1 Scorch stack.

#### Scenario: Ember Field
- **WHEN** the Dragon is at 25% health and completes an action
- **THEN** the player gains 1 Scorch stack

#### Scenario: Both thresholds in one hit
- **WHEN** a single hit takes the Dragon from above 60% to below 30%
- **THEN** it performs the Roar first and the phase 3 effects apply afterwards, each once
