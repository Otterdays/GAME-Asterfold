# Changelog

All notable Asterfold changes are recorded here. Entries describe demonstrated repository behavior; planned work remains in `docs/VERTICAL_SLICE.md`.

The project is currently pre-release, so completed work accumulates under `Unreleased` until a versioned build is cut.

## Unreleased

### Added

- Field play captures the mouse on start and drives Peek from mouse look. Peek recenters to the authored view after 10 idle seconds. Keyboard Peek and right stick remain.
- Map maker Settings panel toggles cursor-follow and idle restore (default 10 seconds) and stores them in `user://asterfold_map_maker.cfg`.

- Added map-maker beginner families (Things / Buildings / Trees / Roads), live-zone loading, footprint occupancy, dirt-road center edits, and a separate tooltip catalog/overlay.
- Added Brindlewick landmark and tree components so the builder authors the same town the walking diorama loads, plus a weighted coverage score (100% connected, 81% writable).
- Added a static canvas-item woodland-clearing shader for the title shell (`assets/materials/ui/title_clearing.gdshader`).
- Map maker camera locks to the ground under the cursor at launch, then restores the authored default view after 10 seconds of idle follow or idle orbit/pan/zoom. Moving the cursor relocks; parked default does not keep retriggering.
- Added an internal Brindlewick map maker (`map_maker.bat`, `game/tools/map_maker/`) that writes zone placement data without appearing in the playable shell.
- Added three independently owned dress components (crate, lamp, planter), a shared piece catalog, and a `PlacementLayer` that instances Brindlewick's map-maker placements in the live zone.
- Vendored the `/caveman` skill at `.cursor/skills/caveman/SKILL.md` with Asterfold default intensity **ultra**, plus an always-on Cursor rule, so agents can follow Rule 1 without a marketplace plugin.
- Added a root README and agent status docs under `docs/` (`SUMMARY`, `SCRATCHPAD`, `SBOM`, `STYLE_GUIDE`, `ARCHITECTURE`, `My_Thoughts`, `docs/README`, `debugs/`).
- Established the local Godot 4.7.2 M0 foundation, validation/export gate, title and settings shell, runtime service boundaries, and Git/LFS baseline.
- Delivered the M1 Brindlewick walking diorama with Mara locomotion, eight-direction presentation, long-lens Peek camera, foreground fading, capture fixtures, and performance-soak tooling.
- Added independently owned grass and dirt-road surface scenes, materials, and procedural shaders for Brindlewick.

### Changed

- Rewrote the title clearing shader for 640×360 stretch: large soft grove ellipses, no high-frequency noise or hard step edges, plus ordered dither against sky banding.

- Made `/caveman ultra` the first agent contribution rule. Documentation and changelog maintenance is now Rule 2.
- Corrected handbook current-phase language: M0 and M1 are implemented locally; M2 World Turns is the next target.
- Documented `validate.bat` as the current Windows validation wrapper in `AGENTS.md` and `docs/TECHNICAL_ARCHITECTURE.md`.
- Upgraded Brindlewick grass from a flat color to broad world-scale painted variation with restrained tuft detail.
- Rebuilt Brindlewick's dirt road as a single rounded distance-field network driven by a validated layout resource, eliminating box-overlap seams and separating route data, rendering behavior, and material styling.
- Deepened the dirt-road treatment with organically varied edges, continuous softened junctions, compacted center wear, broken twin cart ruts, sharply defined directional scuffs, and two anti-aliased scales of embedded gravel.
- Replaced the zone-sized road plane with one tightly bounded batched patch mesh, preserving seamless distance-field joins while reducing road-shader coverage and restoring GPU headroom.
- Made documentation and changelog maintenance the first repository contribution rule. [AMENDED 2026-08-27]: that requirement remains; it is now Rule 2 after `/caveman ultra`.

### Fixed

- Preserved required empty content directories so clean clones pass content validation.
