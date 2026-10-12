# Roadmap

Milestone 1 is complete and testable on its own. Each later milestone is also meant to be
playable and testable independently.

## Milestone 2 — Survival and progression

- **Hunger and thirst**: two more stats in StatsService (same 10 Hz tick), HUD rows are
  data driven. Food: bread crumbs, cookie fragments, fruit pieces, sugar. Water: droplets
  from the tap, water bowls, bottle caps filled with water (`Tags.Water` volumes).
- **Inventory**: slot-based inventory and hotbar on top of InventoryService counts; item
  stacking per `ResourceDefinition.stackSize`; equipment slots; pickup/drop; tools.
- **Crafting**: `RecipeDefinitions` (toothpick spear, miniature hammer, rope, storage chest,
  backpack upgrade, bandage, water container, shelter parts) validated by a CraftingService
  that consumes through `InventoryService.remove`.
- **Introductory quest line**: QuestService generalising ObjectiveService (wake up, discover
  you shrank, first food, water, craft a spear, build a shelter, avoid the cat, the gap behind
  the fridge, the clue), markers and tracker.
- **Saving**: DataService with DataStoreService, retries with backoff, session locking,
  versioned schema, `BindToClose` flush, separation of session state from persistent state.

## Milestone 3 — Creatures and building

- **Cat AI**: patrol, detection cone + hearing, chase with cooldown, hiding spots under
  furniture and narrow passages, procedural animation or rig, audio warnings.
- **Ants**: floor roaming, territory, attack on intrusion, food theft from storage.
- **Friendly ladybug**: discovery encounter with a small quest.
- PathfindingService with miniature-scale agent parameters and local steering fallback.
- **Base building**: placement preview, grid snapping, rotation, collision checks, resource
  costs, walls/floors/doors/storage/beds, removal. Session-based with a persistence-ready
  structure model.

## Milestone 4 — Polish

- Enhanced UI, mobile controls (the input layer already exposes actions and touch buttons).
- Final audio, more VFX, performance passes (StreamingEnabled, part merging), map detail,
  the remaining rooms (living room, bathroom, bedroom, basement, garden).
