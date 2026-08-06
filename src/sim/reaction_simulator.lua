-- Prototype 0.9 deterministic reaction simulator.

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

local function is_eligible_echo_source(attribute_key)
  return attribute_key == "amplify" or attribute_key == "store" or attribute_key == "release"
end

local ATTRIBUTE_HANDLERS

ATTRIBUTE_HANDLERS = {
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

    local replay_handler = ATTRIBUTE_HANDLERS[source.attribute]
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

    local replay_result = replay_handler(state, source.params, replay_ctx)
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

local function build_result(success, state, stage_def, log, error_data)
  local cleared = false
  if type(stage_def) == "table" and type(stage_def.targetDamage) == "number" then
    cleared = state.damage >= stage_def.targetDamage
  end

  return {
    damage = state.damage,
    finalRV = state.rv,
    finalReactionState = state.reactionState,
    cleared = cleared,
    success = success,
    log = log,
    error = error_data,
  }
end

local function validate_object_attributes(object_def, object_key, slot_index)
  if type(object_def) ~= "table" then
    return nil, {
      code = "ERR_INVALID_OBJECT_DEF",
      note = "Object definition must be a table.",
      objectKey = object_key,
      slotIndex = slot_index,
    }
  end

  local attributes = object_def.attributes
  if type(attributes) ~= "table" then
    return nil, {
      code = "ERR_INVALID_OBJECT_ATTRIBUTES",
      note = "Object attributes must be a non-empty ordered table.",
      objectKey = object_key,
      slotIndex = slot_index,
    }
  end

  local attribute_count = #attributes
  if attribute_count == 0 then
    return nil, {
      code = "ERR_INVALID_OBJECT_ATTRIBUTES",
      note = "Object attributes must be non-empty.",
      objectKey = object_key,
      slotIndex = slot_index,
    }
  end
  if attribute_count > 2 then
    return nil, {
      code = "ERR_INVALID_OBJECT_ATTRIBUTES",
      note = "Object attributes exceed Prototype 0.8 maximum count of 2.",
      objectKey = object_key,
      slotIndex = slot_index,
    }
  end

  local seen = {}
  for attribute_index, entry in ipairs(attributes) do
    if type(entry) ~= "table" then
      return nil, {
        code = "ERR_INVALID_OBJECT_ATTRIBUTES",
        note = "Attribute entry must be a table.",
        objectKey = object_key,
        slotIndex = slot_index,
        attributeIndex = attribute_index,
      }
    end

    local key = entry.key
    if type(key) ~= "string" or key == "" then
      return nil, {
        code = "ERR_INVALID_OBJECT_ATTRIBUTES",
        note = "Attribute key must be a non-empty string.",
        objectKey = object_key,
        slotIndex = slot_index,
        attributeIndex = attribute_index,
      }
    end

    if type(entry.params) ~= "table" then
      return nil, {
        code = "ERR_INVALID_OBJECT_ATTRIBUTES",
        note = "Attribute params must be a table.",
        objectKey = object_key,
        slotIndex = slot_index,
        attributeIndex = attribute_index,
        attribute = key,
      }
    end

    if seen[key] then
      return nil, {
        code = "ERR_DUPLICATE_ATTRIBUTE",
        note = "Duplicate attribute keys are invalid for one object.",
        objectKey = object_key,
        slotIndex = slot_index,
        attributeIndex = attribute_index,
        attribute = key,
      }
    end
    seen[key] = true

    if type(ATTRIBUTE_HANDLERS[key]) ~= "function" then
      return nil, {
        code = "ERR_UNSUPPORTED_ATTRIBUTE",
        note = "No handler exists for object attribute.",
        objectKey = object_key,
        slotIndex = slot_index,
        attributeIndex = attribute_index,
        attribute = key,
      }
    end
  end

  return attributes, nil
end

---Runs one deterministic reaction simulation.
---@param stageDef table
---@param objectDefs table
---@param runtimeSlots table
---@return table result
function M.simulate(stageDef, objectDefs, runtimeSlots)
  local state = {
    rv = 0,
    storedRV = 0,
    damage = 0,
    reactionState = "stable",
    chargeEfficiencies = {
      chargeAmplifyEfficiency = 1,
      chargeStoreEfficiency = 1,
      chargeExplodeEfficiency = 1,
    },
    lastRealStep = nil,
    started = false,
    ended = false,
  }
  local log = {}

  if type(stageDef) ~= "table" then
    return build_result(false, state, stageDef, log, {
      code = "ERR_INVALID_STAGE",
      note = "stageDef must be a table.",
    })
  end

  if type(objectDefs) ~= "table" then
    return build_result(false, state, stageDef, log, {
      code = "ERR_INVALID_OBJECTS",
      note = "objectDefs must be a table.",
    })
  end

  if type(runtimeSlots) ~= "table" then
    return build_result(false, state, stageDef, log, {
      code = "ERR_INVALID_SLOTS",
      note = "runtimeSlots must be a table.",
    })
  end

  local step = 0
  for slot_index, slot in ipairs(runtimeSlots) do
    local object_key = type(slot) == "table" and slot.objectKey or nil
    if object_key ~= nil then
      local object_def = objectDefs[object_key]
      if object_def == nil then
        return build_result(false, state, stageDef, log, {
          code = "ERR_INVALID_OBJECT_DEF",
          note = "Object key not found in definitions.",
          slotIndex = slot_index,
          objectKey = object_key,
        })
      end

      local attributes, object_validation_error =
        validate_object_attributes(object_def, object_key, slot_index)
      if object_validation_error then
        return build_result(false, state, stageDef, log, object_validation_error)
      end

      local attribute_count = #attributes
      for attribute_index, attribute_entry in ipairs(attributes) do
        if state.ended then
          break
        end

        step = step + 1
        local attribute_key = attribute_entry.key
        local handler = ATTRIBUTE_HANDLERS[attribute_key]
        local rv_before = state.rv
        local stored_before = state.storedRV
        local damage_before = state.damage
        local reaction_state_before = state.reactionState
        local ctx = {
          step = step,
          slotIndex = slot_index,
          objectKey = object_key,
          attributeIndex = attribute_index,
          attributeCount = attribute_count,
          attribute = attribute_key,
          stage = stageDef,
        }
        local handler_result = handler(state, attribute_entry.params, ctx)
        local rv_after = state.rv
        local stored_after = state.storedRV
        local damage_after = state.damage
        local reaction_state_after = state.reactionState
        local handler_meta = handler_result.meta or {}

        state.lastRealStep = {
          attribute = attribute_key,
          params = attribute_entry.params,
          step = step,
          slotIndex = slot_index,
          objectKey = object_key,
          attributeIndex = attribute_index,
          attributeCount = attribute_count,
          succeeded = handler_result.ok == true,
          eligibleEchoSource = handler_result.ok == true and is_eligible_echo_source(attribute_key),
        }

        log[#log + 1] = {
          step = step,
          slotIndex = slot_index,
          objectKey = object_key,
          attributeIndex = attribute_index,
          attributeCount = attribute_count,
          attribute = attribute_key,
          rvBefore = rv_before,
          rvAfter = rv_after,
          storedBefore = stored_before,
          storedAfter = stored_after,
          damageBefore = damage_before,
          damageAfter = damage_after,
          reactionStateBefore = reaction_state_before,
          reactionStateAfter = reaction_state_after,
          chargeActivated = handler_meta.chargeActivated == true,
          chargeBonusApplied = handler_meta.chargeBonusApplied == true,
          chargeConsumed = handler_meta.chargeConsumed == true,
          echoApplied = handler_meta.echoApplied,
          echoSourceStep = handler_meta.echoSourceStep,
          echoSourceSlotIndex = handler_meta.echoSourceSlotIndex,
          echoSourceObjectKey = handler_meta.echoSourceObjectKey,
          echoSourceAttribute = handler_meta.echoSourceAttribute,
          echoSourceAttributeIndex = handler_meta.echoSourceAttributeIndex,
          echoNoopReason = handler_meta.echoNoopReason,
          echoReplaySucceeded = handler_meta.echoReplaySucceeded,
          echoReplayErrorCode = handler_meta.echoReplayErrorCode,
          note = handler_result.note,
          code = handler_result.code,
        }

        if not handler_result.ok then
          return build_result(false, state, stageDef, log, {
            code = handler_result.code or "ERR_HANDLER",
            note = handler_result.note or "Attribute handler failed.",
            step = step,
            slotIndex = slot_index,
            objectKey = object_key,
            attributeIndex = attribute_index,
            attribute = attribute_key,
            meta = handler_result.meta,
          })
        end
      end

      if state.ended then
        break
      end
    end
  end

  if not state.started then
    return build_result(false, state, stageDef, log, {
      code = "ERR_PRECONDITION",
      note = "Simulation ended without Ignite.",
    })
  end

  if not state.ended then
    return build_result(false, state, stageDef, log, {
      code = "ERR_PRECONDITION",
      note = "Simulation ended without Explode.",
    })
  end

  return build_result(true, state, stageDef, log, nil)
end

return M
