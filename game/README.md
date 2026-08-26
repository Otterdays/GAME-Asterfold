# Asterfold

**Asterfold** is the working title for an original, controller-first party RPG set in a hand-painted world of 2D characters and miniature 3D places. The player can gently orbit each diorama and perform authored quarter-turn **World Turns** that reveal routes, reframe towns, and make perspective part of exploration.

The game is currently in **preproduction / Milestone 0**. A minimal Godot scaffold and playable graybox metrics room now exist; this is an engineering testbed, not a game demo.

## Direction at a glance

- Compact, memorable towns with clear landmarks and dense social detail.
- Visible encounters and brisk timeline-based party combat.
- Mix-and-match **Callings** that encourage expressive party builds.
- 2D sprite characters in real 3D environments, with readable long-lens perspective and restrained pixel styling.
- A polished 25–35 minute vertical slice before full production expands.
- Original setting, content, maps, terminology, assets, and music.

## Start here

1. Read [AGENTS.md](../AGENTS.md) for project rules and architectural boundaries.
2. Read [Vision](../docs/VISION.md) for the player promise.
3. Read [Vertical Slice](../docs/VERTICAL_SLICE.md) for the active build target.
4. Use the discipline-specific documents under `../docs/` before implementation.

## Run the scaffold on Windows

1. Download and extract **Godot 4.7.2 Standard** from the [official archive](https://godotengine.org/download/archive/4.7.2-stable/).
2. Put `Godot_v4.7.2-stable_win64.exe` on your Desktop, add it to `PATH`, or set `ASTERFOLD_GODOT` to its full path.
3. Double-click `../launch.bat` to run the metrics room.

Use WASD or the left controller stick to move. F1 or controller Start toggles the help panel; Escape or controller B exits. Run `launch.bat --editor` from a terminal to open the project in the editor instead.

## Planned toolchain

- Godot 4.7.2 Standard, Forward+ renderer
- Typed GDScript 2.0
- Blender for source environment art
- Aseprite-compatible source files for sprite animation
- Git LFS for binary source art and audio once version control is initialized

The exact engine patch is intentionally pinned. See [ADR-0001](../docs/decisions/0001-engine-and-language.md).

## Documentation map

| Document | Owns |
| --- | --- |
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

## Current build target

Milestone 0 is in progress. The project file, semantic input, debug shell, metrics scene, provenance manifest, test runner, and content-validator entry point are present. CI and debug export automation remain to complete the milestone. All runtime work remains contained within the standalone Asterfold project.
