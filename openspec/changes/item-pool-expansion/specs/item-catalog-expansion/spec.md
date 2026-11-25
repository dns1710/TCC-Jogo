# Spec Delta

## Purpose

Defines the 24 items added to the drop pools, their slot, rarity, stats and behaviour, and how they enter rewards, chests and shops, so the pool covers the combat statuses and every rarity has enough variety.

## ADDED Requirements

### Requirement: New items exist with fixed slot and rarity
The game SHALL provide 24 new items with unique ids: 2 common, 7 uncommon, 8 rare and 7 mythic, split across 7 weapons, 4 helmets, 4 armor and 9 trinkets, matching the catalog table in design.md. No existing item SHALL change.

#### Scenario: Counts by rarity
- **WHEN** all item resources are loaded
- **THEN** the pool holds 14 common, 21 uncommon, 19 rare and 9 mythic items

#### Scenario: Unique ids
- **WHEN** all item resources are loaded
- **THEN** no two items share an id and none is flagged as a starter item

### Requirement: New items enter every drop pool
Every new item SHALL appear in the battle reward, treasure and shop pools and follow the existing rarity rules: commons are not offered by chests or tier-2 rewards, mythics only by tier-2 rewards, chests and shops.

#### Scenario: In a pool
- **WHEN** the item pool check runs
- **THEN** each new item is found in at least the reward and shop pools, and in the treasure pool unless common

#### Scenario: Chest skips commons
- **WHEN** a chest is opened with the new commons in its pool
- **THEN** it never offers a common item

### Requirement: Stat budget follows rarity
New items SHALL carry stat bonuses within their rarity budget: about 1 point for common, 2 for uncommon, 3 for rare, and a build-defining effect for mythic, with penalties counted against the budget.

#### Scenario: Budget check
- **WHEN** an item's stat bonuses are summed
- **THEN** the net value is within the budget of its rarity, or the design table records the exception

### Requirement: Scorch and Sunder weapons
Breaker Pick (weapon, uncommon, 1d6) SHALL apply Sunder to a target that still has block after the hit. Cinderbrand (weapon, rare, 1d6, +1 attack) SHALL add 1 Scorch per hit and, when the target has 3 or more Scorch stacks, detonate them for 1d4 damage per stack and clear the status.

#### Scenario: Breaker Pick on blocked target
- **WHEN** the player hits a target that still has block after the hit
- **THEN** the target gains Sunder and the next hit ignores its block

#### Scenario: Breaker Pick on unblocked target
- **WHEN** the player hits a target with no block left
- **THEN** no Sunder is applied

#### Scenario: Cinderbrand detonation
- **WHEN** the player hits a target that holds 3 Scorch stacks
- **THEN** the target takes 3d4 extra damage and loses Scorch

### Requirement: Freeze and Brittle weapon
Shatterglass Hammer (weapon, mythic, 1d8, -1 speed) SHALL Freeze the target on every fourth attack. Hitting a Frozen target SHALL deal an extra 1d8, apply Brittle and end the Freeze. Against targets that cannot be frozen, the fourth attack SHALL apply Brittle instead.

#### Scenario: Fourth attack freezes
- **WHEN** the player makes a fourth attack on a freezable enemy
- **THEN** the enemy is Frozen

#### Scenario: Shatter
- **WHEN** the player hits a Frozen enemy
- **THEN** it takes an extra 1d8, gains Brittle and is no longer Frozen

#### Scenario: One shatter per freeze
- **WHEN** the player hits the same enemy again right after a shatter
- **THEN** no extra damage is dealt and the enemy cannot be frozen during its immunity window

#### Scenario: Boss fallback
- **WHEN** the fourth attack lands on a freeze-immune boss
- **THEN** the boss gains Brittle and is not Frozen

### Requirement: Block-based weapons
Riposte Foil (weapon, uncommon, 1d4, +1 speed) SHALL add 1d6 to the first attack after the player Blocks. Bulwark Maul (weapon, rare, 1d6) SHALL add 1d4 damage for every 5 of the player's current block, up to 3d4, without spending that block.

#### Scenario: Riposte
- **WHEN** the player Blocks and then attacks
- **THEN** that attack deals an extra 1d6, and the next attack does not unless the player Blocks again

#### Scenario: Maul scales with block
- **WHEN** the player has 12 block and attacks with Bulwark Maul
- **THEN** the attack deals 2d4 bonus damage and the player still has 12 block

#### Scenario: Maul below one die
- **WHEN** the player has 4 block and attacks with Bulwark Maul
- **THEN** there is no bonus damage

#### Scenario: Maul cap
- **WHEN** the player has 40 block and attacks with Bulwark Maul
- **THEN** the bonus is 3d4

### Requirement: Mythic weapons
Hunter's Mercy (weapon, mythic, 1d8) SHALL execute non-boss enemies under 30% health on hit, deal an extra die of the weapon (1d8) to bosses under 30% health instead, and after a kill start the next turn bar at 50%. Frostfire Pike (weapon, mythic, 1d8) SHALL alternate hits between 1 Scorch and 1 Speed Down. The hit that leaves a target holding both SHALL give it Brittle and Sunder, once, until Scorch or Speed Down has worn off.

#### Scenario: Execute
- **WHEN** the player hits a non-boss enemy under 30% health
- **THEN** the enemy dies and the next turn bar starts at 50%

#### Scenario: Boss not executed
- **WHEN** the player hits a boss under 30% health
- **THEN** the boss takes an extra 1d8 and is not killed outright

#### Scenario: Pike alternation
- **WHEN** the player makes two consecutive hits with Frostfire Pike
- **THEN** the first applies 1 Scorch and the second applies 1 Speed Down

#### Scenario: Thermal shock
- **WHEN** a Pike hit leaves a target holding both Scorch and Speed Down
- **THEN** it gains Brittle and Sunder

#### Scenario: Shock fires once
- **WHEN** a target keeps both statuses and is hit again
- **THEN** no new Brittle or Sunder is applied

#### Scenario: Shock re-arms
- **WHEN** one of the two statuses wears off and a later hit leaves the target holding both again
- **THEN** it gains Brittle and Sunder again

### Requirement: Helmets
Fur-Lined Cap (common, +1 block) SHALL make the player immune to Speed Down. Frostborn Circlet (uncommon, +1 block) SHALL grant 1 Attack Up when Freeze ends on the player. Cracked Visor (rare, +1 attack) SHALL add 1d8 damage to attacks while the player is Brittle. Warden's Visage (mythic, +1 speed) SHALL add 1 stack to every stacking status the player inflicts on an enemy.

#### Scenario: Cap blocks slow
- **WHEN** a player wearing Fur-Lined Cap receives Speed Down
- **THEN** no slow is applied

#### Scenario: Thaw bonus
- **WHEN** Freeze ends on a player wearing Frostborn Circlet
- **THEN** the player gains 1 Attack Up

#### Scenario: Visor while Brittle
- **WHEN** a Brittle player wearing Cracked Visor attacks
- **THEN** the attack deals an extra 1d8

#### Scenario: Visage amplifies
- **WHEN** the player applies 2 Scorch to an enemy while wearing Warden's Visage
- **THEN** the enemy gains 3 Scorch

### Requirement: Scorch and Ward armor
Emberweave Tunic (uncommon, +1 block) SHALL grant 1d4 block per stack when the player gains Scorch. Sentinel's Aegis (rare, +2 block) SHALL give Ward at combat start and again after every third Block.

#### Scenario: Tunic converts Scorch
- **WHEN** the player gains 2 Scorch while wearing Emberweave Tunic
- **THEN** the player gains 2d4 block

#### Scenario: Aegis regains Ward
- **WHEN** a player wearing Sentinel's Aegis Blocks for the third time
- **THEN** the player gains Ward if they do not have one

### Requirement: Counter armor
Reactive Plate (rare, +3 block, -1 speed) SHALL, when a hit fully breaks the player's block, deal 2d4 damage to the attacker and apply Brittle to it. Mirrorscale Mail (mythic, +2 block) SHALL give Ward at combat start, apply any status Ward absorbs to every enemy, and regain Ward after 2 player actions.

#### Scenario: Block break counter
- **WHEN** a hit equal to or greater than the player's block, with block above 0, lands
- **THEN** the attacker takes 2d4 and gains Brittle

#### Scenario: Mirrored debuff
- **WHEN** Ward absorbs Freeze on a player wearing Mirrorscale Mail
- **THEN** Freeze is applied to every enemy that can be frozen

### Requirement: Basic trinkets
Kindling Bundle (common) SHALL apply 1 Scorch to a random enemy when the player Blocks. Pine-Tar Gloves (uncommon, +1 attack) SHALL add 1d4 damage to attacks on targets that already carried a debuff before the hit; a debuff applied by the hit itself does not count.


#### Scenario: Bundle ignites
- **WHEN** the player Blocks with Kindling Bundle and an enemy is alive
- **THEN** one random enemy gains 1 Scorch

#### Scenario: Gloves vs an already afflicted target
- **WHEN** the player hits an enemy that already has a debuff while wearing Pine-Tar Gloves
- **THEN** the hit deals an extra 1d4

#### Scenario: Gloves vs a debuff the hit applies
- **WHEN** the player's hit is what applies the first debuff to the enemy
- **THEN** no extra damage is dealt

#### Scenario: Snare opening
- **WHEN** a combat starts with Hunter's Snare equipped
- **THEN** each enemy has 1 Speed Down stack

#### Scenario: Rime Bead combo
- **WHEN** the player hits an enemy that has Speed Down
- **THEN** the enemy gains Brittle

### Requirement: Control trinkets
Warding Talisman (uncommon, no stat bonus) SHALL give Ward at combat start. Rime Bead (uncommon, +1 speed) SHALL apply Brittle when the player hits a Speed Down target. Hunter's Snare (rare, no stat bonus) SHALL give every enemy 1 Speed Down at combat start.

#### Scenario: Ward opening
- **WHEN** a combat starts with Warding Talisman equipped
- **THEN** the player has Ward

### Requirement: Rare trinkets
Carrion Thurible (rare) SHALL, when an enemy dies, copy its Poison, Burn and Scorch to one random other enemy without healing the player. Quicksilver Spurs (rare, +1 speed) SHALL make the next turn bar start at 25% after a hit on a Slowed or Frozen enemy.

#### Scenario: Thurible spread
- **WHEN** a Poisoned enemy dies with another enemy alive
- **THEN** the survivor gains the same Poison and the player is not healed

#### Scenario: Thurible picks one
- **WHEN** an afflicted enemy dies with three enemies alive
- **THEN** exactly one of them receives the statuses

#### Scenario: Spurs tempo
- **WHEN** the player hits a Slowed enemy wearing Quicksilver Spurs
- **THEN** the next turn bar starts at 25%

### Requirement: Mythic trinkets
Phoenix Feather (mythic) SHALL prevent one lethal hit, set health to 30% of maximum, apply 1 Scorch to every enemy, then fizzle out and be removed from the inventory while staying in the drop pools. Glass Heart (mythic, +4 attack, +2 speed) SHALL re-apply Brittle to the player 3 actions after it is consumed.

#### Scenario: Feather once
- **WHEN** a lethal hit lands twice with Phoenix Feather equipped
- **THEN** the first is prevented and the second kills the player

#### Scenario: Feather is used up
- **WHEN** Phoenix Feather prevents a lethal hit
- **THEN** it is no longer equipped or in the inventory, and it can be offered by drops again

#### Scenario: Glass Heart loop
- **WHEN** the player's Brittle is consumed by a hit and 3 actions pass
- **THEN** Brittle is applied to the player again

### Requirement: Tooltips state the real behaviour
Every new item SHALL have a tooltip that lists its stat bonuses and states its effect with the same numbers the code uses, in the project's capitalised stat style.

#### Scenario: Tooltip matches stats
- **WHEN** an item's tooltip is read
- **THEN** every stat and number in it matches the item resource and behaviour
