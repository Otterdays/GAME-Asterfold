<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# Asterfold documentation

Product and engineering truth for Asterfold lives in this folder. The Godot runtime lives in `game/`.

## How to use these files

1. Agents apply `/caveman ultra` first (`AGENTS.md` Rule 1).
2. Then read `SUMMARY.md`, `SBOM.md`, `SCRATCHPAD.md`, and `STYLE_GUIDE.md`.
3. Then read the product document that owns the change.

When documents disagree, follow the source-of-truth order in `AGENTS.md`. Code is evidence of current behavior, not permission to silently change intended behavior.

## Agent status docs

| Document | Owns |
| --- | --- |
| [SUMMARY.md](SUMMARY.md) | Current snapshot, how to run, quick links |
| [SCRATCHPAD.md](SCRATCHPAD.md) | Active tasks, blockers, last actions |
| [SBOM.md](SBOM.md) | Dependencies and provenance |
| [STYLE_GUIDE.md](STYLE_GUIDE.md) | Agent writing and code conventions for this repo |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Agent-facing structure map; defers to Technical Architecture for runtime law |
| [My_Thoughts.md](My_Thoughts.md) | Decision rationale that is not yet an ADR |
| [debugs/](debugs/) | Issue and audit logs |

## Product and engineering docs

| Document | Owns |
| --- | --- |
| [VISION.md](VISION.md) | Player promise, pillars, audience, constraints |
| [GAME_DESIGN.md](GAME_DESIGN.md) | Exploration, World Turns, combat, progression, towns |
| [ART_DIRECTION.md](ART_DIRECTION.md) | Diorama look, camera, sprite and environment standards |
| [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) | Runtime boundaries, data, saves, input, performance |
| [CONTENT_PIPELINE.md](CONTENT_PIPELINE.md) | Asset and content authoring, imports, validation |
| [WORLD_AND_NARRATIVE.md](WORLD_AND_NARRATIVE.md) | Setting, cast, story rules, writing voice |
| [AUDIO_DIRECTION.md](AUDIO_DIRECTION.md) | Music, ambience, SFX, mixing, accessibility |
| [ACCESSIBILITY_AND_UX.md](ACCESSIBILITY_AND_UX.md) | Inclusive controls, readability, motion, difficulty |
| [VERTICAL_SLICE.md](VERTICAL_SLICE.md) | Milestone scope, acceptance criteria, exclusions |
| [MILESTONE_STATUS.md](MILESTONE_STATUS.md) | Demonstrated implementation evidence |
| [TESTING_AND_RELEASE.md](TESTING_AND_RELEASE.md) | Automated, manual, performance, and release gates |
| [decisions/](decisions/) | Accepted architecture decision records |

Changelog is [../CHANGELOG.md](../CHANGELOG.md), not a second changelog in this folder.
