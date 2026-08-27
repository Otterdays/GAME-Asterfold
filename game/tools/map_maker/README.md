# Internal map maker

This scene is an authoring tool. It is not a `GameFlow` state. Launch it with title **Open Map Maker** or `map_maker.bat` from the repository root.

It loads the live Brindlewick zone, then saves `content/zones/brindlewick_square/brindlewick_square_placements.tres` and the dirt-road layout. Pieces come from `content/pieces/piece_catalog.tres`. Hover help comes from `map_maker_tooltip_catalog.tres`.

Families: Things, Buildings, Trees, Nature, Roads. **Nature** holds ambient life: a finch roost and a swift roost each add a perch with birds circling above it, and a leaf drift sheds leaves from a ring over the cell. None of them block walking, and all of them stop moving when camera motion is set below Full. Footfall dust and grass motes are not pieces; they follow the walking actor, so move a road patch to change which ones appear. Nothing is selected at launch, so the first click does nothing until a piece is picked. The selected button is bright green. Click the selected palette button again to put the piece down.

Left-click the ground places the selected piece, or removes it if that same piece already sits on the cell. A translucent ghost follows the held piece. Amber overlay marks any dress piece under the cursor that can be edited; the overlay turns red while Delete mode is on. **Delete** (button or `Delete` key) switches left-click to erase. Short right-click deletes; right-drag still pans. `R` turns the piece under the cursor. Ctrl+S saves.

Undo and redo cover every world edit: placing, lifting, erasing, turning, and moving a road patch. Ctrl+Z undoes, Ctrl+Shift+Z or Ctrl+Y redoes, and the history keeps the last 64 edits. Undoing after a save marks the world unsaved again, because the file on disk no longer matches the scene.

Esc closes Settings first. With unsaved edits, the first Esc only warns; press it again to quit or Ctrl+S to save. The status line reports linked/editable coverage, current mode, placed piece count, undo depth, and whether the world is saved. A bottom-center toast confirms saves, undo, redo, grid toggles, and the unsaved-quit warning.

Keys: `Q`/`E` move to the previous or next family, `1`-`6` pick a piece in the active family, `G` toggles the authoring grid (0.5 m cells, brighter lines every 2 m, amber world axes), `F1` hides or shows the help line.

Camera: right-drag pans, middle-click orbits, wheel zooms (12-120 m), WASD pans. The window opens at most 1600x900, clamped to the usable screen area and centered.

The HUD builds its look in code from `map_maker_theme.gd`, so the tool needs no imported theme asset: translucent dark panels with a soft border, rounded buttons, a green fill on the selected piece, a red fill on Delete, and a visible focus ring for keyboard use.

Open **Settings** for cursor-follow (off by default) and idle restore to the default overview (10 seconds by default). Those options persist in `user://asterfold_map_maker.cfg`.

See `docs/CONTENT_PIPELINE.md`.
