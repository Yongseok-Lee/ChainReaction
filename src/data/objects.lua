-- Prototype 0.7 object definitions (data-only).

local objects = {
  availableOrder = { "spark", "fuel", "crystal", "valve", "catalyst", "bomb" },

  spark = {
    attribute = "ignite",
    params = {
      baseRV = 1,
    },
  },
  fuel = {
    attribute = "amplify",
    params = {
      multiplier = 2,
    },
  },
  crystal = {
    attribute = "store",
    params = {},
  },
  valve = {
    attribute = "release",
    params = {},
  },
  catalyst = {
    attribute = "charge",
    params = {
      chargeAmplifyEfficiency = 1.25,
      chargeStoreEfficiency = 1.25,
      chargeExplodeEfficiency = 1.25,
    },
  },
  bomb = {
    attribute = "explode",
    params = {
      damageRatio = 1,
    },
  },
}

return objects
