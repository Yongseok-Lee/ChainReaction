-- Prototype 0.1 runner.
-- Loads prototype data and executes one deterministic simulation.

local object_defs = require("src.data.objects")
local stage_def = require("src.data.prototype_stage")
local SlotManager = require("src.core.slot_manager")
local simulator = require("src.sim.reaction_simulator")

local M = {}

---Runs Prototype 0.1 once and returns simulator output.
---@return table
function M.run()
  local slot_manager = SlotManager.new(stage_def)
  local runtime_slots = slot_manager:getSlots()
  return simulator.simulate(stage_def, object_defs, runtime_slots)
end

return M
