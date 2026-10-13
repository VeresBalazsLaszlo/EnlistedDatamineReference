import "%ui/currency/premiumWnd.nut" as premiumWnd
from "%ui/preset/notFoundMsg.nut" import showNotFoundMsg
from "%ui/popup/popupsState.nut" import addPopup
from "%ui/meta/profile.nut" import campItemsByLink
from "%ui/soldiers/model/state.nut" import getSoldierItemSlots
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/preset/presetEquipUtils.nut" import presetEquipList, notFoundPresetItems,
  applyEquipmentPreset
from "%ui/preset/presetWidget.nut" import mkPresetBlock, togglePresetBlock, closePresetBlock,
  presetWidgetOpened
from "%ui/style/designConst.nut" import leftAppearanceAnim
from "%ui/ui_library.nut" import *


const presetBlockWidth = hdpxi(415)
let previewPreset = Watched(null)

let processResult = @(text) addPopup({
  id = "preset_equip"
  text
})

function presetAction(presetCfg, soldier) {
  if (presetCfg?.isLockedPrem) {
    premiumWnd()
    return
  }

  if (presetCfg?.onClick != null) {
    presetCfg.onClick()
    return
  }

  if (presetCfg?.fnApply == null) {
    return
  }

  if (notFoundPresetItems.get().len() > 0)
    showNotFoundMsg(notFoundPresetItems.get(), presetCfg?.applyAnyway ?? true,
      @() applyEquipmentPreset(presetCfg, soldier))
  else
    applyEquipmentPreset(presetCfg, soldier)
}

let mkActions = @(soldier) {
  save = function(cfg) {
    let items = getSoldierItemSlots(soldier.guid, campItemsByLink.get())
      .apply(@(slot) {
        slotType = slot.slotType
        slotId = slot.slotId
        itemTpl = trimUpgradeSuffix(slot.item.basetpl)
      })

    cfg?.fnSave(cfg, soldier, items)
    processResult(loc("preset/equip/saved"))
  }
  apply = @(cfg) presetAction(cfg, soldier)
  remove = @(cfg) cfg.fnDelete(cfg, soldier)
  rename = @(cfg, name) cfg?.fnRename(cfg, soldier, name)
  hover = @(on) previewPreset.set(on)
}

let mkPresetEquipBlock = @(soldierInfoWatch) function() {
  let soldier = soldierInfoWatch.get()
  let actions = mkActions(soldier)
  return {
    watch = [presetWidgetOpened, soldierInfoWatch]
    size = FLEX_V
    children = !presetWidgetOpened.get() || soldier == null ? null
      : mkPresetBlock({
          actions
          dataWatch = presetEquipList
          width = presetBlockWidth
          animation = leftAppearanceAnim
        })
  }
}

return {
  closeEquipPresets = closePresetBlock
  togglePresetEquipBlock = togglePresetBlock
  mkPresetEquipBlock
  previewPreset
  presetBlockWidth
}
