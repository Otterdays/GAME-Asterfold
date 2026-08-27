# Vertical Slice Plan

## Purpose

The vertical slice is not a miniature content dump. It is the smallest polished journey that proves Asterfold's defining relationships:

- sprite character presence inside a convincing 3D diorama
- Peek Orbit plus a reliable, meaningful World Turn
- a memorable compact town
- visible encounters and deterministic Tempo Line combat
- enough Calling choice to produce two different party strategies
- stateful dialogue, quest, save/load, accessibility, audio, and return payoff

Target play time is **25–35 minutes** for a first playthrough and 15–25 minutes for a returning player.

## Slice content budget

| Area | Budget |
| --- | --- |
| Zones | Brindlewick hub, Thimblewood route, Bellroot Grotto, one small battle arena set |
| Committed facets | 2 per playable zone; 3 at the final grotto anchor only if earlier tests prove readable |
| Party | Mara plus two recruitable slice companions; battle supports four for future scale |
| Callings | Vanguard, Cantor, Wayfinder, Mender |
| Equipped depth | Active Calling + one borrowed technique + one Cadence where unlocked |
| Enemies | 4 ordinary archetypes, 1 elite variant, 1 boss |
| Encounters | 3 ordinary compositions, 1 optional elite, 1 boss |
| Quests | 1 main slice quest, 1 optional resident vignette |
| Named residents | 6–8, including party and authority figures |
| Interiors | 2 essential, 1 optional maximum |
| Items | 6–10 tactically distinct items; no loot tiers |
| Save states | 3 rotating autosaves, manual slot flow, defeat retry snapshot |
| Music | 6–8 cues/variants using prototypes until final approval |

If the slice exceeds a budget, remove or combine content before silently expanding production.

## Experience path

1. Title and accessibility setup.
2. Arrival at Brindlewick south gate; movement and interaction taught through staging.
3. Market loop introduces landmark, residents, bell problem, and Peek Orbit.
4. Bell-work alley anchor teaches a Reveal World Turn.
5. Party decision and preparation introduce Calling/equipment UI.
6. Thimblewood provides visible encounter, first battle, optional avoidance, and an Align turn.
7. Bellroot combines route observation, stateful dialogue, and two encounter patterns.
8. Boss telegraphs a fold attack; player uses intent and Poise break to create safety.
9. Return to Brindlewick at dusk shows changed staging, dialogue, music, route, and choice consequence.
10. Save-complete beat and a clear hook, not a trailer pretending the rest of the game exists.

Step 5 remains incomplete. A graybox equipment preview exists ahead of schedule: a layered Mara kit, the closed sixteen-slot catalog, a paper-doll screen on the `equipment` action, and one graybox item per slot. Callings, item stats, shops, battle Item, and equipment persistence are still unbuilt, so the step is not satisfied.

## Milestones

Milestones are dependency gates, not calendar promises.
Demonstrated implementation and acceptance status is recorded separately in [MILESTONE_STATUS.md](MILESTONE_STATUS.md); the checklist below remains the scope authority.

### M0 — Project foundation

Deliver:

- `game/project.godot` pinned to the approved engine baseline.
- Folder structure and import defaults.
- App shell, title/debug entry, error logging, and semantic input map.
- Headless test runner and content validator entry points. [AMENDED 2026-08-27]: the runner discovers `TestCase` suites under `game/tests/suites/`; see [TESTING_AND_RELEASE.md](TESTING_AND_RELEASE.md).
- CI for import, tests, validation, and a debug export.
- License/provenance manifest structure.
- Graybox metrics scene with controller movement and camera target.

Exit criteria:

- A clean checkout imports without errors using the pinned Godot version.
- Standard validation commands in `AGENTS.md` succeed.
- Keyboard and controller move a capsule in the metrics scene.
- The build displays its version and exposes a readable failure screen for missing required content.
- The runtime scaffold remains contained under `game/` and leaves project documentation intact.

### M1 — Walking diorama

Deliver:

- One Mara prototype sprite with idle/walk in eight directions.
- Long-lens camera rig, Peek Orbit, recenter, camera volumes, and foreground fade.
- Graybox Brindlewick primary loop with landmark and stable composition.
- Grounding shader/material test, alpha strategy, contact shadow, and direction hysteresis.
- Accessibility settings for camera motion, text scale shell, and remapping foundation. [AMENDED 2026-08-27]: Video settings cover window mode, output resolution, UI scale, and presentation quality.
- [AMENDED 2026-08-27] Ambient nature: one bird species circling authored trees, leaf fall from the grove, and surface-aware footfall motes. Presentation only, gated on camera motion, and authorable through the map maker's Nature family. Additional species are content, not new scope.

Exit criteria:

- The actor reads as grounded at every Peek extreme and through a 360-degree developer camera test.
- Movement direction never wobbles during Peek.
- No sprite direction flicker, alpha sorting halo, collision pop, or camera pumping in the test route.
- 10-minute traversal remains within reference frame budget.
- Reduced and minimal camera modes preserve navigation.

### M2 — One trustworthy World Turn

Deliver:

- `FacetController` transaction state machine.
- Reveal anchor with two facets, safe markers, participants, collision and navigation link swap.
- Full and reduced-motion presentation paths.
- Save/reload of stable facet state.
- Debug visualization and automated facet validation.

Exit criteria:

- Reversing the turn 100 times cannot strand, duplicate, drop, or overlap the player.
- Save/load from either stable facet restores identical logical state.
- Cancel/failure before commit returns safely; forced participant failure rolls back and reports it.
- Interaction focus and sprite directions are correct after every turn.
- Player testers infer the revealed route without explicit tutorial prose.

### M3 — Combat and party proof

Deliver:

- Headless deterministic battle domain, Tempo Line, commands, target validation, resources, statuses, Poise/interrupt, win/defeat/flee.
- Three party actors, four slice Callings, borrowed technique and Cadence slots.
- Two ordinary enemies and one boss test harness before final art.
- Battle UI with intent, timeline, inspect, controller focus, and action preview.
- Encounter entry, results, retry snapshot, and return to field.

Exit criteria:

- Fixed seeds produce identical battle event logs across repeated headless runs.
- No legal command can target an invalid/defeated entity unless its definition explicitly permits it.
- Two distinct party configurations can beat the boss test without level grinding.
- A new tester predicts the boss's dangerous action and identifies at least one valid response.
- All battle flows work with keyboard/gamepad and 150% text.

### M4 — Content-complete graybox

Deliver:

- Full slice route, all encounters, quest and dialogue states, town return, optional vignette.
- Zone transitions, autosaves/manual save, migration fixture, journal, services.
- All World Turn anchors in graybox.
- Temporary but license-safe audio and art.
- Full content validation and playthrough automation for critical state transitions.

Exit criteria:

- Three consecutive fresh playthroughs complete without editor intervention.
- Save/load works at each permitted boundary and defeat retry restores pre-encounter inventory.
- Main route is completable with every legal initial Calling assignment.
- No dead quest state, broken spawn, invalid reference, focus trap, or missing reduced-motion path.
- First-time median play length is inside target range without mandatory grinding.

### M5 — Art, audio, polish, and candidate

Deliver:

- Approved sprite, environment, UI, VFX, music, ambience, and SFX for the slice.
- Final lighting and all facet capture reviews.
- Tutorial and pacing revision based on observation.
- Performance, accessibility, compatibility, and soak passes.
- Signed/versioned candidate packages and release notes.

Exit criteria:

- All gates in `docs/TESTING_AND_RELEASE.md` pass.
- Representative players meet the success measures in `docs/VISION.md`.
- Reference hardware holds performance budgets in town, turn, and boss captures.
- No critical/high accessibility, save, progression, crash, legal/provenance, or content-validation issue remains.
- Every shipped asset has source and redistribution rights recorded.

## Vertical-slice acceptance scenarios

### Presence

From Brindlewick's gate, the player can walk beneath foreground elements, Peek in both directions, see parallax across at least three depth layers, and remain visually grounded and in control.

### Turn

At the bell alley anchor, the player can preview and commit a right turn. The route becomes traversable only at commit, the actor remains safe, interaction focus updates, the camera settles on a readable landmark, and the turn reverses.

### Battle strategy

Against the Bellroot guardian, the UI exposes a dangerous startup. At least three strategies—Poise break, Guard/cover, or timeline delay—can protect the threatened party member when supported by a sensible build.

### Consequence

After rescue, Brindlewick changes to dusk presentation; Ori, Rusk, at least two residents, the bell sound, and one route/interaction reflect completion and the player's dialogue choice.

### Recovery

At every stable boundary, save, quit, relaunch, and load restores zone, facet, party, quest, inventory, settings, and playtime. Corrupting the newest autosave causes the prior valid autosave to be offered with an honest warning.

## Out of scope for the slice

- Full overworld or chapter-select map.
- More than three active party members in content, even though runtime supports four.
- Reserve-party Shift outside test content.
- Invert World Turn verb.
- Crafting, housing, fishing, romance, reputation simulation, or day/night cycle.
- Random/procedural dungeons.
- Online features, telemetry, cloud saves, achievements, or platform SDKs.
- Console builds, mobile, or Steam Deck certification.
- Full voice acting.
- Localization beyond pseudo-localization and pipeline proof.
- Final full-game Calling count or balance.

## Risk register

| Risk | Signal | Mitigation / kill criterion |
| --- | --- | --- |
| Billboard sprites look detached | feet slide, cards feel flat during Peek | M1 prototype before content; test contact shadow, light response, direction set. If unresolved, reduce orbit and test crossed-card/limited mesh alternatives. |
| Rotation causes discomfort | testers avert gaze or avoid turning | reduced/minimal modes from M1; shorter arcs and occlusion. Mandatory turns remain untimed. |
| Facet topology becomes brittle | stranded actors, nav rebuild spikes | canonical world, transactional commit, authored links, safe-marker validator. Cut dynamic physics participants before weakening invariants. |
| Art workload multiplies by direction | animation backlog blocks slice | one hero budget test, legal mirroring, shared action families, strict named-NPC tiers. Reduce unique frames before reducing directional correctness. |
| Combat scope outruns content | many abilities lack meaningful enemies | four Calling kits with few strong verbs; boss test in M3. Cut abilities that do not create a decision. |
| Town is pretty but confusing | repeated wrong exits, map dependence | landmark and loop test in graybox; facet contact sheets; remove equivalent exits and decoration before adding arrows. |
| Godot upgrade churn | importer/render behavior changes | pin 4.7.2; upgrade only by ADR with comparison branch and save/import tests. |
| Project layout is damaged | runtime files leak outside `game/` or overwrite project documentation | keep the Godot runtime under `game/`; treat root documents as project-level source of truth. |
| Inspiration becomes imitation | recognizable layout, icon, melody, terminology | originality review and asset provenance; redesign early rather than cosmetically altering copied structure. |

## Scope change rule

A proposed addition must identify which slice acceptance scenario it improves and what equal-or-larger work leaves the slice. “It will be needed later” is not enough. Full-production planning begins only after M5 evidence is reviewed.
