import "%ui/components/spinner.nut" as spinner
import "%ui/soldiers/mkItemWithMods.nut" as mkItemWithMods
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/textButton.nut" import Regular
from "%ui/style/designConst.nut" import commonBorderRadius, disabledBgColor, leftAppearanceAnim, defItemBlur, fullTransparentBgColor, smallPadding, midPadding, defTxtColor
from "%ui/soldiers/model/state.nut" import curArmy, squadsByArmy, canChangeEquipmentInSlot
from "%ui/researches/researchesSummary.nut" import classSlotLocksByArmy
from "%ui/soldiers/model/all_items_templates.nut" import equipSchemesByArmy
from "%ui/soldiers/model/selectItemState.nut" import openSelectItem
from "%ui/soldiers/components/itemComp.nut" import ItemNotifiers
from "%ui/soldiers/model/soldierSlotsCount.nut" import mkSoldierSlotsComp
from "%ui/helpers/metalink.nut" import getLinkedArmyName, getLinkedSquadGuid
from "%ui/soldiers/model/unseenWeaponry.nut" import betterWeaponrySoldier, soldierSeenSlots
from "%ui/meta/profile.nut" import campItemsByLink, curCampItems, curCampSoldiers
from "%ui/components/itemsInfo.nut" import getErrorSlots
from "%ui/soldiers/model/itemActions.nut" import isItemActionInProgress
from "%ui/preset/presetEquipUtils.nut" import getItemSlotsWithPreset
from "%ui/preset/presetEquipUi.nut" import togglePresetEquipBlock, previewPreset
from "%ui/shop/armyShopState.nut" import goodManageData
from "%ui/ui_library.nut" import *

let { equipSlotRows } = require("%ui/soldiers/model/config/equipGroups.nut")
let { manageBlinkingObject } = require("%ui/components/blinkingIcon.nut")





let waitingSpinner = spinner(hdpx(25))

function openEquipMenu(p ) {
  openSelectItem(curArmy.get(), p?.soldierGuid, p?.slotType, p?.slotId)
}

let mkItem = @(params) mkItemWithMods(params)
  .__merge({ size = [FLEX, params.itemSize[1]] })

function collectSlots(slotType, totalSlots, slotsItems, soldierGuid) {
  let soldierData = curCampSoldiers.get()?[soldierGuid]
  local isAvailable = true
  if (soldierData && slotType) {
    let armyId = getLinkedArmyName(soldierData)
    let { sClass = "unknown" } = soldierData
    isAvailable = !(classSlotLocksByArmy.get()?[armyId][sClass] ?? []).contains(slotType)
  }

  let emptySlot = { item = null, slotType = slotType, slotId = -1, isLocked = !isAvailable,
    canDrag = true }
  let slots = slotsItems.filter(@(s) s.slotType == slotType)
    .map(@(s) emptySlot.__merge(s))
  if (totalSlots <= 0)
    return slots.len() > 0 ? slots : [emptySlot]

  let slotsMap = {}
  slots.each(@(s) slotsMap[s.slotId] <- s)
  return array(totalSlots).map(@(_, slotId) slotId < totalSlots
    ? slotsMap?[slotId] ?? emptySlot.__merge({ slotId = slotId })
    : emptySlot.__merge({ slotId = slotId, isLocked = true }))
}

const lockIconSize = hdpxi(32)
const lockObjSize = hdpx(50)

let mkLockedBlock = @(color) {
  rendObj = ROBJ_WORLD_BLUR
  size = FLEX
  fillColor = color
  color = defItemBlur
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      size = FLEX
      rendObj = ROBJ_VECTOR_CANVAS
      lineWidth = hdpx(2)
      color = fullTransparentBgColor
      opacity = 0.05
      commands = [[ VECTOR_LINE, 0, 0, 100, 100 ], [ VECTOR_LINE, 0, 100, 100, 0 ]]
    }
    {
      size = const [lockObjSize, lockObjSize]
      rendObj = ROBJ_VECTOR_CANVAS
      commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
      fillColor = color
      color
    }
    {
      rendObj = ROBJ_IMAGE
      size = array(2, lockIconSize)
      image = Picture($"ui/skin#locked_icon.svg:{lockIconSize}:{lockIconSize}")
      color = fullTransparentBgColor
      opacity = 0.05
    }
  ]
}


let mkDisabledSlot = @(slotSize) {
  size = slotSize
  rendObj = ROBJ_BOX
  fillColor = disabledBgColor
  borderRadius = commonBorderRadius
  children = mkLockedBlock(disabledBgColor)
}

let mkParatrooperSlot = @(slotSize, headerText) {
  flow = FLOW_VERTICAL
  children = [
    headerText == "" ? null
      : {
          size = FLEX_H
          children = {
            rendObj = ROBJ_TEXT
            text = headerText
          }.__update(fontSub)
        }
    {
      size = slotSize
      rendObj = ROBJ_BOX
      fillColor = 0x40052060
      borderRadius = commonBorderRadius

      children = {
        rendObj = ROBJ_TEXT
        text = loc("slot/equipInBattle")
        margin = smallPadding
        color = defTxtColor
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_LEFT
        opacity = 0.5
      }.__update(fontSub)
    }
  ]
}


function mkSlot(rowIdx, slotData, guid) {
  let { slotSize, slotCtor = null, scheme = null } = slotData
  let key = $"slot_{guid}_{rowIdx}"

  if (slotData?.isParatrooperSlot)
    return mkParatrooperSlot(slotSize, loc(slotData.headerLocId))
      .__update({ key }, leftAppearanceAnim(0.05 * rowIdx))
  if (scheme == null || slotCtor == null)
    return mkDisabledSlot(slotSize).__update({ key }, leftAppearanceAnim(0.05 * rowIdx))

  return slotCtor(slotData)
    .__update(leftAppearanceAnim(0.05 * rowIdx), { key } )
}


function mkSlotsList(slotData, soldier, canManage, slotsCount, slotsItems,
  maxSlotIndex, slotCtor, objectsByGuid
) {
  let { slotType, slotSize, slotImg, hasName = false, headerLocId = "" } = slotData

  let { equipScheme = {}, guid, sClass } = soldier

  let availableType = slotType in equipScheme
    ? slotType
    : equipScheme.findindex(@(v) v?.ingameWeaponSlot == slotType)

  if (availableType == null)
    return []

  let errorSlotTypes = getErrorSlots(slotsItems, equipScheme)

  let curSlotsCount = slotsCount.get()?[availableType] ?? 0
  let scheme = equipScheme?[availableType]
  let { isDisabled = false } = scheme
  let hasWarning = errorSlotTypes?[availableType] ?? false

  let needShowUnseenIcon = canChangeEquipmentInSlot(sClass, availableType)

  local isParatrooperSlot = false
  if (slotType == "secondary") {
    let squadGuid = getLinkedSquadGuid(soldier)
    let soldierSquad = squadsByArmy.get()?[curArmy.get()].findvalue(@(v) v.guid == squadGuid)
    isParatrooperSlot = soldierSquad?.isParatroopers ?? false
  }

  let slotsList = collectSlots(availableType, max(curSlotsCount, maxSlotIndex), slotsItems, guid)
  slotsList.each(function(s) {
    let item = objectsByGuid?[s.item?.guid] ?? s.item
    s.__update({
      item, scheme, isDisabled, hasWarning, canManage, soldierGuid = guid,
      slotSize, slotCtor, hasName, headerLocId, slotImg, isParatrooperSlot
      itemSize = slotSize
      isLocked = s.isLocked || s.slotId >= curSlotsCount
    })
    if (needShowUnseenIcon) {
      s.notifierState <- Computed(@() availableType not in (betterWeaponrySoldier.get()?[guid] ?? {})
        ? ItemNotifiers.EMPTY
        : availableType in soldierSeenSlots.get()?[guid]
          ? ItemNotifiers.BETTER_ITEM
          : ItemNotifiers.UNSEEN_BETTER_ITEM
        )
    }
  })
  return slotsList
}


let mkEquipRow = @(equipRow, rowIdx, soldier, canManage, slotsCount, slotsItems,
    slotCtor, manageSlotType)
  function() {
    let slotsList = []
    let { guid } = soldier

    foreach (slotData in equipRow) {
      if ("slotType" in slotData)
        slotsList.extend(
          mkSlotsList(slotData, soldier, canManage, slotsCount, slotsItems, 0,
            slotCtor, curCampItems.get())
        )
      else {
        let { unitedSlots = [], slots = 1 } = slotData
        foreach (sData in unitedSlots) {
          slotsList.extend(
            mkSlotsList(sData, soldier, canManage, slotsCount, slotsItems, slots,
              slotCtor, curCampItems.get())
          )
        }
      }
    }

    return {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = midPadding
      valign = ALIGN_BOTTOM
      watch = [curCampItems, previewPreset]
      children = slotsList.map(function(slot) {
        let hasManageBlink = slot?.slotType == manageSlotType
        return {
          size = FLEX_H
          children = [
            mkSlot(rowIdx, slot, guid)
            hasManageBlink ? manageBlinkingObject : null
          ]
        }
      })
    }
  }

let mkEquipPresetBtn = @() {
  watch = isItemActionInProgress
  size = FLEX_H
  halign = ALIGN_CENTER
  children = isItemActionInProgress.get()
    ? waitingSpinner
    : Regular(loc("preset/equip/open"), togglePresetEquipBlock, {
        btnWidth = FLEX
        rendObj = ROBJ_WORLD_BLUR_PANEL
      })
}

let soldierEquip = @(soldier, canManage = true, selectedKeyWatch = Watched(null),
  onDoubleClickCb = null, onResearchClickCb = null, dropExceptionCb = null
) function() {
    let itemCtor = @(p) mkItem(p.__merge({
      onClickCb = openEquipMenu
      selectedKey = selectedKeyWatch
      onDoubleClickCb = onDoubleClickCb
      onDropExceptionCb = dropExceptionCb
      onResearchClickCb = onResearchClickCb
    }))

    let slotsCount = mkSoldierSlotsComp(soldier.get().guid, soldier.get()?.equipScheme ?? {})
    let slotsItems = getItemSlotsWithPreset(soldier.get(),
      campItemsByLink.get(), previewPreset.get(), equipSchemesByArmy.get())

    let { manageSlotType = null } = goodManageData.get()
    local rowIdx = 0
    let children = equipSlotRows.map(@(slotGroup) {
      flow = FLOW_VERTICAL
      gap = midPadding
      size = FLEX_H
      children = slotGroup.map(@(equipRow)
        mkEquipRow(equipRow, rowIdx++, soldier.get(), canManage,
          slotsCount, slotsItems, itemCtor, manageSlotType))
    })

    children.append(mkEquipPresetBtn)

    return {
      watch = [soldier, campItemsByLink, previewPreset, goodManageData, equipSchemesByArmy]
      flow = FLOW_VERTICAL
      size = FLEX
      gap = midPadding
      children = [
        {
          size = FLEX
          gap = midPadding * 2
          flow = FLOW_VERTICAL
          children
        }
      ]
    }
}

return kwarg(soldierEquip)