import "%ui/soldiers/model/config/effectsConfig.nut" as effectsConfig
import "%ui/soldiers/model/armyEffects.nut" as armyEffects
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/ui_library.nut" import *

let classSlotLocksByArmy = Computed(@()
  curArmiesList.get().reduce(function(res, armyId) {
    let unlockCfg = effectsConfig.get()?[armyId].slot_unlock ?? {}
    let unlockEff = armyEffects.get()?[armyId].slot_unlock ?? {}
    res[armyId] <- unlockCfg.map(function(list, sClass) {
      let slotsUnlocked = unlockEff?[sClass] ?? []
      return list.filter(@(slot) !slotsUnlocked.contains(slot))
    })
    return res
  }, {}))

let upgradeLocksByArmy = Computed(@()
  curArmiesList.get().reduce(function(res, armyId) {
    let upgradeCfg = effectsConfig.get()?[armyId].weapon_upgrades ?? []
    let upgradeEff = armyEffects.get()?[armyId].weapon_upgrades ?? []
    res[armyId] <- upgradeCfg.filter(@(tmpl) !upgradeEff.contains(tmpl))
    return res
  }, {}))

let upgradeCostMultByArmy = Computed(@()
  curArmiesList.get().reduce(function(res, armyId) {
    let discountTbl = armyEffects.get()?[armyId].weapon_upgrade_discount ?? {}
    res[armyId] <- discountTbl.map(@(discount) max(0.0, 1.0 - discount))
    return res
  }, {}))

let disposeCountMultByArmy = Computed(@()
  curArmiesList.get().reduce(function(res, armyId) {
    res[armyId] <- armyEffects.get()?[armyId].disassemble_bonus ?? {}
    return res
  }, {}))

return {
  classSlotLocksByArmy
  upgradeLocksByArmy
  upgradeCostMultByArmy
  disposeCountMultByArmy
}