-- Prototype 1.1 stage progression manager.
-- Owns stage sequence/index/transition only.

local StageManager = {}
StageManager.__index = StageManager

local function assert_condition(condition, message)
  assert(condition, message)
end

local function is_finite_number(value)
  return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function is_dense_array(value)
  if type(value) ~= "table" then
    return false
  end
  local count = 0
  local max_index = 0
  for key, _ in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
      return false
    end
    count = count + 1
    if key > max_index then
      max_index = key
    end
  end
  return max_index == count
end

local function validate_allowed_object_keys(stage_key, stage, object_defs)
  local allowed = stage.allowedObjectKeys
  if allowed == nil then
    return
  end

  assert_condition(
    is_dense_array(allowed),
    "stage.allowedObjectKeys must be a dense array for stage: " .. stage_key
  )
  assert_condition(#allowed > 0, "stage.allowedObjectKeys must be non-empty for stage: " .. stage_key)

  local seen = {}
  for i, object_key in ipairs(allowed) do
    assert_condition(
      type(object_key) == "string" and object_key ~= "",
      "allowedObjectKeys entries must be non-empty strings for stage: " .. stage_key
    )
    assert_condition(not seen[object_key], "Duplicate allowedObjectKeys entry: " .. object_key)
    seen[object_key] = true
    assert_condition(
      object_defs[object_key] ~= nil,
      "allowedObjectKeys entry not found in objectDefs: " .. object_key
    )
  end
end

local function validate_stage(stage_key, stage, object_defs)
  assert_condition(type(stage) == "table", "Stage definition must be a table for key: " .. tostring(stage_key))
  assert_condition(type(stage.key) == "string" and stage.key ~= "", "stage.key must be a non-empty string")
  assert_condition(stage.key == stage_key, "stage.key must match catalog stage key: " .. stage_key)

  assert_condition(
    is_finite_number(stage.targetDamage) and stage.targetDamage >= 0,
    "stage.targetDamage must be a finite non-negative number for stage: " .. stage_key
  )

  assert_condition(
    is_dense_array(stage.initialSlots),
    "stage.initialSlots must be a dense array for stage: " .. stage_key
  )

  for i, slot in ipairs(stage.initialSlots) do
    assert_condition(type(slot) == "table", "stage.initialSlots entries must be tables")
    local object_key = slot.objectKey
    if object_key ~= nil then
      assert_condition(type(object_key) == "string" and object_key ~= "", "slot.objectKey must be string or nil")
      assert_condition(object_defs[object_key] ~= nil, "slot.objectKey not found in objectDefs: " .. object_key)
    end
  end

  validate_allowed_object_keys(stage_key, stage, object_defs)
end

local function validate_catalog(stage_catalog, object_defs)
  assert_condition(type(stage_catalog) == "table", "stageCatalog must be a table")
  assert_condition(type(object_defs) == "table", "objectDefs must be a table")

  local order = stage_catalog.order
  local stages = stage_catalog.stages
  assert_condition(type(order) == "table", "stageCatalog.order must be a table")
  assert_condition(type(stages) == "table", "stageCatalog.stages must be a table")

  assert_condition(is_dense_array(order), "stageCatalog.order must be a dense array")
  assert_condition(#order > 0, "stageCatalog.order must be non-empty")

  local seen = {}
  for i, stage_key in ipairs(order) do
    assert_condition(type(stage_key) == "string" and stage_key ~= "", "stage key must be a non-empty string")
    assert_condition(not seen[stage_key], "Duplicate stage key in stageCatalog.order: " .. stage_key)
    seen[stage_key] = true

    local stage = stages[stage_key]
    assert_condition(stage ~= nil, "Stage key in order missing from stageCatalog.stages: " .. stage_key)
    validate_stage(stage_key, stage, object_defs)
  end
end

function StageManager.new(stage_catalog, object_defs)
  validate_catalog(stage_catalog, object_defs)

  local self = setmetatable({}, StageManager)
  self._catalog = stage_catalog
  self._index = 1
  return self
end

function StageManager:getCurrentStage()
  local stage_key = self._catalog.order[self._index]
  return self._catalog.stages[stage_key]
end

function StageManager:getCurrentStageKey()
  return self._catalog.order[self._index]
end

function StageManager:getCurrentStageIndex()
  return self._index
end

function StageManager:getStageCount()
  return #self._catalog.order
end

function StageManager:isLastStage()
  return self._index == #self._catalog.order
end

function StageManager:advance()
  if self:isLastStage() then
    return false
  end
  self._index = self._index + 1
  return true
end

function StageManager:restartRun()
  self._index = 1
end

return StageManager
