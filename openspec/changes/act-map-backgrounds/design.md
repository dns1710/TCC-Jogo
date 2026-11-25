# Design

## Context

`map.tscn` has a `MapBackground` `CanvasLayer` with a `Background` `TextureRect` whose texture is a 1D grey to brown gradient. `Map.set_act` already swaps `$MapBackground/Background.texture` when `act.background` is non-null. The battle artwork (`backgroundfloresta.jpg`, `bg_neve_ato2.png` 1748x900, `bg_fogo_ato3.png` 1748x899) already exists and is used for battles; `Battle.apply_background` scales it to 256x144. See proposal.md.

## Goals / Non-Goals

**Goals:**
- No brown gradient; an act-appropriate, readable background with minimal code.

**Non-Goals:**
- New art, parallax, animated backgrounds.

## Decisions

**1. Reuse the battle art, darkened.** Set `Act.background` on all three acts to their battle images. In `map.tscn`, make `Background` a `TextureRect` with `expand_mode` ignore size and `stretch_mode` keep-aspect-covered so it fills 256x144, with a dark `modulate` (for example 0.45) and a dim vignette `ColorRect` if the ice image is still too bright. Alternative: a new dedicated map image; rejected for now, it would wait on the art developer (it can replace `Act.background` later without code changes).

**2. Default is the forest.** The scene's default texture becomes `backgroundfloresta.jpg` with the same treatment, so an act with no background never shows a gradient. Delete the gradient subresource.

**3. Scaling in code only when needed.** `TextureRect` with covered stretch needs no script; `set_act` keeps assigning the texture. If the node's size is not the screen size at load, set `size = Vector2(256, 144)` in `set_act`.

**4. Readability.** Check rooms (map room icons) and `Line2D` lines against each background in screenshots; if the fire or ice image reduces contrast, increase the darkening for that act via a per-act `modulate` kept in the scene (not a new Act field) before adding fields.

## Risks / Trade-offs

- [Detailed background competes with map icons] → Dark modulate plus vignette; screenshot review per act.
- [Large images cost memory] → They are already loaded for battles; the map reuses the same imported resources.
- [Top bar and pause menu overlap] → Background is on its own lower `CanvasLayer`; unchanged layering.
