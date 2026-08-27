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
- Tests: `run_tests.gd` discovers eight `TestCase` suites; details in [TESTING_AND_RELEASE.md](TESTING_AND_RELEASE.md)
- Internal map maker: `map_maker.bat` or title **Open Map Maker** loads the live Brindlewick zone and edits placements plus roads. `GameFlow` still does not own it. Cursor follow and idle restore are map-maker Settings options.

## What runs today

Title shell (distant woodland clearing at High 1920×1080 by default, 640×360 Low still allowed) launches Mara into graybox Brindlewick. A quiet original lute-and-foley loop plays on the title; buttons gold-lift on hover with a bling and a wood click. The clearing stays up through the zone hitch; title actions are locked so a second click cannot miss. Peek camera, eight-direction presentation, separate grass and dirt-road surfaces, a validated 58-tree grove around the town, ambient nature (a hearthfinch flock circling the trees, leaves drifting from every crown, and dust or grass motes under Mara's stride), tabbed Video/Accessibility/Controls settings, and `validate.bat` exist. This is not a game demo.

Mara is now a layered humanoid card (head, torso, stomach, waist, pelvis, and per side shoulder, upper arm, forearm, hand, thigh, knee, calf, foot; five fingers per hand exist at paper-doll density). A graybox equipment screen opens on **I** and covers sixteen slots including a necklace, four rings, one glove set, and one boot set.

Out of scope until later milestones: World Turns, navigation topology changes, player saves, NPC content, dialogue, combat, production art. Equipment has no stats, no Callings, and no persistence; the loadout resets on return to title.

## How to run (Windows)

1. Godot 4.7.2 Standard on Desktop, `PATH`, or `$ASTERFOLD_GODOT`
2. `launch.bat` from the repository root
3. Title: **Start Walking Diorama**
4. Move: WASD or left stick. Peek: mouse (captured on start), Space+WASD, or right stick. Look around: **Look around** / V / Controller Y, then click the map. Idle 10s restores authored Peek. Equipment: I / Controller Select. Field help: F1 / Start. Return: Escape / B

Validate: `validate.bat`. Tests: `godot --headless --path game --script res://tests/run_tests.gd` (458 checks, 9 suites).

Internal map maker: `map_maker.bat`, or **Open Map Maker** on the title screen.

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
