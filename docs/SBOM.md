<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# SBOM

Software bill of materials for Asterfold. Update on every package install or remove. No runtime package manager is in use yet.

## Runtime / engine

| Component | Version | License / source | Notes |
| --- | --- | --- | --- |
| Godot Engine Standard | 4.7.2 | MIT (Godot) | Forward+ renderer. Pinned by ADR-0001. Not vendored in this repo. |
| GDScript 2.0 | Godot 4.7.2 | with engine | Typed scripts only. No C#. |

## Repository / toolchain

| Component | Version | Notes |
| --- | --- | --- |
| Git | local `main` | No remote as of 2026-08-27 |
| Git LFS | enabled | Editable binary source art and runtime audio |
| Windows validation wrapper | `validate.bat` | Locates exact Godot 4.7.2 Standard |
| Export templates | official 4.7.2 | SHA-256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` |

## Third-party runtime addons

None. `game/addons/` is unused. Adding an addon requires an ADR and a row here.

## Agent / editor assets in-repo

| Component | Version / pin | License | Notes |
| --- | --- | --- | --- |
| caveman skill | vendored 2026-08-27 from JuliusBrussee/caveman v1.10.0 skill text | MIT | `.cursor/skills/caveman/SKILL.md`. Chat style only. Not a game runtime dependency. |

## Changes

- 2026-08-27: Initial SBOM. No package install or remove. Added vendored caveman skill as an editor/agent asset.
