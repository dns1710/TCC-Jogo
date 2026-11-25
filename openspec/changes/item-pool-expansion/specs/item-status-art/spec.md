# Spec Delta

## Purpose

Defines the visual quality bar for item and status icons: size, format, palette, outline, readability, rarity language and a review gate, so the new content looks hand-made and consistent with the existing art.

## ADDED Requirements

### Requirement: Every new item has an original icon
Each of the 24 new items SHALL have its own hand-drawn 16x16 PNG icon with a transparent background. No item SHALL use a placeholder, a recolour of another item's icon, or a tile from the generic tileset.

#### Scenario: Complete coverage
- **WHEN** the art check lists the 24 new items
- **THEN** each references a unique 16x16 PNG under the items art folder

#### Scenario: No reuse
- **WHEN** icons are compared pixel by pixel
- **THEN** no new icon is identical to, or a pure palette swap of, another icon

### Requirement: Ward has an icon and placeholder statuses are replaced
Ward SHALL have a 10x10 icon, and the five statuses that currently use placeholder icons (Freeze, Brittle, Ashen, Scorch, Sunder) SHALL be given final 10x10 icons in the statuses art folder.

#### Scenario: No placeholders remain
- **WHEN** every status resource is loaded
- **THEN** none references a file under the placeholder art folder

#### Scenario: Status size
- **WHEN** a status icon is inspected
- **THEN** it is 10x10 with a transparent background

### Requirement: Art follows the written art direction
All new icons SHALL follow one art direction: a shared limited palette, a single top-left light source, a consistent outline rule, and readable silhouettes at native size. The direction SHALL be written down before drawing and kept in the change.

#### Scenario: Palette limit
- **WHEN** an icon is inspected
- **THEN** it uses only colours from the shared palette plus at most one accent

#### Scenario: Silhouette test
- **WHEN** an icon is filled with a single colour
- **THEN** its shape is still identifiable as the item

### Requirement: Rarity is legible from the icon
Icons SHALL signal rarity through detail rather than a coloured frame: commons use simple shapes, uncommons add a secondary material or accent, rares add a glow or contrasting highlight, and mythics add a unique motif that no lower rarity uses.

#### Scenario: Side by side
- **WHEN** a common and a mythic icon are shown at native size
- **THEN** a reviewer can tell which is the higher rarity without reading the tooltip

### Requirement: Status icons read at 10x10
Status icons SHALL be distinguishable from each other at native size by shape and by hue, including for players with red-green colour confusion, and SHALL match the style of the existing statuses.

#### Scenario: Debuff distinction
- **WHEN** Freeze, Brittle, Sunder, Scorch, Ashen and Ward are shown in one row
- **THEN** each is identifiable by shape alone

### Requirement: Art passes review before wiring
Each icon SHALL pass a review checklist (size, transparency, palette, light source, silhouette, rarity cue, in-game legibility on the battle and inventory backgrounds) before its item or status is registered, and the review result SHALL be recorded.

#### Scenario: In-game review
- **WHEN** an icon is placed in the inventory slot and the relic bar on each act background
- **THEN** it stays legible on all of them, or is revised before approval

### Requirement: Art assets are imported correctly
Icons SHALL be saved with nearest-neighbour filtering and no compression artefacts, with their import data committed alongside the PNG.

#### Scenario: Crisp rendering
- **WHEN** an icon is shown in game at the viewport scale
- **THEN** pixels are sharp, not blurred
