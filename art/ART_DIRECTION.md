# Art direction: items and statuses

Applies to the 24 items and 6 status icons added by `item-pool-expansion`. Sources are text pixel maps in
`art/src/*.pix`; `tools/build_icons.gd` renders them to PNG. A hand-drawn PNG may replace any of them if it
passes the same checklist.

## Format
- Items 16x16, statuses 10x10. RGBA PNG, transparent background, no anti-aliasing, no semi-transparent pixels.
- Nearest-neighbour filtering (project default). Import files are committed with the PNG.

## Palette
Extracted from the shipped icons with `tools/extract_palette.gd` (66 colours in use; the dominant outline is
`#3f2631`). The shared palette is `art/src/palette.txt` (37 colours). Ramps used (dark to light):

| Material | Ramp |
|---|---|
| Outline | `#3f2631` (main), `#45283c`, `#1c1c3a` |
| Steel | `#52607c` `#8b9bb4` `#c0cbdc` `#ffffff` |
| Ice | `#37429e` `#5b6ee1` `#639bff` `#8ca8e0` `#cbdbfc` |
| Wood / leather | `#3e2103` `#663931` `#8f563b` `#d9a066` |
| Cloth / blood | `#671717` `#ac3232` `#d95763` `#e55050` |
| Fire | `#913e16` `#df7126` `#ed9559` `#fbf236` |
| Gold | `#ffc800` `#fbf236` |
| Nature | `#37946e` `#6abe30` `#63e984` |
| Ash | `#4c4c4c` `#828282` `#8b9bb4` |

Status hues: Freeze ice cyan, Brittle pale blue with dark crack, Sunder steel with red split, Scorch tall
orange flame with ember pixels (Burn stays the round flame), Ashen grey flakes over a dull mound, Ward gold ring with
pale centre.

## Rules
1. **Light** comes from the top-left: highlight on the top/left edge, shadow bottom/right.
2. **Outline** is the dark plum on every silhouette edge; do not fill with a lighter outline.
3. **Shading** is three tones per material plus one highlight pixel. No dithering at 16x16.
4. **Silhouette first.** Weapons run on the diagonal (hilt bottom-left), helmets and armor face front, trinkets are centred.
5. **Rarity cue** is detail, not a frame:
   - common: two materials, clean shape;
   - uncommon: a secondary material or accent pixel (gold band, ice gem, red twine);
   - rare: glow, gem or contrasting rim light (glass, runes, a fracture);
   - mythic: sparkle pixels (`Y`/`w`) outside the silhouette, which no lower rarity uses.
6. **Statuses** are shape-coded as well as colour-coded: snowflake, shard, split shield, flame, mound, ring.

## Review checklist (pass/fail, each icon)
- [ ] Correct size and fully transparent background
- [ ] Only palette colours, no stray pixels
- [ ] Single top-left light source
- [ ] Silhouette identifiable when filled with one colour
- [ ] Rarity cue matches its rarity and is not shared with a lower tier
- [ ] Legible at native size on the dark plum, ice grey and fire brown backgrounds (`tools/icon_review.gd`)
- [ ] Not a recolour or copy of another icon
- [ ] Hand-made feel: no rigid mirror symmetry, at least one deliberate off-pixel detail

## Review log
Contact sheets are produced with `Godot --headless --path . --script res://tools/icon_review.gd -- sheet.png`.

| Round | Result |
|---|---|
| 1 | All 30 icons pass the checklist except three revisions: Cracked Visor read as a shield with an apple (redrawn with a wide slit and nose guard), Frostborn Circlet was too thin (rebuilt with a taller gem and spikes), Fur-Lined Cap fur looked like a checkerboard (irregular fur). Phoenix Feather vanes widened so it reads as a feather. |
| 2 | Status row (Freeze, Brittle, Sunder, Scorch, Ashen, Ward) next to Burn, Poison and Speed Down: all six identifiable by shape alone in greyscale. |

Open in-game check (task 8.4): play one run per act and note any icon that reads poorly on the relic bar.
