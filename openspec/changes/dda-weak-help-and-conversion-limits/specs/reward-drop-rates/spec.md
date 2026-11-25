# Spec Delta

## ADDED Requirements

### Requirement: Weak runs always get a relic
A regular battle SHALL always offer a relic while the difficulty score is at or below the configured weak-run score, whatever the drop roll, and the pity counter SHALL reset as for any drop.

#### Scenario: Weak run drop
- **WHEN** a regular battle ends with a score at or below the weak-run score and the drop roll fails
- **THEN** the reward screen offers gold and one relic

#### Scenario: Average run
- **WHEN** a regular battle ends with a score above the weak-run score and the drop roll fails
- **THEN** the normal drop and pity rules apply
