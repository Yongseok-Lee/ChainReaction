-- Prototype 0.4 debug visualization entry point.

local RunPrototype = require("src.core.run_prototype")

local App = {
  runtime = nil,
}

local function to_text(value)
  if value == nil then
    return "nil"
  end
  return tostring(value)
end

local function bool_label(value, true_text, false_text)
  if value then
    return true_text
  end
  return false_text
end

function love.load()
  App.runtime = RunPrototype.new()
end

function love.update(_dt)
  -- Prototype 0.1 is a single-run deterministic simulation.
end

function love.draw()
  love.graphics.clear(0.08, 0.08, 0.1, 1.0)
  love.graphics.setColor(1, 1, 1, 1)

  local y = 16
  local line_height = 16
  local function print_line(text)
    love.graphics.print(text, 16, y)
    y = y + line_height
  end

  print_line("ChainReaction Prototype 0.4")
  print_line("Controls: Left/Right select | Up/Down cycle object | Del clear")
  print_line("          S mark/swap slots | R reset slots | Space run simulation")
  print_line("")

  if not App.runtime then
    print_line("Runtime: nil")
    return
  end

  local view = App.runtime:getState()
  print_line("Target Damage: " .. to_text(view.targetDamage))
  print_line("Selected Slot: " .. to_text(view.selectedSlotIndex))
  print_line("Swap Source: " .. to_text(view.swapSourceIndex))
  print_line("Available Objects: " .. table.concat(view.objectOrder, ", "))
  print_line("")
  print_line("Slots:")
  for index, slot in ipairs(view.slots) do
    local marker = " "
    if view.selectedSlotIndex == index then
      marker = ">"
    end
    local swap_mark = ""
    if view.swapSourceIndex == index then
      swap_mark = " [SWAP]"
    end
    local object_key = nil
    if type(slot) == "table" then
      object_key = slot.objectKey
    end
    print_line(string.format(" %s [%d] %s%s", marker, index, to_text(object_key), swap_mark))
  end
  print_line("")

  if view.lastError then
    print_line("Input Error: " .. to_text(view.lastError))
  else
    print_line("Input Error: none")
  end
  print_line("")

  if not view.result then
    print_line("Result: not executed (press Space)")
    return
  end

  print_line("Success: " .. bool_label(view.result.success, "Success", "Failure"))
  print_line("Cleared: " .. bool_label(view.result.cleared, "Cleared", "Failed"))
  print_line("Final RV: " .. to_text(view.result.finalRV))
  print_line("Final Reaction State: " .. to_text(view.result.finalReactionState))
  print_line("Damage: " .. to_text(view.result.damage))

  local error_text = "none"
  if view.result.error then
    if type(view.result.error) == "table" then
      error_text = to_text(view.result.error.code) .. " - " .. to_text(view.result.error.note)
    else
      error_text = to_text(view.result.error)
    end
  end
  print_line("Error: " .. error_text)
  print_line("")
  print_line("Execution Log:")

  local log = view.result.log
  if type(log) ~= "table" or #log == 0 then
    print_line("  (empty)")
    return
  end

  for _, entry in ipairs(log) do
    local line_one = string.format(
      "Step %s | Slot %s | %s | Attr %s/%s %s",
      to_text(entry.step),
      to_text(entry.slotIndex),
      to_text(entry.objectKey),
      to_text(entry.attributeIndex),
      to_text(entry.attributeCount),
      to_text(entry.attribute)
    )
    local line_two = string.format(
      "  RV %s -> %s | STO %s -> %s | DMG %s -> %s",
      to_text(entry.rvBefore),
      to_text(entry.rvAfter),
      to_text(entry.storedBefore),
      to_text(entry.storedAfter),
      to_text(entry.damageBefore),
      to_text(entry.damageAfter)
    )
    local line_three = string.format(
      "  ST %s -> %s | ACT %s | BON %s | CON %s",
      to_text(entry.reactionStateBefore),
      to_text(entry.reactionStateAfter),
      to_text(entry.chargeActivated),
      to_text(entry.chargeBonusApplied),
      to_text(entry.chargeConsumed)
    )
    print_line(line_one)
    print_line(line_two)
    print_line(line_three)
  end
end

function love.keypressed(key)
  if App.runtime then
    App.runtime:handleKey(key)
  end
end
