-- Prototype 0.9 object definitions (data-only).

local objects = {
  availableOrder = {
    "spark",
    "fuel",
    "crystal",
    "valve",
    "catalyst",
    "mirror",
    "bomb",
    "reactor",
    "accumulator",
    "pressure_bomb",
  },

  spark = {
    attributes = {
      {
        key = "ignite",
        params = {
          baseRV = 1,
        },
      },
    },
  },
  fuel = {
    attributes = {
      {
        key = "amplify",
        params = {
          multiplier = 2,
        },
      },
    },
  },
  crystal = {
    attributes = {
      {
        key = "store",
        params = {},
      },
    },
  },
  valve = {
    attributes = {
      {
        key = "release",
        params = {},
      },
    },
  },
  catalyst = {
    attributes = {
      {
        key = "charge",
        params = {
          chargeAmplifyEfficiency = 1.25,
          chargeStoreEfficiency = 1.25,
          chargeExplodeEfficiency = 1.25,
        },
      },
    },
  },
  mirror = {
    attributes = {
      {
        key = "echo",
        params = {},
      },
    },
  },
  bomb = {
    attributes = {
      {
        key = "explode",
        params = {
          damageRatio = 1,
        },
      },
    },
  },

  reactor = {
    attributes = {
      {
        key = "charge",
        params = {
          chargeAmplifyEfficiency = 1.25,
          chargeStoreEfficiency = 1.25,
          chargeExplodeEfficiency = 1.25,
        },
      },
      {
        key = "amplify",
        params = {
          multiplier = 2,
        },
      },
    },
  },

  accumulator = {
    attributes = {
      {
        key = "store",
        params = {},
      },
      {
        key = "release",
        params = {},
      },
    },
  },

  pressure_bomb = {
    attributes = {
      {
        key = "release",
        params = {},
      },
      {
        key = "explode",
        params = {
          damageRatio = 1,
        },
      },
    },
  },
}

return objects
