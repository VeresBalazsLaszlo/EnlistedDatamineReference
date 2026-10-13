from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/currency/premium.nut" import hasPremium
from "%ui/ui_library.nut" import *

const FREE_SLOTS_COUNT = 6
const PREMIUM_SLOTS_COUNT = 4
const MAX_PRESETS_COUNT = FREE_SLOTS_COUNT + PREMIUM_SLOTS_COUNT
let availablePresetsCount = Computed(@() hasPremium.get() ? MAX_PRESETS_COUNT : FREE_SLOTS_COUNT)

let squadsPresetsStorage = mkOnlineSaveData("presetSquads", @() {})
let setSquadsPreset = squadsPresetsStorage.setValue
let squadsPresetWatch = squadsPresetsStorage.watch

return {
  setSquadsPreset
  squadsPresetWatch
  availablePresetsCount
  MAX_PRESETS_COUNT
  PREMIUM_SLOTS_COUNT
}
