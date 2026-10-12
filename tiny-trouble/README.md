# Tiny Trouble

**A colourful multiplayer survival adventure for Roblox where everyone is 2 cm tall.**

You wake up beneath a kitchen table. The table is a mountain, the sink is a lake, the cat is
a monster, and a toothpick is the best spear you will ever own. Explore the giant kitchen,
gather what you can carry, climb the furniture and find a way back to normal size.

This repository is the complete, Rojo-synchronised source for **Milestone 1: Playable
Foundation**. Everything is Luau and Roblox-native: no external models, no paid assets, no
manual building. Sync it into Roblox Studio and press Play.

---

## What is in Milestone 1

| Area | Delivered |
| --- | --- |
| Project | Rojo 7 project, typed Luau (`--!strict`), CI (type-check, lint, format, build) |
| World | Procedurally generated giant kitchen: tiled floor, walls with real windows, counter run with sink and dripping tap, stove, fridge with a hidden gap, dining table, chairs, step stool, upper cabinets, rug, pet bowls, potted plant, trash can, dozens of props, garden outside |
| Scale | Coherent miniature scale (1 cm = 2 studs, player ≈ 2.5 cm) driven by one module |
| Lighting | Warm afternoon sun aligned automatically to shine through the window, atmosphere, bloom, colour grading, sun rays |
| Movement | Walk, sprint, jump, crouch, native truss climbing on cloth and cables, fall damage, stamina drain/regen |
| Camera | Custom over-the-shoulder third-person camera with spherecast occlusion, mouse-lock, gamepad and touch look, cinematic menu orbit |
| Resources | 45 resource nodes (8 resource types) with custom hold-to-collect prompts, sparkle, pickup effects and respawn |
| Survival | Server-authoritative health and stamina, health regen, fall damage with death causes |
| Objectives | Five-step foundation objective chain with tracker, rewards and notifications |
| UI | Loading screen, title/pause menu with settings, vitals HUD, pouch, objective tracker, notifications, death/respawn screen, controls hint |
| Multiplayer | 1–8 players, deterministic spawn ring, player–player collisions disabled, everything replicated from the server |
| Security | Every remote validated and rate-limited; the client never sends item ids, amounts or positions |

Milestones 2–4 (hunger/thirst, inventory & crafting UI, quests, saving, cat/ant/ladybug AI,
base building, polish) are planned in [docs/ROADMAP.md](docs/ROADMAP.md) on top of this
architecture.

---

## Quick start

1. Install [Rojo](https://rojo.space) 7.4.x (or `aftman install` / `rokit install` in this
   folder, which also installs Selene, StyLua and luau-lsp).
2. Install the **Rojo plugin** in Roblox Studio (`rojo plugin install`).
3. From this folder run:

   ```bash
   rojo serve
   ```

4. Open a new **Baseplate** place in Roblox Studio, open the Rojo plugin, press **Connect**.
5. Press **Play** (F5). You should spawn under the kitchen table.

Full instructions, including Studio settings and a diagnosis guide, are in
[docs/SETUP.md](docs/SETUP.md). The acceptance test checklist is in
[docs/TESTING.md](docs/TESTING.md).

---

## Controls (desktop)

| Input | Action |
| --- | --- |
| `W A S D` | Move |
| `Shift` (hold) | Sprint (drains stamina) |
| `Space` | Jump |
| `Ctrl` or `C` | Toggle crouch |
| `E` (hold) | Collect the highlighted resource |
| Mouse | Look (cursor is locked while playing) |
| Mouse wheel | Zoom |
| `Alt` | Free / lock the cursor |
| `M` | Pause menu and settings |

Gamepad (left stick move, right stick look, `X` collect, `L3` sprint, `B` crouch) and
touch (left thumbstick, drag the right half of the screen to look, on-screen buttons)
work through the same input layer.

---

## Repository layout

```
tiny-trouble/
├── default.project.json      Rojo project (services, properties, source mapping)
├── aftman.toml / rokit.toml  Tool versions (rojo, selene, stylua, luau-lsp)
├── selene.toml / stylua.toml / .luaurc
├── scripts/check.sh          Runs build + type-check + lint + format check locally
(repo root) .github/workflows/tiny-trouble-ci.yml runs the same checks on every push / pull request
├── docs/                     Setup, testing, architecture, roadmap, troubleshooting
└── src/
    ├── first/                ReplicatedFirst: branded loading screen
    ├── shared/               ReplicatedStorage.Shared
    │   ├── Config/           GameConfig, ResourceDefinitions, ObjectiveDefinitions, SoundLibrary
    │   ├── Net/Remotes.luau  Remote schema (created on the server, awaited on the client)
    │   ├── Util/             Signal, Trove, Log, RateLimiter, MathUtil, TableUtil, Validate
    │   ├── Scale.luau        The miniature scale (cm -> studs)
    │   ├── Tags.luau         CollectionService tag names
    │   └── Types.luau        Shared data shapes
    ├── server/               ServerScriptService.Server
    │   ├── init.server.luau  Bootstrap: Init/Start every service in order
    │   ├── Services/         World, Player, Notification, Inventory, Stats, Resource, Objective, Session
    │   └── World/            PartBuilder, LightingSetup, KitchenGenerator, ResourceNodeBuilder, Kitchen/*
    └── client/               StarterPlayer.StarterPlayerScripts.Client
        ├── init.client.luau  Bootstrap: Init/Start every controller in order
        ├── State/            ClientState (inventory, objective, settings, signals)
        ├── Controllers/      Audio, Input, Camera, Movement, Interaction, Hud, Menu, Effects
        └── UI/               Theme, UIBuilder, Hud, MainMenu, Notifications, DeathScreen, InteractionPrompt
```

---

## Architecture in one paragraph

The server builds the world and owns every gameplay number. Clients only express intent
(`SprintState`, `CrouchState`, `ClientReady`, `GetInitialState`) and trigger engine-owned
ProximityPrompts; the server validates range, rate and capacity before changing inventory,
then pushes snapshots back. Shared modules describe data (resources, objectives, config,
scale) so both sides agree without trusting each other. Services and controllers follow one
pattern (`Init()` subscribes, `Start()` acts) and clean up with `Trove`s, so respawns and
disconnects never leak. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Development

```bash
./scripts/check.sh        # rojo build + luau-lsp analyze + selene + stylua --check
stylua src                # format
rojo build -o TinyTrouble.rbxlx   # build a place file without Studio
```

The code is written in strict Luau and type-checked against the current Roblox API
definitions, which catches misspelled properties and wrong argument types before Studio does.

---

## Licence

MIT. See [LICENSE](LICENSE).
