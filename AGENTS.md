# Asterfold Agent Handbook

This file is the operating contract for every human or automated contributor working on Asterfold. Read it before changing Asterfold code, content, scenes, imports, build scripts, or documentation.

## Rule 1: update documentation and the changelog

Every change must update `CHANGELOG.md` and every affected source-of-truth document in the same commit. Do this proportionally, but do not skip it: implementation, asset, tooling, test, and process changes all need an `Unreleased` changelog entry plus documentation that lets the next contributor find, operate, and extend the result without reverse-engineering it. Documentation-only changes still update the changelog.

Before implementation, identify which documents own the behavior being changed. Before completion, verify the changelog and those documents describe only behavior actually demonstrated. A change with stale documentation or no changelog entry is incomplete.

## Project scope

This directory is the standalone **Asterfold** project root:

- Product and engineering documentation lives in `docs/`.
- The standalone Godot runtime lives in `game/`.

Keep unrelated projects outside this root. Do not place Asterfold classes, assets, generated files, or build output in sibling projects.

## Mission

Build **Asterfold** (working title): an original, controller-first party RPG presented as a hand-painted 2D-sprite diorama inside a true 3D world. The player should feel physically present in a compact storybook place, be able to gently orbit the view, and use authored quarter-turns of perspective to reveal paths and solve spatial problems. Towns favor the clarity, density, and social warmth of classic handheld RPGs. Combat favors expressive party construction, readable timelines, and brisk encounters.

The project may learn from classic job-system JRPGs and compact monster-adventure towns, but it must not copy their characters, terminology, maps, dialogue, UI, music, story beats, visual assets, or proprietary data. Inspiration describes design values, never production content.

## Product pillars

Every feature must strengthen at least one pillar and must not materially damage another:

1. **A world worth turning.** Sprite characters, miniature 3D spaces, parallax, lighting, and deliberate camera motion make every zone feel like a living diorama.
2. **Small places with deep memory.** Towns are compact, legible, revisitable, and changed by people and quests rather than inflated by empty scale.
3. **A party that becomes yours.** Callings, cross-equipped techniques, gear, and transparent action timing create meaningful builds without grind-dependent complexity.
4. **Momentum with kindness.** Fast interactions, visible encounters, short transitions, generous saves, and strong accessibility respect the player's time.
5. **Authored surprise over systemic noise.** Asterfold is handcrafted. Procedural techniques may accelerate production, but final spaces and moments are intentionally composed.

If a feature has no clear pillar, do not add it.

## Source-of-truth order

When documents disagree, use this order and repair the lower-priority document in the same change:

1. Accepted architecture decision records in `docs/decisions/`.
2. This `AGENTS.md` contract.
3. `docs/TECHNICAL_ARCHITECTURE.md` for engineering behavior.
4. `docs/GAME_DESIGN.md` for player-facing rules.
5. `docs/ART_DIRECTION.md`, `docs/CONTENT_PIPELINE.md`, and `docs/ACCESSIBILITY_AND_UX.md` for discipline-specific constraints.
6. `docs/VERTICAL_SLICE.md` for current scope and sequence.
7. Other design notes and implementation comments.

Code is evidence of current behavior, not permission to silently change intended behavior.

## Required reading by task

- Any Asterfold task: this file, `game/README.md`, and `docs/VISION.md`.
- Gameplay or UI: add `docs/GAME_DESIGN.md` and `docs/ACCESSIBILITY_AND_UX.md`.
- Rendering, camera, scene, shader, or asset work: add `docs/ART_DIRECTION.md`, `docs/TECHNICAL_ARCHITECTURE.md`, and ADR-0002.
- Systems, saving, tools, or data: add `docs/TECHNICAL_ARCHITECTURE.md`, `docs/CONTENT_PIPELINE.md`, and ADR-0003.
- Story, dialogue, quest, or world work: add `docs/WORLD_AND_NARRATIVE.md` and `docs/CONTENT_PIPELINE.md`.
- Music or sound: add `docs/AUDIO_DIRECTION.md` and `docs/ACCESSIBILITY_AND_UX.md`.
- Planning or release work: add `docs/VERTICAL_SLICE.md` and `docs/TESTING_AND_RELEASE.md`.

## Current phase

Asterfold begins in **preproduction / Milestone 0**. Documentation is intentionally landing before the playable scaffold. Do not attempt the full game first. The next implementation target is the walking diorama described in `docs/VERTICAL_SLICE.md`; after that, build one complete vertical slice before expanding content.

Scope rules:

- Prefer one polished end-to-end path over several disconnected subsystems.
- Do not add online multiplayer, open-world streaming, procedural worlds, crafting, romance systems, or voice acting during the vertical slice.
- Do not promise console shipping. Keep input and platform boundaries console-minded, but treat console export as a later business and platform-access decision.
- New dependencies, renderer changes, save-breaking changes, and core mechanic changes require an ADR.

## Locked technology decisions

- Engine: **Godot 4.7.2 Standard**, Forward+ renderer. Use the exact patch version in CI and production unless an engine-upgrade ADR is accepted.
- Language: typed **GDScript 2.0**. Avoid C# so desktop and web demo options remain open and contributors need only the standard editor.
- Initial platform: Windows and Linux desktop; keyboard/mouse and standard gamepads.
- World: 3D scenes using meters, with 2D character art displayed on Y-axis billboards.
- Camera: long-lens perspective by default, not a flat 2D camera. See ADR-0002.
- Simulation: fixed 60 Hz physics; battle rules use deterministic, seeded domain logic.
- Source assets: Aseprite-compatible sprites and Blender-authored environment sources, exported to engine-native imports.

These decisions are justified in `docs/decisions/0001-engine-and-language.md` through ADR-0003.

## Planned repository shape

Keep responsibilities recognizable as the project grows:

```text
AGENTS.md               Asterfold project contract
docs/                   Asterfold product and engineering truth
game/                   standalone Godot project root
  addons/               pinned third-party Godot addons
  art_source/           editable .aseprite, .blend, layered source art
  assets/
    audio/              runtime audio files and bus resources
    generated/          reproducible exports; never hand-edit
    materials/          shaders, materials, palettes
    ui/                 fonts, icons, nine-patches
  content/
    abilities/          data resources, not behavior scripts
    actors/
    callings/
    dialogue/
    encounters/
    items/
    quests/
    zones/
  scenes/
    app/                 boot, shell, transitions
    battle/              battle composition and presentation
    characters/          reusable actors
    debug/               developer-only scenes
    ui/                  menus and HUDs
    world/               zones and reusable world pieces
  src/
    core/                platform-light domain utilities and contracts
    services/            deliberately small application services
    battle/              deterministic battle model and orchestration
    world/               traversal, interaction, facets, quests
    presentation/        cameras, animation, VFX, render adapters
    ui/                  UI controllers and view models
  tests/                 unit, integration, fixtures, smoke scenes
  tools/                 importers, validators, build scripts
```

Do not create a generic `utils` dumping ground. Put game code beside the domain that owns it, or name the precise shared concept under `game/src/core/`.

## Architecture invariants

These rules are non-negotiable unless an ADR replaces them:

- **The world never rotates.** Camera yaw changes, and a `FacetController` commits authored facet states. Keeping canonical world coordinates prevents physics, navigation, particles, and save data from inheriting rotated transforms.
- **Presentation does not own game truth.** Animation, UI, particles, and audio react to state; they do not decide damage, quest completion, inventory, collision topology, or save values.
- **Definitions are immutable; runtime state is separate.** A `CallingDefinition` describes a calling. A party member's learned abilities and equipped technique slots live in runtime/save state.
- **Stable IDs cross boundaries.** Saves, quests, dialogue, and references use namespaced `StringName` IDs such as `zone.brindlewick_square`, never display names, node paths, array positions, or resource paths.
- **Only declared services persist across scenes.** Prefer dependency injection and scene ownership. Autoloads are restricted to `GameFlow`, `ContentDB`, `SaveService`, `InputRouter`, `AudioDirector`, and a small `EventBus`; adding one requires an ADR.
- **Signals point upward; direct calls point downward.** Children may signal intent to owners. Owners configure children. Avoid global event broadcasts when a typed local signal or direct dependency is clearer.
- **Input actions are semantic.** Gameplay consumes `move`, `confirm`, `cancel`, `menu`, `peek`, `fold_left`, and `fold_right`, never raw keys or device buttons.
- **Pause is explicit.** Every process that can run during menus, transitions, or dialogue must have an intentional process mode.
- **Time is injected where rules depend on it.** Do not read wall-clock time from deterministic battle, quest, or save-domain tests.
- **Randomness is owned and seedable.** Do not call global random helpers inside deterministic systems.
- **There is one save authority.** Only `SaveService` writes player saves. Writes are versioned, validated, temporary-file-first, and recoverable.
- **Accessibility is part of the feature.** New UI and interactions are incomplete without keyboard and controller paths, focus behavior, readable text, motion considerations, and non-color-only signaling.

## Scene and code conventions

- Use UTF-8, LF line endings, tabs for GDScript indentation, and one final newline.
- Name scripts, scenes, resources, and folders in `snake_case`. Name GDScript classes in `PascalCase` and constants in `UPPER_SNAKE_CASE`.
- Add `class_name` only for reusable domain or component types. Avoid polluting the global class namespace for one-off scene controllers.
- Use static types for properties, parameters, return values, collections, and signal payloads. Treat new type warnings as defects.
- Prefer composition: focused child components such as `Interactor`, `HealthComponent`, and `FacetParticipant` are better than deep inheritance.
- A scene owns presentation composition; a script owns behavior. Do not store mutable run state in `.tres` definition resources.
- Do not use `get_node("../../...")`. Export a typed dependency, use an owner-controlled unique node, or inject the reference.
- Cache intentional node references with `@onready`; do not repeatedly walk the tree in `_process`.
- Physics mutations happen in `_physics_process` or through deferred calls where Godot requires them.
- Connect signals once, disconnect lifecycle-sensitive connections, and prevent duplicate connections on scene re-entry.
- Public functions should express domain intent (`commit_facet`, `queue_action`) rather than UI accidents (`on_button_3_pressed`).
- Comment the reason, constraint, or non-obvious math. Do not narrate syntax.

## Content and scene rules

- Every zone has a manifest, geometry layer, gameplay layer, presentation layer, and validation metadata as described in `docs/CONTENT_PIPELINE.md`.
- Traversal is authored on a 0.5 m logical grid even when art breaks the grid. Door clearances, steps, interaction radii, and camera occluders follow shared metrics.
- Fold changes use an explicit finite state machine: `IDLE -> PREPARING -> TURNING -> COMMITTING -> SETTLING -> IDLE`.
- No collision or navigation topology may change until the turn reaches `COMMITTING`; player control is restored only after settling.
- Character sprite direction is selected from the actor's world-space facing relative to committed camera yaw. Never key animation direction directly to screen input.
- Use alpha scissor/hashed cutout for world sprites where possible; conventional alpha blending causes sorting artifacts in 3D.
- A zone must remain readable in grayscale and at the minimum supported render scale.
- Dialogue text is externalized and localization-ready from its first committed version.

## Performance and quality budgets

The vertical slice targets 60 fps at 1920x1080 on the reference low-spec desktop described in `docs/TESTING_AND_RELEASE.md`.

- CPU frame: <= 12 ms typical, <= 16.6 ms p99 during normal exploration.
- GPU frame: <= 12 ms typical at the reference quality setting.
- Draw calls: <= 500 in a normal town view and <= 700 in a battle view.
- Visible transparent overdraw: <= 2.5x average; cut out invisible sprite pixels aggressively.
- Active world lights affecting geometry: one sun plus <= 8 local lights in a view.
- Zone transition from warm cache: <= 2 seconds; cold desktop load: <= 5 seconds.
- Input-to-visible-response: <= 100 ms for movement and menu navigation.
- Main save payload: target <= 1 MiB and never embed image, audio, or scene resources.
- No unbounded per-frame allocation, tree-wide searches, or synchronous asset loads during player control.

Budgets are guardrails, not excuses to degrade the art prematurely. Profile representative content before optimizing.

## Working method

For each change:

1. Inspect repository status, read the documents required for the task, and reserve the appropriate `CHANGELOG.md` entry and documentation updates.
2. State the smallest player-visible or tool-visible outcome and its acceptance checks.
3. Search for an existing owner, pattern, and test before adding a new abstraction.
4. Implement the smallest vertical slice of the change through data, domain, presentation, accessibility, and verification as applicable.
5. Run focused tests, then the standard validation suite. Open the relevant scene when visual behavior changes.
6. Complete the changelog, affected documentation, content schemas, fixtures, and save migrations in the same change.
7. Report what changed, what was verified, and any residual risk. Never claim a visual result that was not run or captured.

Before the code scaffold exists, command examples below describe the required contract for Milestone 0. Once scripts are added, keep these entry points stable:

```powershell
godot --editor --path game
godot --headless --editor --quit --path game
godot --headless --path game --script res://tests/run_tests.gd
godot --headless --path game --script res://tools/validate_content.gd
```

If `godot` is not on `PATH`, document and use a task-specific environment variable such as `$ASTERFOLD_GODOT`; do not hard-code a contributor's local path.

## Tests and definition of done

A change is done only when all applicable statements are true:

- Acceptance behavior is demonstrated in a representative scene, not only in isolation.
- Domain rules have deterministic tests, including boundary and failure cases.
- Cross-scene work has an integration or smoke test.
- Content IDs, references, localization keys, and resource schemas pass validation.
- Keyboard and controller operation both work; UI focus never becomes trapped or invisible.
- Save-affecting changes include a schema bump or an explicit proof that no migration is needed.
- Motion, flashing, text size, and color signaling satisfy `docs/ACCESSIBILITY_AND_UX.md`.
- Representative performance remains within budget or the measured exception is documented.
- Imported assets have sources, licenses, and reproducible settings.
- No copyrighted placeholder content is committed.
- Documentation reflects the shipped behavior.
- No new editor, import, parser, or runtime errors appear in logs.

See `docs/TESTING_AND_RELEASE.md` for the complete quality ladder.

## Change control

Create a new ADR when a change affects engine version, renderer, language, repository-wide architecture, persistent data identity, save compatibility policy, camera/fold semantics, content source format, third-party runtime dependency, or target platform. Copy `docs/templates/ADR_TEMPLATE.md`, number it sequentially, and record alternatives and consequences.

Update the relevant feature spec when changing player-facing rules. Update the content pipeline when changing authoring or import behavior. Update the vertical-slice checklist only when scope has genuinely changed; do not quietly redefine incomplete work as complete.

## Forbidden shortcuts

- No copied or extracted assets, maps, fonts, music, text, trademarks, or data from reference games.
- No generated art committed without provenance, review, consistent art direction, and rights suitable for the project.
- No hidden singleton state, mutable definition resources, magic content strings, or save data based on scene paths.
- No `await` chains that can outlive their scene without cancellation or validity checks.
- No gameplay gated solely by color, audio, rapid input, or precise analog dexterity.
- No enormous manager scripts. Split a file before it becomes the only place a subsystem can be understood.
- No speculative framework for unapproved future systems. Build the current milestone cleanly.

## When uncertain

Protect the pillars, the deterministic state model, saved-player data, accessibility, and the vertical-slice scope. Prefer a small reversible experiment behind a debug flag. Record consequential choices in an ADR instead of letting incidental code become architecture.
