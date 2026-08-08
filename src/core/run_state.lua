-- Prototype 1.2 run reward state owner.
-- Owns run-level reward bonuses and reward selection state only.

local RunState = {}
RunState.__index = RunState

local SUPPORTED_TYPES = {
  persistent_slot_increase = true,
  next_stage_slot_increase = true,
}

local function assert_condition(condition, message)
  assert(condition, message)
end

local function is_finite_number(value)
  return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function is_positive_integer(value)
  return is_finite_number(value) and value % 1 == 0 and value > 0
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

local function copy_reward_option(definition)
  return {
    key = definition.key,
    type = definition.type,
    slotDelta = definition.slotDelta,
    label = definition.label,
  }
end

local function copy_reward_options(options)
  if type(options) ~= "table" then
    return {}
  end

  local copied = {}
  for i, option in ipairs(options) do
    copied[i] = copy_reward_option(option)
  end
  return copied
end

local function validate_definition(catalog_key, definition)
  assert_condition(type(definition) == "table", "Reward definition must be a table for key: " .. catalog_key)
  assert_condition(
    type(definition.key) == "string" and definition.key ~= "",
    "Reward definition key must be a non-empty string for key: " .. catalog_key
  )
  assert_condition(
    definition.key == catalog_key,
    "Reward definition key field must match catalog key: " .. catalog_key
  )
  assert_condition(
    type(definition.type) == "string" and SUPPORTED_TYPES[definition.type],
    "Unsupported reward type for key: " .. catalog_key
  )
  assert_condition(
    is_positive_integer(definition.slotDelta),
    "Reward slotDelta must be a finite positive integer for key: " .. catalog_key
  )
  assert_condition(type(definition.label) == "string" and definition.label ~= "", "Reward label must be non-empty.")

  if definition.type == "persistent_slot_increase" then
    assert_condition(definition.slotDelta == 1, "persistent_slot_increase must use slotDelta = 1")
  elseif definition.type == "next_stage_slot_increase" then
    assert_condition(definition.slotDelta == 2, "next_stage_slot_increase must use slotDelta = 2")
  end
end

local function validate_catalog(catalog, stage_catalog)
  assert_condition(type(catalog) == "table", "rewardCatalog must be a table.")
  assert_condition(type(catalog.definitions) == "table", "rewardCatalog.definitions must be a table.")
  assert_condition(type(catalog.byStage) == "table", "rewardCatalog.byStage must be a table.")
  assert_condition(type(stage_catalog) == "table", "stageCatalog must be a table.")
  assert_condition(type(stage_catalog.order) == "table", "stageCatalog.order must be a table.")
  assert_condition(type(stage_catalog.stages) == "table", "stageCatalog.stages must be a table.")
  assert_condition(is_dense_array(stage_catalog.order), "stageCatalog.order must be a dense array.")

  local definition_keys = {}
  for catalog_key, _ in pairs(catalog.definitions) do
    assert_condition(type(catalog_key) == "string" and catalog_key ~= "", "Reward catalog keys must be strings.")
    definition_keys[#definition_keys + 1] = catalog_key
  end
  table.sort(definition_keys)

  local seen_definition_key_fields = {}
  for _, catalog_key in ipairs(definition_keys) do
    local definition = catalog.definitions[catalog_key]
    validate_definition(catalog_key, definition)
    local key_field = definition.key
    assert_condition(not seen_definition_key_fields[key_field], "Duplicate reward definition key field: " .. key_field)
    seen_definition_key_fields[key_field] = true
  end

  local known_stage_keys = {}
  for _, stage_key in ipairs(stage_catalog.order) do
    assert_condition(type(stage_key) == "string" and stage_key ~= "", "Stage keys must be non-empty strings.")
    known_stage_keys[stage_key] = true
    assert_condition(stage_catalog.stages[stage_key] ~= nil, "Missing stage definition for stage key: " .. stage_key)
  end

  local by_stage_keys = {}
  for stage_key, _ in pairs(catalog.byStage) do
    assert_condition(type(stage_key) == "string" and stage_key ~= "", "rewardCatalog.byStage keys must be strings.")
    by_stage_keys[#by_stage_keys + 1] = stage_key
  end
  table.sort(by_stage_keys)
  for _, stage_key in ipairs(by_stage_keys) do
    assert_condition(known_stage_keys[stage_key], "rewardCatalog.byStage contains unknown stage key: " .. stage_key)
  end

  for _, stage_key in ipairs(stage_catalog.order) do
    local options = catalog.byStage[stage_key]
    assert_condition(type(options) == "table", "Missing reward option list for stage: " .. stage_key)
    assert_condition(is_dense_array(options), "Reward option list must be a dense array for stage: " .. stage_key)
    assert_condition(#options > 0, "Reward option list must be non-empty for stage: " .. stage_key)

    local seen = {}
    for i, reward_key in ipairs(options) do
      assert_condition(
        type(reward_key) == "string" and reward_key ~= "",
        "Reward option keys must be non-empty strings for stage: " .. stage_key
      )
      assert_condition(not seen[reward_key], "Duplicate reward option key in stage list: " .. reward_key)
      seen[reward_key] = true
      assert_condition(catalog.definitions[reward_key] ~= nil, "Unknown reward key referenced by stage: " .. reward_key)
    end
  end
end

function RunState.new(reward_catalog, stage_catalog)
  validate_catalog(reward_catalog, stage_catalog)

  local self = setmetatable({}, RunState)
  self._catalog = reward_catalog
  self.persistentSlotBonus = 0
  self.pendingNextStageSlotBonus = 0
  self.currentStageTemporarySlotBonus = 0
  self.currentOptions = nil
  self.selectedRewardIndex = nil
  self.lastAppliedRewardKey = nil
  return self
end

function RunState:getPersistentSlotBonus()
  return self.persistentSlotBonus
end

function RunState:getPendingNextStageSlotBonus()
  return self.pendingNextStageSlotBonus
end

function RunState:getCurrentStageTemporarySlotBonus()
  return self.currentStageTemporarySlotBonus
end

function RunState:getEffectiveSlotBonus()
  return self.persistentSlotBonus + self.currentStageTemporarySlotBonus
end

function RunState:beginRewardSelection(stage_key)
  local option_keys = self._catalog.byStage[stage_key]
  if type(option_keys) ~= "table" or #option_keys == 0 then
    return false, "No reward options found for stage."
  end

  local options = {}
  for i, reward_key in ipairs(option_keys) do
    options[i] = copy_reward_option(self._catalog.definitions[reward_key])
  end

  self.currentOptions = options
  self.selectedRewardIndex = 1
  return true, nil
end

function RunState:getRewardOptions()
  return copy_reward_options(self.currentOptions)
end

function RunState:getSelectedRewardIndex()
  return self.selectedRewardIndex
end

function RunState:moveRewardSelection(direction)
  if type(self.currentOptions) ~= "table" or #self.currentOptions == 0 then
    return false, "Reward selection is not active."
  end

  if direction ~= 1 and direction ~= -1 then
    return false, "Reward selection direction must be 1 or -1."
  end

  local total = #self.currentOptions
  local current = self.selectedRewardIndex or 1
  local next_index = ((current - 1 + direction) % total) + 1
  self.selectedRewardIndex = next_index
  return true, nil
end

function RunState:clearRewardSelection()
  self.currentOptions = nil
  self.selectedRewardIndex = nil
end

function RunState:confirmSelectedReward()
  if type(self.currentOptions) ~= "table" or #self.currentOptions == 0 then
    return nil, "Reward selection is not active."
  end

  local selected_index = self.selectedRewardIndex
  if type(selected_index) ~= "number" or selected_index < 1 or selected_index > #self.currentOptions then
    return nil, "Selected reward index is invalid."
  end

  local reward = self.currentOptions[selected_index]
  if reward.type == "persistent_slot_increase" then
    self.persistentSlotBonus = self.persistentSlotBonus + reward.slotDelta
  elseif reward.type == "next_stage_slot_increase" then
    self.pendingNextStageSlotBonus = self.pendingNextStageSlotBonus + reward.slotDelta
  else
    return nil, "Unsupported reward type selected."
  end

  self.lastAppliedRewardKey = reward.key
  local applied = copy_reward_option(reward)
  self:clearRewardSelection()
  return applied, nil
end

function RunState:enterNextStage()
  self.currentStageTemporarySlotBonus = self.pendingNextStageSlotBonus
  self.pendingNextStageSlotBonus = 0
end

function RunState:getLastAppliedRewardKey()
  return self.lastAppliedRewardKey
end

function RunState:resetRun()
  self.persistentSlotBonus = 0
  self.pendingNextStageSlotBonus = 0
  self.currentStageTemporarySlotBonus = 0
  self.currentOptions = nil
  self.selectedRewardIndex = nil
  self.lastAppliedRewardKey = nil
end

return RunState
