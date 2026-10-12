# Troubleshooting

Start with the Output window: every Tiny Trouble log line is prefixed
`[TinyTrouble][Server|Client][Module]`. A module that fails to load or start prints a red
error naming it; everything else keeps running.

## Startup

**No kitchen, players stand on a baseplate.**
`ServerScriptService.Server` did not run or `WorldService.Init` failed. The error text names
the first builder that threw. Typical causes: a Material enum missing on an old Studio build
(the builders use `PartBuilder.safeMaterial` with fallbacks; add the name there), or a Rojo
sync that only partially completed (reconnect the plugin).

**"Remotes" never appears in ReplicatedStorage.**
The server bootstrap stopped before `Remotes.initServer()`. Check the first error in Output.

**Loading screen never goes away.**
It waits for the client bootstrap to set the local attribute `TT_ClientLoaded`, with a
30 s safety timeout. If it times out, a controller errored during `Init`; see Output.

## Camera and input

**The camera does not follow the player / default Roblox camera is active.**
`CameraController.Start` binds a RenderStep. If `workspace.CurrentCamera` was replaced by a
plugin or the camera type is reset by another script, the controller re-applies
`Scriptable` each frame; if it still fails, another LocalScript is fighting for the camera.

**Character does not turn with the mouse.**
The cursor is free: press `Alt`, or close the menu (`M`). The character only turns with the
camera while the cursor is locked (crosshair visible).

**Mouse wheel zoom does nothing.**
Zoom is ignored while the pointer is over a GUI element (gameProcessed).

## Movement

**Sprint stops immediately.**
Stamina below the start threshold (12) or crouched. Watch the stamina bar: it turns darker
when sprinting is unavailable.

**Crouch does not lower the character.**
R6 rigs have no `HipHeight`; crouch still slows and blocks jumping. Switch the game to R15 in
Game Settings → Avatar.

**Fall damage feels too harsh/lenient.**
Tune `GameConfig.FallDamage.SafeDistanceStuds` and `DamagePerStud`.

**Ramps are walls (the tablecloth drape cannot be walked up).**
Set `PartBuilder.WEDGE_SLOPE_FACES_FRONT = false`. All ramps flip together.

**Cannot climb a cloth/cable.**
Trusses need `CanCollide = true` and the humanoid must walk into them. Make sure
`Workspace.Kitchen.Climbables` exists and contains TrussParts (size multiples of 2).

## Resources

**Prompts do not appear.**
Prompts use `ProximityPromptStyle.Custom`; the UI is drawn by `InteractionController` once
you pressed PLAY (prompts are suppressed while the menu is open). If another script sets
`ProximityPromptService.Enabled = false`, nothing shows.

**Collect does nothing.**
Server-side rejection reasons (debug logging prints them): rate limited, out of range (13
studs + 8 tolerance), dead character, pouch full (a "Pouch full" toast is sent).

**Nodes never respawn.**
The respawn loop runs every second; respawn delay is 45–100 s (`GameConfig.Resources`).

## Tooling

**`luau-lsp analyze` reports hundreds of unknown globals.**
You are missing the Roblox definitions file; `scripts/check.sh` downloads it, or pass
`--definitions=globalTypes.d.luau` yourself (pinned to the luau-lsp version in `aftman.toml`).

**`selene` cannot download the API dump.**
Selene fetches the Roblox API dump on first run and needs network access. Run it on a
connected machine or rely on CI; the type check does not need it.

**StyLua complains in CI.**
Run `stylua src` locally and commit.
