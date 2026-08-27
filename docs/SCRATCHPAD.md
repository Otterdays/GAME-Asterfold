<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# Scratchpad

Active tasks, blockers, last actions. Compact older blocks into Prior when this file approaches 500 lines. Never delete history.

## Active (2026-08-27)

- Map maker loads live Brindlewick zone. Weighted coverage: 100% connected, 81% writable. Next leftover weight: spawns.
- Beginner families Things/Buildings/Trees/Roads. Tooltips are a separate overlay catalog.
- Play field captures mouse on start; Peek from mouse look; 10s idle recenter.
- Map maker Settings panel owns cursor-follow and idle restore.
- Internal map maker writes Brindlewick `*_placements.tres` and dirt-road layout. Title shell does not mention it.
- Title clearing shader: large soft shapes + dither; 360p upscale made noise/step look blocky.

## Prior (same day)

- Agent contract: Rule 1 is `/caveman ultra`. Skill vendored at `.cursor/skills/caveman/SKILL.md`. Always-on Cursor rule at `.cursor/rules/caveman.mdc`.
- Status docs added so the user `docs/` workflow exists beside Asterfold product docs.
- Handbook current-phase text corrected: M0 and M1 are local; next is M2.
- Next product work remains M2 World Turns. Do not start it from this pass.

## Blockers

- Real connected-controller hardware acceptance still pending (`MILESTONE_STATUS.md`).
- No git remote; hosted CI cannot run.
- Linux exported-runtime execution not proven on a Linux machine.

## Last 5 actions

1. Title shell: centered wordmark/actions on static woodland-clearing shader.
2. Map maker camera auto-locks to cursor, restores default view after 10 idle seconds.
3. Added internal map maker plus crate/lamp/planter dress components instanced by `PlacementLayer`.
4. Vendored caveman skill with Asterfold default intensity ultra.
5. Made `/caveman ultra` `AGENTS.md` Rule 1; changelog/docs rule is now Rule 2.

## Prior

- M0 foundation and M1 Brindlewick walking diorama shipped locally (see `MILESTONE_STATUS.md` and root `CHANGELOG.md`).

## Out-of-Scope Observations

- Generic user-rule defaults (JS camelCase, Python `uv`, React Native) do not govern Asterfold GDScript. `STYLE_GUIDE.md` records the override.
- `/caveman` was not installed in this workspace before 2026-08-27. The project now vendors the skill so Rule 1 is followable without a marketplace plugin.
