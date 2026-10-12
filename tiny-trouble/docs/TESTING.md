# Milestone 1 test checklist

Run through this in Roblox Studio with `rojo serve` connected. Every test lists the
expected behaviour; a failure anywhere blocks the milestone.

Legend: **Solo** = Play (F5). **Multi** = Test → Clients and Servers with 2+ players.

## A. Synchronisation and startup

| # | Test | Expected |
| --- | --- | --- |
| A1 | Connect the Rojo plugin | `ReplicatedStorage.Shared`, `ServerScriptService.Server`, `StarterPlayer.StarterPlayerScripts.Client`, `ReplicatedFirst.LoadingScreen` appear; no plugin errors (a `Technology` property warning is acceptable) |
| A2 | Press Play, watch Output | No red errors. Lines from Bootstrap, Lighting, KitchenGenerator, ResourceService, SessionService appear |
| A3 | Loading screen | Branded loading screen with animated dots, fades out within a few seconds |
| A4 | Title menu | "TINY TROUBLE" title, PLAY and SETTINGS buttons, slow orbiting cinematic view of the kitchen behind it |
| A5 | Press PLAY | Menu fades, camera blends smoothly down to a third-person view behind your character under the table, HUD appears, welcome notification shows |

## B. World

| # | Test | Expected |
| --- | --- | --- |
| B1 | Look around under the table | Four table legs like tree trunks, chairs, a felt toy mouse, crumbs sparkling on the floor |
| B2 | Walk to the north wall | Counter run with drawers and handles, a sink with standing water and a dripping tap, a stove with a glowing clock, backsplash tiles, a window with daylight |
| B3 | Walk east | Fridge with handles, magnets and a readable note; a 4 cm gap behind it with a purple glow from a vent; trash can and a crumpled paper ball |
| B4 | Walk south-east | Potted plant with leaves and dry leaves on the floor; water bowl and food bowl with kibble |
| B5 | Walk west | Closed door with light leaking under it; a striped rug in front of the sink |
| B6 | Look up | Ceiling, pendant lamp over the table, upper cabinets, open shelves with jars |
| B7 | Look through either window | Lawn, hedge and trees outside; sunlight enters through the north window and lights the floor |
| B8 | `Workspace.Kitchen` in Explorer | Folders Structure, Furniture, Props, Climbables, Spawns, Zones, Resources; roughly 700–900 parts |

## C. Movement and camera

| # | Test | Expected |
| --- | --- | --- |
| C1 | `W A S D` | Character moves relative to the camera at 18 studs/s |
| C2 | Hold `Shift` while moving | Speed rises to 28, FOV widens slightly, stamina bar drains; stop moving and the bar does not drain |
| C3 | Sprint until empty | At 0 stamina the sprint ends automatically; holding Shift resumes it once stamina passes ~12 |
| C4 | `Space` | Jump about 7 studs; each jump costs a little stamina |
| C5 | `Ctrl` or `C` | Character crouches (hips lower, speed 9, cannot jump); press again to stand |
| C6 | Mouse | Camera orbits; character turns to face the camera direction while the cursor is locked |
| C7 | Mouse wheel | Zoom between 4 and 42 studs |
| C8 | `Alt` | Cursor frees (crosshair hides, character stops turning with the camera); `Alt` again locks it |
| C9 | Walk the camera into a chair leg or wall | Camera pulls in front of the obstacle instead of clipping, then eases back out |
| C10 | Settings → Camera shoulder Left/Right, FOV, sensitivity, Invert Y | Each change applies immediately on resume |
| C11 | Gamepad (if available) | Left stick moves, right stick looks, `X` collects, `L3` sprints, `B` crouches |

## D. Climbing and verticality

| # | Test | Expected |
| --- | --- | --- |
| D1 | Walk into the cloth hanging down the north-west chair leg | Character climbs it automatically (truss), reaches the seat |
| D2 | From the seat, walk into the tablecloth fold on the table side | Climbs onto the table top; "The tablecloth climb" objective completes with a chime, rewards and a notification |
| D3 | Walk onto the east edge of the table | The draped tablecloth is a walkable 45° ramp down to the floor |
| D4 | Walk into the dish towel hanging over the counter edge (by the drawers) | Climbs to the counter top; "Over the counter" objective completes |
| D5 | Walk into the cloth on the east side of the step stool, then the charger cable | Reaches the stool top, then the counter |
| D6 | Jump off a chair seat | Health drops (≈70 damage) with a red flash and a hurt sound; health regenerates slowly after ~6 s |
| D7 | Jump off the table | Death screen "SQUISHED" with "You fell from a great height.", countdown, respawn under the table with full stats |

## E. Resources and inventory

| # | Test | Expected |
| --- | --- | --- |
| E1 | Approach a sparkling crumb | A rounded prompt appears above it: key glyph `E`, icon, name and amount; the node glows |
| E2 | Hold `E` | Progress bar fills over 0.35 s; crumb vanishes with a particle burst, "+N Bread Crumbs" floats up, pickup sound plays |
| E3 | HUD pouch | A row for the resource appears with the count; the capacity counter updates |
| E4 | Collect every kind | Toothpick, Thread (on the rug), Wood Splinter, Plastic Fragment (by the trash), Metal Scrap (slot west of the fridge), Bottle Cap, Plant Fiber (around the pot) all collect with their own icons/colours |
| E5 | Wait 45–100 s | Collected nodes respawn (new sparkle) |
| E6 | Click/tap the prompt panel with the mouse | Also collects (click-and-hold) |
| E7 | Try to collect from far away (cheat test: fire the prompt via the command bar) | Server rejects out-of-range collects; nothing is added |

## F. Objectives and notifications

| # | Test | Expected |
| --- | --- | --- |
| F1 | Objective card | Shows "1 / 5", title, description, hint and a progress bar |
| F2 | Collect 5 crumbs | Progress ticks (3 / 5...), completes with a green flash and reward notification ("Reward: 2 Thread"); next objective appears |
| F3 | Collect 3 toothpicks | Completes; reward wood splinters |
| F4 | Reach the table top, the counter top, then the gap behind the fridge | Each completes in order; the last one shows the "Discovery" message about the purple glow and the "Foundation complete" notification |
| F5 | Notifications | Toasts stack bottom-right, newest at the bottom, fade after their duration |

## G. Multiplayer (2–3 clients)

| # | Test | Expected |
| --- | --- | --- |
| G1 | Start 3 clients | Each spawns on a different point of the spawn ring under the table; players do not push each other |
| G2 | Each client presses PLAY independently | Menus, HUDs and inventories are per player |
| G3 | Player A collects a crumb | Player B sees the node vanish and the burst, but gets no "+N" text and no pouch change |
| G4 | Player A sprints / crouches | Player B sees A move faster / lower |
| G5 | Player A dies | Only A sees the death screen; A respawns after 4 s |
| G6 | A client leaves and rejoins | No errors in Output; the new session starts with an empty pouch (persistence arrives in Milestone 2) |
| G7 | Stop the test session | No errors on shutdown |

## H. Client/server validation (command bar on a client)

| # | Test | Expected |
| --- | --- | --- |
| H1 | `game.ReplicatedStorage.Remotes.SprintState:FireServer("yes")` | Ignored (non-boolean) |
| H2 | Fire `SprintState` 50 times in a loop | Rate limiter drops the excess; no errors |
| H3 | `game.ReplicatedStorage.Remotes.GetInitialState:InvokeServer()` 10 times quickly | Later calls return `nil` with a server warning |
| H4 | Set `Humanoid.WalkSpeed = 100` locally | Server keeps its own values; the next sprint/crouch change resets the speed (full anti-cheat is out of scope for M1) |
| H5 | Edit `Player:SetAttribute("Stamina", 100)` on the client | Local only; the server overwrites it on the next tick |

## I. Performance

| # | Test | Expected |
| --- | --- | --- |
| I1 | Studio micro profiler / stats | Server Heartbeat work is a single 10 Hz tick; no per-frame loops on the server |
| I2 | Client | One RenderStep binding (camera); HUD updates only on events |
| I3 | Instance count | Kitchen ≈ 1000 parts, resources ≈ 150 small parts; no growth over time (effects and sound emitters are debris-collected) |
