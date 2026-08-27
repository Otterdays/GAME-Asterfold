# Content Pipeline

## Goals

Content must be fast to author, safe to rename, mechanically validated, localization-ready, and reproducible from source. The playable game consumes imported/runtime artifacts; creators retain editable source files and documented export settings.

## Identity

Every persistent or cross-referenced definition has a stable lowercase namespaced ID:

```text
actor.mara
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

The playable shell never launches or mentions the map maker. Contributors run `map_maker.bat` from the repository root, which opens `game/tools/map_maker/map_maker.tscn` against the Godot project. The tool instantiates the same Brindlewick zone scene the walking diorama loads, freezes Mara and the playable camera, and writes `*_placements.tres` plus the dirt-road layout. Grass, spawns, camera volumes, bounds, and presentation stay visible so the builder is connected to the live world even when those layers are not yet writable.

Beginner chrome uses four families: Things, Buildings, Trees, Roads. Status reports a weighted connectivity/control score. Hover tooltips live in a separate catalog (`game/tools/map_maker/map_maker_tooltip_catalog.tres`) and overlay, not Godot `tooltip_text`.

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

Place on the 0.5 m grid. Left click places or moves the selected road, right click removes a piece, `R` rotates, and Ctrl+S writes both placement and road resources. Cursor follow and idle restore to default vision live in the map maker Settings panel (defaults on, 10 seconds). Validation rejects unknown piece IDs, overlapping footprints, and positions outside the zone bounds.

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

The title shell uses the same rule: `game/assets/materials/ui/title_clearing.gdshader` is a static canvas-item painting (no `TIME`), owned by the title scene rather than any zone.

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

Runtime audio standards are defined in `docs/AUDIO_DIRECTION.md`. Each asset records source, license, loop points where applicable, loudness review status, and intended bus. Music stems for the same cue must share exact length, sample rate, and loop boundaries.

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
