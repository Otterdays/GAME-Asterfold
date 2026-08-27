<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# My Thoughts

Decision rationale that is not (or not yet) an ADR. Newest notes at the top.

## 2026-08-27 — Title roster is not SaveService

Campaign saves are still out of scope. The user wanted MapleStory-style creation using only looks the layered kit can honour, three slots, one writable. That is title identity: name, appearance IDs, a stable `character.<slug>`. It is not zone, inventory, quest, or facet state.

`CharacterRosterStore` copies the `SettingsStore` write pattern (validate, temp file, backup, replace) because ADR-0003's safety steps are good I/O, not a reason to invent `SaveService` early. Promoting this file into the campaign envelope would mix two lifetimes and imply progress that does not exist.

Slots 2 and 3 exist so the shell can show party size. They stay locked, focusable, and honest about why. Disabling them would trap keyboard focus.

## 2026-08-27 — Hair atlas, not a 22nd body layer

Hair styles need different silhouettes. Putting them on `layer.head` would fight REPLACE helmets and force a body-atlas regen for every hair. A stacked hair atlas keyed to `AppearanceCatalog` keeps body layers stable, skips hair when the head slot replaces, and still flattens to one world quad. Tints cover shirt/jeans/boots/skin without extra costumes.

Twelve columns (4 idle + 8 walk) match the art-direction party budget for this one hero. Widening the sheet to 576 px is the correct size, not a mismatch against the old 6-column 288 px kit.

## 2026-08-27 — Title audio stays off the AudioDirector autoload

User asked for a medieval foley menu bed plus hover/click. AudioDirection already lists Title / “The Fold Between” as a prototype cue. Scene ownership is enough: `TitleShellAudio` on `app.tscn`. Promoting `AudioDirector` would need an ADR and a mixer UI we do not have. Hover highlight is visual first so mute still works.

## 2026-08-27 — One bird body, many birds

The first bird was four triangles, which read as a speck at town-camera distance. Detailing it raised the real question: does a second species mean a second mesh function? No. `build_bird_mesh` now takes the definition and derives head, beak, body, two-segment swept wings, and a forkable tail from ratios, and tags each part in UV.x so the shader recolours body, belly, head, beak, wing, wingtip, and tail independently. A variant is a `.tres` plus a material. `slate_swift` exists purely to keep that promise honest, and the suite asserts both species share the vertex layout.

Ratios instead of meters because wingspan already sets scale; every other dimension should follow it, or a big bird gets a tiny head.

Flap stays a vertex lift, not a rig. Lift scales with the squared outboard fraction so the wingtip swings furthest and the wrist bends, which is the whole read at 30 m.

## 2026-08-27 — Ambient life reuses world data, and no third source of truth

Birds anchor on the tree grove placements. Leaves emit from the grove's crown masses. Footfall reads the dirt-road signed distance. Nothing here re-authors positions, so moving a tree moves the birds and moving a road moves the dust.

That last one needed a small refactor: the signed-distance query lived on `TreeGroveLayout`. It moved to `DirtRoadLayout.signed_distance_m`, because the painted road has no collider and now two systems ask it the same question. `is_on_floor()` cannot answer "dirt or grass" when the dirt is a shader.

Budget shape drove the composition: one MultiMesh for the whole flock, one `GPUParticles3D` fed by emission *points* for the whole grove's leaf fall. Per-tree emitters would have been simpler to write and 58 draws to pay for.

All of it stops outside Full camera motion, same as crown sway. The flock freezes rather than disappearing, because a town that loses its silhouettes when you enable reduced motion is a different town.

## 2026-08-27 — Placeable nature, not a second tool

"Make it customizable in the map maker" could have meant a bespoke nature editor. It did not need one. A flock with no grove circles its own node; a leaf emitter with no layout sheds from a local ring. That standalone mode is all it took to wrap both in ordinary world pieces and add a **Nature** palette tab.

The one new seam is reaching those pieces: a builder can drop them anywhere, so they join an `ambient_motion` group and `ZoneController` fans accessibility to the group. Group calls are a smell in gameplay code; for a presentation fan-out to unknown dress nodes they are the honest tool. The validator now also fails any catalogued family with no palette tab, so a piece can never become unreachable in the tool.

Footfall is deliberately not placeable. It rides the actor. Making it a piece would imply the dust belongs to a cell rather than to a stride.

## 2026-08-27 — Title hitch cover, not a loading screen

M1 has one real wait: title to Brindlewick instantiate. Hiding the menu first showed an empty viewport. Keeping the clearing up is enough cover. A dedicated loading-screen scene would over-promise and fight the later `TransitionLayer` plan. The input sink is the actual requirement: Godot click-through after a blocking load is worse than a freeze. Unlock only after a process frame and after Confirm/Cancel/pointer are released.

## 2026-08-27 — Map maker click again means put it down

Palette toggles were reconnecting `pressed` so the selected piece never deselected. World click on the same piece now unplaces instead of replacing with a duplicate. Right-click delete is a short click; drag past 6 px still pans so both requests coexist. Ghost and amber hover are presentation-only overlays on catalog instances.

## 2026-08-27 — First-person look is a scout, not a new camera law

Player asked for FPS viewing from a map pick. ADR-0002 still owns the diorama camera. The scout eye is a second Camera3D, 70° FOV, no body, center crosshair. It does not change Mara's transform, facet, or movement basis. Opening through a top-down live-zone map keeps “available world” literal.

## 2026-08-27 — Title clearing pull-back and High default

The 1080p SubViewport still looked zoomed because crowns filled UV space, then the 640×360 shell crushed the result. Composition is now a distant meadow. Default presentation is High 1920×1080. Low 640×360 stays a quality option, not the exclusive canvas. Docs must allow High.

## 2026-08-27 — Trees as repeatable bodies, not cards

User wanted handheld-RPG tree density but explicitly not another game's tree design, and wanted the result reusable by the map builder. So density is the borrowed idea; the look is ours. Crowns are two to four overlapping asymmetric masses because one sphere on a cylinder reads as a lollipop from every Peek angle, and the diorama sells volume during parallax.

Data split mirrors the dirt road: `TreeDefinition` for species metrics, `TreeGroveLayout` for placement, `TreeBody3D` for one body, `TreeGrove3D` for composition. That keeps the map-builder API as "one definition plus one placement row" without a bespoke tool.

Hero versus batched is a budget decision, not an art one. Six hero bodies get collision-per-node and crown fading; the 52 belt trees collapse to seven MultiMesh draws with one shared trunk-collision body, so a dense perimeter costs draw calls in the single digits instead of a hundred.

Crowns are opaque with `depth_prepass_alpha` so the one fade case works without a second material family. Per-instance variation comes from the world position hash in the shader rather than instance custom data, so the same material serves hero nodes and MultiMesh rows. Sway reads the camera-motion setting and goes to zero outside Full, because a swaying canopy is exactly the ambient motion reduced-motion players are avoiding.

Only trunks collide. Walk-under clearance is validated against the 2.25 m door metric so a crown never becomes an invisible wall, and grove validation refuses to plant on the road shoulder so the authored 2 m street stays walkable.

## 2026-08-27 — Discovered TestCase suites

One mega `run_tests.gd` hid leaks and a dead grove-ground assert. Runner now only discovers and instruments; assertions live in `game/tests/suites/`. No GUT addon: keep the gate as `godot --script res://tests/run_tests.gd`.

## 2026-08-27 — Title clearing at 1080p

The 360p ellipse plate hurt. Title now paints in a 1920×1080 SubViewport with 2D MSAA and linear-filters onto the shell. Menu stays 640×360. Shader is still static (no TIME).

## 2026-08-27 — Title launches map maker

User asked for a main-menu button. Tool stays a separate scene (`change_scene_to_file`), not a `GameFlow` state. Escape still quits the tool, same as `map_maker.bat`.

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

User asked for a separate builder that edits the live Brindlewick world without appearing in the game. A second Godot project would break `res://` links into the zone package. The map maker therefore lives under `game/tools/map_maker/` and launches with `map_maker.bat`. It never joins `GameFlow`, the title, or autoloads. [AMENDED 2026-08-27]: title now offers **Open Map Maker**; `GameFlow` still does not own it. ContentDB autoload is already used by the tool.

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
