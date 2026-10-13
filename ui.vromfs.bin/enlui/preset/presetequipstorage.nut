from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/components/soldierClasses.nut" import getKindCfg
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/preset/presetEquipCfg.nut" import SLOT_COUNT_MAX
from "%ui/ui_library.nut" import *

let equipmentPresetsStorage = mkOnlineSaveData("presetEquipment", @() {})
let setEquipmentPreset = equipmentPresetsStorage.setValue
let equipmentPresetWatch = equipmentPresetsStorage.watch

function updateStorage(armyId, sKind, slot, newData) {
  let storage = clone equipmentPresetWatch.get()
  let armyStorage = clone storage?[armyId] ?? {}
  storage[armyId] <- armyStorage
  let kindStorage = clone armyStorage?[sKind] ?? array(SLOT_COUNT_MAX)
  armyStorage[sKind] <- kindStorage
  if (kindStorage.len() <= slot)
    kindStorage.resize(SLOT_COUNT_MAX)

  let presetData = kindStorage[slot] ?? {}
  kindStorage[slot] = freeze(presetData.__merge(newData))
  setEquipmentPreset(storage)
}

function deleteSlot(armyId, sKind, slot) {
  let storage = clone equipmentPresetWatch.get()
  let armyStorage = clone storage[armyId]
  storage[armyId] = armyStorage
  let kindStorage = clone armyStorage[sKind]
  armyStorage[sKind] = kindStorage

  kindStorage.remove(slot)
  setEquipmentPreset(storage)
}



function savePreset(config, soldier, value) {
  let { slot } = config
  let { armyId, sKind } = soldier
  let { name = null } = equipmentPresetWatch.get()?[armyId][sKind][slot]
  let presetData = {
    name = name ?? loc("preset/equip/name",
      { order = getRomanNumeral(slot + 1), kind = loc(getKindCfg(sKind).locId) })
    items = value
  }
  updateStorage(armyId, sKind, slot, presetData)
}

function renamePreset(config, soldier, value) {
  let { slot } = config
  let { armyId, sKind } = soldier
  updateStorage(armyId, sKind, slot, { name = value })
}

function deletePreset(config, soldier) {
  let { slot } = config
  let { armyId, sKind } = soldier
  deleteSlot(armyId, sKind, slot)
}

return {
  savePreset
  renamePreset
  deletePreset
  equipmentPresetWatch
}
