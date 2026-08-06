-- Prototype 0.95 per-step attribute execution and logging.

local M = {}

local function is_eligible_echo_source(attribute_key)
  return attribute_key == "amplify" or attribute_key == "store" or attribute_key == "release"
end

local function build_dispatch(handlers)
  return function(attribute_key, state, params, ctx)
    local handler = handlers[attribute_key]
    if type(handler) ~= "function" then
      return {
        ok = false,
        code = "ERR_UNSUPPORTED_ATTRIBUTE",
        note = "No handler exists for object attribute.",
        meta = nil,
      }
    end
    return handler(state, params, ctx)
  end
end

function M.executeStep(args)
  local state = args.state
  local handlers = args.handlers
  local log = args.log
  local step = args.step
  local slot_index = args.slotIndex
  local object_key = args.objectKey
  local stage_def = args.stageDef
  local attribute_index = args.attributeIndex
  local attribute_count = args.attributeCount
  local attribute_entry = args.attributeEntry

  local attribute_key = attribute_entry.key
  local handler = handlers[attribute_key]
  if type(handler) ~= "function" then
    return {
      ok = false,
      kind = "dispatch_error",
      error = {
        code = "ERR_UNSUPPORTED_ATTRIBUTE",
        note = "No handler exists for object attribute.",
        step = step,
        slotIndex = slot_index,
        objectKey = object_key,
        attributeIndex = attribute_index,
        attribute = attribute_key,
      },
    }
  end

  local rv_before = state.rv
  local stored_before = state.storedRV
  local damage_before = state.damage
  local reaction_state_before = state.reactionState
  local dispatch = build_dispatch(handlers)
  local ctx = {
    step = step,
    slotIndex = slot_index,
    objectKey = object_key,
    attributeIndex = attribute_index,
    attributeCount = attribute_count,
    attribute = attribute_key,
    stage = stage_def,
    dispatch = dispatch,
    resolveHandler = function(key)
      return handlers[key]
    end,
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

  return {
    ok = true,
    kind = "executed",
    handlerResult = handler_result,
  }
end

return M
