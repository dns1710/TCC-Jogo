# Spec Delta

## ADDED Requirements

### Requirement: Boss relic drop
A boss battle SHALL offer gold and exactly one relic that always drops, rolled with boss rarity weights that favor uncommon, rare and mythic over the regular weights.

#### Scenario: Boss drop
- **WHEN** a boss is defeated
- **THEN** the reward screen offers gold and exactly one relic, and the relic is never common

#### Scenario: Better than a regular drop
- **WHEN** many boss drops are rolled with the default weights
- **THEN** the share of rare and mythic relics is higher than for a tier-2 battle

## REMOVED Requirements

### Requirement: Boss relic choice
**Reason**: Playtesters disliked picking one of three relics after an act boss.
**Migration**: The boss gives a single default drop with better rarity weights; see "Boss relic drop".

### Requirement: Fewer, pricier shop relics
**Reason**: Playtesters found 2 relics too few and the flat price ignored rarity.
**Migration**: Shop size, rarity weights and prices are defined by the `shop-offers` capability.
