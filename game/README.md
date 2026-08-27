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

1. Read [AGENTS.md](../AGENTS.md) for project rules and architectural boundaries.
2. Read [Changelog](../CHANGELOG.md) for the current `Unreleased` implementation record.
3. Read [Vision](../docs/VISION.md) for the player promise.
4. Read [Vertical Slice](../docs/VERTICAL_SLICE.md) for the active build target.
5. Use the discipline-specific documents under `../docs/` before implementation.

## Run the prototype on Windows

1. Download and extract **Godot 4.7.2 Standard** from the [official archive](https://godotengine.org/download/archive/4.7.2-stable/).
2. Put `Godot_v4.7.2-stable_win64.exe` on your Desktop, add it to `PATH`, or set `ASTERFOLD_GODOT` to its full path.
3. Double-click `../launch.bat` to open the title screen, then choose **Start Walking Diorama**.

Use WASD or the left controller stick to move. Hold Space and use WASD, or use the right controller stick, to Peek without changing Mara's movement basis. F1 or controller Start toggles field help. Escape or controller B returns safely to the title screen. Menus support keyboard and controller focus throughout.

Run `launch.bat --editor` from a terminal to open the project in the editor. The title also retains the original Metrics Room as a developer entry point.

## Validate and export

The complete local gate is one command from the repository root:

```powershell
validate.bat
```

It locates exactly Godot 4.7.2 Standard and runs import/script parsing, 88 unit and integration checks, content/provenance validation, a runtime smoke, Windows and Linux debug exports, and a Windows exported-build boot smoke. Build output and logs stay under ignored `game/builds/` and `game/logs/` directories.

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

The exact engine patch is intentionally pinned. See [ADR-0001](../docs/decisions/0001-engine-and-language.md).

## Documentation map

| Document | Owns |
| --- | --- |
| [Changelog](../CHANGELOG.md) | Demonstrated additions, changes, and fixes not yet included in a versioned build |
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

## Current build status

The M0 implementation is locally recoverable and its automated/release gates are present. M1 supplies the Brindlewick zone package, stable manifest and spawn, 45–75 second primary loop, long-lens camera, three Peek motion modes, constrained camera volume, foreground fading, original five-facing/eight-direction Mara sheet, direction hysteresis, contact shadow, persisted accessibility profile, binding capture/conflict handling, and title/field/return flow. Brindlewick grass and dirt roads are separate surface modules under `scenes/world/surfaces/`, with independently tunable materials and world-scale painted shaders under `assets/materials/environment/`.

See [Milestone Status](../docs/MILESTONE_STATUS.md) for demonstrated evidence and explicitly pending manual acceptance. M2 World Turns, navigation topology changes, save-game state, NPC content, and combat remain out of scope.
