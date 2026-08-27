<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# My Thoughts

Decision rationale that is not (or not yet) an ADR. Newest notes at the top.

## 2026-08-27 — Title clearing at 360p

Screenshot looked like a low-res blur because it was: `window/stretch/mode=canvas_items` at 640×360, plus high-frequency value noise and `step()` trunks. Nearest upscale turns that into square clusters and banding. Fix is large soft ellipses and dither, not a higher-res texture.

## 2026-08-27 — Play mouse grab vs map-maker follow

The first camera pass landed on the map maker. User wanted play: captured mouse the moment the diorama starts, Peek from look, default vision after 10s idle. Cursor-follow stays a map-maker Settings option so placing tools are not stuck to a floating cursor unless enabled.

## 2026-08-27 — Live-zone builder coverage

“100% connectivity” means the builder instantiates `zone.brindlewick_square` the same way `GameFlow` does, then freezes Mara. Weighted surfaces (sum 100) score control separately. Current writable set is buildings, roads, props, and trees (81). Ranked leftovers: spawns 6, grass 5, camera volumes 3, bounds 3, presentation 2. Tooltips stay a second resource so palette labels can stay one or two words.

## 2026-08-27 — Title clearing

User asked for centered buttons and a woodsy open clearing with the name on it. Static canvas shader (no TIME) so reduced-motion stays honest. Wordmark sits in the bright sky; moss buttons stack in the sunlit grass.

## 2026-08-27 — Map maker camera follow then park

Playable `WorldCameraRig` already follows Mara. The request was the authoring camera: lock pivot to the ground under the cursor at start so placing is not fighting WASD. Ten-second idle restore keeps the default overview readable after the cursor stops or after a manual orbit. Relock only on cursor motion so parked default is actually visible.

## 2026-08-27 — Internal map maker writes placements, not landmarks

User asked for a separate builder that edits the live Brindlewick world without appearing in the game. A second Godot project would break `res://` links into the zone package. The map maker therefore lives under `game/tools/map_maker/` and launches with `map_maker.bat`. It never joins `GameFlow`, the title, or autoloads.

Saving packs a `ZonePlacementList` instead of rewriting `brindlewick_square_geometry.tscn`. Landmark meshes stay hand-authored. Dress pieces are three separate components so later props can follow the same catalog without a manager script. [AMENDED 2026-08-27]: landmarks and trees now live in the same placement list; geometry keeps grass, roads, and `PlacementLayer` only.

## 2026-08-27 — Title shell palette

Default Godot PanelContainer read as sandy cardboard on the 640×360 canvas. Title now follows expedition-notebook UI law without honey-sand: indigo ground, copper-teal rail/CTA, cool wordmark, left stack. Settings heading matched so the pair does not snap back to parchment gold.

## 2026-08-27 — `/caveman ultra` as Rule 1

User asked that agents always use `/caveman ultra` first. The skill was not in this workspace, so the repo now vendors `.cursor/skills/caveman/SKILL.md` and an always-on `.cursor/rules/caveman.mdc`. Chat compression is the point. Docs, code, and commits stay normal prose because the skill itself forbids caveman in persisted files.

Changelog/docs maintenance remains mandatory; it is Rule 2, not dropped.

## 2026-08-27 — Agent status docs beside product docs

User workflow wants `SUMMARY`, `SCRATCHPAD`, `SBOM`, `STYLE_GUIDE`, `ARCHITECTURE`, `My_Thoughts`, and `debugs/`. Asterfold already had product specs under `docs/`. New files are additive. `ARCHITECTURE.md` is an index, not a second runtime law. Folder stays `docs/` (not a renamed `DOCS/`).

## Existing product thoughts (recorded)

- World-never-rotates is the load-bearing spatial invariant; Peek is presentation-only.
- Brindlewick road became a distance-field network to kill box-overlap seams and keep GPU time inside the soak budget.
- No C#: keeps web demo and standard-editor contributors possible (ADR-0001).
