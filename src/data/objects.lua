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

  flare = {
    attributes = {
      {
        key = "ignite",
        params = {
          baseRV = 1,
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

  ember_core = {
    attributes = {
      {
        key = "ignite",
        params = {
          baseRV = 1,
        },
      },
      {
        key = "store",
        params = {},
      },
    },
  },

  primer = {
    attributes = {
      {
        key = "ignite",
        params = {
          baseRV = 1,
        },
      },
      {
        key = "release",
        params = {},
      },
    },
  },

  arc_spark = {
    attributes = {
      {
        key = "ignite",
        params = {
          baseRV = 1,
        },
      },
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

  detonator = {
    attributes = {
      {
        key = "ignite",
        params = {
          baseRV = 1,
        },
      },
      {
        key = "explode",
        params = {
          damageRatio = 1,
        },
      },
    },
  },

  capacitor = {
    attributes = {
      {
        key = "amplify",
        params = {
          multiplier = 2,
        },
      },
      {
        key = "store",
        params = {},
      },
    },
  },

  turbine = {
    attributes = {
      {
        key = "release",
        params = {},
      },
      {
        key = "amplify",
        params = {
          multiplier = 2,
        },
      },
    },
  },

  resonator = {
    attributes = {
      {
        key = "amplify",
        params = {
          multiplier = 2,
        },
      },
      {
        key = "echo",
        params = {},
      },
    },
  },

  warhead = {
    attributes = {
      {
        key = "amplify",
        params = {
          multiplier = 2,
        },
      },
      {
        key = "explode",
        params = {
          damageRatio = 1,
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

  prismatic_crystal = {
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
        key = "store",
        params = {},
      },
    },
  },

  memory_crystal = {
    attributes = {
      {
        key = "store",
        params = {},
      },
      {
        key = "echo",
        params = {},
      },
    },
  },

  reservoir_bomb = {
    attributes = {
      {
        key = "store",
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

  converter_valve = {
    attributes = {
      {
        key = "release",
        params = {},
      },
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

  pulse_valve = {
    attributes = {
      {
        key = "echo",
        params = {},
      },
      {
        key = "release",
        params = {},
      },
    },
  },

  kaleidoscope = {
    attributes = {
      {
        key = "echo",
        params = {},
      },
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

  elemental_bomb = {
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
        key = "explode",
        params = {
          damageRatio = 1,
        },
      },
    },
  },

  cluster_bomb = {
    attributes = {
      {
        key = "echo",
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