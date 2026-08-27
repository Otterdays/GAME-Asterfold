# Accessibility and UX

Accessibility is a system constraint and acceptance criterion. It is not a separate mode that receives less design attention.

## Baseline commitments

- Complete keyboard and gamepad navigation without a mouse.
- Full remapping for gameplay and UI actions, including separate left/right World Turn inputs.
- Field play captures the mouse for Peek; Space+WASD Peek and gamepad right stick remain. First-person look uses `scout` (V / Controller Y) or the **Look around** button, then a map click or Confirm. Cancel leaves the scout before it returns to title.
- Subtitles/text for all spoken or essential audio information.
- Information is never communicated by color, sound, vibration, or motion alone.
- Text size, camera motion, screen shake, flashing, battle speed, and hold/toggle behavior are adjustable.
- The game can be saved and safely exited at frequent stable points.

## First-run flow

Before story content, the player can set:

- text size
- subtitle/caption behavior
- master and category volumes
- dynamic range
- screen shake
- camera motion / reduced-motion mode
- hold versus toggle preferences
- controller glyph family when auto-detection is incorrect
- high-contrast focus and combat indicators
- window mode, window resolution (720p through 4K when the desktop fits), UI scale, and presentation quality (default High 1920×1080)

The setup is skippable and all options remain available from title and pause menus. No setting requires loading a campaign.

## Controls

### Remapping

- Every semantic action can be rebound.
- The system warns about conflicts and identifies the affected context.
- Confirm and cancel can be swapped globally.
- Analog movement also has digital bindings.
- Stick dead zones and camera sensitivity are adjustable independently.
- Repeated tapping alternatives exist for any rapid-input interaction; the vertical slice should avoid such interactions entirely.
- Hold actions can become toggles where state remains understandable.

### Focus

- Every screen declares initial focus and cancel behavior.
- Focus remains visible at all times in controller/keyboard navigation.
- Disabled controls state why they are unavailable when focused.
- Closing a modal restores the control that opened it.
- Lists announce position and wrap behavior visually; unexpected wrap is avoided.
- Mouse movement does not thrash focus or input glyphs.
- Title Settings uses clickable **Video**, **Accessibility**, and **Controls** tabs. Only the selected page is visible. Initial focus is the tab bar so keyboard and gamepad can change pages without a mouse.
- Starting the walking diorama, metrics room, or map maker from title immediately disables every title control and covers the canvas with an input sink. Cancel, Confirm, menu, F10, and pointer clicks do nothing until the world exists and the activating press is released. Disabled buttons explain the lock in their tooltip. Focus is restored when the title is shown again. The title clearing stays visible for the hitch; this is not a separate loading screen.
- Title and shell `BaseButton` controls gold-lift and scale up on mouse hover. Hover and click also play short UI cues. The visual highlight remains if SFX/UI is muted. Mouse hover does not steal keyboard or gamepad focus.
- The equipment screen focuses its first slot on open, restores the slot row that opened an item picker, and steps back one level on cancel before closing. Field movement and mouse capture are released while it is open.
- Equipment slots always state their occupant in text and label an unoccupied slot **Empty**; a slot made unavailable by a two-handed weapon says so instead of appearing full. Slot state is never carried by colour alone. The paper doll conveys focus by drawing only the focused body region.

## Display

Window resolution and UI scale are independent, in the Sims 4 sense:

- **Window mode**: Windowed, borderless, or exclusive fullscreen. F11 and Alt+Enter (`toggle_fullscreen`) switch windowed and borderless only, so the shortcut never lands in exclusive fullscreen. Using the shortcut updates the Video tab control and the saved setting.
- **Windowed sizing**: Windowed mode fits the screen's usable rect and reserves title-bar height, so a desktop-sized resolution still shows window controls instead of masquerading as fullscreen.
- **Quit shortcut**: F10 (`quit_prompt`) opens an in-canvas confirmation panel instead of closing immediately. "YES, QUIT" receives focus first so Confirm (Enter or controller A) accepts, and Cancel, F10, or "NO, KEEP PLAYING" dismisses it. Both buttons are reachable by keyboard, controller, and mouse; the mouse is released while the prompt is open.
- **Resolution**: Desktop native, or a standard size that fits the current screen (720p through 4K). This is the OS window size. It does not replace presentation quality.
- **UI scale**: 80%, 100%, 125%, and 150%. HUD and menus layout against a fixed 1920×1080 UI reference; larger scale grows chrome without changing the window.
- **Presentation quality**: Low, Medium, or High. High is default. This scales 3D via `Viewport.scaling_3d_scale` (640/1920, 1280/1920, or 1.0). The title clearing stays 1920×1080.
- **Text scale** stays on Accessibility and multiplies font sizes on top of UI scale.

`user://settings.cfg` stores `accessibility`, `bindings`, and `video` separately. Headless runs skip window resize.

## Text and language

- Default body text targets at least an 18 px equivalent at 1080p.
- Supported text scales: 100%, 125%, and 150%; critical interfaces should tolerate 175% as an engineering test even if layout changes are needed.
- Line length target: 45–75 Latin characters for dialogue and prose.
- Player advances dialogue manually by default; auto-advance is optional and adjustable.
- Dialogue backlog is available during conversations.
- Speaker names, portraits, and directional tails make attribution clear.
- Typewriter reveal can be disabled; confirm during reveal completes the line before advancing it.
- UI is tested with pseudo-localization, long names, plural rules, and font fallback.
- Decorative fonts never carry long body text or critical numbers.

## Color and contrast

- Text and essential icons target WCAG-like contrast of at least 4.5:1 for normal text and 3:1 for large text/UI boundaries where the visual style permits; exceptions require direct readability testing.
- Party, enemy, danger, healing, status, and facet states each use icon shape and pattern in addition to hue.
- Provide high-contrast interaction focus and target outlines.
- Test grayscale plus common protan, deutan, and tritan simulations.
- Do not encode elemental or Calling relationships only as red/green or blue/purple pairs.

## Motion, camera, and flashing

Settings:

- Camera motion: Full / Reduced / Minimal.
- World Turn speed: Fast / Standard / Cinematic.
- Screen shake: Off plus at least two strengths.
- Battle camera cuts: Full / Essential only / Fixed.
- Motion blur: off by default for the target style.
- Flash intensity: Full / Reduced / Off for nonessential flashes.

Reduced World Turn replaces the orbit with anticipation, cover, viewpoint step, and settle. Minimal camera mode disables Peek auto-recenter animation and uses discrete offsets.

Ambient nature follows the same setting. Outside Full camera motion, tree crown sway stops, the bird flock freezes in place rather than disappearing so the town keeps its silhouettes, leaf fall stops emitting, and footfall dust and grass motes are silenced. None of it carries information, so nothing is lost when it is off.

Avoid repeated high-contrast flashes. No essential mechanic should require tracking an object during a fast camera move.

## Combat readability and assistance

- Battle can pause completely on player readiness by default.
- Adjustable battle speeds affect timeline advance and presentation separately where practical.
- Enemy intent includes icon, text label, target region, startup position, and danger tier.
- Inspect explains current statuses, resource changes, and the expected consequence of the selected action.
- Target previews display expected outcome ranges rather than hiding basic arithmetic.
- Action confirmation may be enabled for costly items, friendly fire, or irreversible commands.
- Common animations can be shortened after first use.

Optional assists alter challenge without shaming language:

- incoming damage: 100%, 85%, 70%
- timeline speed while choosing: pause, 25%, 50%, full
- stronger route hint timing
- retry with a temporary encounter-only boost

Assists do not block story, achievements in the vertical slice, or save compatibility.

## Navigation and cognitive support

- Current objective, relevant place, and last important event are summarized in the journal.
- Maps emphasize landmarks, loops, discovered services, exits, and player-added markers.
- A route hint points to the next known landmark rather than drawing a constant trail.
- NPC dialogue does not carry the sole copy of required instructions.
- World Turn anchors show reachable facet direction and preview the type of change once learned.
- Puzzle hints escalate in layers: reminder, observation, stronger relationship, then explicit solution.
- Tutorials can be replayed from the journal.

## Audio and haptics

- Independent Master, Music, SFX, Ambience, and Voice volumes.
- Full, Night, and Focused dynamic-range presets.
- Captions for essential offscreen cues with direction when useful.
- Haptic strength slider and off setting.
- No interaction relies on vibration timing.
- Repetitive high-frequency UI or battle cues have density controls and comfortable alternatives.

## Save, pause, and interruption

- Pause stops game-rule progression in field and battle except during explicitly uninterruptible file commit; the UI explains brief save activity.
- Autosave icon is visible but unobtrusive; never power off language can be localized and screen-reader friendly when platform support exists.
- Manual saves are allowed in safe field states and town interiors.
- On defeat, retry restores the pre-encounter snapshot including consumed items.
- On load, the journal provides a short “Previously” summary without forcing a cutscene.

## UX response targets

- Button press to focus/feedback: <= 100 ms.
- Opening common pause screens from warm state: <= 250 ms.
- Confirmed World Turn begins feedback: <= 100 ms even if transition setup continues.
- Invalid action explains itself in the same context; a sound alone is insufficient.
- Loading longer than 500 ms shows deliberate progress feedback; longer operations remain cancellable where safe.

## Feature acceptance checklist

For every new interaction or screen:

- Can it be reached, used, backed out of, and re-entered with keyboard and gamepad?
- Is initial and restored focus deterministic?
- Does 150% text fit or switch to a valid alternate layout?
- Are state and errors encoded beyond color/audio/motion?
- Does reduced motion preserve meaning?
- Can timing pressure be paused, slowed, or avoided when it is not the core challenge?
- Is required information recoverable after interruption?
- Are prompts semantic and updated for the active device?
- Has the result been tested at minimum resolution and with pseudo-localization?

Accessibility defects that block progress, conceal critical state, trap focus, or cause an unavoidable high-risk flash are release blockers.
