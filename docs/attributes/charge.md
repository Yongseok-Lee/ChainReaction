# Charge Attribute Specification (Prototype 0.x)

Status: Finalized for Prototype acceptance

Scope:
- Gameplay rule specification only
- No implementation details
- Linear deterministic slot execution
- Compatible with the current seven core attributes and 28-object framework

---

## 1) Purpose

Charge sets the reaction into a temporary boosted state for the next eligible reaction step.

Charge exists to create ordering decisions without directly changing reaction value resources.

---

## 2) Runtime State

Charge introduces one reaction-state flag:

- `reactionState = Stable | Charged`

Default at simulation start:

- `reactionState = Stable`

Charge does not introduce additional resource pools.

---

## 3) Preconditions

- Charge requires Ignite to have already started the reaction.
- Charge is invalid after the reaction has ended.

Error behavior:

- Charge before Ignite returns `ERR_PRECONDITION`.
- Charge after Explode returns `ERR_INVALID_STATE`.

---

## 4) State Transition Rules

Charge is idempotent and state-only.

- `Stable -> Charged`
- `Charged -> Charged`

Charge itself never modifies:

- `RV`
- `StoredRV`
- `damage`

Charge only updates `reactionState`.

---

## 5) Eligible Consumption Rules

Charged state persists until one eligible attribute consumes it.

Eligible consumers:

- Amplify
- Store
- Explode

Ineligible (do not consume Charged):

- Ignite
- Release
- Charge
- Echo (interaction deferred)

Consumption rule:

1. Eligible attribute executes.
2. It receives Charge efficiency bonus by its formula schema.
3. Charged is consumed immediately after that eligible step.
4. `reactionState` returns to `Stable`.

---

## 6) Formula Schemas (Parameterized Only)

The exact numeric values are not finalized.

Parameter names:

- `chargeAmplifyEfficiency`
- `chargeStoreEfficiency`
- `chargeExplodeEfficiency`

### 6.1 Charged Amplify

Let:

- `baseAmplifyResult` = Amplify result under normal (Stable) rules

If `reactionState = Charged` when Amplify executes:

- `RV_after = baseAmplifyResult * chargeAmplifyEfficiency`

Then consume Charged and return to Stable.

### 6.2 Charged Store

Let:

- `baseStoreDeposit` = Store deposit amount under normal (Stable) rules

If `reactionState = Charged` when Store executes:

- `StoredRV_after = StoredRV_before + (baseStoreDeposit * chargeStoreEfficiency)`

`RV` behavior follows normal Store rule shape.  
Then consume Charged and return to Stable.

### 6.3 Charged Explode

Let:

- `baseExplodeDamageContribution` = Explode contribution under normal (Stable) rules

If `reactionState = Charged` when Explode executes:

- `damage_after = damage_before + (baseExplodeDamageContribution * chargeExplodeEfficiency)`

Explode termination/consumption behavior remains otherwise unchanged.  
Charged is consumed as part of that eligible step.

---

## 7) Logging Requirements

Every Charge and Charge-consumed eligible step must include normal simulation log fields and state fields.

Required per-step fields:

- `rvBefore`
- `rvAfter`
- `storedBefore`
- `storedAfter`
- `damageBefore`
- `damageAfter`
- `note`
- `code`
- `reactionStateBefore`
- `reactionStateAfter`
- `chargeApplied` (boolean)
- `chargeConsumed` (boolean)

Guidance:

- Charge step: `chargeApplied = false`, `chargeConsumed = false`
- Charged eligible step: `chargeApplied = true`, `chargeConsumed = true`
- Ineligible step while Charged: both `false`

---

## 8) Acceptance Scenarios (Given / When / Then)

Unless otherwise stated, scenarios assume current prototype baseline:

- Spark (Ignite) initializes reaction
- Fuel is Amplify
- Crystal is Store
- Valve is Release
- Bomb is Explode
- Charge state starts as Stable
- Charge formulas use parameter symbols only (no fixed constants)

Initial simulation state:

- `RV = 0`
- `StoredRV = 0`
- `damage = 0`
- `started = false`
- `ended = false`
- `reactionState = Stable`

---

### Scenario A: Charge before Amplify

Given: `Spark -> Catalyst -> Fuel -> Bomb`  
When executed  
Then:

1. Spark starts reaction.
2. Catalyst sets state to Charged.
3. Fuel executes Charged Amplify formula.
4. Charged is consumed; state returns Stable.
5. Bomb executes in Stable unless re-charged before it.

Expected:

- Charge affects Fuel once.
- No direct RV change at Catalyst step.

---

### Scenario B: Charge before Store

Given: `Spark -> Catalyst -> Crystal -> Bomb`  
When executed  
Then:

1. Catalyst sets Charged.
2. Crystal executes Charged Store formula.
3. Charged is consumed immediately after Crystal.

Expected:

- Store receives one-time charged efficiency.
- Bomb executes Stable unless re-charged.

---

### Scenario C: Charge before Explode

Given: `Spark -> Catalyst -> Bomb`  
When executed  
Then:

1. Catalyst sets Charged.
2. Bomb executes Charged Explode formula.
3. Charged is consumed by Bomb.
4. Reaction ends.

---

### Scenario D: Charge then Release then Amplify

Given: `Spark -> Catalyst -> Valve -> Fuel -> Bomb`  
When executed  
Then:

1. Catalyst sets Charged.
2. Release executes and does not consume Charged.
3. Fuel executes as charged eligible target.
4. Charged is consumed after Fuel.

Expected:

- Release behavior remains finalized Full Merge and unchanged.

---

### Scenario E: Consecutive Charges

Given: `Spark -> Catalyst -> Catalyst -> Fuel -> Bomb`  
When executed  
Then:

1. First Catalyst: `Stable -> Charged`
2. Second Catalyst: `Charged -> Charged` (idempotent)
3. Fuel consumes Charged once.

Expected:

- No toggle-cancel behavior.
- Still only one charged consumption on next eligible attribute.

---

### Scenario F: Charge before Ignite

Given a chain where Catalyst executes before Spark  
When Catalyst executes with reaction not started  
Then:

- return `ERR_PRECONDITION`
- simulation fails at that step

---

### Scenario G: Charge after Explode

Given a chain containing `... -> Bomb -> Catalyst`  
When Catalyst is evaluated after reaction ended  
Then:

- return `ERR_INVALID_STATE`

Note:

- In traversal models that stop immediately after Explode, this step may be unreachable.
- Rule remains locked for any context where Catalyst is evaluated with `ended=true`.

---

### Scenario H: Charged survives multiple ineligible attributes

Given: `Spark -> Catalyst -> Valve -> Catalyst -> Valve -> Fuel -> Bomb`  
When executed  
Then:

- Charge persists through ineligible steps (Release, Charge).
- Charge is consumed only at first eligible step (Fuel).

Expected:

- Exactly one eligible charged consumption unless a new Charge occurs later.

---

### Scenario I: Deterministic repeated simulation

Given identical stage slots, object data, and parameter values  
When simulation runs multiple times  
Then every run must produce identical:

- final damage
- final RV and StoredRV
- reactionState transitions
- ordered log entries

---

### Scenario J: Runtime reset between simulations

Given a previous run that entered Charged  
When a new simulation starts  
Then initial state resets to:

- `reactionState = Stable`
- no carryover charged status from prior run

---

## 9) Edge Cases

- Charge when already Charged is valid and idempotent.
- Charged with no later eligible attribute in chain:
  - no consumption occurs before termination/failure.
- Multiple eligible attributes after one Charge:
  - only the first eligible consumes charged bonus.
- Charge directly before ineligible attributes:
  - persists until eligible consumer appears.
- Chains without Catalyst:
  - behave exactly as Stable baseline.

---

## 10) Deferred Rules

The following remain unresolved and are intentionally deferred:

- Exact numeric values for Charge efficiencies
- Echo interaction with Charge
- Any typed-property conversion behavior
- Any non-linear/branching interactions
- Extended balancing rules beyond the parameterized schemas

---

## 11) Implementation Acceptance Checklist

- [ ] Default state at simulation start is Stable.
- [ ] Charge sets Stable -> Charged.
- [ ] Charge on Charged remains Charged (idempotent).
- [ ] Charge does not directly change RV, StoredRV, or damage.
- [ ] Eligible consumers are exactly: Amplify, Store, Explode.
- [ ] Ignite does not consume Charged.
- [ ] Release does not consume Charged.
- [ ] Charge does not consume Charged.
- [ ] Charged is consumed immediately after one eligible charged step.
- [ ] State returns to Stable after charged eligible consumption.
- [ ] Formula schemas use parameters only (no hardcoded constants).
- [ ] Charge before Ignite returns ERR_PRECONDITION.
- [ ] Charge after Explode returns ERR_INVALID_STATE.
- [ ] Required log fields include reaction-state and charge application/consumption flags.
- [ ] Deterministic repeated runs produce identical outputs.
- [ ] Runtime state resets to Stable between simulations.
