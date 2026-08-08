-- Prototype 1.2 runtime controller.
-- Manages deterministic multi-stage progression, reward selection, and runtime slot edits.

local object_defs = require("src.data.objects")
local stage_catalog = require("src.data.stage_catalog")
local reward_catalog = require("src.data.reward_catalog")
local SlotManager = require("src.core.slot_manager")
local StageManager = require("src.core.stage_manager")
local RunState = require("src.core.run_state")
local simulator = require("src.sim.reaction_simulator")

local M = {}

local Runtime = {}
Runtime.__index = Runtime

local function copy_array(list)
  local copied = {}
  for i, value in ipairs(list) do
    copied[i] = value
  end
  return copied
end

local function copy_slots(slots)
  local copied = {}
  for i, slot in ipairs(slots) do
    local object_key = nil
    if type(slot) == "table" then
      object_key = slot.objectKey
    end
    copied[i] = { objectKey = object_key }
  end
  return copied
end

local function build_effective_stage(stage, slot_bonus)
  local base_slots = {}
  local initial_slots = {}
  if type(stage) == "table" and type(stage.initialSlots) == "table" then
    initial_slots = stage.initialSlots
  end

  local initial_count = #initial_slots
  if initial_count > 0 then
    for i = 1, initial_count - 1 do
      local slot = initial_slots[i]
      local object_key = nil
      if type(slot) == "table" then
        object_key = slot.objectKey
      end
      base_slots[#base_slots + 1] = { objectKey = object_key }
    end
  end

  for _ = 1, slot_bonus do
    base_slots[#base_slots + 1] = { objectKey = nil }
  end

  if initial_count > 0 then
    local final_slot = initial_slots[initial_count]
    local final_object_key = nil
    if type(final_slot) == "table" then
      final_object_key = final_slot.objectKey
    end
    base_slots[#base_slots + 1] = { objectKey = final_object_key }
  end

  return {
    key = stage.key,
    targetDamage = stage.targetDamage,
    initialSlots = base_slots,
    allowedObjectKeys = stage.allowedObjectKeys,
  }
end

local function resolve_object_order(defs, stage_def)
  if type(stage_def) == "table" and type(stage_def.allowedObjectKeys) == "table" then
    return copy_array(stage_def.allowedObjectKeys)
  end

  if type(defs.availableOrder) == "table" then
    return copy_array(defs.availableOrder)
  end

  local metadata_keys = {
    availableOrder = true,
  }
  local keys = {}
  for key, value in pairs(defs) do
    if type(key) == "string" and not metadata_keys[key] and type(value) == "table" then
      local attributes = value.attributes
      local first_attribute = type(attributes) == "table" and attributes[1] or nil
      local first_attribute_key = type(first_attribute) == "table" and first_attribute.key or nil
      if type(first_attribute_key) == "string" and first_attribute_key ~= "" then
        keys[#keys + 1] = key
      end
    end
  end
  table.sort(keys)
  return keys
end

local function stage_selected_slot(slot_manager)
  local count = slot_manager:getSlotCount()
  if count == 0 then
    return 0
  end
  return 1
end

local function cycle_key(order, current_key, direction)
  local current_index = 1
  if current_key ~= nil then
    for i, key in ipairs(order) do
      if key == current_key then
        current_index = i + 1
        break
      end
    end
  end

  local total = #order + 1
  local next_index = ((current_index - 1 + direction) % total) + 1
  if next_index == 1 then
    return nil
  end
  return order[next_index - 1]
end

function Runtime.new()
  local manager = StageManager.new(stage_catalog, object_defs)
  local run_state = RunState.new(reward_catalog, stage_catalog)
  local current_stage = manager:getCurrentStage()
  local effective_stage = build_effective_stage(current_stage, run_state:getEffectiveSlotBonus())
  local slot_manager = SlotManager.new(effective_stage)
  local selected_slot = stage_selected_slot(slot_manager)

  local self = {
    stage_manager = manager,
    run_state = run_state,
    slot_manager = slot_manager,
    selected_slot_index = selected_slot,
    swap_source_index = nil,
    object_order = resolve_object_order(object_defs, current_stage),
    result = nil,
    last_error = nil,
    phase = "editing",
  }

  return setmetatable(self, Runtime)
end

function Runtime:_invalidateResultFromEdit()
  if self.phase == "resolved_clear" or self.phase == "resolved_fail" then
    self.result = nil
    self.phase = "editing"
  end
end

function Runtime:_rebuildForCurrentStage()
  local stage = self.stage_manager:getCurrentStage()
  local effective_stage = build_effective_stage(stage, self.run_state:getEffectiveSlotBonus())
  self.slot_manager = SlotManager.new(effective_stage)
  self.selected_slot_index = stage_selected_slot(self.slot_manager)
  self.swap_source_index = nil
  self.result = nil
  self.last_error = nil
  self.object_order = resolve_object_order(object_defs, stage)
  self.phase = "editing"
end

function Runtime:runSimulation()
  local stage = self.stage_manager:getCurrentStage()
  local runtime_slots = self.slot_manager:getSlots()
  self.result = simulator.simulate(stage, object_defs, runtime_slots)
  self.last_error = nil
  if self.result.success and self.result.cleared then
    self.phase = "resolved_clear"
  else
    self.phase = "resolved_fail"
  end
  return self.result
end

function Runtime:handleKey(key)
  if self.phase == "run_complete" then
    if key == "t" then
      self.stage_manager:restartRun()
      self.run_state:resetRun()
      self:_rebuildForCurrentStage()
    end
    return
  end

  if self.phase == "reward_selection" then
    if key == "left" or key == "right" then
      local direction = key == "right" and 1 or -1
      local ok, err = self.run_state:moveRewardSelection(direction)
      if not ok then
        self.last_error = err
      else
        self.last_error = nil
      end
      return
    end

    if key == "return" then
      local _applied, err = self.run_state:confirmSelectedReward()
      if err ~= nil then
        self.last_error = err
        return
      end

      self.last_error = nil
      if self.stage_manager:isLastStage() then
        self.phase = "run_complete"
        return
      end

      local advanced = self.stage_manager:advance()
      if advanced then
        self.run_state:enterNextStage()
        self:_rebuildForCurrentStage()
      else
        self.last_error = "Failed to advance stage."
      end
      return
    end

    return
  end

  if key == "n" then
    if self.phase == "resolved_clear" then
      local stage_key = self.stage_manager:getCurrentStageKey()
      local ok, err = self.run_state:beginRewardSelection(stage_key)
      if ok then
        self.phase = "reward_selection"
        self.last_error = nil
      else
        self.last_error = err
      end
    end
    return
  end

  local slot_count = self.slot_manager:getSlotCount()

  if slot_count > 0 and key == "left" then
    self.selected_slot_index = ((self.selected_slot_index - 2) % slot_count) + 1
    return
  end
  if slot_count > 0 and key == "right" then
    self.selected_slot_index = (self.selected_slot_index % slot_count) + 1
    return
  end

  if slot_count > 0 and (key == "up" or key == "down") then
    local direction = 1
    if key == "down" then
      direction = -1
    end
    local current = self.slot_manager:getObjectKey(self.selected_slot_index)
    local next_key = cycle_key(self.object_order, current, direction)
    local ok, err = self.slot_manager:setObjectKey(self.selected_slot_index, next_key)
    if not ok then
      self.last_error = err
    else
      self.last_error = nil
      self:_invalidateResultFromEdit()
    end
    return
  end

  if slot_count > 0 and (key == "backspace" or key == "delete") then
    local ok, err = self.slot_manager:clearSlot(self.selected_slot_index)
    if not ok then
      self.last_error = err
    else
      self.last_error = nil
      self:_invalidateResultFromEdit()
    end
    return
  end

  if slot_count > 0 and key == "s" then
    if self.swap_source_index == nil then
      self.swap_source_index = self.selected_slot_index
      self.last_error = nil
      return
    end

    if self.swap_source_index == self.selected_slot_index then
      self.swap_source_index = nil
      self.last_error = nil
      return
    end

    local ok, err = self.slot_manager:swapSlots(self.swap_source_index, self.selected_slot_index)
    if ok then
      self.swap_source_index = nil
      self.last_error = nil
      self:_invalidateResultFromEdit()
    else
      self.last_error = err
    end
    return
  end

  if key == "r" then
    self.slot_manager:reset()
    self.swap_source_index = nil
    self.last_error = nil
    self.result = nil
    self.phase = "editing"
    return
  end

  if key == "space" then
    self:runSimulation()
  end
end

function Runtime:getState()
  local current_stage = self.stage_manager:getCurrentStage()
  local current_stage_key = self.stage_manager:getCurrentStageKey()
  local current_stage_index = self.stage_manager:getCurrentStageIndex()
  local stage_count = self.stage_manager:getStageCount()
  local run_complete = self.phase == "run_complete"
  local can_advance = self.phase == "resolved_clear"
  local reward_options = self.run_state:getRewardOptions()
  local selected_reward_index = self.run_state:getSelectedRewardIndex()
  local persistent_bonus = self.run_state:getPersistentSlotBonus()
  local pending_bonus = self.run_state:getPendingNextStageSlotBonus()
  local temporary_bonus = self.run_state:getCurrentStageTemporarySlotBonus()
  local effective_bonus = self.run_state:getEffectiveSlotBonus()

  return {
    selectedSlotIndex = self.selected_slot_index,
    swapSourceIndex = self.swap_source_index,
    slots = self.slot_manager:getSlots(),
    result = self.result,
    lastError = self.last_error,
    objectOrder = copy_array(self.object_order),
    targetDamage = current_stage.targetDamage,
    currentStageIndex = current_stage_index,
    stageCount = stage_count,
    currentStageKey = current_stage_key,
    phase = self.phase,
    runComplete = run_complete,
    canAdvance = can_advance,
    rewardOptions = reward_options,
    selectedRewardIndex = selected_reward_index,
    rewardSelectionActive = self.phase == "reward_selection",
    lastAppliedRewardKey = self.run_state:getLastAppliedRewardKey(),
    persistentSlotBonus = persistent_bonus,
    pendingNextStageSlotBonus = pending_bonus,
    currentStageTemporarySlotBonus = temporary_bonus,
    effectiveSlotBonus = effective_bonus,
  }
end

function M.new()
  return Runtime.new()
end

return M
