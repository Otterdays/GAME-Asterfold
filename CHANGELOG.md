# Changelog

All notable Asterfold changes are recorded here. Entries describe demonstrated repository behavior; planned work remains in `docs/VERTICAL_SLICE.md`.

The project is currently pre-release, so completed work accumulates under `Unreleased` until a versioned build is cut.

## Unreleased

### Added

- Title adventurer roster: **Play** opens a three-slot select screen (one writable slot, two locked until party companions). Create takes a name plus the looks the layered kit can honour (hair style/colour, skin, shirt, jeans, boots), with a live preview that turns on `fold_left` / `fold_right` and can walk except under reduced camera motion. `CharacterRosterStore` writes `user://character_roster.json` (schema 1, temp-file-first, `.bak` recovery). This is title identity, not campaign `SaveService`.
- Denser Mara kit: `generate_mara_layers.ps1` now packs 12 columns by 5 rows per field sheet (4 idle + 8 walk), paints a brown tee / blue jeans / tan boots starter, and emits separate hair atlases (`mara_hair_field.png`, `mara_hair_doll.png`) for `hair.crop`, `hair.fringe`, and `hair.tousle`. The world actor stays one billboarded quad. `AppearanceCatalog` owns the closed v1 look IDs; names are 2–16 characters and may use letters, numbers, spaces, hyphens, and apostrophes (default `Wanderer`, then `Wanderer 2`).
- New `character_roster` test suite covers name rules, catalog channels, slot locks, roster backup recovery, sheet playback, and appearance composition.

- Title shell audio, scene-owned (not an `AudioDirector` autoload): a 24 s looping D-dorian Karplus-Strong lute-and-foley bed (`audio.music.title_fold_between`) plays on title and Settings, fades out when the diorama or metrics room starts, and returns with title. Hovering a shell `BaseButton` lifts and gold-tints it and plays a bell-pluck bling; pressing plays a wood click. Cues are original synthesis from `res://tools/generate_title_audio.gd`. Buses: Master / Music / SFX / UI / Ambience / Voice.

- Added a nature ambience system for Brindlewick, wired through `ZoneController` and gated on camera-motion accessibility:
  - `BirdSpeciesDefinition` (`content/wildlife/hearthfinch.tres`) plus `AmbientBirdFlock`: nine hearthfinches ride seeded circuits anchored on authored trees at 6-11 m, bank into their turns, and render as one MultiMesh with a per-bird flap phase in instance custom data.
  - `LeafFallEmitter`: every crown mass in the grove layout (132 points) becomes an emission point for a single `GPUParticles3D`, so town-wide leaf fall costs one draw. Leaves spin, thin out edge-on, and dissolve in the last metre above the ground.
  - `FootfallMotes`: dust over the dirt road, flicked blades over the grass, chosen from `DirtRoadLayout.signed_distance_m` because the painted road has no collider. Emitters run only while an injected actor is on the floor and above the stride-speed threshold.
  - Painted procedural shaders for all three (`ambient_bird`, `falling_leaf`, `footfall_mote`) with provenance recorded in `assets/asset_manifest.json`.
  - One baseline bird body for every species: `AmbientBirdFlock.build_bird_mesh(definition)` builds head, beak, tapered body, two-segment swept wings, and a forkable tail from the definition's ratios and tags each part in UV.x, so the shared shader recolours body, belly, head, beak, wing, wingtip, and tail per variant. `slate_swift.tres` is the first variant and adds no geometry code.
  - Map maker **Nature** family: `piece.bird_roost`, `piece.swift_roost`, and `piece.leaf_drift` place ambient life anywhere on the square. Standalone flocks circle their own node and standalone leaf drifts shed from a local ring, so no grove is required. Placed pieces join the `ambient_motion` group and `ZoneController` fans accessibility settings to them.

- Map maker authoring comfort and HUD polish:
  - Undo and redo for every world edit (place, lift, erase, turn, road move) through `MapMakerHistory`, a 64-deep whole-world snapshot stack. Ctrl+Z undoes, Ctrl+Shift+Z or Ctrl+Y redoes, and a new edit discards the stale redo branch. Undo marks the world unsaved because the file on disk no longer matches the scene.
  - Unsaved-work guard: Esc closes Settings first, then warns once before it quits.
  - `MapMakerGrid`: an authoring-only additive line overlay across the zone validation bounds, 0.5 m cells with brighter lines every 2 m and amber world axes, hidden until `G`.
  - `MapMakerToast`: bottom-center fading confirmation for saves, save failures, undo, redo, grid toggles, and the unsaved-quit warning.
  - `MapMakerTheme`: one code-built theme for the palette, Settings panel, tooltip, and toast, giving translucent dark panels, rounded buttons, a green fill on the selected piece, a red fill on Delete, and a visible keyboard focus ring. The hover overlay in the world turns red while Delete mode is on.
  - `Q`/`E` cycle families, `F1` hides the help line, and the status line now reports placed piece count, undo depth, and saved/unsaved state. Family switching no longer assumes a hard-coded road-patch count.
  - New `map_maker` test suite covers the history stack, its depth cap, redo-branch discard, grid mesh build and toggle, and the theme styles. Captures: `game/builds/captures/map_maker/`.

- Map maker placement QoL: click the held piece on its own footprint to unplace it, live ghost follows the cursor, amber overlay highlights any editable dress piece under the mouse, and a short right-click deletes. Palette labels size to their text so names are not clipped. Right-drag still pans after a 6 px threshold.

- Rebuilt Mara as a layered humanoid kit. `ActorLayerIds` declares 21 field body layers (head; torso, stomach, waist, pelvis; and per side shoulder, upper arm, forearm, hand, thigh, knee, calf, foot) and 31 paper-doll layers that add five fingers per hand. `game/tools/generate_mara_layers.ps1` emits a packed field atlas, a packed 96x128 doll atlas, the flattened fallback sheet, and provenance; the content validator fails if the generated layer order disagrees with the runtime contract.
- Added `SpriteLayerCompositor`, which flattens per-layer art plus equipment into one texture so the world actor stays a single billboarded quad. Field cards collapse finger layers into their hand; graybox equipment recolours covered layers and anchors accents inside their opaque bounds.
- Added equipment domain content: `ItemDefinition`, `ItemCatalog` (`content/items/item_catalog.tres`, one graybox item per slot), `EquipmentLoadout`, and `PartyInventory`, resolved through `ContentDB`. The closed v1 catalog is 16 slots: head, necklace, shoulders, back, torso, stomach, waist, legs, boots, gloves, four rings, main hand, and off hand. Gloves and boots are sets; the four rings equip independently; a two-handed main hand blocks the off hand instead of silently filling it.
- Added the field equipment screen (`scenes/ui/equipment_screen.tscn`) on the new remappable `equipment` action, default keyboard **I** and controller Select/Back. It shows a paper doll with focused-region highlighting, every slot with its occupant or **Empty** in text, and a per-slot item picker. Movement and mouse capture are released while it is open; `E` and `Q` remain World Turn right and left. Equipment appears in the title Controls list and persists through `user://settings.cfg`.
- The loadout is session-scoped and discarded on return to title. Campaign persistence waits for `SaveService`.

- Fixed leaving fullscreen: `DisplaySettings.apply_to_window` now switches to `MODE_WINDOWED` and clears `borderless` before resizing (Godot ignores size changes made while still fullscreen), sizes the window from the screen's usable rect, and shrinks a screen-filling resolution by the title-bar margin so windowed mode no longer looks like fullscreen.

- Window shortcuts in the app shell: `toggle_fullscreen` (F11 or Alt+Enter) switches between windowed and borderless fullscreen, persists to `user://settings.cfg`, and updates the Settings **Video** tab immediately. `quit_prompt` (F10) opens an in-canvas confirmation panel whose "YES, QUIT" button takes focus first, so Confirm (Enter / controller A) quits and Cancel, F10, or "NO, KEEP PLAYING" dismisses it. Shortcuts are ignored while the Settings screen is capturing a rebind.

- Map maker **Delete** mode: a family-row toggle (or the `Delete` key) turns left-click into erase. Selected palette buttons render bright green with black label text.

- Title Settings **Video** tab: windowed / borderless / exclusive fullscreen, output resolution (desktop native plus standard sizes that fit the screen), and independent UI scale (80/100/125/150%). Presentation quality scales 3D (`Viewport.scaling_3d_scale`); text scale remains an Accessibility font multiplier. F11 (`toggle_fullscreen`) toggles windowed and borderless.

- Added first-person look: field **Look around** (`scout`) opens a top-down live-zone map; a click or Confirm places a body-less eye camera with a center crosshair. Presentation only; Mara and the long-lens rig restore on Cancel/Leave.

- Added a reusable 3D tree system: `TreeDefinition` species resources (`content/trees/`), a validated `TreeGroveLayout` placement resource, painted trunk/crown shaders, `TreeBody3D` bodies with trunk-only collision, `TreeGrove3D` hero/MultiMesh composition, and per-tree crown fading for the camera.
- Dressed Brindlewick with 58 authored trees (6 hero specimens, 52 batched belt and orchard instances) validated against the dirt-road layout, the 0.5 m grid, ground bounds, and trunk spacing.

- Title menu **Open Map Maker** launches `res://tools/map_maker/map_maker.tscn` through the app shell. `GameFlow` still does not own the tool. `map_maker.bat` remains a direct launch.

- Field play captures the mouse on start and drives Peek from mouse look. Peek recenters to the authored view after 10 idle seconds. Keyboard Peek and right stick remain.
- Map maker Settings panel toggles cursor-follow and idle restore (default 10 seconds) and stores them in `user://asterfold_map_maker.cfg`.

- Added map-maker beginner families (Things / Buildings / Trees / Roads), live-zone loading, footprint occupancy, dirt-road center edits, and a separate tooltip catalog/overlay.
- Added Brindlewick landmark and tree components so the builder authors the same town the walking diorama loads, plus a weighted coverage score (100% connected, 81% writable).
- Added a static canvas-item woodland-clearing shader for the title shell (`assets/materials/ui/title_clearing.gdshader`).
- Map maker camera locks to the ground under the cursor at launch, then restores the authored default view after 10 seconds of idle follow or idle orbit/pan/zoom. Moving the cursor relocks; parked default does not keep retriggering.
- Added an internal Brindlewick map maker (`map_maker.bat`, `game/tools/map_maker/`) that writes zone placement data without appearing in the playable shell.
- Added three independently owned dress components (crate, lamp, planter), a shared piece catalog, and a `PlacementLayer` that instances Brindlewick's map-maker placements in the live zone.
- Vendored the `/caveman` skill at `.cursor/skills/caveman/SKILL.md` with Asterfold default intensity **ultra**, plus an always-on Cursor rule, so agents can follow Rule 1 without a marketplace plugin.
- Added a root README and agent status docs under `docs/` (`SUMMARY`, `SCRATCHPAD`, `SBOM`, `STYLE_GUIDE`, `ARCHITECTURE`, `My_Thoughts`, `docs/README`, `debugs/`).
- Established the local Godot 4.7.2 M0 foundation, validation/export gate, title and settings shell, runtime service boundaries, and Git/LFS baseline.
- Delivered the M1 Brindlewick walking diorama with Mara locomotion, eight-direction presentation, long-lens Peek camera, foreground fading, capture fixtures, and performance-soak tooling.
- Added independently owned grass and dirt-road surface scenes, materials, and procedural shaders for Brindlewick.

### Changed

- Title **Play** (node still `StartButton`) opens character select instead of launching Brindlewick immediately. Cancel walks create → select → title menu → quit. The menu plate hides while select/create are up so the clearing stays visible. Metrics still uses the starter look and skips the roster.
- Mara field sheets are 576×320 per layer (48×64 × 12×5) stacked to 576×6720 for 21 body layers. Hair styles are a second stacked atlas validated against `AppearanceCatalog`. `SpriteSheetPlayback` owns idle 3 fps columns 0–3 and walk 10 fps columns 4–11. The headless runner is 520 checks across 10 suites.

- Title world loads keep the clearing on screen until `GameFlow.load_zone` (or the metrics debug scene) finishes instantiating. A full-screen input sink disables every title action, swallows Cancel/Quit/F10, holds movement and mouse capture, and stays up until the first idle field frame so a second click cannot hit Quit or fall through into the town. **Open Map Maker** uses the same lock around `change_scene_to_file`. This is a cover, not a loading-screen feature; async zone loads remain the M4 plan.

- Moved the road signed-distance query onto `DirtRoadLayout.signed_distance_m` so trees and footfall motes classify ground against the same authored data. `TreeGroveLayout.distance_to_road_m` now delegates to it.
- `res://content/wildlife` joined the required content directories, and content validation covers every bird species, the baseline body build, the nature ambience scene, its layout wiring, and the rule that every catalogued piece family has a map-maker palette tab. The headless runner grew a `nature_ambience` suite (413 checks across 8 suites).
- The shared piece catalog grew from 11 to 14 pieces and the map maker palette from four families to five (Things, Buildings, Trees, Nature, Roads).

- Replaced `generate_mara_prototype.ps1` with `generate_mara_layers.ps1`. Mara's world sheet is now the flattened output of the layered kit and her body reads as anatomical segments rather than one silhouette block; asset provenance records both packed atlases.
- `ContentRegistry` now carries the item catalog, and `ContentDB` validates and resolves items alongside zones. `res://content/items` joined the required content directories.
- The field help panel lists the equipment key, and the headless runner grew an `equipment` suite (332 checks across 7 suites).

- Documented the Video display stack (window resolution vs UI scale vs 3D presentation quality), `user://settings.cfg` `video` key, F11 fullscreen toggle, and the 230-check runner.

- Map maker UI now fits the screen: the window opens at most 1600x900 clamped to the usable screen rect and centered, the palette sizes to its content, and the piece row scrolls horizontally instead of overflowing.
- Map maker starts with no piece selected, cursor-follow off by default, and the camera further out (68 m default distance, 120 m maximum). Right-click hold drags the view; erasing moved from right-click to Delete mode.

- Documented the discovered `TestCase` runner, six suite names, `--suite=` filter, and local vs hosted CI split in `docs/TESTING_AND_RELEASE.md`, plus `AGENTS.md`, Technical Architecture, Content Pipeline, Vertical Slice, Architecture index, and Style Guide.

- Title Settings now uses clickable **Video**, **Accessibility**, and **Controls** tabs; only the selected page is on screen. Bindings live under Controls. Opening the screen focuses the tab bar.

- Replaced Brindlewick's graybox cylinder-and-sphere trees, including the map-maker `piece.shade_tree` component, with painted multi-mass tree bodies driven by species definitions.

- Rebuilt the title clearing as a long-lens painted diorama (sky/sun, hills, grass ramps, dirt path, far treeline, multi-mass crowns, overhang) instead of lollipop disks.

- Made `/caveman ultra` the first agent contribution rule. Documentation and changelog maintenance is now Rule 2.
- Corrected handbook current-phase language: M0 and M1 are implemented locally; M2 World Turns is the next target.
- Documented `validate.bat` as the current Windows validation wrapper in `AGENTS.md` and `docs/TECHNICAL_ARCHITECTURE.md`.
- Upgraded Brindlewick grass from a flat color to broad world-scale painted variation with restrained tuft detail.
- Rebuilt Brindlewick's dirt road as a single rounded distance-field network driven by a validated layout resource, eliminating box-overlap seams and separating route data, rendering behavior, and material styling.
- Deepened the dirt-road treatment with organically varied edges, continuous softened junctions, compacted center wear, broken twin cart ruts, sharply defined directional scuffs, and two anti-aliased scales of embedded gravel.
- Replaced the zone-sized road plane with one tightly bounded batched patch mesh, preserving seamless distance-field joins while reducing road-shader coverage and restoring GPU headroom.
- Made documentation and changelog maintenance the first repository contribution rule. [AMENDED 2026-08-27]: that requirement remains; it is now Rule 2 after `/caveman ultra`.

### Fixed

- Adventurer display names accept digits so unique defaults such as `Wanderer 2` are valid. Underscores remain rejected.

- Grove invalid-layout fixture now places a known species off the authored ground so the off-surface validation check actually fires.

- Preserved required empty content directories so clean clones pass content validation.
