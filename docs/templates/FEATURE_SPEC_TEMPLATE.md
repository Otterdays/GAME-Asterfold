# Feature: Name

- Status: Draft
- Owner: discipline or person
- Milestone: M0–M5 or post-slice
- Pillar: product pillar strengthened
- Related ADRs: links

## Player outcome

One short paragraph describing what the player can perceive or accomplish when this is done.

## Scope

### Included

- Concrete behavior.

### Excluded

- Tempting adjacent behavior intentionally deferred.

## Rules

Define player-facing rules, state transitions, failure and recovery behavior, and edge cases. Separate fixed rules from tunable data.

## UX and accessibility

Describe keyboard and controller paths, focus, prompts, text, motion, audio/visual redundancy, timing alternatives, and relevant settings.

## Technical design

Identify domain owner, scene or presentation owner, data definitions, signals and contracts, persistence impact, cancellation, and performance concerns. Link a new ADR if the choice is repository-wide or difficult to reverse.

## Content impact

List new IDs, localization, art, animation, audio, VFX, zone, dialogue, tooling, and provenance needs.

## Acceptance scenarios

Use Given/When/Then or equally precise player-visible scenarios, including at least one failure or recovery path.

## Verification

- Unit tests.
- Integration and smoke tests.
- Manual or visual test scene and settings.
- Performance capture if applicable.
- Save and migration proof if applicable.

## Risks and rollback

State the leading failure signals, smallest fallback, and what would cause the feature to be cut or redesigned.
