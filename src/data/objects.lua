-- Prototype 0.1 object definitions (data-only).

local objects = {
  availableOrder = { "spark", "fuel", "crystal", "bomb" },

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
  bomb = {
    attribute = "explode",
    params = {
      damageRatio = 1,
    },
  },
}

return objects
