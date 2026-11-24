# Tasks

## 1. Report script

- [x] 1.1 Create `tools/report_item_balance.gd` and `.tscn` that scan `res://relics/` (skipping `1old`) and load every `Relic`; verify by running it headless and checking the relic count equals the number of non-`1old` relic `.tres` files.
- [x] 1.2 Compute stat total (negatives subtract), weapon dice string and average; verify with `tools/verify_item_balance_report.gd` on three known relics (a negative-speed armor, a 1d12 weapon, a no-weapon trinket).
- [x] 1.3 Add the budget constants block and the over-budget and data-warning flags; verify the report flags Heavier Armor and Glass Heart and warns on Barbarian Armor.
- [x] 1.4 Add statuses-mentioned (from `.gd` source vs `statuses/*.tres` ids) and the consumable marker; verify Phoenix Feather shows as consumable and Cinderbrand lists Scorch.
- [x] 1.5 Print the grouped markdown table and per-rarity summary with exit code 0; verify by running with the Godot console binary and confirming order and exit code while flagged relics exist.

## 2. Hand-off

- [x] 2.1 Run the report and save the output to `openspec/changes/item-balance-report/report-output.md` with notes on the confirmed budgets; verified the file exists.
- [x] 2.2 Make `tools/run_suite.ps1` use a working Godot path (`$env:GODOT` or the known 4.7.2 console binary) so `tools/run_suite.ps1 verify_item_balance_report` runs; verified it prints the OK line.
un_suite.ps1 verify_item_balance_report` runs; verified it prints the OK line.
