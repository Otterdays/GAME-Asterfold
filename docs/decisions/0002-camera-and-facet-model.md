# ADR-0002: Canonical world with presentation orbit and transactional facets

- Status: Accepted
- Date: 2026-08-25
- Owners: gameplay, rendering, level design

## Context

The game's signature is being present in a 2D-forward world that can turn and reveal depth. A naive implementation rotates the entire level root by 90 degrees. That couples the visual gesture to physics coordinates, navigation, particles, character facing, audio space, save positions, and floating-point transform accumulation. It also makes a small presentation desire responsible for nearly every world-system failure mode.

Pure free camera orbit is reliable but cannot make perspective a meaningful authored exploration verb. A flat orthographic view preserves map clarity but weakens parallax and spatial presence.

## Decision

Use three related but separate concepts:

1. **Canonical world:** the zone, physics, navigation, entities, and saved positions remain in fixed Y-up coordinates and never rotate as a root.
2. **Peek Orbit:** a presentation-only camera offset within authored limits. It changes neither movement basis nor gameplay state.
3. **World Turn:** an authored 90-degree camera transition followed by a transactional commit of a named facet. The facet may atomically change declared collision groups, navigation links, participants, interactions, safe positions, and presentation state.

The exploration camera uses a long-lens perspective, provisionally 18–24 degrees vertical FOV. Movement is camera-relative to committed facet yaw, not transient Peek yaw.

Facet state follows:

```text
IDLE -> PREPARING -> TURNING -> COMMITTING -> SETTLING -> IDLE
```

The commit has rollback data. Each reachable target has a validated player safe marker and reduced-motion presentation path.

## Rationale

- Peek satisfies everyday tactility and parallax without destabilizing controls.
- Authored turns create meaningful reveals and alignments while keeping level design finite and testable.
- Canonical coordinates simplify saves, pathfinding, physics, audio, particles, and debugging.
- Transaction boundaries make visual and collision truth change together at one controlled point.
- Long-lens perspective retains town readability while exposing real depth during motion.

## Alternatives considered

### Rotate the entire world root

Rejected because it spreads rotated coordinate concerns into every subsystem and makes dynamic participants difficult to reason about.

### Free 360-degree gameplay camera

Rejected as the primary rule because every composition, occluder, sprite direction, secret, NPC staging, and path would need to work from every angle. Peek retains a controlled version for presence.

### Orthographic camera

Rejected as the default because it weakens near/far scale and the desired miniature parallax. It may be reevaluated only if M1 long-lens tests fail readability or comfort.

### Render each facet as a separate complete scene

Rejected as the baseline because duplicated content and state synchronization would grow rapidly. Facet participants allow deliberate local variation while shared canonical elements persist.

## Consequences

- Level designers must author facet metadata, safe markers, occlusion, and navigation links.
- A World Turn is available only at declared anchors or zones with an explicit free-turn policy.
- Sprite direction is actor-world-facing relative to committed camera yaw and needs quantization hysteresis.
- Peek cannot be used to aim movement basis or expose essential interactions at a precise held angle.
- Dynamic changes require strong validators and repetition/rollback tests.
- The camera can still move beautifully, but spectacle remains within accessibility duration and reduced-motion alternatives.

## Validation

M1 proves long-lens presence and Peek. M2 reverses one Reveal turn at least 100 times, saves and loads both facets, forces rollback, checks collision/navigation/focus/sprite direction, and observes new-player route comprehension.
