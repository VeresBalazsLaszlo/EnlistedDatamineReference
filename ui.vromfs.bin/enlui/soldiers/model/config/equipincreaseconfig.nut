from "%ui/meta/configs.nut" import mkComputedConfigGet

let equipSlotIncreaseCfg = mkComputedConfigGet("equip_slot_increase", {})
let equipAmmoIncreaseCfg = mkComputedConfigGet("equip_ammo_increase", {})

return {
  equipSlotIncreaseCfg
  equipAmmoIncreaseCfg
}
