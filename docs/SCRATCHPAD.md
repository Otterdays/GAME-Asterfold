<!-- PRESERVATION RULE: Never delete or replace content. Append or annotate only. -->

# Scratchpad

Active tasks, blockers, last actions. Compact older blocks into Prior when this file approaches 500 lines. Never delete history.

## Active (2026-08-27)

- Title adventurer roster shipped: **Play** opens three slots (1 writable, 2 locked with the reason in tooltip and status text; locked buttons stay focusable). Create honours only kit-backed looks. `CharacterRosterStore` writes `user://character_roster.json`; not campaign `SaveService`. Denser Mara kit: 12×5 field sheets (4 idle at 3 fps, 8 walk at 10 fps), starter brown tee / blue jeans / tan boots / short brown hair, separate hair atlases. Runner **520 checks / 10 suites PASS**. Content validator **15 assets / 1 zone PASS**. Field atlas 576×6720 is the correct 12-column size.
- [AMENDED 2026-08-27] Earlier note that `character_roster` had 1 failing check and that field atlas `(576, 6720)` mismatched expected `(288, 6720)` is resolved: names accept digits (`Wanderer 2`), and the validator expects 12 columns.

- Map maker comfort/beauty pass shipped: `MapMakerHistory` (64-deep whole-world snapshot undo/redo on Ctrl+Z / Ctrl+Shift+Z / Ctrl+Y, covering place, lift, erase, turn, road move), unsaved-work Esc guard, `MapMakerGrid` (`G`, 0.5 m cells, 2 m majors, amber axes, hidden by default), `MapMakerToast` (fading bottom-center confirmations), `MapMakerTheme` (one code-built HUD theme, green selected / red Delete / visible focus ring), red world hover overlay in Delete mode, `Q`/`E` family cycling, `F1` help toggle, status line with piece count + undo depth + saved state, and the removed hard-coded road-count hint.
- New `map_maker` suite: 18 checks, PASS. Runner measured 510 checks across 10 suites afterwards. Captures: `game/builds/captures/map_maker/ui_overview.png`, `ui_grid_and_toast.png` (windowed Vulkan run, no engine errors).
- [AMENDED 2026-08-27] Failure note from the map-maker pass is closed: `character_roster` and the 576-wide field atlas now pass with the rest of the gate.
- Out-of-Scope Observations: map maker still cannot edit spawn markers, grass, camera volumes, walk bounds, or lights; undo history is cleared on launch only, never persisted; toast and grid have no Settings-panel entries.

- Title audio: original 24 s Karplus-Strong lute/foley loop on title; UI hover bling + click; gold hover lift on shell buttons. Scene-owned `TitleShellAudio`, not an AudioDirector autoload.

- Title world-load lock: keep the clearing visible until `load_zone` / metrics instantiate returns; `WorldLoadBlocker` plus disabled title actions swallow clicks, Cancel, and F10 until the first idle field frame. Map maker uses the same lock around `change_scene_to_file`. No dedicated loading-screen UI.

- Nature ambience shipped: `NatureAmbience` sits under Brindlewick `Presentation` and is wired by `ZoneController`. Three components: `AmbientBirdFlock` (9 hearthfinches on seeded tree-anchored circuits, one MultiMesh), `LeafFallEmitter` (132 crown emission points, one GPUParticles3D), `FootfallMotes` (dust vs grass chosen by `DirtRoadLayout.signed_distance_m`).
- All three stop outside Full camera motion. `validate.bat -SkipExports` PASS. [AMENDED 2026-08-27]: `nature_ambience` suite is now 72 checks; runner total 413 across 8 suites.
- [AMENDED 2026-08-27] Bird body is now one detailed baseline built from `BirdSpeciesDefinition` ratios (head, beak, tapered body, two-segment swept wings, forkable tail) with per-part UV tags. New species = definition + material, no geometry code. `slate_swift.tres` is the first variant.
- [AMENDED 2026-08-27] Nature is authorable: map maker **Nature** family places `piece.bird_roost`, `piece.swift_roost`, `piece.leaf_drift`. Standalone flocks/leaf drifts anchor on their own node. Placed pieces join `ambient_motion`; `ZoneController` fans accessibility to that group. Piece catalog 11 to 14; palette four families to five.
- Open next: birds have no perching or calls, leaves fall from every tree at one rate, footfall has no audio hook. Product target is still M2 World Turns.

- Title clearing: long-lens painted diorama shader (path, hills, multi-mass crowns, field palettes). Still ColorRect, no TIME.

- Layered character kit shipped: `ActorLayerIds` (21 field layers, 31 doll layers with five fingers per hand), `generate_mara_layers.ps1` producing packed field/doll atlases plus the flattened fallback, `ActorLayerKit` at `content/actors/mara_layer_kit.tres`, and `SpriteLayerCompositor` flattening layers plus equipment into one texture. Field cards collapse fingers into hands; the world actor is still one quad.
- Equipment shipped: closed 16-slot `EquipmentSlotCatalog`, `ItemDefinition` / `ItemCatalog` (`content/items/item_catalog.tres`, one graybox item per slot), `EquipmentLoadout`, `PartyInventory`, and the `equipment` screen on **I** / controller Select. `E` and `Q` still fold. Equipment is listed in Settings Controls and remappable. 332 checks across 7 suites pass; content validator passes.
- Open next: equipment has no stats, no Callings, no persistence. Loadout dies on return to title until `SaveService` exists. Product target is still M2 World Turns.

- Fullscreen exit bug fixed: windowed branch of `DisplaySettings.apply_to_window` sets `MODE_WINDOWED` and `borderless = false` first, then sizes from `DisplayServer.screen_get_usable_rect`, shrinking by `WINDOW_DECORATION_MARGIN` (48 px) when the requested resolution fills the desktop. Aspect ratio preserved. Still unverified on real hardware.

- Window shortcuts implemented in `AppShell._input`: `toggle_fullscreen` (F11, Alt+Enter) flips windowed/borderless, applies, refreshes the Video tab via `SettingsScreen.refresh_from_settings()`, and saves. `quit_prompt` (F10) opens the `QuitPrompt` panel in `app.tscn` with "YES, QUIT" focused; Cancel/F10/"NO, KEEP PLAYING" dismiss. Suppressed while `SettingsScreen.is_capturing()`. `validate.bat` PASS.

- Map maker UX pass: window clamped to usable screen rect (max 1600x900, centered), palette auto-heights, piece row scrolls horizontally, no piece selected at launch, selected buttons bright green, Delete mode (button or `Delete` key) replaces right-click erase, right-click hold drags the camera, default camera distance 68 m (max 120 m), cursor-follow default off. `validate.bat` PASS.

- First-person look: `scout` / **Look around** map, then eye camera with crosshair. Does not move Mara.
- Tree system shipped: `TreeDefinition` species (`content/trees/`), `TreeGroveLayout` placements, `TreeBody3D`, `TreeGrove3D`, painted trunk/crown shaders, per-tree crown fade.
- Brindlewick grove: 58 placements (6 hero, 52 batched), 7 MultiMesh draws, trunk-only collision, validated against dirt-road shoulder and 0.5 m grid.
- `piece.shade_tree` now renders the painted civic-shade body, so map-maker trees match the zone grove.
- Title Settings uses Accessibility / Controls tabs; page content swaps on tab click. Initial focus is the tab bar. [AMENDED 2026-08-27]: Video tab owns window mode, output resolution, UI scale, and presentation quality.
- Map maker placement QoL: ghost, click-to-unplace, right-click delete, amber hover on editable pieces, unclipped palette labels.
- Beginner families Things/Buildings/Trees/Roads. Tooltips are a separate overlay catalog.
- Play field captures mouse on start; Peek from mouse look; 10s idle recenter.
- Map maker Settings panel owns cursor-follow and idle restore.
- Title **Open Map Maker** changes scene to `map_maker.tscn`. `map_maker.bat` still works. `GameFlow` stays out.
- Internal map maker writes Brindlewick `*_placements.tres` and dirt-road layout. [AMENDED 2026-08-27]: title now launches it.
- Title clearing: ColorRect shader (no SubViewport filter), crisp tree disks, dark menu plate. [AMENDED 2026-08-27]: SubViewport linear stretch was smearing the meadow.

## Prior (same day)

- Agent contract: Rule 1 is `/caveman ultra`. Skill vendored at `.cursor/skills/caveman/SKILL.md`. Always-on Cursor rule at `.cursor/rules/caveman.mdc`.
- Status docs added so the user `docs/` workflow exists beside Asterfold product docs.
- Handbook current-phase text corrected: M0 and M1 are local; next is M2.
- Next product work remains M2 World Turns. Do not start it from this pass.

## Blockers

- Real connected-controller hardware acceptance still pending (`MILESTONE_STATUS.md`).
- [AMENDED 2026-08-27] Git remote `origin` is `https://github.com/Otterdays/GAME-Asterfold.git`. Hosted CI still needs a successful Actions run after push; it was previously blocked by having no remote.
- Linux exported-runtime execution not proven on a Linux machine.

## Last 5 actions

0. Documented title roster + 12-column kit; names accept digits; 520 checks / 10 suites PASS; content validator PASS.
0. Title lute/foley loop, gold hover lift, hover bling, and click transients; scene-owned `TitleShellAudio`.
0. Title keeps the clearing up through zone instantiate and sinks title/field input until the first idle frame so a second click cannot miss.
0. Detailed the baseline bird body, added the slate swift variant, and made nature placeable through a map maker **Nature** family; `validate.bat -SkipExports` passes at 413 checks.
0. Added the Brindlewick nature ambience (hearthfinch flock, grove leaf fall, surface-aware footfall motes) with a `nature_ambience` suite and content validation; `validate.bat -SkipExports` passes at 377 checks.
0. Built the layered Mara kit, `SpriteLayerCompositor`, the 16-slot equipment catalog, and the **I** equipment screen; tests and content validation pass.
0. Added F11 / Alt+Enter fullscreen toggle and the F10 quit confirmation prompt, plus contract and display tests.
0. Synced Video/display docs to shipped behavior: window res vs UI scale vs 3D presentation quality, F11, `video` persist, 230 checks.
0. Documented discovered `TestCase` suites in `TESTING_AND_RELEASE.md`; synced handbook, architecture, pipeline, slice, and style docs.
0. Split `run_tests.gd` into discovered `TestCase` suites; leak/signal checks; grove off-ground fixture; 194 checks pass.
0. Implemented the Brindlewick 3D tree system and dressed the town; `validate.bat` passes and capture fixtures show the grove.
1. Split title Settings into Accessibility and Controls tabs so only one page is on screen.
2. Connected map maker to live Brindlewick zone; landmarks/trees/roads now authorable; separate tooltip catalog.
3. Added map maker camera follow/idle restore.
4. Redesigned title shell (woodland clearing / centered actions).
5. Vendored caveman skill with Asterfold default intensity ultra.

## Prior

- M0 foundation and M1 Brindlewick walking diorama shipped locally (see `MILESTONE_STATUS.md` and root `CHANGELOG.md`).

## Out-of-Scope Observations

- Map-maker palette still exposes one tree piece. Adding `orchard_tidemark` and `gate_sentinel` palette pieces needs catalog, tooltip, and test-count updates; deferred to keep the tree pass scoped.
- Tree crowns use `depth_prepass_alpha` so crown fading works without a second material family. Revisit if profiling shows transparency cost in a denser zone.

- Generic user-rule defaults (JS camelCase, Python `uv`, React Native) do not govern Asterfold GDScript. `STYLE_GUIDE.md` records the override.
- `/caveman` was not installed in this workspace before 2026-08-27. The project now vendors the skill so Rule 1 is followable without a marketplace plugin.
