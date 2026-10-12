# Changelog

All notable changes to Tiny Trouble are documented here.

## 0.1.0-m1 — Milestone 1: Playable Foundation

### Added
- Rojo 7 project with typed Luau sources, tool pins (aftman/rokit), Selene, StyLua and a CI workflow.
- Procedurally generated giant kitchen (structure, furniture, props, climbing routes, garden).
- Miniature scale system (`Shared/Scale.luau`, 1 cm = 2 studs).
- Lighting setup with automatic sun alignment to the north window.
- Server services: World, Player, Notification, Inventory, Stats, Resource, Objective, Session.
- Client controllers: Audio, Input, Camera, Movement, Interaction, Hud, Menu, Effects.
- Custom third-person camera with spherecast occlusion, mouse lock, gamepad and touch look.
- Sprint, crouch, stamina, health regeneration and fall damage (server authoritative).
- 45 resource nodes across 8 resource types with custom prompts, effects and respawn.
- Five-step foundation objective chain with rewards.
- Loading screen, title/pause menu with settings, HUD, notifications, death screen.
- Documentation: setup, testing checklist, architecture, roadmap, troubleshooting.
