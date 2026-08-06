-- Prototype 0.6 object definitions (data-only).

local objects = {
  availableOrder = { "spark", "fuel", "crystal", "valve", "bomb" },

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
  bomb = {
    attribute = "explode",
    params = {
      damageRatio = 1,
    },
  },
}

return objects
