# Testing and Release

## Quality strategy

Testing protects player state, spatial trust, combat correctness, input access, and content integrity. Automation proves rules and catches regressions; representative play proves feel, communication, comfort, and art.

## Test layers

### Static and import checks

Run on every change:

- headless Godot import with no parser/import errors
- typed script parse and warning policy
- content/schema validator
- localization key and placeholder validator
- asset import/provenance validator
- forbidden large/binary file check outside approved LFS paths
- build version and manifest consistency

### Unit tests

Pure or platform-light tests cover:

- camera-relative movement transforms and direction quantization boundaries
- interaction candidate ranking
- facet transition validity and rollback decisions
- timeline scheduling and tie-breaking
- action validation, damage/resource math, statuses, Poise, defeat
- Calling unlock/equip rules
- inventory bounds and item effects
- quest condition/effect evaluation and idempotency
- stable ID parsing/resolution
- world piece catalog, footprint occupancy, dirt-road patch centers, and map-maker tooltip catalog
- save serialization, validation, and each migration step
- input glyph hysteresis and binding conflicts

Tests use fixed time and RNG sources. Floating-point comparisons declare tolerances.

### Integration tests

Small scenes and service harnesses cover:

- boot to title and new game
- load zone through `GameFlow`
- enter, reverse, save, and reload a World Turn
- zone exit/spawn pairing
- interaction to dialogue to quest effect
- field encounter to battle to results to field
- defeat retry snapshot
- menu focus restoration and input-device swap
- audio snapshot changes across pause, battle, and facet

### Content tests

Validators load the complete definition graph and report all errors where safe:

- unique IDs and resolved references
- valid bounds, tags, flags, localization, and placeholders
- quest dependency reachability and cycles
- encounter/ability/target legality
- zone spawn, exit, participant, safe-marker, and facet coverage
- UI initial/cancel focus declarations
- retired ID alias or migration coverage

### Smoke playthrough

A deterministic automation path checks critical transitions, not player feel:

1. Boot and create a save.
2. Enter each slice zone.
3. Commit each facet in each allowed direction.
4. Complete required dialogue/quest effects.
5. Resolve a controlled ordinary battle and boss battle.
6. Return to changed town state.
7. Save, restart runtime, and reload.

Automation may call debug-only semantic helpers but cannot mutate state in ways unavailable to real game flow without explicitly marking a fixture setup boundary.

## Visual verification

Capture at 640 x 360 internal resolution and at 1080p presentation:

- each zone/facet at authored camera center and Peek extremes
- sprite eight-direction spin, idle, walk, and turn transition
- each World Turn at anticipation, commit, and settle frames
- battle command, target, intent, inspect, damage, Poise break, and results
- every menu at 100%, 150%, pseudo-localized, and minimum supported window
- grayscale and color-vision simulations for critical gameplay views

Compare for composition and regressions, but do not rely on pixel-perfect screenshots for time-dependent 3D effects. Store capture metadata: engine version, build, GPU, resolution, quality, settings, zone/facet, and seed.

## Manual test charters

### Spatial trust

Try every turn near collision edges, with simultaneous input, after interaction focus, after loading, and repeatedly in both directions. Look for stranding, sudden collision, feet sliding, wrong sprite direction, occluder pops, stale prompts, follower duplication, and motion discomfort.

### Combat trust

Attempt invalid targets, simultaneous readiness, tied speeds, queued status expiry, interrupt at boundaries, defeat during delayed recovery, flee, retry, and animation skip. Compare preview with resolved result and verify the event log.

### Save trust

Save at every allowed boundary, fill slots, interrupt simulated writes, corrupt newest data, remove a referenced content ID in a fixture, migrate old versions, and inspect honest recovery messaging. Never test destructive cases against personal saves.

### Input and UI

Start with keyboard, Xbox-style controller, PlayStation-style controller where available, and mouse. Swap during every major screen, test drift/noise, remap conflicts, unplug/reconnect, cancel paths, focus restore, long text, and repeat rates.

### Accessibility

Play end-to-end with:

- reduced and minimal camera motion
- no audio
- no haptics
- screen shake and flashes off
- 150% text and pseudo-localization
- keyboard-only and controller-only
- high-contrast indicators and grayscale display
- slow/paused command selection

Passing isolated option screens is insufficient; settings must preserve the complete journey.

## Performance

### Reference tiers

Final exact hardware is recorded when available. Until then, test three declared profiles:

- **Reference low:** integrated or entry-level Vulkan-capable GPU, 4 physical CPU cores, 8 GB RAM, SATA SSD.
- **Reference target:** mainstream 6-core CPU, midrange discrete GPU, 16 GB RAM, SSD.
- **Development stress:** target hardware with debug overlays plus deliberately dense scene fixture.

Do not invent passing hardware claims. Record actual model, driver, OS, display mode, and power profile with results.

### Capture scenarios

- Brindlewick market at maximum resident density.
- Peek beneath the heaviest foreground overdraw.
- World Turn through commit with all participants.
- Bellroot's densest particles and local lights.
- Boss startup plus full party VFX and UI.
- Zone transition cold and warm.
- Save commit with a mature slice save.

Capture CPU/GPU frame time distributions, not only average FPS. Track p50, p95, p99, draw calls, primitives, texture/mesh memory, script time, physics time, and loading duration. Reference budgets live in `AGENTS.md`.

Any budget waiver names the scenario, measured devices, player impact, owner, and resolution milestone.

## Stability and soak

Before M5 candidate:

- 60-minute automated facet reversal and zone-transition soak.
- 100 deterministic boss simulations across varied legal builds/seeds.
- 25 save/write/load/migrate cycles per slot fixture.
- 60-minute idle/pause/resume and controller reconnect run.
- Repeated return-to-title/new-game/load cycle while watching retained nodes and memory.

The test runner detects leaked scene ownership, duplicate signal callbacks, increasing memory trends, and unhandled errors where instrumentation permits.

## Severity

| Severity | Meaning | Candidate policy |
| --- | --- | --- |
| Critical | data loss, security issue, unrecoverable crash, legal issue | zero allowed |
| High | blocked progression, broken save/load, inaccessible required flow, severe comfort risk, deterministic desync | zero allowed |
| Medium | meaningful feature failure with workaround, major visual/audio defect, budget regression | explicit owner; normally zero for slice path |
| Low | cosmetic or low-impact polish issue | triaged and documented |

## CI gate order

1. Repository and license/provenance checks.
2. Headless import and script parse.
3. Unit tests.
4. Content validation.
5. Integration tests.
6. Smoke playthrough.
7. Debug export and boot smoke.
8. Scheduled/RC visual, compatibility, soak, and performance suites.

Fail fast on broken import but preserve complete validator reports as artifacts.

## Versioning and builds

Use semantic product versions with build metadata where useful. During preproduction, `0.x.y` communicates instability. Save schema version is independent from product version.

Every package includes:

- product version and source revision
- engine version
- build timestamp in UTC
- platform and architecture
- debug/release channel
- save schema version

Build channels: development, playtest, candidate. Development builds expose diagnostics and cheats; candidate builds disable mutation cheats but retain safe diagnostic logging.

## Release candidate checklist

- Required CI gates pass from a clean checkout on the pinned engine.
- Candidate is built from a recorded immutable revision.
- Fresh install, update, uninstall/reinstall-with-saves, and path-with-non-ASCII tests pass.
- Save compatibility and corrupt-save recovery pass.
- Full controller/keyboard path and device reconnect pass.
- Accessibility end-to-end matrix passes.
- Visual facet contact sheets are approved.
- Reference performance captures meet budgets or approved waivers.
- No critical/high issue; medium slice-path issues resolved.
- All content references and localization keys validate.
- Every asset has approved provenance and license.
- Credits, third-party notices, privacy statement, version, and settings defaults are correct.
- Release notes describe known limitations honestly.
- Rollback artifact and prior compatible build are retained.

## Evidence standard

A completion report states:

- exact command/build tested
- test counts and result
- scene/content path manually exercised
- device, resolution, and relevant settings for visual/performance claims
- save schema/build used for persistence claims
- remaining risk or untested platform

“Works” without a named check is not release evidence.
