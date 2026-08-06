# Release Attribute Specification (Prototype 0.6)

Status: Finalized for Prototype 0.6 acceptance

Scope:
- Gameplay rule specification only
- No implementation details
- Linear deterministic slot execution
- Compatible with the current seven core attributes and 28-object framework

---

## 1) Canonical Rule (Full Merge)

Release is finalized as **Full Merge**.

- `RV_after = RV_before + StoredRV_before`
- `StoredRV_after = 0`

Release transfers stored numerical value into active flow and clears storage.

---

## 2) Locked Rules

### 2.1 Preconditions

- Release requires Ignite to have already started the reaction.
- Release is invalid after the reaction has ended.

### 2.2 Zero-Storage Behavior

- Release with `StoredRV = 0` is a valid no-op.
- It must not produce an error.

### 2.3 Multiple Release Behavior

- Multiple Release objects are allowed in one chain.
- Each Release uses the current state at its execution step.
- A Release after another Release is normally a no-op unless Store added new `StoredRV` in between.

### 2.4 Sequential Processing

- No special-case interactions are added.
- Store, Release, Amplify, and Explode execute strictly by slot/attribute order.

### 2.5 Numeric Policy

- `RV` and `StoredRV` use finite Lua numbers.
- Values are not restricted to integers.
- Release introduces no rounding.

### 2.6 Convert Compatibility

- Prototype 0.6 Release transfers numerical value only.
- Reaction property metadata behavior remains unresolved until Convert is specified.

### 2.7 Echo Compatibility

- Release interaction with Echo remains unresolved until Echo is specified.
- No Echo rule is defined in this document.

### 2.8 Logging Requirements

Every Release log entry must include:

- `rvBefore`
- `rvAfter`
- `storedBefore`
- `storedAfter`
- `damageBefore`
- `damageAfter`
- `note`
- `code`

### 2.9 Error Behavior

- Release before Ignite returns `ERR_PRECONDITION`.
- Release after Explode returns `ERR_INVALID_STATE`.
- Zero `StoredRV` is not an error.

---

## 3) Acceptance Scenarios (Given/When/Then)

Unless otherwise stated, scenarios use these current prototype assumptions:

- Spark (Ignite) sets `RV = 1`
- Fuel (Amplify) applies `RV = RV * 2`
- Store adds current `RV` into `StoredRV`
- Release follows Full Merge
- Explode converts current final state to damage as:
  - `damage += RV + StoredRV`
  - then reaction ends and pools are consumed

Initial state for each simulation:

- `RV = 0`
- `StoredRV = 0`
- `damage = 0`
- `started = false`
- `ended = false`

---

### Scenario A: Spark -> Store -> Release -> Bomb

Given a chain: `Spark -> Store -> Release -> Bomb`  
When the simulation executes in order  
Then:

1. Spark: `RV=1`, `StoredRV=0`
2. Store: `RV=1`, `StoredRV=1`
3. Release: `RV=2`, `StoredRV=0`
4. Bomb: `damage += 2 + 0 = 2`, then `RV=0`, `StoredRV=0`, ended

Expected result:
- `damage = 2`
- success/clear depends on stage target

---

### Scenario B: Spark -> Store -> Release -> Fuel -> Bomb

Given a chain: `Spark -> Store -> Release -> Fuel -> Bomb`  
When executed  
Then:

1. Spark: `RV=1`, `StoredRV=0`
2. Store: `RV=1`, `StoredRV=1`
3. Release: `RV=2`, `StoredRV=0`
4. Fuel: `RV=4`, `StoredRV=0`
5. Bomb: `damage += 4 + 0 = 4`

Expected result:
- `damage = 4`

---

### Scenario C: Spark -> Store -> Release -> Store -> Release -> Bomb

Given the chain above  
When executed  
Then:

1. Spark: `RV=1`, `StoredRV=0`
2. Store: `RV=1`, `StoredRV=1`
3. Release: `RV=2`, `StoredRV=0`
4. Store: `RV=2`, `StoredRV=2`
5. Release: `RV=4`, `StoredRV=0`
6. Bomb: `damage += 4 + 0 = 4`

Expected result:
- `damage = 4`

---

### Scenario D: Spark -> Release -> Bomb

Given a chain: `Spark -> Release -> Bomb`  
When executed  
Then:

1. Spark: `RV=1`, `StoredRV=0`
2. Release (zero stored): valid no-op  
   - `RV=1`, `StoredRV=0`
   - no error
3. Bomb: `damage += 1 + 0 = 1`

Expected result:
- `damage = 1`
- Release step logs normal success with unchanged values

---

### Scenario E: Release before Spark

Given a chain starting with `Release` before any Ignite  
When Release executes with `started=false`  
Then:

- Handler returns `ERR_PRECONDITION`
- Simulation fails at that step
- No further steps are processed

---

### Scenario F: Release after Bomb

Given a chain containing `... -> Bomb -> Release`  
When Release is evaluated after reaction ended  
Then:

- Release returns `ERR_INVALID_STATE`

Note:
- In implementations that stop traversal immediately on explode, this step may be unreachable in normal execution.
- Rule remains locked for any context where Release is evaluated with `ended=true`.

---

### Scenario G: Consecutive Release objects

Given `Spark -> Store -> Release -> Release -> Bomb`  
When executed  
Then:

1. After first Release: `RV=2`, `StoredRV=0`
2. Second Release: valid no-op (`RV=2`, `StoredRV=0`)
3. Bomb: `damage = 2`

Expected:
- no error from second Release
- second Release logs unchanged before/after values

---

### Scenario H: No Store path regression

Given `Spark -> Fuel -> Bomb` (no Release, no Store)  
When executed  
Then behavior must match pre-Release baseline:

1. Spark: `RV=1`
2. Fuel: `RV=2`
3. Bomb: `damage=2`

Expected:
- existing non-Release chains remain unchanged

---

### Scenario I: Repeated simulation determinism

Given identical stage slots and object data  
When simulation is run multiple times  
Then every run must produce identical:

- final `damage`
- final `RV` and `StoredRV`
- success/failure outcome
- ordered log entries (including Release fields)

---

### Scenario J: StoredRV reset between separate simulations

Given a first run that builds non-zero `StoredRV` during execution  
When a new simulation starts  
Then initial state must reset:

- `RV=0`
- `StoredRV=0`
- no carried state from prior run

Expected:
- Release in a new run depends only on that run's Store steps

---

## 4) Finalized Rules

- Release is Full Merge:
  - `RV_after = RV_before + StoredRV_before`
  - `StoredRV_after = 0`
- Release requires Ignite and is invalid after reaction end.
- Release with zero stored value is a valid no-op.
- Multiple Release steps are valid and state-driven.
- Processing order is strictly sequential and deterministic.
- Release introduces no rounding and no integer-only restriction.
- Release defines numeric transfer only; non-numeric metadata behavior is deferred.
- Release logging fields are mandatory as listed.

---

## 5) Explicitly Deferred Rules

- Convert property/type metadata and how Release interacts with that metadata
- Echo targeting/timing/repetition behavior with Release
- Any non-linear or branch-based behavior
- Numerical balance tuning values beyond this canonical merge rule
- Any redesign of explosion lifecycle semantics beyond current prototype conventions

---

## 6) Implementation Acceptance Checklist

- [ ] Full Merge formula is applied exactly.
- [ ] `StoredRV` is set to zero after each successful Release.
- [ ] Release before Ignite returns `ERR_PRECONDITION`.
- [ ] Release after ended reaction returns `ERR_INVALID_STATE`.
- [ ] Release with `StoredRV=0` succeeds as no-op.
- [ ] Multiple Release steps work with current state at each step.
- [ ] Release does not alter sequential execution ordering.
- [ ] Release introduces no rounding behavior.
- [ ] Release logs include all required fields:
      `rvBefore`, `rvAfter`, `storedBefore`, `storedAfter`,
      `damageBefore`, `damageAfter`, `note`, `code`.
- [ ] No-Store chains remain behaviorally unchanged.
- [ ] Repeated runs are deterministic.
- [ ] `StoredRV` resets between separate simulations.
