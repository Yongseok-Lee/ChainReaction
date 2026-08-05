-- Prototype 0.3 runtime slot state manager.
-- Owns mutable slot contents only; no gameplay logic.

local SlotManager = {}
SlotManager.__index = SlotManager

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

local function validate_index(slots, index)
  if type(index) ~= "number" or index % 1 ~= 0 then
    return false, "Slot index must be an integer."
  end
  if index < 1 or index > #slots then
    return false, "Slot index out of range."
  end
  return true, nil
end

function SlotManager.new(stageDef)
  assert(type(stageDef) == "table", "stageDef must be a table.")
  assert(type(stageDef.initialSlots) == "table", "stageDef.initialSlots must be a table.")

  local self = setmetatable({}, SlotManager)
  self._initial_slots = copy_slots(stageDef.initialSlots)
  self._slots = copy_slots(stageDef.initialSlots)
  return self
end

function SlotManager:getSlotCount()
  return #self._slots
end

function SlotManager:getSlots()
  return copy_slots(self._slots)
end

function SlotManager:getObjectKey(index)
  local ok, _err = validate_index(self._slots, index)
  if not ok then
    return nil
  end
  return self._slots[index].objectKey
end

function SlotManager:setObjectKey(index, objectKeyOrNil)
  local ok, err = validate_index(self._slots, index)
  if not ok then
    return false, err
  end
  if objectKeyOrNil ~= nil and type(objectKeyOrNil) ~= "string" then
    return false, "objectKey must be a string or nil."
  end

  self._slots[index].objectKey = objectKeyOrNil
  return true, nil
end

function SlotManager:clearSlot(index)
  return self:setObjectKey(index, nil)
end

function SlotManager:swapSlots(indexA, indexB)
  local ok_a, err_a = validate_index(self._slots, indexA)
  if not ok_a then
    return false, err_a
  end
  local ok_b, err_b = validate_index(self._slots, indexB)
  if not ok_b then
    return false, err_b
  end

  local temp = self._slots[indexA].objectKey
  self._slots[indexA].objectKey = self._slots[indexB].objectKey
  self._slots[indexB].objectKey = temp
  return true, nil
end

function SlotManager:reset()
  self._slots = copy_slots(self._initial_slots)
end

return SlotManager
