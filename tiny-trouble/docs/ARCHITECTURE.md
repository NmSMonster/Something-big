# Architecture

## Principles

1. **Server authority.** The server builds the world, owns stats, inventory, objectives and
   resource nodes. Clients express intent; they never send item ids, amounts, damage or
   positions. Remote payloads are validated (`Shared/Util/Validate`) and rate limited
   (`Shared/Util/RateLimiter`) before anything changes.
2. **One pattern everywhere.** Services (server) and controllers (client) are plain tables
   with optional `Init()` and `Start()`. Bootstraps load them in an explicit order, run every
   `Init` (subscribe, create), then every `Start` (act). A failing module is reported with a
   red error and the rest continue.
3. **Data in shared config.** Resources, objectives, sounds, tuning constants and the world
   scale live in `ReplicatedStorage.Shared`. Both realms read the same tables, so there is
   nothing to keep in sync by hand.
4. **Deterministic cleanup.** Anything with a lifetime (a character, a prompt, a UI window)
   owns a `Trove` and cleans it on the way out. Respawns and disconnects never leak
   connections or instances.
5. **No per-frame work unless it is the camera.** Server stats tick at 10 Hz, zones poll at
   2 Hz, respawns at 1 Hz. HUD updates are event driven.

## Runtime layout

```
ReplicatedFirst
  LoadingScreen (LocalScript)                 branded loading screen, no dependencies

ReplicatedStorage
  Shared/Config/*                             GameConfig, ResourceDefinitions, ObjectiveDefinitions, SoundLibrary
  Shared/Net/Remotes                          remote schema + realm-aware accessors
  Shared/Util/*                               Signal, Trove, Log, RateLimiter, MathUtil, TableUtil, Validate
  Shared/{Scale,Tags,Types}
  Remotes (Folder, created by the server)     RemoteEvents / RemoteFunctions

ServerScriptService
  Server (Script)                             bootstrap
    Services/*                                gameplay services
    World/*                                   generator + builders

StarterPlayer/StarterPlayerScripts
  Client (LocalScript)                        bootstrap
    State/ClientState                         replicated state mirror + settings + signals
    Controllers/*                             gameplay controllers
    UI/*                                      pure view builders

Workspace
  Kitchen (Model)                             Structure, Furniture, Props, Climbables, Spawns, Zones, Resources
```

## Server services (start order)

| Service | Responsibility | Depends on |
| --- | --- | --- |
| WorldService | Applies lighting, builds the kitchen, removes template leftovers, exposes the build result | World/* |
| PlayerService | Player and character lifecycle, humanoid defaults, collision group, lifecycle signals | — |
| NotificationService | `send` / `broadcast` toasts | Remotes |
| InventoryService | Per-player resource counts with capacity; pushes snapshots; `ResourceAdded` signal | PlayerService |
| StatsService | 10 Hz tick: stamina drain/regen, sprint/crouch authority, jump cost, fall damage, health regen | PlayerService |
| ResourceService | Spawns nodes from the layout, validates prompt triggers, respawns | WorldService, InventoryService, NotificationService |
| ObjectiveService | Objective chain progress, zone polling, rewards | InventoryService, WorldService, NotificationService |
| SessionService | `GetInitialState` handshake, `ClientReady` welcome | InventoryService, ObjectiveService |

Lifecycle signals come only from PlayerService (`PlayerAdded`, `PlayerRemoving`,
`CharacterAdded`, `CharacterRemoving`, `CharacterDied`), which keeps ordering deterministic:
subscribers connect in `Init`, PlayerService connects to `Players` in `Start` and replays
players who are already present.

## Client controllers (start order)

| Controller | Responsibility |
| --- | --- |
| AudioController | Named sounds from `SoundLibrary`, 2D and positional, silent on missing assets |
| InputController | ContextActionService bindings -> `ActionBegan/Ended` signals; touch buttons; input kind detection |
| CameraController | Third-person camera, occlusion, cursor lock stack, menu orbit, transitions |
| MovementController | Sprint/crouch prediction and intent; disables default controls while the menu is open |
| InteractionController | Custom prompt UI and highlight for ProximityPrompts |
| HudController | Vitals, pouch, objective tracker, notifications, death screen, crosshair, controls hint |
| MenuController | Title / pause menu, settings, first `ClientReady` |
| EffectsController | Pickup bursts, floating text, pickup sounds |

`ClientState` is initialised before the controllers and holds inventory, objective state,
settings and session flags with signals (`InventoryChanged`, `ObjectiveChanged`,
`SettingsChanged`, `PlayingChanged`, `MovementChanged`).

## Network contract

| Remote | Direction | Payload | Validation |
| --- | --- | --- | --- |
| `SprintState` | C→S | `boolean` | type, rate limit, stamina/crouch rules |
| `CrouchState` | C→S | `boolean` | type, rate limit, alive |
| `ClientReady` | C→S | — | once per player |
| `GetInitialState` | C→S (function) | — → `InitialState` | rate limit (burst 3, 1 per 5 s) |
| `InventoryUpdate` | S→C | `InventorySnapshot` | shape-checked on the client |
| `ResourceCollected` | S→C (all) | `ResourceCollectedPayload` | shape-checked on the client |
| `Notification` | S→C | `NotificationPayload` | shape-checked on the client |
| `ObjectiveUpdate` | S→C | `ObjectiveState` | shape-checked on the client |
| `SprintDenied` | S→C | — | — |

Collection itself uses the engine's `ProximityPrompt.Triggered` (server side). The server
re-checks range with latency tolerance, the rate limiter, that the character is alive and
that the pouch has room before touching inventory.

Stats replicate as attributes: `Player.Stamina`, `Player.MaxStamina` (integers, written only
on change), `Player.LastDeathCause`, `Player.ClientReady`. Health uses `Humanoid.Health`.

## Movement model

- Roblox's default `PlayerModule` handles walking, jumping and climbing. The custom camera
  sets `CameraType = Scriptable`, which the default camera scripts respect.
- Sprint: the client predicts `WalkSpeed` immediately and sends intent. The server applies
  `WalkSpeed`/`JumpPower`/`HipHeight` authoritatively (they replicate to everyone), drains
  stamina only while the character actually moves, and sends `SprintDenied` when stamina
  runs out so the client stops predicting. Hysteresis: 12 stamina to start, 0 to stop.
- Crouch: toggle; server lowers `HipHeight` on R15 rigs, sets speed 9 and jump 0.
- Fall damage: the 10 Hz tick remembers the peak height during `Freefall` and applies
  `(drop - 26) * 1.1` damage on landing. Chair height hurts, table height kills, which makes
  the climbing routes matter.
- Climbing: TrussParts. Cloth folds, a towel and a charger cable are trusses tinted to match.

## World generation

`World/Kitchen/Layout.luau` is the floor plan in centimetres. `Shared/Scale.luau` converts
(1 cm = 2 studs). `Structure`, `Furniture`, `Props` and `Climbables` build primitives through
`PartBuilder` (boxes by bottom-centre, vertical/arbitrary cylinders, ramps, trusses,
ellipsoids via SpecialMesh, surface text). `KitchenGenerator.build()` assembles the model and
returns spawn CFrames, resource spawn points and objective zones for the services.

Lighting is applied by `LightingSetup`: it searches clock time and latitude for the sun
direction that best enters the north window, so the sun patch on the floor is guaranteed
without hand-tuning.

## Extending (Milestone 2+ hooks already present)

- `InventoryService.remove` exists for crafting costs; the snapshot shape carries capacity for
  backpack upgrades.
- `ObjectiveDefinitions` entries support `collect` and `reach`; quests add kinds without
  changing the service loop.
- `Tags.Water` marks every water volume for thirst/drowning.
- `Tags.Zone` parts exist in `Workspace.Kitchen.Zones` for debugging and future triggers.
- `SoundLibrary` ids are the only thing to swap for real audio.
- Persistence: session state (inventory, objectives) is held in services keyed by Player and
  is deliberately separate from anything that will be saved; a DataService can load into and
  snapshot from these services without changing them.
