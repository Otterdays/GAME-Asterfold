# Art Direction

## Visual thesis

**Asterfold should look like a hand-painted adventure book assembled into a theatrical miniature, then gently turned in the player's hands.**

The visual system is not strict retro imitation. Character sprites keep deliberate pixels and expressive silhouettes; architecture uses low-complexity 3D forms, painted texture ramps, real depth, and restrained modern light. Camera movement reveals the construction instead of trying to disguise it.

## The visual hierarchy

At every gameplay view, readability follows this order:

1. Player and current interaction target.
2. Walkable route and immediate navigation boundary.
3. Hostile intent, hazards, and World Turn affordances.
4. Landmarks and story staging.
5. Atmosphere and decorative detail.

If fog, lighting, foreground art, particles, or texture noise reverses this order, reduce it.

## Camera language

### Exploration camera

- Projection: long-lens perspective, provisionally 18–24 degree vertical FOV.
- Typical pitch: 32–38 degrees downward.
- Composition yaw: authored per facet in 90 degree families.
- Target height: around the player torso, adjusted by camera volume.
- Distance: chosen per zone to preserve a readable character height, not a universal constant.
- Peek Orbit: up to 24 degrees horizontal and 8 degrees vertical from the authored view.
- World Turn: a 90 degree yaw arc, normally 0.55–0.8 seconds with authored anticipation and settle.

Long-lens perspective preserves the town-plan clarity of an illustrated map while still producing parallax and foreground movement. Orthographic projection may be used for isolated UI tableaux, never as an unreviewed zone-level shortcut.

Camera collision must preserve the subject. Use authored occluder fading or alternate camera rails before pushing the camera into a confusing overhead angle. Never let fast geometry collision cause repeated zoom pumping.

### Battle camera

Battle uses a small set of authored compositions rather than free orbit:

- Establishing view shows party, enemies, terrain context, and the Tempo Line.
- Command view moves subtly toward the active party member.
- Action views use short tracks with strict motion and duration budgets.
- Dangerous enemy startup earns a clear hold or push, not camera shake alone.

All nonessential battle cuts can be shortened. Repeated common actions should resolve quickly.

## Resolution and pixel treatment

- Reference internal render size: **640 x 360** for the vertical slice.
- Supported integer presentations: 1280 x 720, 1920 x 1080, and 2560 x 1440 with letterboxing or controlled crop policies.
- UI layout uses the internal canvas but must remain usable at high-resolution accessibility scale.
- World sprite reference density: **32 pixels per meter**.
- Standard adult sprite canvas: **48 x 64 pixels**, with a visible body height of roughly 54–60 pixels depending on silhouette.
- Props may use denser source art for hero details, but adjacent assets must share edge and texture rhythm.

The 3D render may use modest anti-aliasing before final nearest-neighbor presentation when it reduces geometry shimmer. Character art must remain crisp. Do not enforce “pixel perfect” rules that make rotation sparkle, distort silhouettes, or cause uneven camera motion. Judge stillness and motion separately.

## Character sprites

Characters are Y-axis billboarded cards placed in 3D space. They rotate around vertical only and remain grounded by a contact shadow.

### Direction set

Player and full party members use eight world-relative directions:

```text
N, NE, E, SE, S, SW, W, NW
```

NPCs may use four directions only when their staging never exposes a poor diagonal. Left/right mirroring is allowed for production efficiency unless costume asymmetry, handedness, or story detail makes it visibly incorrect.

The displayed direction is chosen by comparing actor world facing to committed camera yaw. A World Turn must not make a stationary actor appear to change its world orientation.

### Baseline animation budget

| Animation | Party member | Named NPC | Ambient NPC |
| --- | ---: | ---: | ---: |
| Idle | 4 frames x 8 dir | 4 x 4 | 2 x 4 |
| Walk | 8 x 8 | 6 x 4 | 4 x 4 |
| Run | 8 x 8 | optional | no |
| Interact / emote | 4–8, reusable set | 2–6 | 1–2 |
| Battle ready | 4–6 x battle-facing set | n/a | n/a |
| Hurt / down | 3–6 | as needed | n/a |
| Calling action | authored by action family | n/a | n/a |

Do not begin full sprite production at this maximum. Validate silhouette, direction switching, scale, and shader behavior with one hero before multiplying the budget.

### Sprite rendering rules

- Use alpha scissor or alpha hash for stable depth whenever the art permits.
- Extrude texture borders in generated atlases to prevent sampling seams.
- Use nearest filtering for sprite color; disable mipmaps unless a specific zoom range proves they are needed.
- Ground contact comes from a soft blob/contact shadow and foot placement, not from a thick universal outline.
- Rim or outline effects are contextual readability tools. They must not flatten every character into the same sticker.
- Hair, capes, and held objects may use layered cards only after measuring overdraw and direction behavior.

## Environments

### Shape language

- Primary architecture uses clear masses and slightly exaggerated proportions.
- Roofs, awnings, trees, and signs establish large rhythm before surface texture.
- Doorways and stairs are visually wider than realistic scale to support traversal clarity.
- Towns curve paths and offset facades enough to feel lived in while retaining a strong grid beneath art.
- Each zone has a distinctive silhouette family: roof pitch, vegetation crown, masonry profile, or industrial frame.

### Geometry metrics

- World unit: 1 meter.
- Logical authoring snap: 0.5 meters.
- Standard floor module: 2 x 2 meters.
- Standard exterior doorway: minimum 1.5 meters clear width and 2.25 meters clear height.
- Traversable stair rise: represented visually as steps but usually uses a simplified ramp collider.
- Primary path: 2.0 meters or wider; short secondary passages: 1.25 meters minimum.
- Collision is simplified and authored independently from decorative meshes.

### Textures and materials

- Environment reference density: 32 texels per meter, with 64 texels per meter reserved for focal props.
- Use small coordinated palette ramps per material family instead of unconstrained local color picking.
- Painted value grouping matters more than physically exact surface response.
- Roughness and normal detail remain broad. Tiny high-frequency normals fight the sprite language.
- Texture atlases and trim sheets serve coherent material families; avoid one-off 4K textures.
- World Turns may use subtle directional light and material response changes, but geometry identity remains stable.

Ground families are independently owned assets rather than inline zone colors. Grass, dirt road, stone, water, and other traversal surfaces each receive a discoverable scene/material/shader boundary when they need distinct art direction or reuse. Zone geometry composes those modules and owns their placement; it does not duplicate their shader implementation.

For the M1 Brindlewick prototype, grass uses broad world-scale value patches with restrained tuft marks. The dirt road is one continuous rounded network rather than overlapping rectangular meshes: broad worn-earth variation establishes the base, organic edge modulation softens the silhouette, compacted center wear and broken twin cart ruts imply use, and sharper directional scuffs plus two anti-aliased stone scales provide focal detail. The stones use stable world-sized cells with analytic edge smoothing so they read crisply at 640×360 without reverting to block noise or distant shimmer. Junctions must read as one traveled surface without darker overlap seams or stacked geometry. Surface variation must remain subordinate to Mara and the route and retain a clear grass/road value separation in grayscale.

### Lighting

- One directional key light defines time and facet readability.
- Baked or probe-supported indirect light grounds architecture.
- Local lights identify warmth, services, secrets, and story focus; they are not sprinkled uniformly.
- Character values must remain readable in every reachable facet. Use a controlled character light response rather than full emissive sprites.
- Shadow softness and resolution should evoke a miniature stage. Crawling, unstable pixel shadows are worse than simplified shadows.

## Color script

The vertical slice uses three connected palette states:

- **Brindlewick:** honey plaster, blue-gray slate, faded berry cloth, living green, warm window amber.
- **Thimblewood verge:** moss teal, desaturated fern, pale fungal cream, rare warning coral.
- **Bellroot Grotto:** mineral indigo, oxidized copper, lamplight gold, dangerous magenta reserved for unstable folds.

Gameplay semantics cannot rely on these hues alone. Shape, icon, value, and animation must carry the same information.

## World Turn presentation

A turn has six visual beats:

1. **Invitation:** anchor emblem breathes; nearby composition suggests a lateral continuation.
2. **Anticipation:** player motion settles, foreground reacts, audio narrows.
3. **Turn:** camera follows a clean eased arc with stable target height.
4. **Occlusion:** architecture, fold shimmer, or a purposeful wipe masks topology changes.
5. **Commit:** the new route becomes physically true and its landmark catches attention.
6. **Settle:** parallax and ambience resume before control returns.

The environment itself does not spin as a root transform. Individual authored pieces may hinge, slide, unfold, or relight to explain the facet change.

Reduced-motion mode uses a brief hold, midpoint occlusion, and near-instant viewpoint step. It communicates the same before/after state without a sweeping orbit.

## VFX

- Build VFX from graphic shapes, sprite sheets, mesh ribbons, and restrained particles.
- Effects begin with a readable anticipation, show the exact target region, and end cleanly.
- Friendly, hostile, restorative, and fold-related effects have different shape families in addition to palette.
- Screen shake is optional, intensity-scaled, and never the only hit feedback.
- Full-screen flashes respect the flash reduction setting and luminance-frequency limits.
- Common actions target <= 0.8 seconds of presentation after command confirmation; signature actions target <= 2.0 seconds outside first-use showcases.

## UI visual language

The interface resembles an expedition notebook built from folded vellum, enamel pins, inked icons, and narrow metal rules. It is clean rather than distressed.

The title shell is a static painted woodland clearing authored for the 640×360 canvas: large soft ellipses for grove and canopy, soft trunks, and ordered dither to hide sky banding. No TIME. High-frequency noise and hard step edges are forbidden here because canvas_items nearest-upscale turns them into blocky clusters. Focus is a high-contrast pale outline, not hue alone.

- Body text prioritizes a highly legible UI font; decorative pixel lettering is limited to headings and labels.
- Default body text is equivalent to at least 18 px at 1080p; scalable to 150% without clipping.
- Selected focus uses shape, movement, contrast, and optional sound.
- The Tempo Line uses portraits, action icons, directional movement, and time spacing; color is secondary.
- Menus preserve spatial consistency: party left, details center, actions right unless a screen has a tested reason to differ.
- Every decorative frame must survive localization expansion and large-text mode.

## Composition checklist

Before approving a zone view, capture every reachable facet at reference resolution and verify:

- Player silhouette is readable over the floor and foreground.
- Main route and nearest exit are understandable without UI arrows.
- Important interaction is neither hidden nor competing with brighter decoration.
- Foreground occluders frame the view and yield correctly when crossed.
- Sprite direction and feet remain grounded through Peek and World Turn motion.
- No cutout sorting halo, atlas bleed, shadow crawl, or obvious billboard flattening appears.
- Grayscale, common color-vision simulations, reduced motion, and 125–150% UI scale remain usable.
- The view stays within draw-call, light, and overdraw budgets.

## Anti-goals

- Do not imitate HD-2D branding, signature effects, or a specific commercial game's visual composition.
- Do not mix arbitrary asset-store realism with authored pixel forms.
- Do not use depth of field to conceal poor hierarchy; gameplay subjects remain sharp.
- Do not cover empty geometry with particles, bloom, chromatic aberration, or film grain.
- Do not turn every roof transparent. Author camera lanes and occlusion groups deliberately.
- Do not make all NPCs tiny variations of the hero rig; silhouettes must express place and personality.
