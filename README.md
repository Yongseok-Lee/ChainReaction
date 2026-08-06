# ChainReaction

Love2D 11.5 deterministic puzzle prototype for a data-driven roguelite concept.

## Status

Implemented prototype slice:

- Runtime slot editing with keyboard controls
- Deterministic reaction simulation
- Seven implemented core attributes:
  - Ignite
  - Amplify
  - Store
  - Release
  - Charge
  - Echo
  - Explode
- Ordered one/two-attribute object execution
- Echo eligible-handler replay behavior
- Strict deterministic object catalog structural validation

Not implemented yet:

- Full 7-single / 21-dual / 28-total playable catalog rollout
- Stage progression loop
- Reward and upgrade systems
- Inventory/unlock/save systems

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
- Deterministic and debuggable simulation
- Extensible attribute interactions
- Easy to add new object combinations through data

## Folder Layout

- `main.lua` - application bootstrap and Love callbacks.
- `conf.lua` - Love2D runtime/window/module configuration.
- `src/` - game code.
  - `core/` - runtime controller and slot state ownership.
  - `sim/` - deterministic reaction simulator.
  - `data/` - object catalog, stage definitions, and catalog validation.
- `docs/` - design notes, architecture docs, balancing references.

## Current Architecture Snapshot

- Stage definition remains immutable (`src/data/prototype_stage.lua`).
- SlotManager owns mutable runtime slots (`src/core/slot_manager.lua`).
- Simulator executes ordered attributes and owns reaction state/logging (`src/sim/reaction_simulator.lua`).
- Catalog validator enforces strict schema before simulation (`src/data/object_catalog_validator.lua`).

## Run

From this directory, launch with Love2D 11.5:

```bash
love .
```
