import "%ui/currency/premiumWnd.nut" as premiumWnd
from "%ui/currency/premium.nut" import hasPremium
from "%ui/preset/presetEquipStorage.nut" import savePreset, renamePreset, deletePreset,
  equipmentPresetWatch
from "%ui/soldiers/model/state.nut" import curArmy, getSoldierItemSlots
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/meta/profile.nut" import campItemsByLink, curCampItems
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/soldiers/model/itemActions.nut" import equipByList
from "%ui/preset/presetEquipCfg.nut" import minimumEquipList,
  bestEquipList, selectedEquipList, buyEquipList, SLOT_COUNT, SLOT_COUNT_MAX
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate,
  equipSchemesByArmy
from "%ui/soldiers/model/items_list_lib.nut" import mkShopItem
from "%ui/soldiers/model/selectItemState.nut" import MAX_ITEM_BR
from "%ui/researches/researchesSummary.nut" import classSlotLocksByArmy
from "%ui/preset/presetWidget.nut" import InlineButtons
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/quickMatchQueue.nut" import isChangesBlocked, showBlockedChangesMessage
from "%ui/ui_library.nut" import *


let slotCount = Computed(@() hasPremium.get() ? SLOT_COUNT_MAX : SLOT_COUNT)
let notFoundItems = Watched({})

enum PreviewState {
  OK = "replace"
  ERROR = "noReplace"
  NONE = "none"
}

let frameColors = {
  [PreviewState.OK] = Color(20,255,10),
  [PreviewState.ERROR] = Color(255,150,150),
  [PreviewState.NONE] = null
}

let previewHighlightColor = @(previewState) frameColors[previewState ?? PreviewState.NONE]

const BR_BTN_FLAGS = InlineButtons.HIDE_COMMON | InlineButtons.VISIBLE_ALWAYS

function genButtons(presetCfg) {
  let { buttonsLocId = null } = presetCfg
  let result = []
  for (local i = 1; i <= MAX_ITEM_BR; i++) {
    let name = getRomanNumeral(i)
    result.append({
      name
      tooltip = buttonsLocId == null ? "" : loc(buttonsLocId, { BR = name })
      args = { maxBR = i }
    })
  }
  return result
}

let autoPresets = [
  { locId = loc("autoEquip"), fnApply = bestEquipList, genButtons,
    inlineBtns = BR_BTN_FLAGS, buttonsLocId = "squads/presets/applyBR" }
  { locId = loc("buyBestBR"), fnApply = buyEquipList, genButtons,
    inlineBtns = BR_BTN_FLAGS, buttonsLocId = "squads/presets/buyBR", applyAnyway = false }
  { locId = loc("removeAllEquipment"), fnApply = minimumEquipList }
]

let presetSlotName = @(preset, index) preset?.campaign
  ? loc("squads/presets/united", { campaign = loc($"{preset.campaign}/full"),
      name = preset.name })
  : (preset?.name ?? loc("btn/preset/name", { count = getRomanNumeral(index + 1) }))

function mkSlotDesc(data, i) {
  let exists = data != null
  return {
    locId = presetSlotName(data, i)
    slot = i
    data
    fnApply = exists ? selectedEquipList : null
    fnRename = exists && i < SLOT_COUNT_MAX ? renamePreset : null
    fnDelete = exists && i >= SLOT_COUNT_MAX ? deletePreset : null
    fnSave = i < SLOT_COUNT_MAX ? savePreset : null
  }
}

function mkSlotPrem(data, i) {
  return {
    locId = data?.name ?? loc("btn/preset/locked")
    slot = i
    data
    fnApply = data != null ? selectedEquipList : null
    onClick = @() premiumWnd()
    isLockedPrem = true
  }
}

let presetEquipList = Computed(function() {
  let allPresets = clone autoPresets
  let armyId = curArmy.get()
  let { sKind = null } = curSoldierInfo.get()
  let list = equipmentPresetWatch.get()?[armyId][sKind]
  let presetsCount = list?.len() ?? SLOT_COUNT_MAX
  let slotCountVal = slotCount.get()
  for (local idx = 0; idx < presetsCount; idx++) {
    let slotData = list?[idx]
    allPresets.append(idx < slotCountVal || idx >= SLOT_COUNT_MAX
      ? mkSlotDesc(slotData, idx)
      : mkSlotPrem(slotData, idx))
  }
  return allPresets
})

function shopItemByTemplateData(itemTpl) {
  
  let template = findItemTemplate(allItemTemplates.get(), curArmy.get(), itemTpl)
  if (template == null)
    return null
  return mkShopItem(itemTpl, template, curArmy.get())
}

let canEquip = @(slotData)
  !(slotData?.shopItem != null || (slotData?.item.isFixed ?? false))

let expandedSlotTypes = ["inventory", "grenade"]

let isLocked = @(lockedSlots, slotData, needRemoveExpanded)
  lockedSlots.contains(slotData.slotType)
    || (needRemoveExpanded && expandedSlotTypes.contains(slotData.slotType) && slotData.slotId > 0)

function makePreviewList(soldier, slotsItems, changeEquipList) {
  if (changeEquipList.len() == 0)
    return slotsItems

  let lockedSlots = classSlotLocksByArmy.get()?[getLinkedArmyName(soldier)][soldier.sClass] ?? []
  let removeExpanded = lockedSlots.contains("backpack")

  foreach(slotData in changeEquipList) {
    
    
    if (slotData?.item == null) {
      let item = slotData?.shopItem == null
        ? slotData?.guid == null ? null : curCampItems.get()?[slotData.guid]
        : shopItemByTemplateData(slotData.shopItem)
      slotData.item <- item
    }
    

    slotData.previewState <- canEquip(slotData) && !isLocked(lockedSlots, slotData, removeExpanded)
      ? PreviewState.OK : PreviewState.ERROR

    let equippedItem = slotsItems.findvalue(@(i)
      i.slotType == slotData.slotType && i.slotId == slotData.slotId)

    if (equippedItem == null)
      slotsItems.append(slotData)
    else if (slotData?.item.basetpl != equippedItem?.item.basetpl)
      equippedItem.__update(slotData)
  }

  return slotsItems
}

function getItemSlotsWithPreset(soldier, campItemsByLinkVal, previewPresetVal, equipSchemesVal) {
  let changeEquipList = previewPresetVal?.fnApply(previewPresetVal,
    soldier, campItemsByLinkVal, notFoundItems, equipSchemesVal) ?? []
  let slotsItems = getSoldierItemSlots(soldier.guid, campItemsByLinkVal)
  return makePreviewList(soldier, slotsItems, changeEquipList)
}

function applyEquipmentToSoldier(presetCfg, soldier, notFoundItemsWatch) {
  if (soldier == null)
    return

  let changeEquipList = presetCfg?.fnApply(presetCfg,
    soldier, campItemsByLink.get(), notFoundItemsWatch, equipSchemesByArmy.get()) ?? []

  if (changeEquipList.len() > 0) {
    let lockedSlots = classSlotLocksByArmy.get()?[getLinkedArmyName(soldier)][soldier.sClass] ?? []
    let removeExpanded = lockedSlots.contains("backpack")

    equipByList(soldier.guid, changeEquipList
      .filter(@(slotData) canEquip(slotData) && !isLocked(lockedSlots, slotData, removeExpanded))
      .map(@(i) {
        guid = i?.guid ?? (i?.item.guid ?? "")
        slotType = i.slotType
        slotId = i.slotId
      }
    ))
  }
}

function applyEquipmentPreset(presetCfg, soldier) {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }

  applyEquipmentToSoldier(presetCfg, soldier, notFoundItems)
}

return {
  applyEquipmentPreset
  presetEquipList
  notFoundPresetItems = notFoundItems
  getItemSlotsWithPreset
  shopItemByTemplateData
  previewHighlightColor
}
