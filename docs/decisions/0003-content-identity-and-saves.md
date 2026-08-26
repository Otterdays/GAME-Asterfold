# ADR-0003: Stable content IDs and versioned domain-only saves

- Status: Accepted
- Date: 2026-08-25
- Owners: systems, content, QA

## Context

RPG content is frequently renamed, reorganized, rebalanced, and localized. Godot resource paths, node paths, array positions, and display names are convenient during early prototypes but brittle across production. Serializing Nodes or Resources directly also entangles saves with scene structure and makes migrations opaque.

Player saves are trust. A content rename or interrupted write must not silently destroy progress.

## Decision

- Give every cross-referenced or persistent content definition a unique namespaced stable `StringName` ID.
- Resolve IDs through a validated `ContentDB`.
- Treat definition Resources as immutable; store mutable runtime state separately.
- Serialize only primitives, stable IDs, and explicit value objects in a versioned save envelope.
- Make `SaveService` the only writer.
- Validate in memory, write temporary, read and validate temporary, rotate backup, then replace the main file.
- Keep rotating autosaves and a per-slot backup.
- Migrate schema sequentially with pure N-to-N+1 transformations and fixtures.
- Require alias or migration coverage before retiring a referenced content ID.

## Rationale

- Files and folders can move without breaking content or saves.
- Validators can report complete missing-reference graphs before runtime.
- Domain-only payloads are inspectable, testable, bounded, and portable.
- Sequential migrations localize compatibility reasoning.
- Temporary-first writes and backups reduce corruption risk.

## Alternatives considered

### Resource paths as identity

Easy initially but turns project organization into persistent player data. Rejected.

### UUID for every definition

Robust against naming collisions but hostile to authoring, reviews, debugging, and hand-built fixtures. Human-readable namespaced IDs provide enough stability for an authored project.

### Serialize complete Godot objects or resources

Reduces mapper code but tightly couples payloads to scripts, classes, and engine serialization behavior. Rejected for campaign saves.

### No compatibility before 1.0

Fast for prototypes but undermines meaningful playtests and prevents migration tooling from being proven early. Preproduction may intentionally invalidate throwaway fixtures, but M2 onward uses the real policy.

## Consequences

- Definition authors must choose IDs deliberately and cannot casually rename them.
- More explicit mapping code and validators are required.
- Save-schema and content-schema changes need tests and sometimes migrations.
- Display names and localization can change independently without save impact.
- Debug tools should display both stable ID and localized label.

## Validation

CI validates unique IDs and references. Tests round-trip mature save fixtures, run every migration, simulate failed or corrupt writes, retire IDs through aliases, and verify recovery selects the newest valid backup honestly.
