-- Prototype 1.2 reward catalog (data-only, deterministic).

local catalog = {
  definitions = {
    rw_s1_persistent_slot_1 = {
      key = "rw_s1_persistent_slot_1",
      type = "persistent_slot_increase",
      slotDelta = 1,
      label = "Persistent Slot +1",
    },
    rw_s1_next_stage_slot_2 = {
      key = "rw_s1_next_stage_slot_2",
      type = "next_stage_slot_increase",
      slotDelta = 2,
      label = "Next Stage Slots +2",
    },
    rw_s2_persistent_slot_1 = {
      key = "rw_s2_persistent_slot_1",
      type = "persistent_slot_increase",
      slotDelta = 1,
      label = "Persistent Slot +1",
    },
    rw_s2_next_stage_slot_2 = {
      key = "rw_s2_next_stage_slot_2",
      type = "next_stage_slot_increase",
      slotDelta = 2,
      label = "Next Stage Slots +2",
    },
    rw_s3_persistent_slot_1 = {
      key = "rw_s3_persistent_slot_1",
      type = "persistent_slot_increase",
      slotDelta = 1,
      label = "Persistent Slot +1",
    },
    rw_s3_next_stage_slot_2 = {
      key = "rw_s3_next_stage_slot_2",
      type = "next_stage_slot_increase",
      slotDelta = 2,
      label = "Next Stage Slots +2",
    },
  },

  byStage = {
    stage_01_basics = {
      "rw_s1_persistent_slot_1",
      "rw_s1_next_stage_slot_2",
    },
    stage_02_storage = {
      "rw_s2_persistent_slot_1",
      "rw_s2_next_stage_slot_2",
    },
    stage_03_charge_echo = {
      "rw_s3_persistent_slot_1",
      "rw_s3_next_stage_slot_2",
    },
  },
}

return catalog
