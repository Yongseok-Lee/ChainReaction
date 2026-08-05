-- Prototype 0.4 runtime controller.
-- Manages keyboard-driven runtime slot edits and explicit simulation runs.

local object_defs = require("src.data.objects")
local stage_def = require("src.data.prototype_stage")
local SlotManager = require("src.core.slot_manager")
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

local function resolve_object_order(defs)
  if type(defs.availableOrder) == "table" then
    return copy_array(defs.availableOrder)
  end

  local keys = {}
  for key, value in pairs(defs) do
    if type(key) == "string" and type(value) == "table" and type(value.attribute) == "string" then
      keys[#keys + 1] = key
    end
  end
  table.sort(keys)
  return keys
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
  local slot_manager = SlotManager.new(stage_def)
  local slot_count = slot_manager:getSlotCount()
  local selected_slot = 1
  if slot_count == 0 then
    selected_slot = 0
  end

  local self = {
    slot_manager = slot_manager,
    selected_slot_index = selected_slot,
    swap_source_index = nil,
    object_order = resolve_object_order(object_defs),
    result = nil,
    last_error = nil,
  }

  return setmetatable(self, Runtime)
end

function Runtime:runSimulation()
  local runtime_slots = self.slot_manager:getSlots()
  self.result = simulator.simulate(stage_def, object_defs, runtime_slots)
  self.last_error = nil
  return self.result
end

function Runtime:handleKey(key)
  local slot_count = self.slot_manager:getSlotCount()
  if slot_count == 0 then
    if key == "space" then
      self:runSimulation()
    end
    return
  end

  if key == "left" then
    self.selected_slot_index = ((self.selected_slot_index - 2) % slot_count) + 1
    return
  end
  if key == "right" then
    self.selected_slot_index = (self.selected_slot_index % slot_count) + 1
    return
  end

  if key == "up" or key == "down" then
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
    end
    return
  end

  if key == "backspace" or key == "delete" then
    local ok, err = self.slot_manager:clearSlot(self.selected_slot_index)
    if not ok then
      self.last_error = err
    else
      self.last_error = nil
    end
    return
  end

  if key == "s" then
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
    return
  end

  if key == "space" then
    self:runSimulation()
  end
end

function Runtime:getState()
  return {
    selectedSlotIndex = self.selected_slot_index,
    swapSourceIndex = self.swap_source_index,
    slots = self.slot_manager:getSlots(),
    result = self.result,
    lastError = self.last_error,
    objectOrder = copy_array(self.object_order),
    targetDamage = stage_def.targetDamage,
  }
end

function M.new()
  return Runtime.new()
end

return M
