# Spec Delta

## Purpose

Defines the Krampus boss fight that closes Act 2, so the Ice act ends on a multi-phase encounter that tests slows, exposure and handling summoned allies.

## ADDED Requirements

### Requirement: Krampus is Act 2's boss
Act 2's tier 3 battle SHALL be Krampus alone, and Act 1's bosses SHALL no longer appear in Act 2. Krampus SHALL be immune to Freeze.

#### Scenario: Boss floor
- **WHEN** the player reaches Act 2's boss floor
- **THEN** the battle is against Krampus

#### Scenario: Freeze immunity
- **WHEN** Freeze is applied to Krampus
- **THEN** his turn bar is unaffected

### Requirement: Phase 1 attacks
While above 50% health Krampus SHALL use Birch Switch (two quick hits) and Chain Pull (applies 3 Speed Down stacks and Brittle to the player), chosen by weight.

#### Scenario: Chain Pull
- **WHEN** Krampus uses Chain Pull
- **THEN** the player gains 3 Speed Down stacks and Brittle

### Requirement: Phase 2 summons wolves
When Krampus first falls to 50% health or below, he SHALL begin summoning Snow Wolves, keeping at most 2 alive and summoning again no sooner than 3 of his actions after the last summon.

#### Scenario: Summon
- **WHEN** Krampus is at 50% health with no wolves alive
- **THEN** he summons 2 Snow Wolves

#### Scenario: Cap and cooldown
- **WHEN** 2 wolves are alive, or he summoned within his last 3 actions
- **THEN** he does not summon

### Requirement: Phase 3 Winter's Wrath
When Krampus first falls to 25% health or below, he SHALL gain 1 stack of Speed Up once and SHALL use a telegraphed Winter's Wrath as every third action: a preparation action followed by a heavy hit that also applies a short Freeze to the player.

#### Scenario: Telegraph
- **WHEN** it is time for Winter's Wrath
- **THEN** Krampus first shows a warning, and the heavy hit is his next action

#### Scenario: Wrath cadence
- **WHEN** Krampus is at 20% health
- **THEN** every third of his actions is Winter's Wrath and the other actions are his phase 1 and 2 attacks
