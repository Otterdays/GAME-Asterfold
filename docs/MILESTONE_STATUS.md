# Milestone Status

This file records demonstrated behavior. It does not redefine milestone scope or convert an untested path into a completed one.

## Snapshot

- Product version: `0.1.0-dev`
- Engine: Godot 4.7.2 Standard, Forward+
- Repository: local `main` branch with Git LFS; no remote or push
- Active implementation: M0 foundation plus the M1 walking diorama
- Out of scope: M2 World Turns, navigation topology changes, player saves, NPC content, dialogue, combat, and production art

## M0 foundation

Implemented and demonstrated locally:

- Exact-engine discovery through `ASTERFOLD_GODOT`, Desktop convention, or `PATH`.
- Controller-friendly title/debug shell with deterministic focus, version display, settings, quit, and readable structured-load failure presentation. [AMENDED 2026-08-27]: Settings uses Accessibility and Controls tabs. [AMENDED 2026-08-27]: Settings adds a Video tab for window mode, output resolution, UI scale, and presentation quality. [AMENDED 2026-08-27]: title keeps the clearing visible through zone instantiate and sinks input until the first idle field frame. [AMENDED 2026-08-27]: title plays an original lute-and-foley loop; shell buttons gold-lift on hover with bling and click cues.
- Explicit `GameFlow`, `ContentDB`, and `InputRouter` autoload boundaries.
- Stable content registry and zone manifest validation.
- Separate `user://settings.cfg` accessibility, binding, and video persistence.
- Headless import, typed-script checks, tests, content validation, runtime smoke, Windows/Linux debug exports, and Windows exported-runtime smoke through `validate.bat`.
- Dormant Windows/Linux GitHub Actions gate, ready for activation if a remote is added.
- Provenance validation for the original project-owned Mara prototype.

Pending manual acceptance:

- A real connected-controller pass covering navigation, movement, Peek, device swapping, unplug/reconnect, dead zones, binding capture, and controller-only return/exit. Synthetic keyboard and input-device tests pass, but they do not replace hardware acceptance.
- Hosted CI execution. The workflow cannot run before a remote exists.

## M1 walking diorama

Implemented and demonstrated locally:

- `zone.brindlewick_square` composes separate geometry, gameplay, and presentation layers from an explicit registry.
- Brindlewick's grass and dirt-road ground are separately discoverable surface scenes with external material/shader resources. Grass uses restrained world-scale painted variation. The road uses a validated zone layout, reusable network renderer, and shared style shader to produce rounded corners, continuous junctions, organic edges, cart-rut wear, and embedded stones without overlapping geometry; canonical ground collision and route readability remain unchanged.
- The 188 m primary loop targets approximately 47 seconds at 4 m/s and includes the bell-tower landmark, three declared depth layers, a constrained camera volume, foreground laundry and awning occluders, and simplified collision.
- Mara uses an original project-owned 48×64 sheet: two idle frames and four walk frames over five authored facings, with legal mirroring for eight displayed directions.
- Camera-relative acceleration uses committed yaw only. Peek is presentation-only, clamps to ±24° horizontal / ±8° vertical, recenters after 10 seconds, captures the mouse on field start, and supports Full, Reduced, and Minimal modes.
- Foreground occluders use alpha hashing and fade to a readable minimum rather than changing collision or world truth.
- Settings provide 100/125/150% text scale, live camera motion selection, binding capture, conflict replacement, default reset, and confirm/cancel swapping. [AMENDED 2026-08-27]: those options sit on Accessibility vs Controls tabs. [AMENDED 2026-08-27]: Video also exposes window mode, output resolution, independent UI scale (80/100/125/150%), and presentation quality. F11 toggles windowed and borderless.
- The automated runner currently exercises 98 unit/integration checks, including title/field/return flow, focus restoration, synthetic movement, missing-content presentation, persistence, stable IDs, manifest validation, binding conflicts, UI confirm/cancel synchronization, device hysteresis/disconnect fallback, movement boundaries, direction hysteresis, Peek timing, road-layout validation, rounded-corner distance, smooth joins, single-surface batching, and instance-local material setup. [AMENDED 2026-08-27]: the runner now exercises 142 checks; added live-zone map maker coverage, footprints, road-center edits, tooltip catalog, landmark/tree pieces, and title isolation. [AMENDED 2026-08-27]: title isolation is replaced by an Open Map Maker button check; runner now exercises 143 checks. [AMENDED 2026-08-27]: settings tab switch checks added; runner now exercises 194 checks (log `02_tests.log`). [AMENDED 2026-08-27]: those 194 checks run through six discovered `TestCase` suites with root-child leak and service-signal checks; grove invalid fixture now includes a known-species off-ground tree. [AMENDED 2026-08-27]: display/video settings checks added; runner now exercises 230 checks. [AMENDED 2026-08-27]: first-person scout and later suites; last passing log is 332 checks across 7 suites (`02_tests.log`). [AMENDED 2026-08-27]: the `nature_ambience` suite added ambient-life coverage; last passing log is 413 checks across 8 suites (`02_tests.log`). [AMENDED 2026-08-27]: title audio and button-hover checks added; last passing log is 458 checks across 9 suites.
- Brindlewick's trees are a validated three-species system rather than graybox primitives. `content/trees/` holds immutable species metrics; `brindlewick_tree_grove_layout.tres` holds 58 placements (6 hero specimens, 52 batched) checked against the dirt-road shoulder, the 0.5 m grid, ground bounds, trunk spacing, species scale range, yaw snap, and hero/batch budgets. `TreeGrove3D` builds the batched rows as seven MultiMesh draws plus one batched trunk-collision body, collision stays trunk-only, crown-fade specimens answer the existing camera occlusion mask, and crown sway is disabled outside Full camera motion. Evidence: `02_tests.log`, `03_content.log`, and the regenerated `builds/captures/m1/` set. Draw-call and overdraw re-measurement after the grove is still pending.
- Brindlewick has ambient life. `NatureAmbience` runs a nine-bird hearthfinch flock on seeded circuits anchored to authored trees as one MultiMesh, leaf fall from all 132 grove crown masses as one `GPUParticles3D`, and footfall motes that pick dust or grass from `DirtRoadLayout.signed_distance_m`. One baseline bird body is built from `BirdSpeciesDefinition` ratios with per-part UV tags, so the `slate_swift` variant adds no geometry. The map maker's **Nature** family places finch roosts, swift roosts, and leaf drifts, and every placed piece obeys camera-motion settings through the `ambient_motion` group. Evidence: `02_tests.log`, `03_content.log`, and the regenerated `builds/captures/m1/brindlewick_center.png`, which shows birds over the east roof. Draw-call and overdraw re-measurement after the particle work is still pending.
- Brindlewick geometry instances a `PlacementLayer` that rebuilds crate, lamp, planter, trees, and graybox buildings from `brindlewick_square_placements.tres`. The map maker that authors that resource is launched from title or `map_maker.bat` and is still not a `GameFlow` entry.
- The M1 capture harness records authored center, both Peek extremes, all motion modes, 100/150% UI, grayscale, and the eight-direction fixture at 640×360 internal resolution and 1920×1080 output.
- A 600-second rendered traversal on an Intel N150 / Intel Graphics system completed 35,997 samples at 1920×1080 output using Forward+ / Vulkan. CPU time was 0.670 ms p50, 1.095 ms p95, and 1.250 ms p99; GPU time was 3.974 ms p50, 5.067 ms p95, and 5.364 ms p99; draw calls were 35 p50, 52 p95, and 57 maximum. These results are within the M1 exploration budgets.
- After the rounded, high-definition road-network upgrade, a 60-second rendered regression traversal completed 3,602 samples on the same system. CPU p99 was 1.390 ms; GPU time was 5.745 ms p50, 7.036 ms p95, and 7.189 ms p99; draw calls remained at 49 maximum. The bounded batched mesh keeps the richer shader within the established exploration budgets. The original 600-second soak remains the long-duration acceptance record.

Pending manual acceptance:

- Real-controller coverage listed under M0.
- Human comfort/readability review of the generated capture set and a hands-on traversal. Automated captures prove composition and layout output, not subjective approval.
- Linux exported-runtime execution on a Linux machine or the prepared hosted workflow. The Linux artifact is produced and structurally validated on Windows.

## Reproduction

From the repository root on Windows:

```powershell
validate.bat
powershell -ExecutionPolicy Bypass -File game/tools/capture_m1_review.ps1
powershell -ExecutionPolicy Bypass -File game/tools/run_performance_soak.ps1
```

Generated evidence is intentionally ignored under `game/builds/` and `game/logs/`. The final completion note must include the measured soak percentiles and clean-clone result from the current revision.
