# Game Design

This document owns player-facing systems and their relationships. Exact numbers are tuning data; the rules and intent below are the contract.

## Core game states

```text
Boot -> Title -> Load/Start -> Field
Field <-> Dialogue
Field <-> Menu
Field -> Battle -> Results -> Field
Field -> Transition -> Field
Any safe state -> Save/Load boundary
```

The game never saves halfway through a facet commit, scene transition, battle action resolution, or cutscene animation. It records the last stable logical state and resumes presentation from there.

## Title adventurer roster

Preproduction title identity is not a campaign save.

- **Play** opens a three-slot roster. Slot 1 is writable. Slots 2 and 3 stay locked until party companions exist; focusing a locked slot states `Locked. Party companions unlock in a later milestone.`
- Create asks for a display name (2–16 characters: letters, numbers, spaces, hyphens, apostrophes; unique on the roster, case-insensitive) and cycles looks the layered kit can honour: hair style, hair colour, skin, shirt, jeans, boots. Default look is a brown t-shirt, blue jeans, tan boots, and short brown hair. Default name is `Wanderer`, then `Wanderer 2`.
- A live preview shows the composed card. `fold_left` / `fold_right` (and on-screen turn buttons) rotate the preview. Walk preview is still while reduced camera motion is on.
- Callings, extra faces, gender options, and equipment persistence are not title-creation features.
- Roster identity lives in `user://character_roster.json`. Campaign zone, inventory, and quest state still wait for `SaveService`.

## Field exploration

### Movement

- Eight-direction analog movement on the world XZ plane.
- Digital input resolves to eight directions with normalized diagonal speed.
- Default travel speed: 4.0 m/s; context acceleration and deceleration should feel responsive, not slippery.
- The player avatar faces movement direction unless an interaction, cutscene, or target focus temporarily owns facing.
- Party followers are represented for warmth but never create collision or block navigation.
- Walkable spaces use generous collision margins; decorative art must not make a visually open route physically closed.

Movement is camera-relative for the player and immediately transformed into canonical world-space intent. Actor state and saves never store screen-relative direction.

### Interaction

One context action handles talk, inspect, open, and confirm. Candidate interactions are ranked by:

1. Explicit focus from a recent directional input.
2. Distance within the interaction cone.
3. Angle from player facing.
4. Designer priority for overlapping candidates.

The chosen target receives a subtle focus mark before confirmation. Important actions state their result in a verb phrase where ambiguity exists: “Board ferry,” “Turn east,” or “Leave grotto.”

### Camera presence: Peek Orbit

Peek Orbit is available through captured mouse look, the right stick, or assigned digital controls in normal safe exploration.

- Default range: 24 degrees left/right and 8 degrees upward/downward from the zone's authored composition.
- The camera follows a damped orbit, never changes collision or route state, and recenters after 10 seconds without Peek input.
- Peek can expose visual hints and provide parallax, but essential interactables cannot require holding an exact angle.
- Indoor rooms may reduce the range through authored camera volumes.
- A “Reduced Camera Motion” option replaces smooth motion with three stepped offsets and removes automatic overshoot.

Peek is the everyday answer to “I want to feel inside this 2D world.” It is tactile presentation, not a puzzle state.

### First-person look

Look around is a presentation-only scout. The player opens a top-down map of the current zone, clicks (or confirms) a point, and views from that ground-relative eye height with a center crosshair and no visible body. It does not move Mara, change collision, or commit a facet. Cancel or Leave view returns to the diorama camera.

## World Turns

World Turns are authored, meaningful quarter-turn changes to a zone's active **facet**. They are not arbitrary rotation of world transforms.

### Player rule

- A fold emblem indicates that the current position permits a turn.
- Pressing `fold_left` or `fold_right` requests the neighboring valid facet.
- The game previews turn direction, temporarily locks locomotion, rotates the camera 90 degrees, commits the target facet, and settles control.
- A facet may change visible geometry, collision, navigation links, interaction availability, NPC staging, music coloration, and secrets.
- Objects never visibly pop during the readable portion of the turn. Occlusion, unfolding animation, light, particles, or deliberate material transitions cover state changes.
- The party cannot be placed inside new collision. Each anchor defines validated safe positions for every reachable facet.

### Spatial grammar

Every World Turn belongs to one of four understandable verbs:

- **Reveal:** foreground structure moves out of the composition and exposes a hidden route or resident.
- **Align:** separated ledges, stairs, light beams, or mechanisms become connected in the target facet.
- **Invert:** an apparent front/back relationship changes which surface can be approached.
- **Reframe:** the physical route is unchanged, but the new view reveals story information, an interactable, or a battle advantage.

The vertical slice teaches Reveal, then Align, then combines Reveal with a timed enemy telegraph. Invert is reserved for later production.

### Fairness rules

- A mandatory turn is previewed by composition, environmental motion, NPC language, or a visible emblem.
- The target result must be at least partially inferable before committing.
- A turn is reversible unless a clearly signaled story event consumes or breaks the anchor.
- Repeated failed turns cannot damage the party or reset unrelated progress.
- Camera motion can be sped up, stepped, or reduced; puzzle timing never depends on enduring the animation.

## Encounters

Enemies appear in the field as readable encounter representatives. Touching or deliberately engaging one starts battle.

- Most encounters can be avoided using space and timing.
- Recently escaped or defeated encounters do not immediately respawn on camera.
- Contact direction may grant a small opening timeline advantage, but never a full unwarned party wipe.
- Quest or boss encounters require explicit confirmation and establish a nearby retry point.
- The vertical slice targets 60–120 seconds for ordinary encounters and 4–6 minutes for its final battle.

## Battle: the Tempo Line

Battle is command-based and resolves on a visible continuous timeline called the **Tempo Line**.

### Turn flow

1. Each combatant advances toward `READY` according to effective speed.
2. At `READY`, a player combatant pauses battle according to the selected battle-speed option and opens commands.
3. Each action displays its startup, target, potency category, tags, and **beat cost** before confirmation.
4. The actor begins any startup period. Interruptible actions clearly expose an interrupt marker.
5. The action resolves from deterministic battle state.
6. The actor returns to the timeline at a position based on beat cost and modifiers.

Animation may lag logical resolution only within a controlled presentation queue. Input never advances a battle while required state is visually ambiguous.

### Core resources

- **Vitality:** defeat at zero. Restored through abilities, items, and rest.
- **Focus:** shared per-character ability resource. Begins partially filled, grows through basic actions and exploiting intent, and does not encourage hoarding between ordinary battles.
- **Guard:** a temporary mitigation value that is consumed before Vitality and usually expires at the actor's next ready point.
- **Poise:** enemy resistance to interrupts. Specific actions damage Poise; reaching zero cancels an exposed startup and delays that enemy. Poise then resets with short resistance to repeat locking.

No resource is communicated by color alone. Text, icon shape, fill pattern, and motion all contribute.

### Action families

- **Strike:** immediate, reliable actions that build Focus.
- **Technique:** Calling-granted actions with a Focus or condition cost.
- **Guard:** defensive stance, cover, counter preparation, or timeline manipulation.
- **Item:** consumes a party inventory item; common recovery items have a quick but nonzero beat cost.
- **Shift:** once unlocked, swap a reserve party member or change formation at a meaningful timeline cost.
- **Flee:** visible success calculation for eligible encounters; failure moves the acting member back on the timeline but never steals hidden currency.

### Intent and challenge

Enemies show their next action family, target pattern, startup, and danger level unless a specific authored trait hides one element. The game asks the player to respond to disclosed problems, not memorize surprise deaths.

Difficulty comes from overlapping timelines, target pressure, resource tradeoffs, formation, and build interaction. It does not come from inflated health, frequent unavoidable status loss, or mandatory grinding.

## Party building

### Characters

Characters have fixed personal identity:

- A small personal stat tendency.
- One signature field interaction or social lens.
- One personal battle trait that remains useful across Callings.
- Story relationships and dialogue independent of equipped role.

Identity should affect play without trapping a character in a permanent mandatory job.

### Callings

A **Calling** is a learned discipline that provides:

- A stat profile and equipment permissions.
- A compact command set of four to six actions.
- A mastery track with techniques and one capstone.
- One passive **Cadence**.

A character equips one active Calling and, after mastery begins, one borrowed technique plus one learned Cadence from other Callings. Limited slots create meaningful combinations and keep command menus readable.

Vertical-slice Callings:

- **Vanguard:** guards allies, redirects pressure, and converts consumed Guard into strong deliberate hits.
- **Cantor:** uses short refrains that strengthen the next compatible party action and manipulate Focus.
- **Wayfinder:** exploits enemy intent, acts cheaply, and marks timeline openings.
- **Mender:** restores, clears conditions, and plants delayed recovery at a future point on the Tempo Line.

Names and kits are working designs and require playtest validation; their distinct tactical verbs are more important than familiar class silhouettes.

### Growth

- Character level provides modest baseline durability and prevents content from becoming numerically brittle.
- Calling Insight unlocks abilities; it is awarded for completing encounters while using a Calling, not for repeating a specific move.
- Story milestones unlock new Callings and party options.
- Gear changes tactical properties more often than raw tier. A new item should enable a choice, solve a problem, or complete a visual identity.
- Respeccing learned Cadences and borrowed techniques is free outside battle.

There are no missable permanent build points in the vertical slice.

## Town design grammar

Every settlement is built for memory rather than acreage.

### Required structure

- One dominant landmark visible from at least two arrival paths.
- A primary loop that returns to its origin within 45–75 seconds of walking.
- Two or three short spokes from that loop.
- One early locked or obscured shortcut that later collapses travel time.
- A clear services cluster without making the town feel like a menu lobby.
- No more than three visually equivalent exits from a single plaza.
- At least one optional interior or edge space whose reward is character, not loot.

### Residents

- Named story residents have a desire, routine implication, verbal texture, and at least two state changes.
- Ambient residents communicate place in one or two lines and should not impersonate quest markers.
- Dialogue changes in small batches after chapter beats so revisiting a town feels acknowledged.
- NPC schedules are event-state swaps, not a full clock simulation during the vertical slice.

### Services

Save, rest, equipment, Calling adjustment, and quest recall must be available through both diegetic locations and fast menu paths once discovered. Flavor should not make routine party maintenance tedious.

## Quests and narrative choice

- Main goals use a visible next step, location hint, and relevant character.
- Side stories target 10–25 minutes and end in a changed resident, space, route, or relationship.
- Objectives describe outcomes, not exhaustive instructions.
- Choices affect local relationships, resources, dialogue, and routes before they claim to alter the entire ending.
- No quest expires because the player explored slowly unless the deadline is explicit, opt-in, and mechanically visible.

## Failure and recovery

- Defeat offers retry from the current encounter, load, or return to the last safe point.
- Encounter retry restores the party and consumables to their pre-engagement snapshot.
- Falling from a navigable edge returns the player to the last grounded safe marker with a brief penalty-free transition.
- Puzzle reset is local and immediate.
- Autosaves occur on zone entry, after battle results, after major dialogue, and before irreversible choices. Rotating autosave slots protect against corruption and regret.

## Input contract

| Action | Field | Battle/menu |
| --- | --- | --- |
| Move / navigation | Move avatar | Move focus |
| Confirm / interact | Interact | Confirm |
| Cancel | Back / close | Back one level |
| Menu | Open field menu | Context pause |
| Equipment | Open the equipment screen | Return to equipment from a submenu |
| Peek | Orbit camera | Inspect combatant/detail |
| Fold left/right | Commit valid World Turn | Cycle target group/page |
| Shoulder actions | Quick party/status view | Cycle actors/targets |

Bindings are semantic and fully remappable. Prompts update when the active input device changes without rapid icon flicker.

Default equipment bindings are keyboard `I` and controller Select/Back. `E` and `Q` remain World Turn right and left; equipment never takes a World Turn key. Every semantic action, including equipment, appears in the title Controls list for remapping.

## Equipment slots and body regions

Anatomy and equipment are deliberately two maps. Body regions exist so the player can point at a knee or a ring finger; equipment slots exist so gear stays legible.

The paper doll addresses 31 body layers: head; torso, stomach, waist, and pelvis; and per side a shoulder, upper arm, forearm, hand, five fingers, thigh, knee, calf, and foot. World cards collapse the ten finger layers into their hand because 32 pixels per metre cannot resolve a finger.

The v1 slot catalog is closed at sixteen slots:

| Slot | Covers |
| --- | --- |
| Head | Head |
| Necklace | Neck and upper chest accent |
| Shoulders | Both shoulders as one set |
| Back | Cloak accent over the torso |
| Torso | Torso and upper arms |
| Stomach | Abdomen |
| Waist | Waist |
| Legs | Pelvis, thighs, knees, calves |
| Boots | Both feet as one set |
| Gloves | Both hands and all ten fingers as one set |
| Ring x4 | Right index, right ring finger, left index, left ring finger |
| Main hand, Off hand | Held items; a two-handed main hand blocks the off hand |

Selecting a body region focuses the slot that governs it: a knee or calf focuses Legs, a thumb focuses Gloves, and a ring finger focuses its own ring. Rings draw over gloves so all four stay visible. Replacement items repaint the layers they cover; accent items such as headwear, necklaces, rings, and held tools draw on top of whatever is already there. Headwear is an accent so it never repaints the face, which outranks costume detail in the readability order.

Adding, removing, or splitting a slot is a content and save migration, not a text edit. Per-finger armour, independent left and right gloves, and jewelry beyond the necklace and four rings are out of scope for v1.

## Tuning principles

- Prefer changes that produce a new decision over changes that merely extend duration.
- Ordinary battles should end before their pattern becomes repetition.
- A strong strategy should feel clever for several encounters before a later enemy asks it to adapt.
- Tutorial text is the final layer. First teach through composition, safe interaction, animation, enemy intent, and immediate consequence.
- Record tuning in data and test fixtures. Do not hide balance constants inside presentation scripts.
