<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# Debug log 2026-08-27 — project checkout / agent docs

## What was inspected

- `AGENTS.md` still said preproduction / Milestone 0 with docs landing before a playable scaffold.
- `docs/MILESTONE_STATUS.md` and `game/README.md` already described M0 plus M1 Brindlewick as local.
- `docs/TECHNICAL_ARCHITECTURE.md` still treated Godot validation commands as a future Milestone 0 contract.
- No `SUMMARY`, `SCRATCHPAD`, `SBOM`, `STYLE_GUIDE`, `ARCHITECTURE`, `My_Thoughts`, `docs/README`, or root `README`.
- `/caveman` skill was not present in the workspace.

## What changed in this pass

Process and documentation only. No gameplay code.

## Residual risk

- Caveman ultra applies to chat. If an agent compresses commits or docs, that violates the skill boundary and Rule 1's file exception.
- Always-on `.cursor/rules/caveman.mdc` plus `AGENTS.md` Rule 1 plus the skill file can duplicate instructions; keep the rule file short.
- Controller hardware, hosted CI, and Linux runtime execution remain unproven, unchanged from `MILESTONE_STATUS.md`.
