-- Prototype 0.1 debug visualization entry point.

local RunPrototype = require("src.core.run_prototype")

local App = {
  result = nil,
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
  App.result = RunPrototype.run()
end

function love.update(_dt)
  -- Prototype 0.1 is a single-run deterministic simulation.
end

function love.draw()
  love.graphics.clear(0.08, 0.08, 0.1, 1.0)
  love.graphics.setColor(1, 1, 1, 1)

  local y = 16
  local line_height = 18
  local function print_line(text)
    love.graphics.print(text, 16, y)
    y = y + line_height
  end

  print_line("ChainReaction Prototype 0.1")
  print_line("")

  if not App.result then
    print_line("Result: nil")
    return
  end

  print_line("Success: " .. bool_label(App.result.success, "Success", "Failure"))
  print_line("Cleared: " .. bool_label(App.result.cleared, "Cleared", "Failed"))
  print_line("Final RV: " .. to_text(App.result.finalRV))
  print_line("Damage: " .. to_text(App.result.damage))

  local error_text = "none"
  if App.result.error then
    if type(App.result.error) == "table" then
      error_text = to_text(App.result.error.code) .. " - " .. to_text(App.result.error.note)
    else
      error_text = to_text(App.result.error)
    end
  end
  print_line("Error: " .. error_text)
  print_line("")
  print_line("Execution Log:")

  local log = App.result.log
  if type(log) ~= "table" or #log == 0 then
    print_line("  (empty)")
    return
  end

  for _, entry in ipairs(log) do
    local summary = string.format(
      "Step %s | %s | %s | RV %s -> %s | DMG %s -> %s",
      to_text(entry.step),
      to_text(entry.objectKey),
      to_text(entry.attribute),
      to_text(entry.rvBefore),
      to_text(entry.rvAfter),
      to_text(entry.damageBefore),
      to_text(entry.damageAfter)
    )
    print_line(summary)
  end
end
