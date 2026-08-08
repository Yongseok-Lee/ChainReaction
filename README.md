# ChainReaction

Love2D 11.5 deterministic puzzle prototype for a data-driven roguelite concept.

## Status

Implemented prototype slice:

- 3-stage deterministic stage progression
- StageManager integration
- Stage-specific allowed object cycling
- Explicit runtime phases:
  - editing
  - resolved_clear
  - resolved_fail
  - reward_selection
  - run_complete
- N enters reward selection after clear
- Fixed two-choice deterministic reward options per stage
- Persistent slot bonus reward
- Next-stage temporary slot bonus reward
- Reward lifetime handling across stage transitions
- Reward input gating during reward_selection
- Final-stage reward selection/apply flow before run_complete
- Run restart clears all reward state
- Reward-added slots are inserted immediately before the terminal Bomb slot
- Reward effects never mutate StageDefinition
- T restarts after run completion
- Slot edits invalidate stale simulation results
- Advancing creates fresh stage slot state
- Reset restores current stage effective initial slots
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
- 21 finalized dual-attribute objects
- 28 executable catalog objects total
- Ordered one/two-attribute object execution
- Echo eligible-handler replay behavior
- Strict deterministic object catalog structural validation

Not implemented yet:

- Run inventory / ownership model
- Object acquisition rewards
- Upgrade application
- Save/load
- Shop/currency

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

- `src/data/stage_catalog.lua` owns immutable-by-convention stage definitions and order.
- `src/data/reward_catalog.lua` owns deterministic reward definitions and per-stage option order.
- `src/core/stage_manager.lua` owns stage index, lookup, transition, and stage validation.
- `src/core/run_state.lua` owns run-level reward state:
  - `persistentSlotBonus`
  - `pendingNextStageSlotBonus`
  - `currentStageTemporarySlotBonus`
  - reward selection state
  - `lastAppliedRewardKey`
- `src/core/run_prototype.lua` coordinates phase flow, reward selection, reward application, StageManager advance, and effective runtime slot construction.
- `src/core/slot_manager.lua` owns mutable runtime slots for the active stage.
- `src/sim/reaction_simulator.lua` owns simulation orchestration and result assembly.
- `src/sim/simulation_state.lua` owns runtime state creation.
- `src/sim/attribute_handlers.lua` owns attribute gameplay rules.
- `src/sim/attribute_executor.lua` owns top-level attribute execution, logging, and history updates.
- `src/data/object_catalog_validator.lua` enforces strict catalog schema before simulation.
- The simulator remains unchanged and reward-agnostic; stage/reward progression never changes simulator rules.
- `stage.allowedObjectKeys` remains a stage teaching/QA whitelist, not inventory/ownership/unlock state.
- `availableOrder` in `src/data/objects.lua` is a compact keyboard QA list, not full catalog/inventory/unlock data.
- The runtime catalog contains more executable objects than appear in `availableOrder`.

## Run

From this directory, launch with Love2D 11.5:

```bash
love .
```
