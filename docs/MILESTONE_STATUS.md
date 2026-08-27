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
- Controller-friendly title/debug shell with deterministic focus, version display, settings, quit, and readable structured-load failure presentation.
- Explicit `GameFlow`, `ContentDB`, and `InputRouter` autoload boundaries.
- Stable content registry and zone manifest validation.
- Separate `user://settings.cfg` accessibility/binding persistence.
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
- Camera-relative acceleration uses committed yaw only. Peek is presentation-only, clamps to ±24° horizontal / ±8° vertical, recenters after 1.25 seconds, and supports Full, Reduced, and Minimal modes.
- Foreground occluders use alpha hashing and fade to a readable minimum rather than changing collision or world truth.
- Settings provide 100/125/150% text scale, live camera motion selection, binding capture, conflict replacement, default reset, and confirm/cancel swapping.
- The automated runner currently exercises 98 unit/integration checks, including title/field/return flow, focus restoration, synthetic movement, missing-content presentation, persistence, stable IDs, manifest validation, binding conflicts, UI confirm/cancel synchronization, device hysteresis/disconnect fallback, movement boundaries, direction hysteresis, Peek timing, road-layout validation, rounded-corner distance, smooth joins, single-surface batching, and instance-local material setup.
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
