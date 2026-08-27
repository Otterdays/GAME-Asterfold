<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# My Thoughts

Decision rationale that is not (or not yet) an ADR. Newest notes at the top.

## 2026-08-27 — `/caveman ultra` as Rule 1

User asked that agents always use `/caveman ultra` first. The skill was not in this workspace, so the repo now vendors `.cursor/skills/caveman/SKILL.md` and an always-on `.cursor/rules/caveman.mdc`. Chat compression is the point. Docs, code, and commits stay normal prose because the skill itself forbids caveman in persisted files.

Changelog/docs maintenance remains mandatory; it is Rule 2, not dropped.

## 2026-08-27 — Agent status docs beside product docs

User workflow wants `SUMMARY`, `SCRATCHPAD`, `SBOM`, `STYLE_GUIDE`, `ARCHITECTURE`, `My_Thoughts`, and `debugs/`. Asterfold already had product specs under `docs/`. New files are additive. `ARCHITECTURE.md` is an index, not a second runtime law. Folder stays `docs/` (not a renamed `DOCS/`).

## Existing product thoughts (recorded)

- World-never-rotates is the load-bearing spatial invariant; Peek is presentation-only.
- Brindlewick road became a distance-field network to kill box-overlap seams and keep GPU time inside the soak budget.
- No C#: keeps web demo and standard-editor contributors possible (ADR-0001).
