# Changelog

All notable Asterfold changes are recorded here. Entries describe demonstrated repository behavior; planned work remains in `docs/VERTICAL_SLICE.md`.

The project is currently pre-release, so completed work accumulates under `Unreleased` until a versioned build is cut.

## Unreleased

### Added

- Established the local Godot 4.7.2 M0 foundation, validation/export gate, title and settings shell, runtime service boundaries, and Git/LFS baseline.
- Delivered the M1 Brindlewick walking diorama with Mara locomotion, eight-direction presentation, long-lens Peek camera, foreground fading, capture fixtures, and performance-soak tooling.
- Added independently owned grass and dirt-road surface scenes, materials, and procedural shaders for Brindlewick.

### Changed

- Upgraded Brindlewick grass from a flat color to broad world-scale painted variation with restrained tuft detail.
- Rebuilt Brindlewick's dirt road as a single rounded distance-field network driven by a validated layout resource, eliminating box-overlap seams and separating route data, rendering behavior, and material styling.
- Deepened the dirt-road treatment with organically varied edges, continuous softened junctions, compacted center wear, broken twin cart ruts, sharply defined directional scuffs, and two anti-aliased scales of embedded gravel.
- Replaced the zone-sized road plane with one tightly bounded batched patch mesh, preserving seamless distance-field joins while reducing road-shader coverage and restoring GPU headroom.
- Made documentation and changelog maintenance the first repository contribution rule.

### Fixed

- Preserved required empty content directories so clean clones pass content validation.
