# Internal map maker

This scene is an authoring tool. It is not a `GameFlow` state. Launch it with title **Open Map Maker** or `map_maker.bat` from the repository root.

It loads the live Brindlewick zone, then saves `content/zones/brindlewick_square/brindlewick_square_placements.tres` and the dirt-road layout. Pieces come from `content/pieces/piece_catalog.tres`. Hover help comes from `map_maker_tooltip_catalog.tres`.

Families: Things, Buildings, Trees, Nature, Roads. **Nature** holds ambient life: a finch roost and a swift roost each add a perch with birds circling above it, and a leaf drift sheds leaves from a ring over the cell. None of them block walking, and all of them stop moving when camera motion is set below Full. Footfall dust and grass motes are not pieces; they follow the walking actor, so move a road patch to change which ones appear. Nothing is selected at launch, so the first click does nothing until a piece is picked. The selected button is bright green. Click the selected palette button again to put the piece down.

Left-click the ground places the selected piece, or removes it if that same piece already sits on the cell. A translucent ghost follows the held piece. Amber overlay marks any dress piece under the cursor that can be edited. **Delete** (button or `Delete` key) switches left-click to erase. Short right-click deletes; right-drag still pans. `R` turns the piece under the cursor. Ctrl+S saves. Esc closes Settings, then quits.

Camera: right-drag pans, middle-click orbits, wheel zooms (12-120 m), WASD pans. The window opens at most 1600x900, clamped to the usable screen area and centered.

Open **Settings** for cursor-follow (off by default) and idle restore to the default overview (10 seconds by default). Those options persist in `user://asterfold_map_maker.cfg`.

See `docs/CONTENT_PIPELINE.md`.
