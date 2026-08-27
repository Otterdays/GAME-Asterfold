<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# Summary

Agent start-here. Product law remains `AGENTS.md` plus the documents in [README.md](README.md).

## Snapshot (2026-08-27)

- Product: Asterfold (working title), `0.1.0-dev`
- Engine: Godot 4.7.2 Standard, Forward+
- Language: typed GDScript 2.0
- Phase: preproduction. M0 foundation and M1 walking diorama are implemented locally. Next target: M2 World Turns
- Repository: local `main`, Git LFS, no remote
- Agent contract: `/caveman ultra` is Rule 1 in `AGENTS.md`
- Internal map maker: `map_maker.bat` loads the live Brindlewick zone and edits placements plus roads; playable title does not mention it. Cursor follow and idle restore are map-maker Settings options.

## What runs today

Title shell (woodland clearing, centered wordmark and actions) launches Mara into graybox Brindlewick. Peek camera, eight-direction presentation, separate grass and dirt-road surfaces, accessibility settings, and `validate.bat` exist. This is not a game demo.

Out of scope until later milestones: World Turns, navigation topology changes, player saves, NPC content, dialogue, combat, production art.

## How to run (Windows)

1. Godot 4.7.2 Standard on Desktop, `PATH`, or `$ASTERFOLD_GODOT`
2. `launch.bat` from the repository root
3. Title: **Start Walking Diorama**
4. Move: WASD or left stick. Peek: mouse (captured on start), Space+WASD, or right stick. Idle 10s restores authored view. Field help: F1 / Start. Return: Escape / B

Validate: `validate.bat`

Internal map maker: `map_maker.bat` from the repository root. It is not a title entry.

## Quick links

- Contract: [../AGENTS.md](../AGENTS.md)
- Changelog: [../CHANGELOG.md](../CHANGELOG.md)
- Status evidence: [MILESTONE_STATUS.md](MILESTONE_STATUS.md)
- Scope: [VERTICAL_SLICE.md](VERTICAL_SLICE.md)
- Runtime map: [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md)
- Agent architecture index: [ARCHITECTURE.md](ARCHITECTURE.md)
- Game readme: [../game/README.md](../game/README.md)
- Active tasks: [SCRATCHPAD.md](SCRATCHPAD.md)
- Dependencies: [SBOM.md](SBOM.md)
- Caveman skill: [../.cursor/skills/caveman/SKILL.md](../.cursor/skills/caveman/SKILL.md)
