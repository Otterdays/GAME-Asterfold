# Content Pipeline

## Goals

Content must be fast to author, safe to rename, mechanically validated, localization-ready, and reproducible from source. The playable game consumes imported/runtime artifacts; creators retain editable source files and documented export settings.

## Identity

Every persistent or cross-referenced definition has a stable lowercase namespaced ID:

```text
actor.mara
character.wanderer
calling.wayfinder
ability.wayfinder.thread_needle
item.consumable.sunmint_draught
quest.brindlewick.missing_chime
zone.brindlewick_square
spawn.brindlewick_square.south_gate
dialogue.brindlewick.ori_first_meeting
flag.brindlewick.bell_repaired
```

Rules:

- IDs match `^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$`.
- IDs are not display text and are never localized.
- Moving a file does not change its ID.
- Renaming an ID is a save and reference migration, not a text edit.
- No two definitions share an ID across content types.
- Validators reject unresolved references, duplicates, accidental uppercase, and undeclared flags.

## Source and runtime layout

The standalone game is rooted at `game/`:

```text
game/
  art_source/
    characters/          .aseprite or layered originals
    environments/        .blend and source textures
    ui/                  editable vector/raster sources
  assets/
    generated/           repeatable sprite/mesh exports
    audio/               normalized runtime sources
    materials/           shaders, palettes, materials
    ui/                  runtime fonts and textures
  content/               validated definition resources
  scenes/                composed runtime scenes
  tools/                 exporters, validators, and the internal map maker
```

Generated files carry a header or adjacent manifest identifying source file, exporter version, and relevant settings. Never hand-edit a generated artifact.

Binary source files belong in Git LFS after version control is configured. Godot `.tscn`, `.tres`, scripts, JSON, Markdown, and small metadata remain text for useful diffs.

## Definition schema conventions

Definition Resources contain:

- `id: StringName`
- localization keys for player-visible name and description
- typed cross-reference IDs
- explicit tags from a validated registry
- balance values with units or semantic names
- optional developer note that never appears in game

Definitions do not contain mutable unlock state, current HP, quest progress, scene instances, node paths into another scene, or localized prose copied directly into gameplay fields.

The content database indexes definitions during boot/import validation. Production startup fails to title with a clear error if required content is invalid; development startup reports all discoverable errors in one pass.

## Zone authoring

### Package contract

Each zone folder contains:

```text
zone_id/
  zone_id.tscn                 composed entry scene
  zone_id_manifest.tres        identity, facets, spawns, neighbors
  zone_id_geometry.tscn        imported and modular visible geometry
  zone_id_gameplay.tscn        collision, navigation, entities, anchors
  zone_id_presentation.tscn    light, camera volumes, ambience, VFX
  zone_id_placements.tres      map-maker dress pieces on the 0.5 m grid
  encounters/                  local encounter compositions
  dialogue/                    local conversation resources/scripts
```

Large zones may split layers further, but the manifest remains the single entry point.

### Environment workflow

1. Graybox on the 0.5 m logical grid with final player collision metrics.
2. Establish every committed facet and Peek range with camera volumes.
3. Prove landmark, loop, exits, and World Turn result using flat materials.
4. Export modular/hero geometry from Blender as glTF/GLB using metric units, applied transforms, Y-up conversion verified in engine, and named collision markers only where the importer understands them.
5. Author simplified collision in Godot or as dedicated low-poly source meshes; never use detailed render meshes by default.
6. Add navigation regions and named links for each facet state.
7. Dress using shared material families, then light and add foreground occlusion groups.
8. Run zone validation and capture all facets at reference resolution.

Do not art-lock a space before navigation, occlusion, fold-safe positions, and backtracking are playable.

### Internal map maker

The map maker is an authoring tool, not a `GameFlow` state. Launch it from title **Open Map Maker** or `map_maker.bat`. Both open `game/tools/map_maker/map_maker.tscn` against the Godot project. [AMENDED 2026-08-27]: title now launches the scene; earlier isolation from the shell is superseded. The tool instantiates the same Brindlewick zone scene the walking diorama loads, freezes Mara and the playable camera, and writes `*_placements.tres` plus the dirt-road layout. Grass, spawns, camera volumes, bounds, and presentation stay visible so the builder is connected to the live world even when those layers are not yet writable.

Beginner chrome uses five families: Things, Buildings, Trees, Nature, Roads. Status reports a weighted connectivity/control score. Hover tooltips live in a separate catalog (`game/tools/map_maker/map_maker_tooltip_catalog.tres`) and overlay, not Godot `tooltip_text`.

Dress, landmarks, and trees are reusable world components:

```text
game/content/pieces/piece_catalog.tres
game/scenes/world/pieces/
game/scenes/world/placement_layer.tscn
game/src/world/pieces/
game/tools/map_maker/
```

`PlacementLayer` instances catalog scenes from the zone placement list, including footprint occupancy for buildings. Saving from the map maker does not rewrite grass meshes, gameplay collision walls, or the composed zone entry scene. Road strip centers save through `DirtRoadLayout.set_patch_center`.

Weighted leftover work (highest first): spawn markers, grass ground, camera volumes, walk bounds, lights/occluders. Those surfaces are already visible in the builder.

Place on the 0.5 m grid. Left click places the selected piece, or lifts it if that same piece already occupies the cell. A live ghost follows the held piece. Amber overlay marks any hoverable dress piece that can be edited, and turns red in Delete mode. Short right-click deletes; right-drag still pans. `R` rotates, Delete mode still turns left-click into erase, and Ctrl+S writes both placement and road resources. Cursor follow and idle restore to default vision live in the map maker Settings panel (cursor-follow off by default, 10 seconds). Validation rejects unknown piece IDs, overlapping footprints, and positions outside the zone bounds.

[AMENDED 2026-08-27]: authoring comfort layer. Every world edit is undoable. `MapMakerHistory` keeps up to 64 whole-world snapshots (placement entries plus road patch rectangles) rather than inverse operations, because a Brindlewick-sized layout snapshots cheaply and a snapshot cannot drift out of sync with the layout resource. Ctrl+Z undoes, Ctrl+Shift+Z or Ctrl+Y redoes, and a fresh edit after an undo discards the stale redo branch. An undo leaves the world marked unsaved, since the resource on disk no longer matches the scene. Esc with unsaved edits warns once before it quits. `G` toggles `MapMakerGrid`, an authoring-only additive line mesh over the zone validation bounds with 0.5 m cells, brighter lines every 2 m, and amber world axes; it starts hidden so the diorama reads normally. `Q`/`E` cycle families, `F1` hides the help line, and `MapMakerToast` confirms saves, undo, redo, and grid state at the bottom of the screen. `MapMakerTheme` builds the HUD look in code so the tool needs no imported theme asset and keeps a visible keyboard focus ring. Evidence: `game/builds/captures/map_maker/ui_overview.png` and `ui_grid_and_toast.png`.

### Ground-surface ownership

Keep surface look-development separate from zone composition:

```text
game/assets/materials/environment/
  grass_surface.gdshader
  grass_surface_material.tres
  dirt_road_surface.gdshader
  dirt_road_surface_material.tres
game/content/zones/brindlewick_square/
  brindlewick_dirt_road_layout.tres
game/scenes/world/surfaces/
  brindlewick_grass_surface.tscn
  brindlewick_dirt_road_surface.tscn
game/src/presentation/
  dirt_road_layout.gd
  dirt_road_network_3d.gd
```

The material and shader own palette, scale, roughness, and painted variation. The grass surface scene owns its render geometry and canonical ground collision. Dirt roads have three narrower owners:

- `DirtRoadLayout` stores zone-authored rounded patches, corner radii, surface bounds, and join softness in meters.
- `DirtRoadNetwork3D` validates that layout, creates one draw-call batched mesh from tightly bounded patch quads, duplicates the shared material per instance, and transfers layout uniforms without mutating shared state. The quads overlap only inside the same opaque surface and share world-positioned shading, while the shader resolves the final continuous silhouette.
- `dirt_road_surface.gdshader` evaluates the patch union, discards non-road pixels, and renders edge wear and surface detail across the continuous result.

The zone geometry layer owns composition and landmarks by instancing these surface scenes. Do not return to one mesh per road strip: stacked strips reintroduce depth seams, duplicate shading at intersections, and scatter layout across node transforms. Do not move player collision into the decorative road network when the canonical grass ground already owns it.

Code-native procedural surface shaders are project source, not generated binary art, and therefore do not require an asset-provenance entry. Bitmap or model-backed replacements must follow the normal `art_source/`, runtime export, provenance, and validation workflow.

The title shell uses the same rule: `game/assets/materials/ui/title_clearing.gdshader` is a static canvas-item painting (no `TIME`) of a long-lens woodland diorama on a full-rect ColorRect.

### Tree ownership

Trees follow the same data/render/style split as ground surfaces:

```text
game/assets/materials/environment/
  tree_trunk.gdshader
  tree_trunk_material.tres
  tree_crown.gdshader
  tree_crown_civic_material.tres
  tree_crown_orchard_material.tres
  tree_crown_sentinel_material.tres
game/content/trees/
  civic_shade.tres
  orchard_tidemark.tres
  gate_sentinel.tres
game/content/zones/brindlewick_square/
  brindlewick_tree_grove_layout.tres
game/scenes/world/trees/
  tree_body.tscn
  brindlewick_tree_grove.tscn
game/src/world/tree_definition.gd
game/src/presentation/
  tree_grove_layout.gd
  tree_body_3d.gd
  tree_grove_3d.gd
  tree_crown_occluder.gd
```

- `TreeDefinition` is an immutable species record: stable `tree.*` ID, trunk taper and height, canopy radius and walk-under clearance, crown masses, crown flatten, allowed scale range, yaw snap, variant count, crown-fade flag, and materials. Validation rejects trunks wider than their canopy, missing materials, crown masses outside the declared canopy, and walk-under claims below the 2.25 m door metric.
- `TreeGroveLayout` is the zone-owned placement table: parallel rows of species ID, XZ position, yaw, uniform scale, variant seed, and a hero flag, plus ground bounds, the zone dirt-road layout, and hero/batch budgets. Validation rejects off-grid positions, unsnapped yaw, out-of-range scale, unknown species, trees on the road shoulder, trees off the ground surface, crowded trunks, misaligned rows, and budget overruns.
- `TreeBody3D` builds one species body: root flare, tapered trunk, crown masses, and a trunk-only cylinder collider. Crown jitter comes from a locally seeded generator, so one seed always produces the same silhouette.
- `TreeGrove3D` builds hero specimens as full bodies and collapses the remaining rows into one MultiMesh per species part, plus a single batched trunk-collision body. It also drives crown sway from the camera-motion accessibility setting.

To add a tree: author a species definition, add or reuse a crown material, then add one placement row. To add a map-maker-placeable tree, wrap a `tree_body.tscn` instance in a piece scene and catalog it.

Tree shaders are code-native procedural source and follow the same provenance exemption as the ground surfaces; the shader/material pair is still recorded in `assets/asset_manifest.json`.

### Nature ambience ownership

Ambient life is presentation-only and reuses the authored world data rather than duplicating it:

```text
game/assets/materials/environment/
  ambient_bird.gdshader
  ambient_bird_hearthfinch_material.tres
  falling_leaf.gdshader
  falling_leaf_civic_material.tres
  footfall_mote.gdshader
  footfall_dust_material.tres
  footfall_grass_material.tres
  ambient_bird_slate_swift_material.tres
game/content/wildlife/
  hearthfinch.tres
  slate_swift.tres
game/scenes/world/nature/
  brindlewick_nature_ambience.tscn
game/scenes/world/pieces/
  bird_roost.tscn
  swift_roost.tscn
  leaf_drift.tscn
game/src/world/bird_species_definition.gd
game/src/world/pieces/
  bird_roost.gd
  leaf_drift.gd
game/src/presentation/
  nature_ambience.gd
  ambient_bird_flock.gd
  leaf_fall_emitter.gd
  footfall_motes.gd
```

- `BirdSpeciesDefinition` is an immutable species record: stable `bird.*` ID, localization key, flock size, wingspan, cruise speed, circuit radius and cruise height ranges, silhouette ratios (body length, head, beak, tail length and fork, wing sweep and taper), bob, flap rate and amplitude, and bank angle. Validation rejects unordered ranges and any species that would cruise below the 2.0 m clearance that keeps birds out of walkable space.
- There is one bird body. `AmbientBirdFlock.build_bird_mesh(definition)` builds head, beak, tapered body, two-segment swept wings, and a forkable tail entirely from those ratios, and tags each part in UV.x so the shared shader can recolour body, belly, head, beak, wing, wingtip, and tail independently. **A new species is a definition plus a material, never new geometry.** `slate_swift.tres` exists to prove it: faster, higher, deeply forked tail, swept narrow wings, cool slate palette, same builder.
- `AmbientBirdFlock` seeds one circuit per bird from the zone's `TreeGroveLayout` anchors, hero specimens first, and renders the whole flock as one MultiMesh with a per-bird flap phase in instance custom data.
- `LeafFallEmitter` reads every crown mass in the same grove layout and feeds them to one `GPUParticles3D` as emission points, so a town-wide leaf fall stays a single draw.
- `FootfallMotes` classifies the ground under an injected actor with `DirtRoadLayout.signed_distance_m`, because the painted dirt road has no collider of its own, and enables exactly one of its dust and grass emitters.
- `NatureAmbience` is the zone-facing coordinator. `ZoneController` injects the player and forwards accessibility settings; nothing here writes save, quest, or collision state.

Ambient life is also authorable in the map maker. The **Nature** family offers `piece.bird_roost`, `piece.swift_roost`, and `piece.leaf_drift`. Those pieces wrap the same components in standalone mode: a flock with no `anchor_layout` circles its own node origin, and a leaf emitter with no `layout` sheds from a ring above itself (`local_crown_height_m`, `local_crown_radius_m`, `local_emission_points`). Placed pieces join the `ambient_motion` group, and `ZoneController` fans accessibility settings out to that group so builder-placed nature obeys reduced motion exactly like the zone-wide system. Footfall motes are not placeable because they follow the walking actor; a builder changes them by moving dirt-road patches, since the mote choice is read from the road layout.

To add a species or a new ambient effect: author the definition resource, add its material, then add the node to a zone's nature-ambience scene or wrap it in a world piece. Content validation checks every species, the scene, that the zone's leaf fall and footfall motes point at the zone-owned grove and dirt-road layouts, and that every catalogued piece family has a palette tab.

These shaders are code-native procedural source with the same provenance exemption as the ground surfaces, and each shader/material pair is recorded in `assets/asset_manifest.json`.

### World Turn authoring

Every `FoldAnchor` declares:

- stable anchor ID
- source and valid target facets
- player safe marker per target
- participant group and expected participant count
- collision group changes
- navigation link changes
- cover/occlusion strategy
- camera transition profile
- reduced-motion transition profile
- return/reversibility behavior

The validator checks that reachable targets have safe markers, no marker overlaps active collision, routes do not strand the player, all participants support declared facets, and the reduced-motion path exists.

## Character sprite workflow

### Source structure

- One source file per costume set or coherent animation group.
- Named layers separate body, face, hair, calling costume, held item, shadow guide, and notes where useful.
- Tags follow `animation_direction`, for example `walk_ne`, `idle_s`, `interact_w`.
- Pivot metadata uses the ground contact between the feet, not image center.
- Palette and outline choices follow the zone/character color script.

### Layered graybox kit

Until Aseprite sources exist, `game/tools/generate_mara_layers.ps1` is the deterministic source of the Mara kit. One run produces:

- `mara_layers_field.png`: the 21 field layers stacked vertically, each a full 576 x 320 direction sheet (48 x 64 frames in 12 columns by 5 rows: 4 idle, 8 walk).
- `mara_layers_doll.png`: the 31 paper-doll layers stacked horizontally, each a 96 x 128 south idle frame.
- `mara_hair_field.png` / `mara_hair_doll.png`: one stacked sheet per hair style (`hair.crop`, `hair.fringe`, `hair.tousle`), matching `AppearanceCatalog` IDs. Hair is a second atlas, not a 22nd body layer and not a second world quad.
- `mara_prototype.png`: the flattened unequipped field sheet used as the fallback texture.
- `mara_layers.source.json`: provenance plus the exact field and doll layer orders, frame counts, and hair style IDs.

Both body atlases and both hair atlases are copied into `assets/generated/characters/mara/` and recorded in `assets/asset_manifest.json`. `ActorLayerKit` (`content/actors/mara_layer_kit.tres`) points the runtime at them. The content validator fails if generated layer order disagrees with `ActorLayerIds`, if hair style IDs disagree with `AppearanceCatalog`, or if a field sheet is not 12 columns.

### Equipment definitions

Equipment lives in `content/items/item_catalog.tres` as immutable `ItemDefinition` resources resolved through `ContentDB`. Each definition carries a stable `item.*` ID, a localization key, one slot from the closed catalog, a draw mode of replace or overlay, a graybox colour, and a two-handed flag. Runtime ownership is separate: `PartyInventory` holds instances and an `EquipmentLoadout`.

Validation requires a stable namespaced ID, a localization key, a known slot, every slot to have at least one graybox item, and every body layer to reach a focusable slot.

### Export

An exporter creates PNG atlases plus machine-readable metadata, then a Godot import tool generates `SpriteFrames` or the project equivalent. The export step validates:

- required directions and frame counts
- consistent canvas and ground pivot
- legal mirroring metadata
- nonempty frame bounds
- atlas padding/extrusion
- animation event names
- absence of unapproved colors where a restricted palette applies

Generated frames are previewed in an automated eight-direction spin scene before integration.

## 3D asset standards

- Apply object transforms before export unless animation requires otherwise.
- Origin and forward conventions are documented beside reusable kits.
- Use stable, semantic node names; exporter suffixes are standardized.
- Materials map to shared Godot material definitions where possible.
- UVs include padding appropriate to target atlas and mip policy.
- Hero props have authored LOD only when measurement justifies it; small diorama distances often make material batching more valuable.
- Collision, camera occluder, and navigation helper geometry are visually identifiable and excluded from render.
- Source licenses and authorship are recorded in `asset_manifest.json` at the nearest sensible scope.

## UI content

- UI scenes contain structure and style resources, not final English strings.
- Text uses localization keys with named placeholders: `{actor_name}`, `{amount}`, never positional guesswork.
- Icons have semantic IDs and accessible labels.
- Prompt glyphs come from the active-device atlas selected by `InputRouter`.
- Layouts are tested with pseudo-localized strings at roughly 35% expansion and with the largest supported text scale.

## Dialogue

Dialogue entries contain stable line IDs, speaker IDs, localization keys, portrait/emote cues, typed conditions, and typed effects. Markup is allowlisted: emphasis, pause, speed, icon, and named substitutions. It cannot execute arbitrary GDScript.

Writing workflow:

1. Define conversation purpose and state changes.
2. Draft in externalized line records.
3. Validate speakers, conditions, effects, jumps, and unreachable nodes.
4. Test from every valid entry state.
5. Review in context at default and large text.
6. Lock line IDs before localization; wording may change without changing IDs.

## Quest content

Quest definitions declare availability, objectives, completion conditions, journal localization, rewards/effects, and failure rules. Conditions and effects use registered typed operations. Validators identify impossible dependency cycles, missing targets, undeclared flags, and objectives with no reachable completion path.

## Audio content

Runtime audio standards are defined in `docs/AUDIO_DIRECTION.md`. Each asset records source, license, loop points where applicable, loudness review status, and intended bus. Music stems for the same cue must share exact length, sample rate, and loop boundaries. [AMENDED 2026-08-27]: regenerate title/UI prototype WAVs with `godot --headless --path game --script res://tools/generate_title_audio.gd`.

## Validation tiers

### Import validation

- File naming and supported formats.
- Texture filter, mip, compression, color-space, and alpha policy.
- Mesh scale, transforms, material count, and unexpected animation tracks.
- Audio channel, loop, and stream settings.

### Schema validation

- Unique IDs and localization keys.
- Required fields and bounded values.
- Resolvable cross-references.
- Registered tags, conditions, effects, and flags.
- Save aliases/migrations for retired IDs.

### Composition validation

- Zone spawn and exit pairing.
- Facet reachability, safe markers, and participant coverage.
- Dialogue entry reachability.
- Encounter parties and legal ability references.
- UI focus entry/cancel routes.

### Visual validation

- Sprite spin preview.
- Zone facet capture contact sheet.
- Battle readability capture.
- Large-text and pseudo-localization screenshots.
- Grayscale and color-vision simulation checks.

Validation errors fail CI. Explicit warnings require an owner and reason before a release candidate.

Zone and piece definition checks also run inside `world_content` and `tree_grove_runtime` suites (`res://tests/run_tests.gd`). Full provenance remains `res://tools/validate_content.gd`.

## Provenance and legal safety

Every external or generated asset must have:

- creator/source
- license and proof link or project ownership note
- allowed use and attribution requirement
- modification notes
- generation model/tool and prompt record when applicable
- human art-direction review status

Reference-game captures may live only in private mood boards where legally appropriate. They do not enter runtime folders or become trace-over sources. No extracted assets, fonts, maps, audio, text, or proprietary data are allowed.

## Content review checklist

- Does the content serve a product pillar and current milestone?
- Is its identity stable and namespaced?
- Can another creator reproduce the runtime artifact from source?
- Are all references, strings, conditions, and effects validated?
- Does it work in every reachable facet and relevant game state?
- Does it remain readable with accessibility settings?
- Is its performance cost measured in representative composition?
- Is provenance complete and suitable for redistribution?
- Is the result original rather than a transformed copy of an inspiration?
