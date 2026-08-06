-- Prototype 0.95 attribute handlers.

local M = {}

local function ok(note, meta)
  return {
    ok = true,
    note = note,
    code = nil,
    meta = meta,
  }
end

local function fail(code, note, meta)
  return {
    ok = false,
    note = note,
    code = code,
    meta = meta,
  }
end

local function parse_charge_efficiencies(params)
  if type(params) ~= "table" then
    return nil, "Charge requires params table."
  end

  local amp = params.chargeAmplifyEfficiency
  local store = params.chargeStoreEfficiency
  local explode = params.chargeExplodeEfficiency

  if type(amp) ~= "number" then
    return nil, "Charge requires numeric params.chargeAmplifyEfficiency."
  end
  if type(store) ~= "number" then
    return nil, "Charge requires numeric params.chargeStoreEfficiency."
  end
  if type(explode) ~= "number" then
    return nil, "Charge requires numeric params.chargeExplodeEfficiency."
  end

  return {
    chargeAmplifyEfficiency = amp,
    chargeStoreEfficiency = store,
    chargeExplodeEfficiency = explode,
  }, nil
end

local HANDLERS

HANDLERS = {
  ignite = function(state, params, _ctx)
    if state.started then
      return fail("ERR_INVALID_STATE", "Ignite already processed.")
    end

    local base_rv = params and params.baseRV
    if type(base_rv) ~= "number" then
      return fail("ERR_INVALID_PARAM", "Ignite requires numeric params.baseRV.")
    end

    state.rv = base_rv
    state.started = true
    return ok("Ignite started reaction.")
  end,

  amplify = function(state, params, _ctx)
    if not state.started then
      return fail("ERR_PRECONDITION", "Amplify requires an active reaction.")
    end
    if state.ended then
      return fail("ERR_INVALID_STATE", "Amplify cannot run after explosion.")
    end

    local multiplier = params and params.multiplier
    if type(multiplier) ~= "number" then
      return fail("ERR_INVALID_PARAM", "Amplify requires numeric params.multiplier.")
    end

    local base_amplify_result = state.rv * multiplier
    if state.reactionState == "charged" then
      state.rv = base_amplify_result * state.chargeEfficiencies.chargeAmplifyEfficiency
      state.reactionState = "stable"
      return ok("Reaction value amplified with Charge bonus.", {
        chargeBonusApplied = true,
        chargeConsumed = true,
      })
    end

    state.rv = base_amplify_result
    return ok("Reaction value amplified.")
  end,

  store = function(state, _params, _ctx)
    if not state.started then
      return fail("ERR_PRECONDITION", "Store requires an active reaction.")
    end
    if state.ended then
      return fail("ERR_INVALID_STATE", "Store cannot run after explosion.")
    end

    local base_store_deposit = state.rv
    if state.reactionState == "charged" then
      local charged_deposit = base_store_deposit * state.chargeEfficiencies.chargeStoreEfficiency
      state.storedRV = state.storedRV + charged_deposit
      state.reactionState = "stable"
      return ok("Stored current RV with Charge bonus.", {
        chargeBonusApplied = true,
        chargeConsumed = true,
      })
    end

    state.storedRV = state.storedRV + base_store_deposit
    return ok("Stored current RV into bank.")
  end,

  charge = function(state, params, _ctx)
    if not state.started then
      return fail("ERR_PRECONDITION", "Charge requires an active reaction.")
    end
    if state.ended then
      return fail("ERR_INVALID_STATE", "Charge cannot run after explosion.")
    end

    local charge_efficiencies, err = parse_charge_efficiencies(params)
    if not charge_efficiencies then
      return fail("ERR_INVALID_PARAM", err)
    end

    state.chargeEfficiencies = charge_efficiencies
    if state.reactionState == "charged" then
      return ok("Reaction state is already charged.", {
        chargeActivated = false,
        chargeBonusApplied = false,
        chargeConsumed = false,
      })
    end

    state.reactionState = "charged"
    return ok("Reaction state changed to charged.", {
      chargeActivated = true,
      chargeBonusApplied = false,
      chargeConsumed = false,
    })
  end,

  echo = function(state, _params, ctx)
    if not state.started then
      return fail("ERR_PRECONDITION", "Echo requires an active reaction.", {
        echoApplied = false,
        echoNoopReason = nil,
        echoReplaySucceeded = nil,
        echoReplayErrorCode = nil,
      })
    end
    if state.ended then
      return fail("ERR_INVALID_STATE", "Echo cannot run after explosion.", {
        echoApplied = false,
        echoNoopReason = nil,
        echoReplaySucceeded = nil,
        echoReplayErrorCode = nil,
      })
    end

    local source = state.lastRealStep
    if source == nil then
      return ok("Echo no-op: no previous real step.", {
        echoApplied = false,
        echoSourceStep = nil,
        echoSourceSlotIndex = nil,
        echoSourceObjectKey = nil,
        echoSourceAttribute = nil,
        echoSourceAttributeIndex = nil,
        echoNoopReason = "no-previous-real-step",
        echoReplaySucceeded = nil,
        echoReplayErrorCode = nil,
      })
    end

    if source.succeeded ~= true then
      return ok("Echo no-op: previous real step failed.", {
        echoApplied = false,
        echoSourceStep = source.step,
        echoSourceSlotIndex = source.slotIndex,
        echoSourceObjectKey = source.objectKey,
        echoSourceAttribute = source.attribute,
        echoSourceAttributeIndex = source.attributeIndex,
        echoNoopReason = "previous-step-failed",
        echoReplaySucceeded = nil,
        echoReplayErrorCode = nil,
      })
    end

    if source.eligibleEchoSource ~= true then
      return ok("Echo no-op: previous real step ineligible.", {
        echoApplied = false,
        echoSourceStep = source.step,
        echoSourceSlotIndex = source.slotIndex,
        echoSourceObjectKey = source.objectKey,
        echoSourceAttribute = source.attribute,
        echoSourceAttributeIndex = source.attributeIndex,
        echoNoopReason = "previous-step-ineligible",
        echoReplaySucceeded = nil,
        echoReplayErrorCode = nil,
      })
    end

    local replay_handler = nil
    if type(ctx.resolveHandler) == "function" then
      replay_handler = ctx.resolveHandler(source.attribute)
    else
      replay_handler = HANDLERS[source.attribute]
    end
    if type(replay_handler) ~= "function" then
      return fail("ERR_UNSUPPORTED_ATTRIBUTE", "Echo replay source handler is missing.", {
        echoApplied = true,
        echoSourceStep = source.step,
        echoSourceSlotIndex = source.slotIndex,
        echoSourceObjectKey = source.objectKey,
        echoSourceAttribute = source.attribute,
        echoSourceAttributeIndex = source.attributeIndex,
        echoNoopReason = nil,
        echoReplaySucceeded = false,
        echoReplayErrorCode = "ERR_UNSUPPORTED_ATTRIBUTE",
      })
    end

    local replay_ctx = {
      step = ctx.step,
      slotIndex = ctx.slotIndex,
      objectKey = ctx.objectKey,
      attributeIndex = ctx.attributeIndex,
      attributeCount = ctx.attributeCount,
      attribute = source.attribute,
      stage = ctx.stage,
      isEchoReplay = true,
      originAttribute = "echo",
      echoSourceStep = source.step,
      echoSourceSlotIndex = source.slotIndex,
      echoSourceObjectKey = source.objectKey,
      echoSourceAttribute = source.attribute,
      echoSourceAttributeIndex = source.attributeIndex,
    }

    local replay_result = nil
    if type(ctx.dispatch) == "function" then
      replay_result = ctx.dispatch(source.attribute, state, source.params, replay_ctx)
    else
      replay_result = replay_handler(state, source.params, replay_ctx)
    end
    local replay_meta = replay_result.meta or {}
    if not replay_result.ok then
      return fail(replay_result.code or "ERR_HANDLER", replay_result.note or "Echo replay failed.", {
        echoApplied = true,
        echoSourceStep = source.step,
        echoSourceSlotIndex = source.slotIndex,
        echoSourceObjectKey = source.objectKey,
        echoSourceAttribute = source.attribute,
        echoSourceAttributeIndex = source.attributeIndex,
        echoNoopReason = nil,
        echoReplaySucceeded = false,
        echoReplayErrorCode = replay_result.code or "ERR_HANDLER",
        chargeActivated = replay_meta.chargeActivated == true,
        chargeBonusApplied = replay_meta.chargeBonusApplied == true,
        chargeConsumed = replay_meta.chargeConsumed == true,
      })
    end

    return ok("Echo replayed previous eligible attribute.", {
      echoApplied = true,
      echoSourceStep = source.step,
      echoSourceSlotIndex = source.slotIndex,
      echoSourceObjectKey = source.objectKey,
      echoSourceAttribute = source.attribute,
      echoSourceAttributeIndex = source.attributeIndex,
      echoNoopReason = nil,
      echoReplaySucceeded = true,
      echoReplayErrorCode = nil,
      chargeActivated = replay_meta.chargeActivated == true,
      chargeBonusApplied = replay_meta.chargeBonusApplied == true,
      chargeConsumed = replay_meta.chargeConsumed == true,
    })
  end,

  release = function(state, _params, _ctx)
    if not state.started then
      return fail("ERR_PRECONDITION", "Release requires an active reaction.")
    end
    if state.ended then
      return fail("ERR_INVALID_STATE", "Release cannot run after explosion.")
    end

    state.rv = state.rv + state.storedRV
    state.storedRV = 0
    return ok("Released stored RV into active flow.")
  end,

  explode = function(state, params, _ctx)
    if not state.started then
      return fail("ERR_PRECONDITION", "Explode requires an active reaction.")
    end
    if state.ended then
      return fail("ERR_INVALID_STATE", "Explode already processed.")
    end

    local damage_ratio = params and params.damageRatio
    if type(damage_ratio) ~= "number" then
      return fail("ERR_INVALID_PARAM", "Explode requires numeric params.damageRatio.")
    end

    local total_rv = state.rv + state.storedRV
    local base_explode_damage_contribution = total_rv * damage_ratio
    if state.reactionState == "charged" then
      local charged_damage =
        base_explode_damage_contribution * state.chargeEfficiencies.chargeExplodeEfficiency
      state.damage = state.damage + charged_damage
      state.reactionState = "stable"
      state.rv = 0
      state.storedRV = 0
      state.ended = true
      return ok("Explosion converted RV to damage with Charge bonus.", {
        chargeBonusApplied = true,
        chargeConsumed = true,
      })
    end

    state.damage = state.damage + base_explode_damage_contribution
    state.rv = 0
    state.storedRV = 0
    state.ended = true
    return ok("Explosion converted RV to damage.")
  end,
}

M.HANDLERS = HANDLERS

return M
