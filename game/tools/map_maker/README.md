# Internal map maker

This scene is an authoring tool. It is not part of the playable game, title shell, or `GameFlow`. Launch it with `map_maker.bat` from the repository root.

It loads the live Brindlewick zone, then saves `content/zones/brindlewick_square/brindlewick_square_placements.tres` and the dirt-road layout. Pieces come from `content/pieces/piece_catalog.tres`. Hover help comes from `map_maker_tooltip_catalog.tres`.

Families: Things, Buildings, Trees, Roads. Click ground to place or to slide a road. Right-click removes a piece. `R` turns. Ctrl+S saves. Esc quits.

Open **Settings** for cursor-follow and idle restore to the default overview (10 seconds by default). Those options persist in `user://asterfold_map_maker.cfg`.

See `docs/CONTENT_PIPELINE.md`.
