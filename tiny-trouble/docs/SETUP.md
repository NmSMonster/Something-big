# Setup guide

This guide takes you from an empty machine to playing Tiny Trouble in Roblox Studio,
and ends with a diagnosis section for the problems people actually hit.

## 1. Get the repository

**Clone an existing repository**

```bash
git clone https://github.com/<your-account>/<your-repo>.git
cd <your-repo>/tiny-trouble
```

**Or create a new repository from this folder**

```bash
cd tiny-trouble
git init
git add .
git commit -m "Tiny Trouble: Milestone 1"
git remote add origin https://github.com/<your-account>/tiny-trouble.git
git push -u origin main
```

## 2. Install Rojo and the tooling

Rojo is the bridge between the files on disk and Roblox Studio. Pick one of these:

**Option A: toolchain manager (recommended, installs everything pinned in this repo)**

- [Rokit](https://github.com/rojo-rbx/rokit): `rokit install` (reads `rokit.toml`)
- [Aftman](https://github.com/LPGhatguy/aftman): `aftman install` (reads `aftman.toml`)

Both install `rojo` 7.4.4, `selene`, `stylua` and `luau-lsp` into your PATH.

**Option B: Rojo only**

Download the 7.4.x release for your OS from https://github.com/rojo-rbx/rojo/releases
and put the binary on your PATH, or `cargo install rojo --version 7.4.4`.

Check:

```bash
rojo --version
# Rojo 7.4.4
```

## 3. Install the Roblox Studio Rojo plugin

```bash
rojo plugin install
```

This drops the plugin into your local Studio plugins folder. Alternatively install it
from the Creator Store (search "Rojo" by the Rojo team). Restart Studio if it was open.
The plugin version must match the server major version (7.x).

## 4. Connect the project

1. Open Roblox Studio and create a new place from the **Baseplate** template.
   (Any template works; the server removes the template's Baseplate and SpawnLocation.)
2. In a terminal, from the `tiny-trouble` folder:

   ```bash
   rojo serve
   ```

   Rojo prints `Rojo server listening: Address: localhost, Port: 34872`.
3. In Studio: **Plugins → Rojo → Connect** (defaults `localhost:34872`).
4. The Explorer now contains `ReplicatedStorage.Shared`, `ServerScriptService.Server`,
   `StarterPlayer.StarterPlayerScripts.Client` and `ReplicatedFirst.LoadingScreen`.
   Rojo also applies service properties from `default.project.json` (respawn time,
   walk speed, lighting technology, etc.). Keep `rojo serve` running while you work; every
   file save syncs instantly.

**Alternative without live sync:** build a place file and open it directly:

```bash
rojo build default.project.json -o TinyTrouble.rbxlx
```

## 5. Recommended Studio settings

These are applied by Rojo through `default.project.json`, but check them if something looks off:

| Setting | Where | Value |
| --- | --- | --- |
| Lighting.Technology | Lighting properties | `ShadowMap` (or `Future` on strong GPUs) |
| StarterPlayer.EnableMouseLockOption | StarterPlayer properties | `false` (the custom camera owns mouse lock) |
| Players.RespawnTime | Players properties | `4` |
| Workspace.StreamingEnabled | Workspace properties | `false` for Milestone 1 |

Manual settings the plugin cannot write:

- **Max players:** File → Game Settings → Basic Info → Maximum Player Count → `8`.
- **Avatar:** File → Game Settings → Avatar → R15 (default). R6 works, but crouch
  does not lower the hips on R6 rigs.
- **Chat:** optional; the game does not depend on it.

## 6. Run and test

- Press **Play** (F5). You get the loading screen, then the title menu over an orbiting view
  of the kitchen. Press **PLAY** to spawn under the dining table.
- For multiplayer: **Test → Clients and Servers → 2–3 players → Start**. Each client window
  gets its own menu, HUD and inventory.
- Follow [TESTING.md](TESTING.md) for the full Milestone 1 checklist.

The Output window should show lines like:

```
[TinyTrouble][Server][Bootstrap] Starting Tiny Trouble server 0.1.0-m1
[TinyTrouble][Server][Lighting] Lighting configured (clock 15.00, latitude 30)
[TinyTrouble][Server][KitchenGenerator] Kitchen built: 7xx parts in xx ms
[TinyTrouble][Server][ResourceService] Spawned 45 resource nodes
[TinyTrouble][Server][Bootstrap] Server ready in xx ms (8 services)
[TinyTrouble][Client][Bootstrap] Client ready in xx ms (8 controllers)
```

Set `GameConfig.Debug.VerboseLogging = true` for per-event debug lines.

## 7. Diagnosing common setup issues

| Symptom | Cause | Fix |
| --- | --- | --- |
| Rojo plugin says "Connection refused" | `rojo serve` is not running, or another port | Start `rojo serve` in the `tiny-trouble` folder; match the port in the plugin |
| Plugin connects but nothing appears | Connected to the wrong project file | Run `rojo serve default.project.json` from `tiny-trouble`, not the repo root |
| "Unknown property Technology" warning on connect | Studio build cannot set `Lighting.Technology` from a plugin | Harmless; set Lighting → Technology to ShadowMap manually |
| Scripts show as `.luau` errors in Studio | Very old Rojo (< 7.3) does not understand `.luau` | Upgrade to Rojo 7.4.x |
| Player spawns on a flat baseplate, no kitchen | Server script did not run (output has errors) | Read the first red error in Output; it names the service that failed |
| Spawned inside a wall or far away | A stray SpawnLocation outside the kitchen | The server deletes SpawnLocations that are not in `Workspace.Kitchen`; check Output for errors |
| Camera is the default Roblox camera | `CameraController` failed to start | Check Output; the controller sets `CameraType = Scriptable` each frame when alive |
| Mouse never locks | Studio window not focused, or a menu is open | Click the viewport; press `Alt` to toggle; close the menu with `M` |
| Stamina bar never moves | `Stamina` attribute missing: StatsService not started | Check Output for `StatsService.Init failed` |
| "Pouch full" immediately | `GameConfig.Inventory.Capacity` edited to 0 | Restore the value |
| Ramps go the wrong way (the tablecloth drape is a wall) | Engine wedge orientation differs from the generator's assumption | Set `PartBuilder.WEDGE_SLOPE_FACES_FRONT = false` |
| No sound | Placeholder sounds are built-in `rbxasset://` files; some Studio builds mute them | Replace ids in `SoundLibrary.luau` with your own `rbxassetid://` values |
| `selene` fails with "error when getting API dump" | Selene needs network access to download the Roblox API dump once | Run it on a connected machine or in CI; type checking (`luau-lsp analyze`) does not need it |

More in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
