# Technical Architecture

## Goals

The architecture must make four hard things reliable:

1. A world that can be viewed and committed through different facets without rotating its physics space.
2. Crisp 2D character presentation that remains spatially grounded in real 3D scenes.
3. Deterministic, testable party combat and progression separate from animation timing.
4. Content-rich production with stable identity, validation, save migration, and fast iteration.

The smallest useful architecture is preferred. Systems become services only when they cross scene lifetimes or own a clear process boundary.

## Platform baseline

- Godot 4.7.2 Standard, Forward+.
- Typed GDScript 2.0.
- Fixed physics rate: 60 Hz.
- Initial desktop render API: Vulkan; Compatibility renderer is a later measured fallback, not an assumption.
- Default presentation canvas: 1920 x 1080 (High). Low 640 x 360 remains the minimum supported world/title render scale. Window size is independent and may be 720p through 4K.
- Initial build targets: Windows x86-64 and Linux x86-64.
- All player actions must work through keyboard and a standard dual-stick controller.

The standalone game runtime lives under `game/` so engine files, source assets, and generated output remain distinct from the product documentation at the project root.

## Layer model

```text
Content definitions (.tres/.res/JSON localization)
                 |
                 v
Pure-ish domain state and rules
                 |
                 v
Application orchestration / scene controllers
                 |
                 v
Godot presentation, animation, audio, VFX, UI
                 |
                 v
Platform I/O: input, files, display, build
```

Dependencies point downward. Domain code never looks up nodes, plays audio, starts tweens, reads controller devices, or writes files. Presentation receives snapshots/events and returns semantic intent.

## Runtime scene composition

Planned main tree:

```text
App (Node)
|- WorldViewport (SubViewportContainer)
|  `- WorldRoot (Node3D)
|     |- ActiveZone (Node3D)
|     |- PartyActors (Node3D)
|     |- WorldCameraRig (Node3D)
|     `- WorldEnvironment
|- BattleLayer (Node)
|- UILayer (CanvasLayer)
|- TransitionLayer (CanvasLayer)
`- DebugLayer (CanvasLayer, development only)
```

`GameFlow` owns transitions between stable game states. It currently instantiates the target zone synchronously. The app shell keeps the title clearing visible for that hitch, disables title actions, and raises `WorldLoadBlocker` until the first idle field frame after the zone exists so a click cannot fall through. Asynchronous loads, a `TransitionLayer`, and releasing the previous zone only after the next is staged remain the M4 zone-transition plan. The screen cover is presentation; it never acts as proof that loading succeeded.

## Autoload boundaries

Allowed long-lived services:

| Service | Owns | Must not own |
| --- | --- | --- |
| `GameFlow` | Top-level state machine, zone/battle transitions | Quest truth, animation details |
| `ContentDB` | Validated ID-to-definition lookup | Mutable character or quest state |
| `SaveService` | Serialization, migrations, slot metadata, atomic I/O | UI, autosave policy decisions |
| `InputRouter` | Active device, semantic prompts, input context | Character movement rules |
| `AudioDirector` | Buses, music state, ambience transitions | Quest or battle truth |
| `EventBus` | Small set of declared cross-lifetime notifications | Local scene communication or arbitrary strings |

All service APIs are typed. Adding another autoload requires evidence that scene ownership and explicit injection are insufficient, then an ADR.

Title music and UI transients currently live on the app-shell `TitleShellAudio` node (Music / UI buses). That is scene ownership, not the `AudioDirector` autoload. Do not promote it without an ADR.

## Zone contract

Each zone provides a `ZoneManifest` definition and a composed scene with these roles:

```text
ZoneRoot
|- Geometry                 static visible meshes and composed surface modules
|  |- GrassSurface          ground render/collision plus its shared material family
|  |- DirtRoadSurface       one rounded route network; canonical ground retains collision
|  `- PlacementLayer        map-maker dress pieces instanced from the zone placement list
|- DynamicGeometry          animated/hideable facet pieces
|- Collision                simplified canonical collision
|- Navigation               regions and named links
|- Entities                 NPCs, enemies, props
|- Interactions             anchors and interaction volumes
|- CameraVolumes            composition and occlusion policy
|- Lighting                 zone-owned lights/probes
|- AudioRegions             ambience and reverb
`- SpawnPoints              stable named spawn markers
```

The manifest declares stable zone ID, scene, allowed facets, default facet, spawn IDs, neighboring zones, audio profile, and validation bounds. Save data refers to zone and spawn IDs, never nodes.

Surface modules are presentation composition, not world state. Their shaders may derive stable variation from canonical world position, but they must not alter traversal, navigation, facet state, or saved coordinates. Shared look parameters belong in external material resources so later zones can reuse or override a family without editing Brindlewick's main geometry scene.

Roads use a data/render/style split. A zone-owned `DirtRoadLayout` resource declares bounded rounded patches and join softness on the meter grid. `DirtRoadNetwork3D` is a reusable presentation component that validates the resource, generates one surface containing tightly bounded patch quads, and copies layout uniforms into an instance-local material. The shared shader produces a smooth distance-field union and surface treatment. Keeping the mesh near the road avoids evaluating the detailed shader over the whole zone; batching retains one draw call. This removes visible overlap seams while keeping authoring data out of shader code and shared materials free of zone-specific mutable state.

Trees use the same split. `TreeDefinition` describes a species; a zone-owned `TreeGroveLayout` stores placements and validates them against the dirt-road layout, the logical grid, ground bounds, and trunk spacing; `TreeBody3D` builds one painted body with trunk-only collision; `TreeGrove3D` composes hero bodies plus one MultiMesh per batched species part and a single batched trunk-collision body. Crowns collide only on the camera occlusion mask through `tree_crown_occluder.gd`, which implements the same `set_faded` contract the camera rig already raycasts for. `ZoneController` forwards camera-motion accessibility settings to the grove so crown sway stops outside Full motion.

Ambient nature reuses that authored data instead of adding a second source of truth. `NatureAmbience` is a zone presentation node owning three components: `AmbientBirdFlock` seeds per-bird circuits from the grove's tree placements and renders the flock as one MultiMesh with the flap phase carried in instance custom data; `LeafFallEmitter` turns every crown mass in the grove layout into an emission point for a single `GPUParticles3D`; `FootfallMotes` rides an injected actor and enables one of its dust and grass emitters based on `DirtRoadLayout.signed_distance_m`, because the painted dirt road has no collider to query. There is one bird body: `AmbientBirdFlock.build_bird_mesh(definition)` builds head, beak, body, two-segment swept wings, and a forkable tail from the species ratios and tags each part in UV.x, so a variant species is a definition plus a material rather than new geometry. The flock and the leaf emitter also run standalone: with no grove assigned they anchor on their own node, which is what the map maker's `nature` family pieces (`piece.bird_roost`, `piece.swift_roost`, `piece.leaf_drift`) use. `ZoneController` injects the player, forwards camera-motion accessibility settings, and fans the same settings to the `ambient_motion` group so builder-placed nature obeys reduced motion too. Reduced and Minimal motion freeze the flock, stop leaf fall, and silence footfall motes. None of these components read or write gameplay state.

Map-maker dress uses the same data/instance split. `WorldPieceCatalog` lists reusable piece scenes in `prop`, `building`, and `tree` families. A zone-owned `ZonePlacementList` stores grid cells, piece IDs, footprints, and quarter-turn yaw. `PlacementLayer` instances those components when the zone is ready. The internal map maker loads the composed zone scene, edits placements and dirt-road patch centers, and never joins `GameFlow`. Title **Open Map Maker** uses `change_scene_to_file` from the app shell. `map_maker.bat` still opens the same scene. Tooltips are a separate overlay plus `MapMakerTooltipCatalog`, not inline palette strings. Cursor follow and idle restore are `MapMakerSettings` options shown in the Settings panel. Placement preview uses `MapMakerPreview`: a translucent ghost of the held piece, amber overlay on editable hover targets, click-to-unplace on the same piece, and short right-click delete with right-drag pan.

## Coordinate conventions

- Godot Y-up world coordinates.
- Ground movement on XZ.
- Forward-facing convention: world `-Z`.
- Clockwise camera facet order when viewed from above: `north`, `east`, `south`, `west`.
- Angles stored in radians at runtime; exported authoring values may use degrees when the field name says so.
- Distances are meters.
- Actor world facing is a normalized XZ vector, never inferred from the billboard transform.

## Camera and facet system

### Important invariant

The zone root and canonical physics world do not rotate. `WorldCameraRig` changes yaw. The `FacetController` activates authored state associated with the committed camera facet.

### State model

```text
IDLE
  -> PREPARING       validate request, choose safe player marker, lock locomotion
  -> TURNING         camera and cover presentation run
  -> COMMITTING      swap topology atomically at the occluded threshold
  -> SETTLING        re-evaluate focus, sprites, navigation, audio
  -> IDLE            return control
```

Any failure before `COMMITTING` returns to the source facet. A failure during commit restores a captured source state and reports a structured error in development builds. A facet transaction includes:

- Source and target facet IDs.
- Player and follower safe positions.
- Active collision groups.
- Enabled navigation links.
- Facet participant visibility/state.
- Interaction candidate invalidation.
- Camera composition and occlusion groups.
- Audio snapshot.

`FacetParticipant` components respond to `prepare`, `commit`, and `settle`. They do not independently decide the active facet. Participants are registered and validated when the zone becomes ready.

### Peek Orbit

Peek applies a presentation-only offset beneath the committed camera rig. It cannot alter the active facet, cursor target, navigation direction basis, or saved state. Camera-relative movement always uses committed yaw rather than transient peek yaw; this avoids movement wobble while inspecting. Field play captures the mouse immediately and drives Peek from mouse motion. Keyboard Peek and right stick remain. Peek recenters after 10 seconds without look input.

First-person look (`FirstPersonScout`) is a second presentation camera. The field HUD **Look around** control (semantic `scout`) opens a top-down SubViewport of the live zone. A click or Confirm chooses an XZ point inside the zone bounds; the scout eye sits 1.65 m above ground, hides Mara, and shows a center crosshair. Mouse and Peek-stick look. The world does not rotate. Cancel returns to the long-lens rig without changing spawn or save state.

### Character sprite direction

For each sprite actor:

1. Project its world-facing vector onto XZ.
2. Express that vector relative to the committed camera forward.
3. Quantize to the supported four- or eight-direction animation set with hysteresis near boundaries.
4. Select animation and legal mirroring.
5. Rotate only the render card around Y to face the actual camera.

Direction selection updates on facing or committed facet changes, not every frame unless the actor is turning. Hysteresis prevents flicker.

## World traversal

The player uses a `CharacterBody3D` driven by a `LocomotionController`. Logical input is camera-relative but resolved against committed yaw. Movement uses acceleration with fast direction response, slide collision, explicit slope limits, and grounded safe-marker sampling.

Navigation agents are for non-player intent, not player collision. Dynamic facet routes use pre-authored `NavigationLink3D` groups toggled at commit. Rebuilding an entire navigation mesh during the turn is forbidden unless profiling and an ADR justify it.

Followers replay a time-spaced trail of stable player samples and teleport unobtrusively when invalidated by a facet or transition. They have no world collision.

## Interaction model

`InteractionSensor` collects typed `Interactable` candidates through an area and optional sight check. An `InteractionResolver` ranks them deterministically. The field controller shows focus; the interactable returns an interaction command or dialogue ID. The interaction system never embeds quest-specific string branching in general sensor code.

Interaction commands are cancellable across transition and scene unload. Long sequences are represented by explicit cutscene steps with skip/recovery boundaries.

## Battle architecture

Battle uses a domain model that can run headless without a scene tree.

Core types:

- `BattleState`: combatant states, timeline positions, resources, status instances, encounter seed.
- `BattleRules`: validates commands and calculates deterministic outcomes.
- `BattleCommand`: actor, action ID, targets, optional parameters.
- `BattleEvent`: immutable logical output such as damage, movement, status, interrupt, defeat.
- `TimelineScheduler`: advances readiness and scheduled effects.
- `BattleOrchestrator`: bridges player/AI commands, domain resolution, and presentation queue.
- `BattlePresenter`: animates events and acknowledges completion; it cannot revise outcomes.

The RNG is instantiated from the encounter seed and passed into rules that need it. Random calls have a stable documented order within an action. Tests can use fixed-roll sources for exact scenarios.

Animation completion may gate presentation sequencing but cannot decide whether an action hit. If an animation is skipped or missing, logical battle still completes.

## Content definitions and runtime state

Definitions extend focused `Resource` types and are treated as immutable after `ContentDB` validation. Examples:

- `ActorDefinition`
- `CallingDefinition`
- `AbilityDefinition`
- `StatusDefinition`
- `ItemDefinition`
- `EnemyDefinition`
- `EncounterDefinition`
- `QuestDefinition`
- `ZoneManifest`

Every definition contains a namespaced stable ID. Cross-references are IDs resolved by `ContentDB`, allowing validators to identify missing references and saves to survive file moves.

Runtime models contain primitives, stable IDs, and small value objects. Nodes and Resources never appear in serialized state.

## Equipment and layered actor presentation

`ItemDefinition` is immutable content. Runtime ownership is split so presentation never becomes game truth:

- `EquipmentSlotCatalog` and `ActorLayerIds` own the closed slot list and the canonical body-layer identities.
- `EquipmentLoadout` owns occupancy rules: one occupant per slot, set items occupying a single slot, and a two-handed main hand that blocks rather than silently fills the off hand.
- `PartyInventory` owns instances, bag membership, and equip/unequip transactions, and emits `loadout_changed`.
- `SpriteLayerCompositor` reacts to the loadout by flattening per-layer art into one texture. It decides nothing about what is equipped.

There is no equipment autoload. `AppShell` owns one session-scoped `PartyInventory`, the equipment screen sends intent to it, and the zone controller forwards the resulting definitions to the actor's `SpriteActor`. The loadout is discarded on return to title; campaign persistence waits for `SaveService` and the save envelope below.

The compositor recomposes a whole direction sheet on equipment change and caches recent loadouts, so the world actor stays one billboarded quad regardless of layer count.

## Quest and flag state

Quest state is explicit:

```text
unavailable -> available -> active -> completed
                                `-> failed (only when authored and disclosed)
```

Objectives use typed conditions and effects. Global flags are namespaced and declared in a registry; dialogue cannot silently create a new flag through a typo. Repeated effects declare idempotency behavior.

## Save system

### Shape

The envelope contains:

- `schema_version`
- `build_version`
- slot metadata and playtime
- current stable zone/spawn/facet
- party roster, progression, equipment, and inventory
- quest/objective state and declared world flags
- defeated or changed persistent entity IDs
- settings profile reference
- encounter seed state only where explicitly resumable
- payload checksum

Settings and input bindings are stored separately from campaign saves so accessibility choices apply before loading.

### Safety

1. Serialize domain state to an in-memory dictionary.
2. Validate required IDs, bounds, and schema.
3. Write to a slot-specific temporary file.
4. Read and validate the temporary file.
5. Rotate the previous valid file to backup.
6. Atomically replace the main slot where the platform permits.
7. Update slot metadata only after success.

Maintain three rotating autosaves and one backup per manual slot. Never overwrite the only known-good copy first.

### Migrations

Migrations are sequential pure transformations from version N to N+1. A build that changes persisted meaning must add a migration fixture using a real older-save sample. Removing a content ID requires an alias, migration, or explicit incompatibility decision before merge.

## Input and focus

`InputRouter` maps physical inputs to semantic actions and selects one of three contexts: field, UI, or cutscene. A context consumes only actions it owns. Active-device detection uses hysteresis so stick drift does not rapidly swap prompts.

UI screens define an initial focus target, directional neighbors where automatic navigation is ambiguous, a cancel destination, and a focus restoration target. Mouse hover cannot permanently steal gamepad focus.

Title Settings uses a `TabContainer` with **Video** (window mode, output resolution, UI scale, presentation quality), **Accessibility** (camera motion, text scale, confirm/cancel swap), and **Controls** (rebinding list and reset). `DisplaySettings` owns window mode, resolution, and UI scale. `AccessibilitySettings` owns presentation quality and text scale. Window resolution sets the OS window or fullscreen size. UI scale grows HUD and menus inside a 1920×1080 UI reference without changing that window size. Presentation quality sets `WorldViewport.scaling_3d_scale`; the title clearing stays High 1920×1080. F11 and Alt+Enter (`toggle_fullscreen`) toggle windowed and borderless from `AppShell._input`, then refresh the Video tab and save. F10 (`quit_prompt`) opens the shell's `QuitPrompt` panel with "YES, QUIT" focused. Both shortcuts are suppressed while the Controls tab is capturing a rebind so the keys remain bindable. Values persist under `user://settings.cfg` keys `accessibility`, `bindings`, and `video`. Clicking a tab title switches the visible page. Opening the screen focuses the tab bar; cancel still returns to title.

## Asynchrony and cancellation

Zone loads, dialogue sequences, transitions, and long presentations can outlive their initiating node. Each receives an operation token owned by `GameFlow` or the scene controller. After every `await`, code verifies token validity and node lifetime before mutating state.

Only the owner can finalize or cancel an operation. Avoid fire-and-forget coroutines.

## Error handling and observability

- Expected validation failures return structured results with content ID and source path.
- Impossible state uses assertions in development and a recoverable error path in release.
- Logs use categories: `FLOW`, `SAVE`, `CONTENT`, `FACET`, `BATTLE`, `INPUT`, `AUDIO`, `WORLD`.
- Development HUD can show FPS/frame times, draw calls, current zone/facet, interaction target, navigation state, content warnings, and last save result.
- Release telemetry is opt-in and out of scope for the vertical slice. Do not add network reporting casually.

## Performance strategy

- Profile a representative town and battle, not empty test scenes.
- Keep static environment pieces mergeable or instanced by material family.
- Use occlusion culling only after authored camera routes make it predictable.
- Pool only measured churn such as repeated damage labels or common battle effects; do not create universal object pools.
- Avoid per-frame allocations and node-tree searches in actor loops.
- Load the next likely zone asynchronously at explicit approach volumes when memory budgets permit.
- Keep sprite materials shared and instance parameters narrowly.
- Validate transparency overdraw with captured frames.

Vertical-slice reference budgets are in `AGENTS.md`; measurement procedure is in `docs/TESTING_AND_RELEASE.md`.

## Security and dependency policy

- Runtime content is local and trusted only after schema validation.
- File paths are built from controlled slot/content identifiers; user strings never become paths.
- Dialogue markup uses a small allowlist parser, not arbitrary expression execution.
- Third-party addons are pinned to an exact commit or release, recorded with license and purpose, and placed under `game/addons/`.
- No addon may become the sole readable representation of core battle, save, or facet state.
- Network access is not part of the runtime vertical slice.

## Validation entry points

From the workspace root, Windows contributors run `validate.bat`. That wrapper locates Godot 4.7.2 Standard and runs import/script parsing, the discovered `TestCase` suite (`res://tests/run_tests.gd`, 458 checks across 9 suites as of 2026-08-27), content/provenance validation, a runtime smoke, debug exports, and the Windows exported-build boot smoke. Suite names, leak checks, and `--suite=` filtering are documented in `docs/TESTING_AND_RELEASE.md`.

Direct Godot entry points remain:

```powershell
godot --headless --editor --quit --path game
godot --headless --path game --script res://tests/run_tests.gd
godot --headless --path game --script res://tests/run_tests.gd -- --suite=project_contract
godot --headless --path game --script res://tools/validate_content.gd
```

If `godot` is not on `PATH`, use `$ASTERFOLD_GODOT` or the Desktop convention documented in `game/README.md`. Do not hard-code a contributor's local path.
