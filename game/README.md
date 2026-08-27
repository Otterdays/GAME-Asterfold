# Asterfold

**Asterfold** is the working title for an original, controller-first party RPG set in a hand-painted world of 2D characters and miniature 3D places. The player can gently orbit each diorama and perform authored quarter-turn **World Turns** that reveal routes, reframe towns, and make perspective part of exploration.

The game is in **preproduction**. The Milestone 0 foundation and Milestone 1 walking-diorama implementation are available locally: a controller-friendly title shell now launches an original Mara prototype into the Brindlewick graybox. This remains an engineering and art-direction prototype, not a game demo.

## Direction at a glance

- Compact, memorable towns with clear landmarks and dense social detail.
- Visible encounters and brisk timeline-based party combat.
- Mix-and-match **Callings** that encourage expressive party builds.
- 2D sprite characters in real 3D environments, with readable long-lens perspective and restrained pixel styling.
- A polished 25–35 minute vertical slice before full production expands.
- Original setting, content, maps, terminology, assets, and music.

## Start here

1. Read [AGENTS.md](../AGENTS.md). Agents apply `/caveman ultra` first.
2. Read [Summary](../docs/SUMMARY.md) for the current snapshot, then [Changelog](../CHANGELOG.md) for `Unreleased` work.
3. Read [Vision](../docs/VISION.md) for the player promise.
4. Read [Vertical Slice](../docs/VERTICAL_SLICE.md) for the active build target.
5. Use the discipline-specific documents under `../docs/` before implementation. See [docs/README.md](../docs/README.md) for the full map.

## Run the prototype on Windows

1. Download and extract **Godot 4.7.2 Standard** from the [official archive](https://godotengine.org/download/archive/4.7.2-stable/).
2. Put `Godot_v4.7.2-stable_win64.exe` on your Desktop, add it to `PATH`, or set `ASTERFOLD_GODOT` to its full path.
3. Double-click `../launch.bat` to open the title screen, then choose **Start Walking Diorama**. A quiet original lute-and-foley loop plays on the menu. Buttons highlight on hover. The clearing stays visible while Brindlewick instantiates; title buttons do not accept a second click during that hitch.

Use WASD or the left controller stick to move. Hold Space and use WASD, or use the right controller stick, to Peek without changing Mara's movement basis. Look around (V, controller Y, or the field button) opens a top-down map of the zone; click or Confirm to view from that point in first person with a center crosshair and no body. Escape or B leaves first-person view first, then returns to the title screen from the diorama. I or controller Select opens the equipment screen, where the paper doll and slot list cover the head, necklace, shoulders, back, torso, stomach, waist, legs, boots, gloves, four rings, and both hands. F1 or controller Start toggles field help. Menus support keyboard and controller focus throughout.

Run `launch.bat --editor` from a terminal to open the project in the editor. The title also retains the original Metrics Room as a developer entry point.

## Validate and export

The complete local gate is one command from the repository root:

```powershell
validate.bat
```

It locates exactly Godot 4.7.2 Standard and runs import/script parsing, the discovered unit/integration suite (458 checks across 9 suites as of 2026-08-27), content/provenance validation, a runtime smoke, Windows and Linux debug exports, and a Windows exported-build boot smoke. Suite names and `-- --suite=<name>` filtering are in [Testing and Release](../docs/TESTING_AND_RELEASE.md). Build output and logs stay under ignored `game/builds/` and `game/logs/` directories.

Install the official pinned export templates once before the first full gate:

```powershell
powershell -ExecutionPolicy Bypass -File game/tools/install_export_templates.ps1
```

The installer verifies SHA-256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`. Use `validate.bat -SkipExports` when working on a machine without templates. The checked-in GitHub Actions workflow mirrors the gate on Windows and Linux but remains inactive until this local repository receives a remote.

Visual and performance review entry points are:

```powershell
powershell -ExecutionPolicy Bypass -File game/tools/capture_m1_review.ps1
powershell -ExecutionPolicy Bypass -File game/tools/run_performance_soak.ps1
```

## Toolchain

- Godot 4.7.2 Standard, Forward+ renderer
- Typed GDScript 2.0
- Blender for source environment art
- Aseprite-compatible source files for sprite animation
- Local Git on `main`, with Git LFS enabled for editable binary source art and runtime audio
- Internal map maker: title **Open Map Maker**, or `map_maker.bat` from the repository root; see [Content Pipeline](../docs/CONTENT_PIPELINE.md)

The exact engine patch is intentionally pinned. See [ADR-0001](../docs/decisions/0001-engine-and-language.md).

## Documentation map

| Document | Owns |
| --- | --- |
| [Changelog](../CHANGELOG.md) | Demonstrated additions, changes, and fixes not yet included in a versioned build |
| [Summary](../docs/SUMMARY.md) | Agent start-here snapshot and quick links |
| [Milestone Status](../docs/MILESTONE_STATUS.md) | Demonstrated M0/M1 evidence and pending acceptance |
| [Vision](../docs/VISION.md) | Player promise, pillars, audience, constraints |
| [Game Design](../docs/GAME_DESIGN.md) | Exploration, World Turns, combat, progression, towns |
| [Art Direction](../docs/ART_DIRECTION.md) | Diorama look, camera, sprite and environment standards |
| [Technical Architecture](../docs/TECHNICAL_ARCHITECTURE.md) | Runtime boundaries, data, saves, input, performance |
| [Content Pipeline](../docs/CONTENT_PIPELINE.md) | Asset and content authoring, imports, validation |
| [World and Narrative](../docs/WORLD_AND_NARRATIVE.md) | Setting, cast, story rules, writing voice |
| [Audio Direction](../docs/AUDIO_DIRECTION.md) | Music, ambience, SFX, mixing, accessibility |
| [Accessibility and UX](../docs/ACCESSIBILITY_AND_UX.md) | Inclusive controls, readability, motion, difficulty |
| [Vertical Slice](../docs/VERTICAL_SLICE.md) | Milestones, acceptance criteria, exclusions, risks |
| [Testing and Release](../docs/TESTING_AND_RELEASE.md) | Automated, manual, performance, and release gates |
| [Docs index](../docs/README.md) | Full documentation map, including agent status files |

## Current build status

The M0 implementation is locally recoverable and its automated/release gates are present. M1 supplies the Brindlewick zone package, stable manifest and spawn, 45–75 second primary loop, long-lens camera, three Peek motion modes, constrained camera volume, foreground fading, original five-facing/eight-direction Mara sheet, direction hysteresis, contact shadow, persisted accessibility profile, binding capture/conflict handling, and title/field/return flow. Brindlewick grass and dirt roads are separate surface modules under `scenes/world/surfaces/`, with independently tunable materials and world-scale painted shaders under `assets/materials/environment/`. The dirt road additionally separates its zone-authored layout resource from the reusable `DirtRoadNetwork3D` renderer, producing one continuous rounded surface with no overlapping road meshes. Trees follow the same pattern: species definitions in `content/trees/`, placements in `content/zones/brindlewick_square/brindlewick_tree_grove_layout.tres`, and reusable bodies in `scenes/world/trees/`. Ambient life sits under `NatureAmbience` in the zone presentation layer: a hearthfinch flock, grove-wide leaf fall, and footfall dust or grass motes chosen from the road layout. Species live in `content/wildlife/` and all share one baseline body, so a variant such as `slate_swift.tres` is a definition plus a material. The map maker's **Nature** family places roosts and leaf drifts anywhere on the square.

See [Milestone Status](../docs/MILESTONE_STATUS.md) for demonstrated evidence and explicitly pending manual acceptance. M2 World Turns, navigation topology changes, save-game state, NPC content, and combat remain out of scope.
