# ADR-0001: Godot 4.7.2 Standard with typed GDScript

- Status: Accepted
- Date: 2026-08-25
- Owners: project engineering

## Context

Asterfold needs first-class 2D and 3D composition, fast scene iteration, custom shader access, reliable controller input, data resources, headless automation, and a toolchain viable for a small team. Its defining presentation places sprite characters inside 3D environments and moves a long-lens camera through authored facet views.

Asterfold is a standalone game. Coupling it to a Java/Minecraft/Fabric runtime would constrain the game to another product's renderer, camera, content format, distribution, and controls without serving the standalone RPG design.

As of this decision, Godot 4.7.2 is the current stable patch published by the [official Godot release archive](https://godotengine.org/download/archive/). Pre-release 4.8 builds are not production baselines.

## Decision

- Place the standalone project under `game/`.
- Use Godot 4.7.2 Standard with Forward+.
- Use typed GDScript 2.0 for runtime and editor tooling.
- Pin the exact engine patch in CI and contributor setup documentation.
- Target Windows and Linux desktop first.
- Reconsider the engine version only through an upgrade ADR with import, render, performance, test, and save comparison evidence.

## Rationale

- Godot composes 2D resources, sprite-card rendering, 3D physics, cameras, shaders, UI, and scene tooling in one open project format.
- GDScript keeps the editor/runtime dependency surface small and supports headless tests and tools without a separate .NET editor/runtime requirement.
- Standard Godot retains a possible web demo path; a C# project would narrow current Godot web export options.
- Text scenes/resources and scripts are reviewable and automate well.
- Engine source access reduces the risk of a rendering blocker becoming opaque, though engine forks are not planned.

## Alternatives considered

### Unity with C#

Strong rendering and mature ecosystem, but adds licensing/account/tooling weight and encourages a larger dependency surface than this slice needs. It remains a viable fallback only if prototype evidence reveals a Godot blocker.

### GameMaker

Excellent 2D workflow, but the project's true 3D camera, collision, lighting, and authored topology make it a less natural fit.

### Java/LWJGL or Fabric

Offers low-level control but would require building and editorizing most scene, content, animation, UI, import, and render workflows. Fabric specifically would make Asterfold a Minecraft modification, which the product vision does not request.

### Custom engine

Maximum control with unacceptable risk to content iteration and vertical-slice timing.

## Consequences

Positive:

- The 2D/3D prototype can be proven early with a small code surface.
- Contributors use one primary editor and language.
- Runtime and content can remain portable and open.

Costs and risks:

- Billboard sorting, pixel stability, Forward+ performance, and import behavior require early measurement.
- Console shipping would require platform approval and a supported porting route; it is not promised.
- Godot minor releases can change imports and rendering, so the patch stays pinned.
- Commands run from the project root and must specify `--path game` so tools consistently target the Godot runtime.

## Validation

M0 proves clean import, headless test/validation entry points, export, controller input, and a metrics scene. M1 is the engine-fit gate: grounded sprite, long-lens camera, Peek Orbit, foreground occlusion, directional animation, and performance must all pass before content production.
