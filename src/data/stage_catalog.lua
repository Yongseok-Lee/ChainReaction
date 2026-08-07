-- Prototype 1.1 stage catalog (data-only, immutable).

local catalog = {
  order = {
    "stage_01_basics",
    "stage_02_storage",
    "stage_03_charge_echo",
  },
  stages = {
    stage_01_basics = {
      key = "stage_01_basics",
      targetDamage = 2,
      initialSlots = {
        { objectKey = "spark" },
        { objectKey = nil },
        { objectKey = nil },
        { objectKey = "bomb" },
      },
      allowedObjectKeys = {
        "spark",
        "fuel",
        "bomb",
      },
    },
    stage_02_storage = {
      key = "stage_02_storage",
      targetDamage = 4,
      initialSlots = {
        { objectKey = "spark" },
        { objectKey = nil },
        { objectKey = nil },
        { objectKey = nil },
        { objectKey = nil },
        { objectKey = "bomb" },
      },
      allowedObjectKeys = {
        "spark",
        "fuel",
        "crystal",
        "valve",
        "bomb",
      },
    },
    stage_03_charge_echo = {
      key = "stage_03_charge_echo",
      targetDamage = 5,
      initialSlots = {
        { objectKey = "spark" },
        { objectKey = nil },
        { objectKey = nil },
        { objectKey = nil },
        { objectKey = nil },
        { objectKey = "bomb" },
      },
      allowedObjectKeys = {
        "spark",
        "fuel",
        "catalyst",
        "mirror",
        "bomb",
      },
    },
  },
}

return catalog
