<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# Style guide

Asterfold conventions win over generic language defaults. `AGENTS.md` is the contract. This file tells agents how to write in this repository.

## Preservation

Status docs in this folder keep this header:

`<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->`

Append or annotate. Do not rewrite history out of `SCRATCHPAD.md`, `SBOM.md`, `CHANGELOG.md`, or `debugs/`. Product specs may be updated to match demonstrated behavior; do not silently redefine incomplete vertical-slice work as complete.

## Chat vs files

- Chat: `/caveman ultra` (Rule 1).
- Files: normal prose. Code, comments, commits, docs, and PRs are not caveman-speak.

## GDScript and scenes

- UTF-8, LF, tabs, one final newline.
- Files and folders: `snake_case`. Classes: `PascalCase`. Constants: `UPPER_SNAKE_CASE`.
- `class_name` only for reusable domain or component types.
- Static types on properties, parameters, returns, collections, and signal payloads.
- Comments explain why, constraints, or non-obvious math. No syntax narration.
- Semantic input actions only: `move`, `confirm`, `cancel`, `menu`, `peek`, `fold_left`, `fold_right`.

## Limits (agent hygiene)

Prefer small files. Split before a script becomes the only place a subsystem can be understood. Do not add a generic `utils` dumping ground.

## Trace

When a comment must point at a doc, use a short path, not a private ticket idiom:

`# Constraint: world never rotates. See docs/decisions/0002-camera-and-facet-model.md.`

## Other languages

If JS/TS, Python, or shell appear in tools, follow that language's common conventions without dragging them into GDScript. Do not introduce npm/Python packages without updating `SBOM.md`.
