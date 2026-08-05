# ChainReaction

Love2D 11.5 project scaffold for a data-driven puzzle roguelite.

## Status

Project structure initialized only.  
Gameplay systems, content, and progression are intentionally not implemented yet.

## Game Vision

Genre:

- Puzzle Roguelite

Core Gameplay Loop:

Ignite
→ Chain Reaction
→ Explosion
→ Rewards
→ Shop
→ Next Stage

Design Goals:

- Data-driven gameplay
- Highly extensible attribute system
- Event-driven reactions
- Easy to add new mechanics
- Minimal code changes when adding content

## Folder Layout

- `main.lua` - application bootstrap and Love callbacks.
- `conf.lua` - Love2D runtime/window/module configuration.
- `src/` - game code.
  - `core/` - app lifecycle, state management, service locators.
  - `entities/` - runtime object instances and factories. Avoid putting gameplay rules or behaviors here.
  - `components/` - runtime data containers for object attributes and states. Components should remain pure data and should not contain gameplay logic.
  - `systems/` - systems process events, resolve reactions, manage game flow, and handle technical responsibilities.
  - `events/` - event definitions and event dispatching for decoupled gameplay systems.
  - `data/` - externalized gameplay definitions.
    - `attributes/` - object attributes and properties.
    - `reactions/` - trigger, condition, and effect definitions for chain reactions.
  - `ui/` - HUD, menus, overlays, and UI flow controllers.
  - `utils/` - helpers (math, table utilities, serialization wrappers).
- `assets/` - static resources.
  - `images/` - sprites, atlases, and textures.
  - `audio/` - music and SFX.
  - `fonts/` - bitmap/ttf/otf fonts.
- `docs/` - design notes, architecture docs, balancing references.
- `tests/` - automated and manual test assets/scripts.

## Architectural Direction (Planned)

- Game design documentation is maintained under `docs/`.
- Modular Lua organized by domain (`core`, `entities`, `systems`, etc.).
- Data-first content pipeline under `src/data/`.
- Extensible systems suitable for puzzle mechanics + roguelite meta layers.
- Event-driven gameplay architecture.
- Composition over inheritance.
- Data-driven object definitions.
- Systems should communicate through events instead of direct dependencies.

## Run

From this directory, launch with Love2D 11.5:

```bash
love .
```
