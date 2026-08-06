# ChainReaction

Love2D 11.5 deterministic puzzle prototype for a data-driven roguelite concept.

## Status

Implemented prototype slice:

- Runtime slot editing with keyboard controls
- Deterministic reaction simulation
- Behavior-preserving simulator modular refactor
- Seven implemented core attributes:
  - Ignite
  - Amplify
  - Store
  - Release
  - Charge
  - Echo
  - Explode
- 7 core single-attribute objects
- 20 finalized dual-attribute objects
- 27 executable catalog objects total
- Ordered one/two-attribute object execution
- Echo eligible-handler replay behavior
- Strict deterministic object catalog structural validation

Not implemented yet:

- Resonant Spark (`Ignite + Echo`) execution identity/order finalization
- Complete 28th runtime object rollout
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
- `src/sim/reaction_simulator.lua` owns simulation orchestration and result assembly.
- `src/sim/simulation_state.lua` owns runtime state creation.
- `src/sim/attribute_handlers.lua` owns attribute gameplay rules.
- `src/sim/attribute_executor.lua` owns top-level attribute execution, logging, and history updates.
- `src/data/object_catalog_validator.lua` enforces strict catalog schema before simulation.
- `availableOrder` in `src/data/objects.lua` is a compact keyboard QA list, not full catalog/inventory/unlock data.
- The runtime catalog contains more executable objects than appear in `availableOrder`.

## Run

From this directory, launch with Love2D 11.5:

```bash
love .
```
