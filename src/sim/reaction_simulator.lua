-- Prototype 0.1 deterministic reaction simulator.

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

local ATTRIBUTE_HANDLERS = {
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

    state.rv = state.rv * multiplier
    return ok("Reaction value amplified.")
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

    state.damage = state.damage + (state.rv * damage_ratio)
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
    cleared = cleared,
    success = success,
    log = log,
    error = error_data,
  }
end

---Runs one deterministic reaction simulation.
---@param stageDef table
---@param objectDefs table
---@return table result
function M.simulate(stageDef, objectDefs)
  local state = {
    rv = 0,
    damage = 0,
    started = false,
    ended = false,
  }
  local log = {}

  if type(stageDef) ~= "table" or type(stageDef.chain) ~= "table" then
    return build_result(false, state, stageDef, log, {
      code = "ERR_INVALID_STAGE",
      note = "stageDef.chain must be a table.",
    })
  end

  if type(objectDefs) ~= "table" then
    return build_result(false, state, stageDef, log, {
      code = "ERR_INVALID_OBJECTS",
      note = "objectDefs must be a table.",
    })
  end

  for step, object_key in ipairs(stageDef.chain) do
    local object_def = objectDefs[object_key]
    if type(object_def) ~= "table" then
      return build_result(false, state, stageDef, log, {
        code = "ERR_UNKNOWN_OBJECT",
        note = "Object key not found in definitions.",
        step = step,
        objectKey = object_key,
      })
    end

    local attribute = object_def.attribute
    local handler = ATTRIBUTE_HANDLERS[attribute]
    if type(handler) ~= "function" then
      return build_result(false, state, stageDef, log, {
        code = "ERR_UNSUPPORTED_ATTRIBUTE",
        note = "No handler exists for object attribute.",
        step = step,
        objectKey = object_key,
        attribute = attribute,
      })
    end

    local rv_before = state.rv
    local damage_before = state.damage
    local ctx = {
      step = step,
      objectKey = object_key,
      attribute = attribute,
      stage = stageDef,
    }
    local handler_result = handler(state, object_def.params, ctx)
    local rv_after = state.rv
    local damage_after = state.damage

    log[#log + 1] = {
      step = step,
      objectKey = object_key,
      attribute = attribute,
      rvBefore = rv_before,
      rvAfter = rv_after,
      damageBefore = damage_before,
      damageAfter = damage_after,
      note = handler_result.note,
      code = handler_result.code,
    }

    if not handler_result.ok then
      return build_result(false, state, stageDef, log, {
        code = handler_result.code or "ERR_HANDLER",
        note = handler_result.note or "Attribute handler failed.",
        step = step,
        objectKey = object_key,
        attribute = attribute,
        meta = handler_result.meta,
      })
    end

    if state.ended then
      break
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
