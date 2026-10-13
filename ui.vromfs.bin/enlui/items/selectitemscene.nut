import "%ui/unlocks/isNewbie.nut" as isNewbie
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/mkHeader.nut" as mkHeader
import "%ui/components/mkToggleHeader.nut" as mkToggleHeader
import "%ui/soldiers/mkItemWithMods.nut" as mkItemWithMods
import "%ui/soldiers/researchUpgradeMsgBox.nut" as gotoResearchUpgradeMsgBox
import "%ui/tutorial/armoryTutorial.nut" as openArmoryTutorial
import "%ui/shop/clickShopItem.nut" as clickShopItem
import "%ui/components/fontIconButton.nut" as fontIconButton
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/style/designConst.nut" import defLockedSlotBgColor, defTxtColor, blurBgColor, bigPadding,
  defSlotBgColor, attentionTxtColor, blurBgFillColor, unitSize, midPadding, smallPadding,
  tinyOffset, selectedPanelBgColor, fullTransparentBgColor, accentColor
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/textButton.nut" import Regular, Primary, FARegular
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/components/itemPkg.nut" import statusIconCtor
from "%ui/soldiers/components/itemComp.nut" import ItemNotifiers
from "%ui/soldiers/model/mkItemDemands.nut" import mkItemDemands, mkItemListDemands
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/soldiers/model/all_items_templates.nut" import itemTypesInSlots
from "%ui/soldiers/components/itemDetailsComp.nut" import mkViewDetailsSwitchable, lockedInfo
from "%ui/soldiers/mkSoldierInfo.nut" import mkSoldierInfo
from "%ui/components/soldierClasses.nut" import soldierClasses
from "%ui/soldiers/model/state.nut" import getSoldierItemSlots, getEquippedItemGuid
from "%ui/meta/profile.nut" import campItemsByLink
from "%ui/soldiers/model/itemActions.nut" import isItemActionInProgress
from "%ui/showState.nut" import curHoveredItem, changeCameraFov
from "%ui/researches/researchesFocus.nut" import focusResearch, findSlotUnlockRequirement
from "%ui/soldiers/unequipItem.nut" import unequipItem, unequipBySlot
from "%ui/soldiers/model/selectItemState.nut" import slotItems, otherSlotItems, prevItems
  , selectParams, selectParamsList, selectParamsArmyId, curEquippedItem, viewItem
  , paramsForPrevItems, openSelectItem, trySelectNext, curInventoryItem, checkSelectItem, selectItem, itemClear
  , markLastViewedSlot, selectNextSlot, selectPreviousSlot, ItemCheckResult, getBR, MAX_ITEM_BR
from "%ui/soldiers/model/unseenWeaponry.nut" import soldierSlotsTiersEquipped
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo, curSoldierGuid
from "%ui/soldiers/model/newItemsToShow.nut" import justPurchasedItems
from "%ui/soldiers/model/chooseSoldiersState.nut" import dismissGuids
from "%ui/shop/armyShopState.nut" import getShopItemsCmp, getShopItemsList
from "%ui/options/mkOnlinePersistentFlag.nut" import mkOnlinePersistentFlag
from "%ui/preset/presetEquipUi.nut" import mkPresetEquipBlock, presetBlockWidth
from "%ui/quickMatchQueue.nut" import isChangesBlocked
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/battleData/testDrive.nut" import mkCommonTestDriveButtonUi
from "%ui/meta/tutorial/meta_tutorial_button.nut" import mkPageButton
from "%ui/meta/tutorial/meta_tutorial_config.nut" import Tutorial
from "%ui/soldiers/components/modifyItemPkg.nut" import mkDisposeBtn, mkUpgradeBtn
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/preset/equipDesign.nut" import rowHeight, innerBtnStyle
from "%ui/style/cursors.nut" import setTooltip
from "%ui/components/mkSpecialItemIcon.nut" import bpIcon, eventIcon, SIGN_BP, SIGN_EVENT
from "%sqstd/string.nut" import utf8ToLower
from "%ui/components/itemsInfo.nut" import itemNameFromItem
from "%ui/ui_library.nut" import *

let { waitingSpinner } = require("%ui/soldiers/components/modifyItemPkg.nut")
let textInput = require("%ui/components/textInput.nut")

const ADD_CAMERA_FOV_MIN = -15
const ADD_CAMERA_FOV_MAX = 15

let filterButtonSize = {
  btnWidth = hdpx(46)
  btnHeight = hdpx(46)
}

let isItemsFilterOpened = Watched(false)
let itemsFilterPreset = Watched(null)
let itemsFilterText = Watched("")

let mkFilteredByPreset = @(listWatch) Computed(function() {
  let list = listWatch.get()
  let handler = itemsFilterPreset.get()?.handler
  return handler == null ? list
    : list.filter(@(item) handler(item))
})

let mkFilteredList = @(listWatch) Computed(function() {
  let list = listWatch.get()
  let filterText = itemsFilterText.get().strip()
  if (filterText == "")
    return list

  let mask = utf8ToLower(filterText)
  return list.filter(function(item) {
    return utf8ToLower(itemNameFromItem(item)).contains(mask)
  })
})

let slotItemsFiltered = mkFilteredList(mkFilteredByPreset(slotItems))
let otherSlotItemsFiltered = mkFilteredList(mkFilteredByPreset(otherSlotItems))

let armoryWndOpenFlag = mkOnlinePersistentFlag("armoryWndOpenFlag")
let armoryWndOpened = armoryWndOpenFlag.flag
let markSeenArmoryTutorial = armoryWndOpenFlag.activate

let getItemSelectKey = @(item) item?.isShopItem ? item?.basetpl : item?.guid

let selectedKey = Watched(null)
viewItem.subscribe(function(item) {
  selectedKey.set(getItemSelectKey(item))
  changeCameraFov(0)
})

let selectedSlot = Computed(function() {
  let { ownerGuid = null, slotType = null, slotId = null } = selectParams.get()
  local guid = null
  if (ownerGuid && slotType)
    guid = getEquippedItemGuid(campItemsByLink.get(), ownerGuid, slotType, slotId)
  return guid ?? "_".concat(ownerGuid, slotType, slotId)
})

function defStatusCtor(item, soldierWatch) {
  let demandsWatch = mkItemDemands(item)
  return @() {
    watch = [demandsWatch, soldierWatch]
    children = statusIconCtor(demandsWatch.get())
  }
}

let activeItemParams = {
  statusCtor = defStatusCtor
}

let blockedItemParams = {
  bgColor = defLockedSlotBgColor
  statusCtor = defStatusCtor
  canEquip = false
  onDoubleClickCb = null
}

let prevItemParams = {
  statusCtor = defStatusCtor
  selectedKey = selectedSlot
  onClickCb = function(data) {
    let prev = paramsForPrevItems.get()
    let { soldierGuid = "" } = data
    if (soldierGuid != "") 
      openSelectItem(prev?.armyId, soldierGuid, data.slotType, data.slotId)
    else
      curInventoryItem.set(data.item)
  }
  canEquip = false
  onDoubleClickCb = unequipItem
}

function processItemDrop(item, checkInfo) {
  let { result, soldier = null, slotType = null, soldierClass = null } = checkInfo
  let buttons = [{ text = loc("Ok"), isCancel = true }]
  local text = ""
  if (result == ItemCheckResult.NEED_RESEARCH) {
    let { research = null } = findSlotUnlockRequirement(soldier, slotType)
    if (research != null) {
      text = loc("slotClassResearch", { soldierClass })
      buttons.append({
        text = loc("GoToResearch")
        action = @() focusResearch(research)
        isCurrent = true })
    }

  } else if (result == ItemCheckResult.WRONG_CLASS){
    text = loc("Not available for class", { soldierClass })

  } else if (result == ItemCheckResult.IN_SHOP) {
    
    let shopItem = getShopItemsList(item.basetpl)?[0]
    if (shopItem)
      clickShopItem(shopItem)
    return
  }
  showMsgbox({ text, buttons })
}

function dropExceptionCb(dropItem) {
  let checkDropItem = checkSelectItem(dropItem)
  if (checkDropItem)
    processItemDrop(dropItem, checkDropItem)
}

let mkStdCtorData = @(itemSize) {
  size = itemSize
  itemsInRow = 1
  ctor = @(item, override) mkItemWithMods({
    isXmb = true
    item
    itemSize
    forceTypeIcon = true
    canDrag = !!item?.basetpl
    selectedKey = selectedKey
    selectKey = getItemSelectKey(item)
    onClickCb = @(data) data.item == item ? curInventoryItem.set(item)
      : (item?.guid ?? "") != "" ? openSelectItem(selectParamsArmyId.get(), item.guid, data.slotType, data.slotId)
      : null
    onDropExceptionCb = dropExceptionCb
    onDoubleClickCb = function(data) {
      if (data.item != item)
        return
      let checkSelectInfo = checkSelectItem(item)
      if (checkSelectInfo){
        processItemDrop(item, checkSelectInfo)
        return
      }
      selectItem(item)
      trySelectNext()
      sound_play("ui/inventory_item_place")
    }
  }.__update(override))
}

let defaultCtorData = mkStdCtorData([6.0 * unitSize, 2.2 * unitSize])

let mainWeaponCtorData = mkStdCtorData([9.0 * unitSize, 2.2 * unitSize])

let getCtorData = @(typesInSlots, itemType)
  itemType in typesInSlots.mainWeapon ? mainWeaponCtorData : defaultCtorData

let mkItemsList = @(listWatch, itemParamsOverride) function() {
  itemParamsOverride.soldierGuid <- curSoldierInfo.get()?.guid
  let items = listWatch.get()
  let ctorData = getCtorData(itemTypesInSlots.get(), items?[0].itemtype)
  let { size, itemsInRow } = ctorData
  let itemContainerWidth = itemsInRow * size[0] + (itemsInRow - 1) * midPadding
  return wrap(
    items.map(@(item) (getCtorData(itemTypesInSlots.get(), item?.itemtype) ?? ctorData).ctor(item, itemParamsOverride)),
    { width = itemContainerWidth, hGap = smallPadding, vGap = smallPadding, hplace = ALIGN_CENTER }
  ).__update({ watch = [listWatch, itemTypesInSlots, curSoldierInfo] })
}

function mkDemandHeader(demand) {
  let key = demand.keys()?[0]
  let value = demand?[key]
  let suffix = value == true ? "_yes"
    : value == false ? "_no"
    : ""
  return {
    rendObj = ROBJ_TEXT
    size = FLEX_H
    margin = [tinyOffset, 0, 0, 0]
    text = demand?.lockTxt ?? loc($"itemDemandsHeader/{key}{suffix}", demand)
    color = defTxtColor
  }.__update(fontSub)
}

let mkItemsGroupedList = kwarg(@(listWatch, overrideParams, newWatch, onlyNew = false,
  noHeaders = false
) function() {
    overrideParams.soldierGuid <- curSoldierInfo.get()?.guid

    let newList = newWatch.get()
    let itemsToDisplay = listWatch.get()
      .filter(@(i) !onlyNew || newList.contains(i.guid))

    let itemsWithDemands = mkItemListDemands(itemsToDisplay)
    let itemsDemands = itemsWithDemands.get()
    let ctorData = getCtorData(itemTypesInSlots.get(), itemsDemands?[0].item.itemtype)
    let { size, itemsInRow } = ctorData
    let itemContainerWidth = itemsInRow * size[0] + (itemsInRow - 1) * midPadding

    let { ownerGuid = null, slotType = null } = selectParams.get()
    let isShowClassesHint = slotType == "primary" || slotType == "secondary"
    let groupedItems = {}
    let mappedDemands = {}
    foreach (data in itemsDemands) {
      let { item, demands = null } = data
      let groupKey = demands?.order ?? 0
      mappedDemands[groupKey] <- demands
      groupedItems[groupKey] <- (groupedItems?[groupKey] ?? []).append(item)
    }
    let children = []
    let keysOrdered = groupedItems.keys().sort()
    foreach (groupKey in keysOrdered) {
      let demand = mappedDemands[groupKey]
      if (groupKey != 0 && !noHeaders)
        children.append(mkDemandHeader(demand))

      let itemsList = groupedItems[groupKey].map(function(item) {
          let ctor = (getCtorData(itemTypesInSlots.get(), item?.itemtype) ?? ctorData).ctor
          let { tier = 0, isShopItem = false } = item
          let notifierState = Computed(@() !isShopItem
            && ownerGuid in soldierSlotsTiersEquipped.get()
            && tier > (soldierSlotsTiersEquipped.get()?[ownerGuid][slotType] ?? -1)
              ? ItemNotifiers.BETTER_ITEM : ItemNotifiers.EMPTY)
          return ctor(item,
            overrideParams.__merge({
              isNew = onlyNew
              isShowClassesHint
              notifierState
            }))
        })

      children.append(wrap(itemsList, {
        width = itemContainerWidth, hGap = smallPadding, vGap = smallPadding, hplace = ALIGN_CENTER
      }))
    }
    return {
      watch = [listWatch, itemTypesInSlots, curSoldierInfo, itemsWithDemands, selectParams]
      size = [itemContainerWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = children
    }
  })

let armoryList = mkItemsGroupedList({
  listWatch = slotItemsFiltered
  overrideParams = activeItemParams
  newWatch = justPurchasedItems
})
let otherList = mkItemsGroupedList({
  listWatch = otherSlotItemsFiltered
  overrideParams = blockedItemParams
  newWatch = justPurchasedItems
  noHeaders = true
})
let otherListNewOnly = mkItemsGroupedList({
  listWatch = otherSlotItems
  overrideParams = blockedItemParams
  newWatch = justPurchasedItems
  onlyNew = true
})

let prevArmory = mkItemsList(prevItems, prevItemParams)

function onBackAction() {
  markLastViewedSlot()
  itemClear()
}

let backButton = Regular(loc("mainmenu/btnBack"), onBackAction)

function mkChooseButtonUi(item) {
  return function() {
    let watch = [curEquippedItem, isItemActionInProgress, isChangesBlocked]
    let equippedItem = curEquippedItem.get()
    if (item == equippedItem
        || (equippedItem == null && item?.basetpl == null)
        || checkSelectItem(item) != null)
      return { watch }

    return {
      watch
      margin = [0, 0, 0, midPadding]
      children = Primary(
        loc("mainmenu/btnSelect"),
        @() selectItem(item),
        {
          hotkeys = [[ "^J:Y" ]]
          isEnabled = !isItemActionInProgress.get() && !isChangesBlocked.get()
        }
      )
    }
  }
}


function mkObtainButton(item) {
  if (item == null || item?.basetpl == null)
    return null

  let shopItemsCmp = getShopItemsCmp(item.basetpl)
  let isWrongClass = checkSelectItem(item)?.result == ItemCheckResult.WRONG_CLASS

  return function() {
    let shopItem = shopItemsCmp.get()?[0]
    return {
      watch = [shopItemsCmp, isItemActionInProgress]
      margin = [0, 0, 0, midPadding]
      children = shopItem != null ? Regular(loc("btn/buy"),
          @() clickShopItem(shopItem, isWrongClass),
          {
            hotkeys = [["^J:X"]]
            isEnabled = !isItemActionInProgress.get()
          }
        )
      : null
  }}
}

let mkListToggleHeader = @(sClass, flag) mkToggleHeader(flag
  loc("Not available for class", { soldierClass = loc(soldierClasses?[sClass].locId ?? "unknown") }))

function otherItemsBlock() {
  let watch = [curSoldierInfo, otherSlotItemsFiltered, itemsFilterText]
  if (otherSlotItemsFiltered.get().len() == 0)
    return { watch }

  let isListExpanded = Watched(itemsFilterText.get() != "")
  let sClass = curSoldierInfo.get()?.sClass ?? "unknown"
  return {
    watch
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      mkListToggleHeader(sClass, isListExpanded)
      @() {
        watch = [isListExpanded, itemsFilterText]
        children = isListExpanded.get() ? otherList : otherListNewOnly
      }
    ]
  }
}

let mkPresetBtnStyle = @(hintText) {
  btnWidth = rowHeight
  btnHeight = rowHeight
  onHover = function(on) {
    setTooltip(!on ? null : hintText)
  }
}.__update(innerBtnStyle)

let mkPresetButton = @(text, action, hintText) Regular(text, action, mkPresetBtnStyle(hintText))

let mkFAPresetButton = @(icon, action, hintText) FARegular(icon, action, mkPresetBtnStyle(hintText))

let mkBpPresetFilter = @(index) function() {
  itemsFilterPreset.set({
    handler = @(item) item?.sign == SIGN_BP
    sign = SIGN_BP
    index
  })
}

let mkEventPresetFilter = @(index) function() {
  itemsFilterPreset.set({
    handler = @(item) item?.sign == SIGN_EVENT
    sign = SIGN_EVENT
    index
  })
}

let mkPresetContent = @(icon) @(_textField, params, handler, group, sf)
  textButtonTextCtor({
    size = [rowHeight, rowHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = icon
  }, params, handler, group, sf)

let bpPresetContent = mkPresetContent(bpIcon)
let eventPresetContent = mkPresetContent(eventIcon)

let mkBPPresetButton = @(index) Regular(bpPresetContent, mkBpPresetFilter(index),
  mkPresetBtnStyle(loc("squads/filter/bp")))

let mkEventPresetButton = @(index) Regular(eventPresetContent, mkEventPresetFilter(index),
  mkPresetBtnStyle(loc("squads/filter/event")))

let mkAllPresetButton = @() mkFAPresetButton("asterisk", function() {
  itemsFilterPreset.set(null)
}, loc("squads/filter/all"))

function mkPresetContainer(content, index) {
  let isCurrent = Computed(@() itemsFilterPreset.get()?.index == index)
  return @() {
    watch = isCurrent
    rendObj = ROBJ_SOLID
    color = isCurrent.get() ? selectedPanelBgColor : fullTransparentBgColor
    children = {
      rendObj = ROBJ_BOX
      borderWidth = isCurrent.get() ? [0, 0, hdpx(2), 0] : 0
      borderColor = accentColor
      children = content
    }
  }
}

function mkFilterPopup() {
  local filterButtonIndex = 0
  let buttons = [
    mkPresetContainer(mkAllPresetButton(), null)
    mkPresetContainer(mkBPPresetButton(filterButtonIndex), filterButtonIndex++)
    mkPresetContainer(mkEventPresetButton(filterButtonIndex), filterButtonIndex++)
  ]

  for (local i = 1; i <= MAX_ITEM_BR; ++i) {
    let index = filterButtonIndex++
    let name = getRomanNumeral(i)
    let hintText = loc("squads/filter/br", { br = name })
    let br = i
    let btn = mkPresetButton(name, function() {
      itemsFilterPreset.set({
        handler = @(item) getBR(item) == br
        text = name
        index
      })
    }, hintText)
    buttons.append(mkPresetContainer(btn, index))
  }

  let watch = [isItemsFilterOpened, slotItems, otherSlotItems]
  return @() !isItemsFilterOpened.get() || (slotItems.get().len() == 0 && otherSlotItems.get().len() == 0)
    ? { watch }
    : {
        watch
        rendObj = ROBJ_WORLD_BLUR_PANEL
        flow = FLOW_HORIZONTAL
        size = [presetBlockWidth, SIZE_TO_CONTENT]
        fillColor = defSlotBgColor
        gap = { size = FLEX }
        children = buttons
      }
}

function toggleFilterPopup() {
  let state = isItemsFilterOpened.get()
  isItemsFilterOpened.set(!state)
}

function mkFilterButton(presetData) {
  let { text = null, sign = null } = presetData
  return sign == SIGN_BP ? Regular(bpPresetContent, toggleFilterPopup, filterButtonSize)
    : sign == SIGN_EVENT ? Regular(eventPresetContent, toggleFilterPopup, filterButtonSize)
    : text ? Regular(text, toggleFilterPopup, filterButtonSize)
    : FARegular("filter", toggleFilterPopup, filterButtonSize)
}

let mkFilterBlock = @() {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    {
      size = FLEX_H
      valign = ALIGN_CENTER
      children = [
        textInput(itemsFilterText, { placeholder = loc("squads/filter/search") })
        @() {
          watch = itemsFilterText
          hplace = ALIGN_RIGHT
          children = itemsFilterText.get() == "" ? null : fontIconButton("close", {
            onClick = @() itemsFilterText.set("")
            margin = const [0, fsh(0.5)]
          })
        }
      ]
    }
    @() {
      watch = itemsFilterPreset
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = mkFilterButton(itemsFilterPreset.get())
    }
  ]
}

let mkItemsListBlock = @(children) {
  size = FLEX_V
  flow = FLOW_VERTICAL
  gap = smallPadding
  padding = [0, smallPadding, midPadding, smallPadding]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  behavior = [Behaviors.DragAndDrop]
  xmbNode = XmbContainer({
    canFocus = false
    scrollSpeed = 5.0
    isViewport = true
  })
  children = [
    mkFilterBlock()
    makeVertScroll(children, {
      size = FLEX_V
      needReservePlace = false
    })
  ]
  canDrop = @(data) data?.slotType != null
  onDrop = @(data) unequipItem(data)
}

function nothingWasFound() {
  let watch = [slotItemsFiltered, otherSlotItemsFiltered, itemsFilterText, itemsFilterPreset]
  let hasItems = slotItemsFiltered.get().len() > 0 || otherSlotItemsFiltered.get().len() > 0
  let isFilterText = itemsFilterText.get() != ""
  let isPreset = itemsFilterPreset.get() != null

  if (hasItems && !isFilterText && !isPreset)
    return { watch }

  let text = hasItems ? loc("squads/filter/result")
    : isFilterText ? loc("squads/filter/no_result_search")
    : loc("squads/filter/no_result_filter")

  return {
    watch
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = FLEX_H
    halign = ALIGN_CENTER
    color = attentionTxtColor
    text
    margin = midPadding
  }.__update(fontSub)
}

let itemsListBlock = @() {
  watch = [slotItems, otherSlotItems]
  size = FLEX_V
  children = slotItems.get().len() > 0 || otherSlotItems.get().len() > 0
    ? mkItemsListBlock({
        flow = FLOW_VERTICAL
        children = [
          armoryList
          otherItemsBlock
          nothingWasFound
        ]
      })
    : null
}

let prevItemsListBlock = @() {
  size = FLEX_V
  watch = prevItems
  children = prevItems.get().len()
    ? mkItemsListBlock(prevArmory)
    : null
}

let buttonsUi = @() {
  watch = [viewItem, isItemActionInProgress]
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  children = isItemActionInProgress.get()
    ? waitingSpinner
    : [
        mkCommonTestDriveButtonUi(viewItem.get(), {
          margin = [0, 0, 0, midPadding]
          hotkeys = [[ "^J:Start" ]]
        })
        mkDisposeBtn(viewItem.get(), { margin = [0, 0, 0, midPadding] })
        mkUpgradeBtn(viewItem.get(), { margin = [0, 0, 0, midPadding] })
        mkObtainButton(viewItem.get())
        mkChooseButtonUi(viewItem.get())
      ]
}

function mkDemandsInfo(item) {
  if (item == null)
    return null

  let demandsWatch = mkItemDemands(item)
  return @() {
    watch = demandsWatch
    size = FLEX_H
    padding = smallPadding
    children = lockedInfo(demandsWatch.get())
  }
}

let infoBlock = @() {
  watch = viewItem
  size = FLEX
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  gap = midPadding
  children = [
    mkViewDetailsSwitchable(viewItem.get(), fsh(74))
    mkDemandsInfo(viewItem.get())
    buttonsUi
  ]
}

let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[-hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[0, 0], playFadeOut = true, to = [-hdpx(150), 0], duration = 0.2, easing = OutQuad }
]

function getItemSlot(item, soldier) {
  if (!item || !soldier)
    return null
  let ownerGuid = soldier.guid
  let itemSlot = getSoldierItemSlots(ownerGuid, campItemsByLink.get())
    .findvalue(@(slot) slot.item?.guid == item?.guid)
  if (!itemSlot)
    return null
  local { slotType, slotId } = itemSlot
  if (slotId == null) {
    let equipScheme = soldier?.equipScheme ?? {}
    slotId = slotType
    slotType = equipScheme.findindex(@(val) slotType in val)
    if (slotType == null)
      return null
  }
  return {
    ownerGuid = ownerGuid
    slotType = slotType
    slotId = slotId
  }
}

function quickEquipHotkeys() {
  let item = curHoveredItem.get()
  let watch = [isGamepad, curHoveredItem]
  if (!isGamepad.get() || item == null)
    return { watch }

  let soldier = curSoldierInfo.get()
  let slot = getItemSlot(item, soldier)
  return slot != null
    
    ? {
        watch
        children = {
          key = $"unequip_{item?.guid}"
          hotkeys = [["^J:Y", {
            description = loc("equip/quickUnequip")
            action = function() {
              unequipBySlot(slot)
              openSelectItem(selectParamsArmyId.get(), slot?.soldierGuid, slot?.slotType, slot?.slotId)
            }
          }]]
        }
      }
    
    : {
        watch
        children = {
          key = $"equip_{item?.guid}"
          hotkeys = [["^J:Y", {
            description = loc("equip/quickEquip")
            action = function() {
              let checkSelectInfo = checkSelectItem(item)
              if (checkSelectInfo){
                processItemDrop(item, checkSelectInfo)
                return
              }
              selectItem(item)
            }
          }]]
        }
      }
}

let itemsContent = [
  {
    size = FLEX
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    animations = animations
    transform = true
    children = [
      mkSoldierInfo({
        soldierInfoWatch = curSoldierInfo
        isMoveRight = false
        selectedKeyWatch = selectedSlot
        onDoubleClickCb = unequipItem
        dropExceptionCb
        onResearchClickCb = gotoResearchUpgradeMsgBox
      })
      prevItemsListBlock
      itemsListBlock
      {
        size = FLEX
        children = [
          infoBlock
          {
            size = FLEX
            flow = FLOW_VERTICAL
            gap = midPadding
            children = [
              mkFilterPopup()
              mkPresetEquipBlock(curSoldierInfo)
            ]
          }
        ]
        behavior = Behaviors.DragAndDrop
        onDrop = @(data) unequipItem(data)
        canDrop = @(data) data?.slotType != null
        skipDirPadNav = true
      }
    ]
    hotkeys = [
      ["^Tab | J:RB", { action = selectNextSlot, description = loc("equip/nextSlot") }],
      ["^L.Shift Tab | R.Shift Tab | J:LB", { action = selectPreviousSlot, description = loc("equip/prevSlot") }]
    ]
  }
  quickEquipHotkeys
]

let selectItemScene = @() {
  watch = safeAreaBorders
  size = const [sw(100), sh(100)]
  flow = FLOW_VERTICAL
  key = "selectItemScene"
  onAttach = function() {
    if (armoryWndOpened.get() && isNewbie.get()){
      openArmoryTutorial()
      markSeenArmoryTutorial()
    }
  }
  padding = safeAreaBorders.get()
  behavior = [DngBhv.MenuCameraControl, Behaviors.TrackMouse]
  onMouseWheel = function(mouseEvent) {
    changeCameraFov(mouseEvent.button * 5, ADD_CAMERA_FOV_MIN, ADD_CAMERA_FOV_MAX)
  }
  children = [
    @() {
      watch = selectParamsArmyId
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = [midPadding, 0]
      gap = midPadding
      children = [
        backButton
        mkHeader({
          armyId = selectParamsArmyId.get()
          textLocId = "Choose item"
          addAfterText = mkPageButton(Tutorial.EQUIPMENT).__update({padding = [0, bigPadding]})
          closeButton = closeBtnBase({ onClick = onBackAction })
        })
      ]
    }
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = itemsContent
    }
  ]
}

function open() {
  itemsFilterPreset.set(null)
  itemsFilterText.set("")
  isItemsFilterOpened.set(false)
  sceneWithCameraAdd(selectItemScene, "armory")
}

if (selectParams.get())
  open()

let isCurSoldierDismissed = Computed(function() {
  let selectedGuid = curSoldierGuid.get()
  return selectedGuid == null
    || (dismissGuids.get()?.contains(selectedGuid) ?? false)
})

let isArmoryWndOpen = keepref(Computed(@()
  selectParams.get() != null && !isCurSoldierDismissed.get()))

isArmoryWndOpen.subscribe(function(isOpen) {
  if (!isOpen) {
    defer(@() selectParamsList.set([]))
    sceneWithCameraRemove(selectItemScene)
    return
  }

  open()
})
