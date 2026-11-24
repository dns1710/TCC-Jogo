# Tasks

## 1. Simulator

- [x] 1.1 Create `tools/simulate_balance.gd` and `.tscn`: seeded turn loop using `Dice`, player stats and relic bonuses, enemy resources and act scaling; verify two runs with the same seed print identical output.
- [x] 1.2 Add loadout selection, act selection and a two-loadout comparison output; verify a baseline run prints turns to win, HP lost and win rate and a comparison prints the difference.
- [x] 1.3 Confirm the targets in design.md with the owner and print an advisory note when a loadout is outside them; verify the script exits 0 when out of target.

## 2. Data fixes and budget

- [x] 2.1 Fix data the report flags (Barbarian Armor weapon fields, relics with no explicit rarity); verify the report shows no data warnings.
- [x] 2.2 Add the exceptions list (constant in the report plus a table in design.md); verify an exception relic is not flagged and shows its reason.

## 3. Tuning

- [x] 3.1 Tune Glass Heart (+4/+2 to +3/+2) and review Cracked Visor (left as is: inside budget, a Glass Heart combination piece), update tooltips; verify the item pool suites pass and the ranking shows Glass Heart below the top rare.
- [x] 3.2 Fix the trap items the ranking found (Heavier Armor, Heavy Plate, Heavy Helmet) and review Great Axe (left as is: at the rare cap, mid-ranked); verify the report and suites.
- [x] 3.3 Recheck Frostfire Pike and Phoenix Feather with the simulator; their effects cannot be simulated, so they are left unchanged and flagged for playtest in design.md.
- [x] 3.4 Run the simulator on presets and random builds per act; act 1 lands inside its target and the act 2 and 3 gap is recorded in design.md for the owner.

## 4. Integration

- [x] 4.1 Run the full `tools/run_suite.ps1` with the Godot console binary and the balance report; verify the suite passes and the report has no unlisted over-budget relics.
