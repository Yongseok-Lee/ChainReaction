-- Prototype 0.1 object definitions (data-only).

local objects = {
  availableOrder = { "spark", "fuel", "bomb" },

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
  bomb = {
    attribute = "explode",
    params = {
      damageRatio = 1,
    },
  },
}

return objects
