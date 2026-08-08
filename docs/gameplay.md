# ChainReaction - Gameplay Design v1.2

> This document is the Single Source of Truth (SSOT) for gameplay design.
> If implementation conflicts with this document, this document takes precedence.

---

# 1. Core Concept

ChainReaction is a puzzle roguelite where the player designs a reaction circuit.

The player begins with a single Spark, places reaction objects into limited slots, and attempts to produce enough total damage to clear the stage.

The goal is not to use objects individually, but to design an efficient reaction circuit through the interaction of simple mechanics.

Core philosophy:

- Small rule set
- High interaction between mechanics
- Deterministic simulation
- Emergent gameplay through combinations

---

# 2. Core Gameplay Loop

Stage Start

↓

Design Circuit

↓

Run Simulation

↓

Calculate Damage

↓

Clear / Fail

↓

Choose Reward

↓

Next Stage

---

## Stage Information

Each stage provides:

- Target Damage
- Available Objects
- Number of Slots

---

## Circuit Structure

Basic prototype:

Spark

↓

[Slot]

↓

[Slot]

↓

...

↓

Bomb

The player fills slots with reaction objects.

---

## Simulation

Once the player starts the reaction:

- Ignite starts the reaction.
- Objects activate sequentially.
- Each object modifies the reaction state.
- Bomb converts the final reaction into damage.

If total damage reaches the stage target, the stage is cleared.

---

# 3. Roguelite Progression

After clearing a stage, the player chooses one reward.

Examples:

- Increase slot count
- Obtain new object
- Upgrade existing object
- Unlock new object combinations

Progression expands the player's design space rather than increasing raw numbers.

---

# 4. Core Resources

The simulation currently uses two reaction resources.

## Reaction Value (RV)

The active reaction value flowing through the circuit.

Example:

Spark

↓

RV = 1

Most reaction objects manipulate RV.

---

## Stored Reaction Value (StoredRV)

Reaction value stored by Store.

StoredRV remains separate from active RV until other attributes interact with it.

Exact interactions with StoredRV depend on active attribute rules.

---

# 5. Core Attribute Roles

The gameplay is built around seven core attribute roles.

---

## Ignite

Purpose:

Start a reaction.

Example:

Spark

↓

RV = 1

---

## Amplify

Purpose:

Increase the current RV.

Example:

RV 5

↓

RV 10

---

## Store

Purpose:

Store reaction value for later use.


---

## Release

Purpose:

Move stored reaction value back into the active reaction flow.

Prototype 0.6 finalized rule:

- RV_after = RV_before + StoredRV_before
- StoredRV_after = 0
- Release with StoredRV = 0 is a valid no-op.
- Release requires Ignite and is invalid after reaction termination.

For full details, reference:

`docs/attributes/release.md`

---

## Charge

Purpose:

Prepare the next eligible reaction attribute for a one-time efficiency bonus.

Rules:

- Charge sets the reaction state to Charged.
- Charge is idempotent.
- Charge does not directly modify RV, StoredRV, or damage.
- Charged is consumed by the next eligible Amplify, Store, or Explode.
- Ignite and Release do not consume Charged.
- Exact efficiency values remain balance parameters.

Reference:

`docs/attributes/charge.md`

---

## Echo

Purpose:

Replay the immediately previous successful eligible real attribute once.

Rules:

- Eligible Echo sources are Amplify, Store, and Release.
- Echo reuses the source attribute's parameters.
- Replay is evaluated against current runtime state.
- Echo repeats handler behavior, not recorded numerical deltas.
- Ignite, Charge, Echo, Explode, and synthetic Echo replays are ineligible.
- Echo does not search backward past the immediately previous real attribute.
- No valid source produces a successful deterministic no-op.
- Echo does not introduce post-terminal execution exceptions.

Reference:

`docs/attributes/echo.md`

---

## Explode

Purpose:

Converts the final reaction state into damage.

The exact damage calculation depends on participating attributes.

Explosion consumes the reaction.

---

# 6. Core Objects

## Single-Attribute Base Objects

| Object   | Attribute |
| -------- | --------- |
| Spark    | Ignite    |
| Fuel     | Amplify   |
| Crystal  | Store     |
| Valve    | Release   |
| Catalyst | Charge    |
| Mirror   | Echo      |
| Bomb     | Explode   |

## Dual-Attribute Upgraded Objects (Ordered Execution)

1. Flare - Ignite -> Amplify
2. Ember Core - Ignite -> Store
3. Primer - Ignite -> Release
4. Arc Spark - Ignite -> Charge
5. Resonant Spark - Ignite -> Echo
6. Detonator - Ignite -> Explode
7. Capacitor - Amplify -> Store
8. Turbine - Release -> Amplify
9. Reactor - Charge -> Amplify
10. Resonator - Amplify -> Echo
11. Warhead - Amplify -> Explode
12. Accumulator - Store -> Release
13. Prismatic Crystal - Charge -> Store
14. Memory Crystal - Store -> Echo
15. Reservoir Bomb - Store -> Explode
16. Converter Valve - Release -> Charge
17. Pulse Valve - Echo -> Release
18. Pressure Bomb - Release -> Explode
19. Kaleidoscope - Echo -> Charge
20. Elemental Bomb - Charge -> Explode
21. Cluster Bomb - Echo -> Explode

Object names are provisional until the visual theme and world setting are finalized.
Attribute combinations are stable.

---

# 7. Core Object Framework

The core object catalog targets unique dual-attribute combinations.

Target framework:

- 7 single-attribute base objects
- 21 unique dual-attribute combinations
- 28 total core objects

Current runtime implementation:

- 7 single-attribute objects implemented
- 21 dual-attribute objects implemented
- 28 executable objects total

Resonant Spark (`ignite + echo`) is now finalized as `ignite -> echo`.
Under current Echo rules, its Echo step is a deterministic no-op at the ignition boundary.
Catalog structure and execution order are finalized for the current 28-object framework.
Resonant Spark's current gameplay identity is intentionally minimal and may be revisited during
balancing/content evaluation, but this does not reopen Echo semantics or the 28-pair framework.

Dual combinations are unordered for catalog uniqueness.

- Amplify + Store and Store + Amplify are the same catalog combination.

Working execution orders may be finalized individually.
Some execution orders may remain provisional while attribute rules are prototyped.
Attribute execution order must be stored as ordered data.

## Object Catalog Schema (Prototype 0.95)

Catalog root metadata:

- `availableOrder`
- Prototype QA ordering only
- Not player inventory, ownership, or unlock data
- Intentionally not the full runtime catalog list
- Absence from `availableOrder` does not imply absence from `objects.lua`

Object identity:

- Catalog map key is the canonical object identity
- Internal object `id`/`key` fields are forbidden

Allowed object fields:

- `attributes`
- optional `orderStatus`

`orderStatus` rules:

- Omitted is valid
- `"provisional"` is valid
- Metadata only; does not change simulation behavior

Attribute-entry fields:

- `key`
- `params`

Validation contract:

- `attributes` must be a dense ordered array
- Object attribute count must be one or two
- Duplicate attribute keys are invalid
- Unsupported attribute keys are invalid
- Unknown object fields are invalid
- Unknown attribute-entry fields are invalid
- Duplicate unordered dual pairs are invalid
- `availableOrder` keys must exist and cannot repeat
- Catalog structural validation runs before simulation
- Semantic parameter validation remains handler-owned

## Upgrade Path Convergence

A single-attribute object can gain one of the other six attributes.

Symmetric upgrade paths converge on the same dual object.

Upgrading either parent base object may lead to the same dual-attribute result.

Example:

- Fuel + Store -> Capacitor
- Crystal + Amplify -> Capacitor

---

# 8. Design Principles

The project follows these principles.

## Small Mechanics

Simple mechanics should create complex interactions.

---

## Deterministic Simulation

The same input must always produce the same output.

No randomness exists inside the reaction simulation itself.

---

## Data-Driven Design

Objects should primarily contain data.

Simulation rules belong to the simulator.

---

## Separation of Responsibility

Stage Catalog

↓

Stage Manager

↓

Run Prototype

├─ Slot Manager
└─ Reaction Simulator

↓

Result

Ownership:

- Stage Catalog owns immutable-by-convention stage definitions and order.
- Stage Manager owns current stage index, lookup, validation, and transition.
- Run Prototype owns runtime phase, simulation result, input handling, and SlotManager lifecycle.
- Slot Manager owns mutable slot state for the active stage.
- Reaction Simulator remains deterministic and stage-agnostic.

Each system owns only its own responsibility.

---

## Prototype First

Validate gameplay before expanding content.

New mechanics are added only after the existing ones prove fun.

---

# 9. Current Prototype Scope

Implemented:

- Runtime Slot Manager
- Keyboard Slot Editing
- Stage Progression
- 3 prototype stages
- Explicit runtime phase lifecycle (`editing`, `resolved_clear`, `resolved_fail`, `reward_selection`, `run_complete`)
- Per-stage `allowedObjectKeys` object cycling
- Deterministic stage reward choices (two options per stage)
- Persistent slot increase reward
- Next-stage temporary slot increase reward
- Run-level reward state
- Effective-slot construction without `StageDefinition` mutation
- Reward input gating during `reward_selection`
- Final-stage reward application before `run_complete`
- Ordered Multi-Attribute Execution
- Behavior-preserving simulator modular refactor
- Ignite
- Amplify
- Store
- Release
- Charge
- Echo
- Explode
- 7 single-attribute objects
- 21 dual-attribute objects
- 28 executable catalog objects
- Deterministic Simulation
- Object Catalog Validation
- Deterministic Catalog Error Ordering

Finalized Specifications:

- Release
- Charge
- Echo

## Stage Progression (Prototype 1.1 Foundation, Active in 1.2)

Implemented stages:

- Stage 1: `stage_01_basics`
  - `targetDamage`: 2
  - Teaching focus: Amplify
- Stage 2: `stage_02_storage`
  - `targetDamage`: 4
  - Teaching focus: Store + Release
- Stage 3: `stage_03_charge_echo`
  - `targetDamage`: 5
  - Teaching focus: Charge + Echo

Lifecycle:

- `editing` -> `resolved_clear` or `resolved_fail` after simulation
- `resolved_clear` + `N` -> `reward_selection`
- `reward_selection` + reward confirm -> next stage `editing`
- final-stage `reward_selection` + reward confirm -> `run_complete`
- `run_complete` + `T` -> stage 1 `editing`

Stale-result rule:

- Any successful slot mutation after a resolved result clears the old result and returns to `editing`.

Stage slot policy:

- Retry preserves edited slots.
- `R` restores current stage effective initial slots.
- Advancing creates a fresh `SlotManager` from the next stage's effective runtime layout derived from its `StageDefinition` and active run slot bonuses.

`allowedObjectKeys` policy:

- Stage teaching/QA selection only.
- Not inventory, ownership, or unlock state.

## Reward System (Prototype 1.2)

Reward lifecycle:

- `editing` -> `resolved_clear` -> `N` -> `reward_selection` -> confirm reward -> next stage `editing`
- final stage: `resolved_clear` -> `reward_selection` -> confirm -> `run_complete`

Reward types:

1. `persistent_slot_increase`
   - +1 slot for all remaining stages in the current run
   - survives fail/retry/reset/advance
   - cleared only on full run restart
2. `next_stage_slot_increase`
   - +2 slots for the next stage only
   - stored as pending after reward confirmation
   - becomes current-stage temporary bonus on next-stage entry
   - survives retry/reset within that stage
   - expires when a later stage is entered

Effective slot rule:

- `effectiveSlotBonus = persistentSlotBonus + currentStageTemporarySlotBonus`

Reward-added slot placement:

- Reward-added slots are inserted immediately before the final initial slot.
- The final terminal Bomb remains final.
- `StageDefinition` is never mutated.

Reward selection controls:

- `N` from `resolved_clear` enters `reward_selection`.
- `Left`/`Right` select reward option.
- `Return` confirms reward.
- Slot edit/sim/reset inputs are blocked during `reward_selection`.

Deterministic reward policy:

- Fixed two choices per stage.
- No RNG in Prototype 1.2.

Final-stage reward policy:

- Final-stage reward is still selected and applied for lifecycle consistency.
- It has no downstream gameplay effect before run restart.
- This is explicit prototype behavior and may change later.

Stage availability policy:

- `stage.allowedObjectKeys` remains stage-level teaching/QA availability.
- It is not ownership, inventory, or unlock state.

---

# 10. Postponed Mechanics

## Split

Status:

Postponed.

Reason:

Split rule specifications are not finalized.

Proper Split requires:

- A finalized gameplay rule specification
- Deterministic interaction rules with Store, Release, and Explode
- Clear catalog placement relative to the seven core attributes

Those decisions are intentionally postponed until the core seven-attribute framework is validated.

Split will be reconsidered after the linear reaction system is fully validated.

---

# 11. Development Roadmap

Current priority:

1. Run inventory / object ownership model
2. Object acquisition rewards
3. Upgrade acquisition/application model
4. Integrate ownership with stage allowed-object teaching rules
5. Save/load later
6. Shop/currency later

---

# 12. Design Decisions

## Prototype 1.2 Reward Scope

Prototype 1.2 intentionally postpones:

- Owned object state
- Object acquisition rewards
- Upgrade rewards

Reason:

- `stage.allowedObjectKeys` is stage teaching availability, not ownership.
- Ownership and upgrade semantics should be designed together in Prototype 1.3.
- Prototype 1.2 validates reward phase/lifetime behavior using slot-space rewards only.

## Core Attribute Roles

The seven core roles are fixed:

- Ignite
- Amplify
- Store
- Release
- Charge
- Echo
- Explode

---

## Core Object Strategy

Content expansion is based on attribute combinations.

Target:

- 7 single-attribute objects
- 21 dual-attribute objects
- 28 total core objects

Dual-attribute execution order is explicit and data-driven, with some entries provisional during prototyping.

Split remains postponed.

Gate and Delay are not part of the seven core attributes.

---

## Charge Naming Decision

Convert was replaced by Charge.

Reason:

The accepted mechanic prepares the next eligible attribute for a one-time efficiency bonus; it does not convert a reaction property.

The name Convert remains available for a possible future true property-conversion mechanic.

Charge is idempotent and is not a toggle.

Core framework remains 7 single + 21 dual = 28 objects.

---

## Echo Replay Decision

Echo uses eligible handler replay, not delta replay.

Delta replay was rejected because it can violate resource invariants, such as producing negative StoredRV when replaying Release.

Echo replay is not a separate global simulation step.

Echo cannot replay Echo or synthetic replay.

Pulse Valve, Kaleidoscope, and Cluster Bomb execution orders were changed to preserve meaningful behavior without special-case execution rules.
Resonant Spark is finalized as `Ignite -> Echo`.

---

## Simulation Philosophy

The simulator should remain:

- Deterministic
- Data-driven
- Easy to debug
- Easy to extend

Gameplay depth should emerge from the interaction of simple systems rather than increasingly complex rules.

---

# 13. Unresolved Rule Specifications

The following items are unresolved and must not be treated as finalized:

- Exact Charge efficiency parameters
- Complete Explode detailed specification
- Whether upgrades are permanent, run-based, or object-instance based
- Exact numerical balance values
- Object naming/theme pass
- Run inventory / object ownership / acquisition / upgrade / save runtime systems

---

# 14. Detailed Attribute Specifications

- Release: docs/attributes/release.md - finalized and implemented
- Charge: docs/attributes/charge.md - finalized and implemented
- Echo: docs/attributes/echo.md - finalized and implemented
- Explode: detailed specification not yet finalized

---

# 15. Design Stability

The following are considered stable unless a major redesign occurs:

- Core gameplay loop
- Seven core attribute roles
- 28 core object framework
- Deterministic simulation
- Data-driven architecture

The following are intentionally expected to evolve during prototyping:

- Individual attribute rules
- Numerical balance
- Upgrade rules
- Future mechanics
- Object parameter tuning
