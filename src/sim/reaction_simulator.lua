-- Prototype 0.95 deterministic reaction simulator.

local M = {}
local ObjectCatalogValidator = require("src.data.object_catalog_validator")
local SimulationState = require("src.sim.simulation_state")
local AttributeHandlers = require("src.sim.attribute_handlers")
local AttributeExecutor = require("src.sim.attribute_executor")

local SUPPORTED_ATTRIBUTE_KEYS = {
  ignite = true,
  amplify = true,
  store = true,
  release = true,
  charge = true,
  echo = true,
  explode = true,
}

local ATTRIBUTE_HANDLERS = AttributeHandlers.HANDLERS

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

---Runs one deterministic reaction simulation.
---@param stageDef table
---@param objectDefs table
---@param runtimeSlots table
---@return table result
function M.simulate(stageDef, objectDefs, runtimeSlots)
  local state = SimulationState.newState()
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

  local catalog_validation = ObjectCatalogValidator.validateCatalog(objectDefs, SUPPORTED_ATTRIBUTE_KEYS)
  if not catalog_validation.ok then
    local first_error = catalog_validation.errors[1] or {
      code = "ERR_INVALID_OBJECTS",
      note = "Object catalog validation failed.",
    }
    return build_result(false, state, stageDef, log, first_error)
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

      local attributes = object_def.attributes

      local attribute_count = #attributes
      for attribute_index, attribute_entry in ipairs(attributes) do
        if state.ended then
          break
        end

        step = step + 1
        local execution = AttributeExecutor.executeStep({
          state = state,
          handlers = ATTRIBUTE_HANDLERS,
          log = log,
          step = step,
          slotIndex = slot_index,
          objectKey = object_key,
          stageDef = stageDef,
          attributeIndex = attribute_index,
          attributeCount = attribute_count,
          attributeEntry = attribute_entry,
        })
        if not execution.ok and execution.kind == "dispatch_error" then
          return build_result(false, state, stageDef, log, execution.error)
        end
        local handler_result = execution.handlerResult
        local attribute_key = attribute_entry.key

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
