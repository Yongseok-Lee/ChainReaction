-- Prototype 0.95 simulation runtime state factory.

local M = {}

function M.newState()
  return {
    rv = 0,
    storedRV = 0,
    damage = 0,
    reactionState = "stable",
    chargeEfficiencies = {
      chargeAmplifyEfficiency = 1,
      chargeStoreEfficiency = 1,
      chargeExplodeEfficiency = 1,
    },
    lastRealStep = nil,
    started = false,
    ended = false,
  }
end

return M
