# Spec Delta

## MODIFIED Requirements

### Requirement: Shop "bought everything" matches the shop size
The "bought everything the shop offered" check SHALL compare the relics gained in the shop against the number of relics that shop actually offered.

#### Scenario: Two-relic shop
- **WHEN** a shop offers 2 relics and the player buys both
- **THEN** the shop-swap check treats it as having bought everything on offer

#### Scenario: Five-relic shop
- **WHEN** a shop offers 5 relics and the player buys 3
- **THEN** the shop-swap check does not treat it as having bought everything

#### Scenario: Three-relic shop
- **WHEN** a shop offers 3 relics and the player buys all 3
- **THEN** the shop-swap check treats it as having bought everything on offer
