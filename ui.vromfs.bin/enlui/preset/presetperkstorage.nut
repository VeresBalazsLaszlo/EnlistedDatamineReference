from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/components/soldierClasses.nut" import getKindCfg
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/ui_library.nut" import *

const SLOT_COUNT_MAX = 4
const SLOT_COUNT = 2

let perkPresetsStorage = mkOnlineSaveData("presetPerks", @() {})
let setPerkPreset = perkPresetsStorage.setValue
let perkPresetWatch = perkPresetsStorage.watch

function updateStorage(sKind, slot, newData) {
  let storage = clone perkPresetWatch.get()
  let kindStorage = clone storage?[sKind] ?? array(SLOT_COUNT_MAX)
  storage[sKind] <- kindStorage
  if (kindStorage.len() <= slot)
    kindStorage.resize(SLOT_COUNT_MAX)

  let presetData = kindStorage[slot] ?? {}
  kindStorage[slot] = freeze(presetData.__merge(newData))
  setPerkPreset(storage)
}

function deleteSlot(sKind, slot) {
  let storage = clone perkPresetWatch.get()
  let kindStorage = clone storage[sKind]
  storage[sKind] = kindStorage

  kindStorage.remove(slot)
  setPerkPreset(storage)
}



function savePreset(config, soldier, value) {
  let { slot } = config
  let { sKind } = soldier
  let { name = null } = perkPresetWatch.get()?[sKind][slot]
  let presetData = {
    name = name ?? loc("preset/equip/name",
      { order = getRomanNumeral(slot + 1), kind = loc(getKindCfg(sKind).locId) })
    items = value
  }
  updateStorage(sKind, slot, presetData)
}

function renamePreset(config, soldier, value) {
  let { slot } = config
  let { sKind } = soldier
  updateStorage(sKind, slot, { name = value })
}

function deletePreset(config, soldier) {
  let { slot } = config
  let { sKind } = soldier
  deleteSlot(sKind, slot)
}

return {
  savePreset
  renamePreset
  deletePreset
  perkPresetWatch
  SLOT_COUNT
  SLOT_COUNT_MAX
}
