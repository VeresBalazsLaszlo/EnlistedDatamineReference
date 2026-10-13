import "%ui/components/fontawesome.map.nut" as fa
import "%ui/soldiers/model/armyEffects.nut" as armyEffects
import "%ui/components/faComp.nut" as faComp
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/soldiers/model/equipClassSchemes.nut" as getEquipClasses
from "%ui/style/fontsStyle.nut" import fontBody, fontSub, fontawesome
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/style/designConst.nut" import defLockedSlotBgColor, hoverLockedSlotBgColor, darkTxtColor, defSlotBgColor, hoverSlotBgColor, defItemBlur, modsBgColor, unseenColor, unitSize, gap, bigGap, midPadding, smallPadding, fadedTxtColor, selectedTxtColor, defTxtColor, attentionTxtColor, totalBlack
from "%ui/soldiers/components/itemSlotComp.nut" import mkLockedBlock, mkEmptyItemSlotImg
from "%ui/components/itemPkg.nut" import statusIconCtor, statusBadgeWarning
from "%ui/soldiers/model/mkItemDemands.nut" import mkItemDemands
from "%ui/soldiers/model/state.nut" import getItemOwnerGuid, getSoldierItemSlots, curArmy, getDemandingSlots, getDemandingSlotsInfo, getEquippedItemGuid
from "%ui/helpers/metalink.nut" import getItemIndex
from "%ui/meta/profile.nut" import campItemsByLink, curCampItems, curCampSoldiers
from "%ui/soldiers/model/itemActions.nut" import equipItem, swapItems
from "%ui/components/itemsInfo.nut" import iconByItem, itemNameFromItem
  , getItemDesc, trimUpgradeSuffix
from "%ui/showState.nut" import curHoveredItem
from "%ui/style/cursors.nut" import withTooltip, draggable, setTooltip
from "%ui/soldiers/unequipItem.nut" import unequipItem
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/soldiers/components/mkAmmo.nut" import mkAmmoInfo
from "%ui/soldiers/model/collectWeaponData.nut" import getWeaponData
from "%ui/components/mkSpecialItemIcon.nut" import mkSpecialItemIcon
from "%ui/soldiers/components/itemDetailsComp.nut" import detailsStatusTier
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/soldiers/model/squadInfoState.nut" import isObjGuidBelongToRentedSquad
from "%ui/soldiers/components/squadsComps.nut" import showRentedSquadLimitsBox
from "%ui/components/soldiersUiComps.nut" import mkAlertIcon, ITEM_ALERT_SIGN, UPGRADE_ALERT_SIGN
from "%ui/preset/presetEquipUtils.nut" import previewHighlightColor
from "%ui/soldiers/model/all_items_templates.nut" import itemTypesInSlots
from "%ui/components/battleRatingPkg.nut" import mkBattleRating, mkBattleRatingShort
from "%ui/components/soldierClasses.nut" import getClassCfg, getKindCfg, soldierKindsList
from "%ui/helpers/metalink.nut" import getLinkedSquadGuid, getLinkedArmyName
from "%ui/meta/servProfile.nut" import squads
from "%ui/ui_library.nut" import *
from "types" import String

let popupsState = require("%ui/popup/popupsState.nut")

enum ItemNotifiers {
  EMPTY              
  UNSEEN_ITEM        
  UNSEEN_BETTER_ITEM 
  BETTER_ITEM        
}

let UPGRADE_COLOR = mul_color(attentionTxtColor, 0.5)

let upgradeIcon = @(icon, color) {
  rendObj = ROBJ_INSCRIPTION
  validateStaticText = false
  text = fa[icon]
  font = fontawesome.font
  fontSize = hdpx(16)
  margin = hdpx(3)
  color
}

function mkTypeIcon(itemtype, itemsubtype) {
  if (itemtype == null)
    return null

  let children = itemTypeIcon(itemtype, itemsubtype)
  return children == null ? null
    : {
        size = hdpx(30)
        margin = smallPadding
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
        fillColor = totalBlack
        color = totalBlack
        children
      }
}

function mkUpgradeSign(upgradeStateWatch, isArmoryItem) {
  let hint = loc(isArmoryItem ? "hint/itemIsUpgrade" : "hint/slotHasUpgrade")
  return function() {
    let res = { watch = upgradeStateWatch }
    let state = upgradeStateWatch.get()
    if (state == ItemNotifiers.EMPTY)
      return res
    let color = state == ItemNotifiers.UNSEEN_BETTER_ITEM ? unseenColor : UPGRADE_COLOR
    return res.__update({
      hplace = ALIGN_RIGHT
      children = withTooltip(upgradeIcon(UPGRADE_ALERT_SIGN, color), @() hint)
    })
  }
}

let DISABLED_ITEM = { tint = Color(40, 40, 40, 160), picSaturate = 0.0 }
let baseItemSize = [7 * unitSize, 2 * unitSize] 

let listTxtColor = @(flags, selected = false)
  (flags & S_HOVER) || (flags & S_ACTIVE) || selected ? selectedTxtColor : defTxtColor

let itemDragData = Watched()

let amountText = @(count, sf, selected) {
  rendObj = ROBJ_SOLID
  color = selected || (sf & S_HOVER) ? Color(120, 120, 120, 120) : Color(0, 0, 0, 120)
  size = SIZE_TO_CONTENT
  padding = [smallPadding, 2 * smallPadding]
  children = {
    rendObj = ROBJ_TEXT
    color = listTxtColor(sf, selected)
    text = loc("common/amountShort", { count })
  }.__update(fontSub)
}

function defSlotnameCtor(slotType, group, selected) {
  if (slotType == null)
    return null
  return watchElemState(@(sf) {
    watch = selected
    group
    size = FLEX_H
    margin = smallPadding
    children = {
      rendObj = ROBJ_TEXT
      group
      color = listTxtColor(sf, selected.get())
      text = loc($"inventory/{slotType}", "")
      opacity = 0.5
      maxWidth = pw(100)
      behavior = Behaviors.Marquee
      scrollOnHover = true
    }.__update(fontSub)
  })
}

let mkSlotName = @(text, isSelected, group, battleRating) watchElemState(@(sf) {
  watch = isSelected
  group
  size = FLEX_H
  clipChildren = true
  children = {
    behavior = Behaviors.Marquee
    group
    scrollOnHover = true
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_BOTTOM
        color = listTxtColor(sf, isSelected.get())
        text
      }.__update(fontSub)
      battleRating > 0 ? mkBattleRatingShort(battleRating) : null
    ]
  }
})

let mkNameBlock = @(item, slotName) {
  size =  FLEX_H
  flow = FLOW_VERTICAL
  vplace = ALIGN_BOTTOM
  children = [
    detailsStatusTier(item)
    slotName
  ]
}

let MAX_ICON_SIZE = unitSize * 7

let bigWeapons = {
  mgun = true
  submgun = true
  assault_rifle = true
  assault_semi = true
  carbine_pistol = true
  semiauto_sniper = true
  semiauto = true
  rifle_grenade_launcher = true
  rifle_at_grenade_launcher = true
  mortar = true
  launcher = true
  antitank_rifle = true
}

let isMainWeapon = @(item) item?.itemtype in itemTypesInSlots.get()?.mainWeapon

let isBigWeapon = @(item) item?.itemtype in bigWeapons

function isAmmoWeapon(item) {
  let { caliber = null, bullets = null } = getWeaponData(item?.gametemplate ?? "")
  return caliber != null || bullets != null
}

function defIcon(item, size, isIgnore = false, override = {}) {
  let armyId = getLinkedArmyName(item)
  return iconByItem(item, {
    vplace = ALIGN_TOP
    hplace = ALIGN_CENTER
    width  = min(MAX_ICON_SIZE, size[0]) - 2 * smallPadding
    height = size[1] - 2 * smallPadding
    margin = smallPadding
  }.__update(override), armyId, isIgnore)
}

let smgIcon = @(item, size) defIcon(item, size, true, {
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
  pos    = [midPadding * 3, 0]
})

let gunIcon = @(item, size) defIcon(item, size, true, {
  hplace = ALIGN_LEFT
  pos    = [midPadding * 3, 0]
})

let pistolIcon = @(item, size) defIcon(item, size, true, {
  vplace = ALIGN_CENTER
})

let bigIconSize = [(unitSize * 6.3).tointeger(), (unitSize * 3.6).tointeger()]

let forBigWeapon = @(item, _size) isBigWeapon(item)
  ? smgIcon(item, bigIconSize) : null

let forMainWeapon = @(item, size) isMainWeapon(item)
  ? gunIcon(item, size.map(@(v) v * 0.7)) : null

let forAmmoWeapon = @(item, size) isAmmoWeapon(item)
  ? pistolIcon(item, size.map(@(v) v * 0.7)) : null

let iconVariants = [
  forBigWeapon
  forMainWeapon
  forAmmoWeapon
]

function defItemCtor(item, size) {
  let isIgnoreIconSlots = !(item?.isOutfitItem ?? false)
  local icon
  foreach (cb in iconVariants) {
    icon = cb(item, size)
    if (icon)
      break
  }
  if (icon == null)
    icon = defIcon(item, size, isIgnoreIconSlots)
  return icon
}

function getTntExtraCharges(soldierGuid, slotType, item) {
  let isTnt = slotType == "mine" && item.gametemplate == "tnt_block_exploder"
  if (!isTnt)
    return 0

  let soldier = curCampSoldiers.get()?[soldierGuid]
  if (!soldier)
    return 0

  let squadGuid = getLinkedSquadGuid(soldier)
  let squad = squads.get()?[squadGuid]
  let army = getLinkedArmyName(soldier)
  let effects = armyEffects.get()?[army]
  return effects?.tnt_charge[squad?.squadId] ?? 0
}

let mkItemCount = @(count) count > 1 ? {
  rendObj = ROBJ_BOX
  fillColor = modsBgColor
  padding = [0, midPadding]
  children = {
    rendObj = ROBJ_TEXT
    defTxtColor
    text = loc("common/amountShort", { count })
  }.__update(fontSub)
} : null

function itemSlotCtor(item, itemSize, itemCtor, group, isSelected, isAvailable,
  slotName, slotType, soldierGuid, mods, status, unseenSign, forceTypeIcon = false) {

  let weapData = getWeaponData(item?.gametemplate ?? "")
  let needShowAmmo = weapData?.caliber != null || weapData?.bullets != null
  let itemIcon = itemCtor(item, itemSize)
  if (itemIcon != null && !isAvailable) {
    itemIcon.__update(DISABLED_ITEM)
  }

  let extraCount = getTntExtraCharges(soldierGuid, slotType, item)

  return watchElemState(function(sf) {
    let color = (sf & S_HOVER) || isSelected.get() ? darkTxtColor : defTxtColor
    let ammoBox = needShowAmmo
      ? mkAmmoInfo(item, soldierGuid, weapData, slotType, {
          color
          hplace = ALIGN_RIGHT
          vplace = ALIGN_CENTER
          padding = [smallPadding, midPadding, smallPadding, smallPadding]
        })
      : null

    let itemCount = item?.count ?? 1
    return {
      size = FLEX
      group
      watch = isSelected
      children = [
        mkSpecialItemIcon(item, hdpxi(32), { margin = 0 })
        itemIcon
        {
          flow = FLOW_VERTICAL
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          halign = ALIGN_RIGHT
          children = [
            {
              flow = FLOW_HORIZONTAL
              children = [
                unseenSign
                ammoBox
              ]
            }
            {
              vplace = ALIGN_RIGHT
              padding = [0, midPadding]
              children = mods
            }
          ]
        }
        {
          size =  FLEX_H
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          flow = FLOW_HORIZONTAL
          padding = [smallPadding, midPadding]
          gap = smallPadding
          children = [
            isMainWeapon(item) || forceTypeIcon ? mkTypeIcon(item?.itemtype, item?.itemsubtype) : null
            mkNameBlock(item, slotName)
            mkItemCount(itemCount)
            status
          ]
        }
        extraCount == 0 ? null : {
          rendObj = ROBJ_TEXT
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          margin = [smallPadding, midPadding]
          color = isSelected.get() ? darkTxtColor : fadedTxtColor
          text = loc("common/amountShort", { count = itemCount + extraCount})
        }.__update(fontSub)
      ]
    }
  })
}

let canEquip = @(item, scheme) item != null && !(item?.isShopItem ?? false)
  && (scheme == null
    || ((scheme?.itemTypes.len() ?? 0) == 0 && (scheme?.items.len() ?? 0) == 0)
    || scheme?.itemTypes.contains(item?.itemtype)
    || scheme?.items.contains(trimUpgradeSuffix(item?.basetpl)))

let showSwapImpossible = @(text) popupsState.addPopup({
  id = "swap_items_error"
  text
  styleName = "error"
})

function checkFixedItem(item) {
  if (item?.isFixed ?? false) {
    showSwapImpossible(loc($"equipDemand/deniedUnequipPremium"))
    return true
  }
  return false
}



function trySwapItems(toOwnerGuid, targetDropData, draggedDropData) {
  if (draggedDropData == null)
    return false

  local { slotId = null, slotType = null, item = {} } = targetDropData?.slotType == null ? targetDropData : draggedDropData
  if (checkFixedItem(item))
    return false

  let toSlotType = targetDropData?.slotType ?? draggedDropData.slotType
  let toSlotId = targetDropData?.slotId ?? draggedDropData.slotId
  let itemGuid = item?.guid
  if (!toOwnerGuid || !itemGuid || toSlotType == null)
    return false

  let equippedItems = getSoldierItemSlots(toOwnerGuid, campItemsByLink.get())
  let toItem = equippedItems.findvalue(@(d) d.slotType == toSlotType && d.slotId == toSlotId)?.item
  if (item?.basetpl == toItem?.basetpl)
    
    return true

  if (checkFixedItem(toItem))
    return false

  
  if (targetDropData.scheme == null){
    
    if ("guid" not in targetDropData.item) {
      unequipItem(draggedDropData)
      return false
    }
    if (isObjGuidBelongToRentedSquad(toOwnerGuid)) {
      showRentedSquadLimitsBox()
      return false
    }
    
    equipItem(targetDropData.item.guid, draggedDropData.slotType, draggedDropData.slotId, toOwnerGuid)
    return true
  }

  
  let parentItemGuid = getItemOwnerGuid(item)
  if (!parentItemGuid) {
    
    if (isObjGuidBelongToRentedSquad(toOwnerGuid)) {
      showRentedSquadLimitsBox()
      return false
    }
    equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
    return true
  }

  slotId = slotId ?? getItemIndex(item)
  slotType = slotType ?? item.links[parentItemGuid]

  
  let owner = curCampSoldiers.get()?[parentItemGuid] ?? curCampItems.get()?[parentItemGuid]
  let demandingSlots = getDemandingSlots(slotType, owner, campItemsByLink.get())
  if (demandingSlots.len() > 0) {
    local equippedCount = demandingSlots.filter(@(v) v != null).len()
    let equippedGuid = getEquippedItemGuid(campItemsByLink.get(), toOwnerGuid, toSlotType, toSlotId)
    if (!equippedGuid && !(toSlotId in demandingSlots))
      --equippedCount
    if (equippedCount < 1) {
      if (draggedDropData.scheme?.atLeastOne == targetDropData.scheme?.atLeastOne) {
        equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
        return true
      }
      let demandingInfo = getDemandingSlotsInfo(owner, slotType)
      if (demandingInfo != "") {
        showSwapImpossible(demandingInfo)
        return false
      }
    }
  }

  if (toItem != null)
    swapItems(toOwnerGuid, toSlotType, toSlotId, parentItemGuid, slotType, slotId)
  else {
    if (isObjGuidBelongToRentedSquad(toOwnerGuid)) {
      showRentedSquadLimitsBox()
      return false
    }
    equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
  }

  return true
}

let hintWithIcon = @(icon, locId) {
  flow = FLOW_HORIZONTAL
  gap = gap
  valign = ALIGN_CENTER
  size = FLEX_H
  children = [
    faComp(icon, {fontSize = hdpx(12), color = fadedTxtColor})
    {
      rendObj = ROBJ_TEXTAREA
      size = FLEX_H
      behavior = Behaviors.TextArea
      text = loc(locId)
      color = fadedTxtColor
    }.__update(fontSub)
  ]
}

let dragAndDropHint = hintWithIcon("hand-paper-o", "hint/equipDragAndDrop")
let quickEquipHint = hintWithIcon("reply", "hint/equipDoubleClick")
let quickUnequipHint = hintWithIcon("share", "hint/unequipDoubleClick")

function mkAvailableClasses(item) {
  let { basetpl, itemtype } = item
  let kindsList = getEquipClasses(curArmy.get(), basetpl, itemtype)
    .reduce(function(tbl, sClass) {
      let { kind, isPremium = false, isEvent = false } = getClassCfg(sClass)
      if (!isPremium && !isEvent)
        tbl[kind] <- true
      return tbl
    }, {}).keys()

  let count = kindsList.len()
  if (count == 0)
    return null

  return {
    size = FLEX_H
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = (count == soldierKindsList.len())
      ? loc("shop/allCanUse")
      : loc("shop/someCanUse", { classes = ", ".join((kindsList.map(@(sKind)
          loc(getKindCfg(sKind).locId))).sort()) })
    color = defTxtColor
  }
}

function makeToolTip(item, canDrag, isEquipped, canChange, isShowClassesHint = false) {
  if (!item?.gametemplate)
    return null

  let children = []

  let name = itemNameFromItem(item)
  if (name != null)
    children.append({
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = FLEX_H
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = name
          color = defTxtColor
        }.__update(fontBody)
        detailsStatusTier(item)
      ]
    })

  let desc = getItemDesc(item)
  if (desc != "")
    children.append({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = hdpx(500)
      text = desc
      color = Color(180, 180, 180, 120)
    })


  let { growthTier = 0 } = item
  let hints = []
  if (growthTier > 0)
    hints.append(mkBattleRating(growthTier))
  if (isShowClassesHint)
    hints.append(mkAvailableClasses(item))
  if (!isGamepad.get() && item?.guid && !(item?.isShopItem ?? false)) {
    if (canDrag)
      hints.append(dragAndDropHint)
    if (canChange)
      hints.append(isEquipped ? quickUnequipHint : quickEquipHint)
  }
  if (hints.len() > 0)
    children.append({
      size = FLEX_H
      minWidth = SIZE_TO_CONTENT
      color = Color(0, 0, 0, 224)
      flow = FLOW_VERTICAL
      margin = [bigGap, 0, 0, 0]
      gap = bigGap
      children = hints
    })

  if (children.len() == 0)
    return null

  return tooltipCtor(@() {
    minWidth = hdpx(350)
    maxWidth = hdpx(500)
    flow = FLOW_VERTICAL
    children
  })
}

let defBgStyle = @(sf, isSelected, bgColor) {
  rendObj = ROBJ_WORLD_BLUR
  fillColor = isSelected || (sf & S_HOVER) ? hoverSlotBgColor : bgColor
  color = isSelected ? hoverSlotBgColor : defItemBlur
}

function defIconCtor(item, soldierWatch) {
  let demandsWatch = mkItemDemands(item)
  return @() {
    watch = [demandsWatch, soldierWatch]
    children = statusIconCtor(demandsWatch.get())
  }
}

let mkUnseenSign = @(hasUnseen) mkAlertIcon(ITEM_ALERT_SIGN, hasUnseen)

let defEmptyItemCtor = @(slotName, emptyItemImg, unseenSign) {
  size = FLEX
  children = [
    slotName
    emptyItemImg
    unseenSign
  ]
}

let lockedSlotCtor = @(children, group, isLocked, hasWarningSign) watchElemState(@(sf) {
  size = FLEX
  group
  children = [
    mkLockedBlock(sf & S_HOVER ? hoverLockedSlotBgColor : defLockedSlotBgColor)
    {
      size = FLEX
      group
      children = [
        !isLocked ? null : {
          size = FLEX_H
          margin = smallPadding
          vplace = ALIGN_BOTTOM
          group
          children = {
            rendObj = ROBJ_TEXT
            hplace = ALIGN_RIGHT
            color = listTxtColor(sf)
            text = loc("slot/locked")
            opacity = 0.5
            maxWidth = pw(100)
            behavior = Behaviors.Marquee
            scrollOnHover = true
            group
          }.__update(fontSub)
        }
        hasWarningSign ? statusBadgeWarning : null
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          children
        }
      ]
    }
  ]
})

function mkItem(slotId = null, item = null, slotType = null, itemSize = baseItemSize,
  emptySlotName = defSlotnameCtor, scheme = null, itemCtor = null,
  onDropExceptionCb = null, statusCtor = defIconCtor, soldierGuid = null, isInteractive = true,
  isDisabled = false, canDrag = true, bgStyle = defBgStyle, selectedKey = Watched(null),
  selectKey = null, isXmb = false, bgColor = defSlotBgColor, pauseTooltip = Watched(false),
  onClickCb = null, onHoverCb = null, isLocked = false, onDoubleClickCb = null,
  onResearchClickCb = null, mods = null, notifierState = Watched(ItemNotifiers.EMPTY),
  isAvailable = null, hideStatus = false, hasWarningSign = false, needItemName = true,
  slotImg = null, previewState = null, isShowClassesHint = false, forceTypeIcon = false
) {
  let soldier = Computed(@() curCampSoldiers.get()?[soldierGuid])
  if (item instanceof String)
    item = curCampItems.get()?[item]
  if (isDisabled)
    isInteractive = false
  itemCtor = itemCtor ?? @(itemVal, size) defItemCtor(itemVal, size)
  let itemDesc = { item, slotType, soldierGuid, slotId, scheme }

  let stateFlags = Watched(0)
  selectKey = selectKey ?? (item != null
    ? (item?.isShopItem ? item?.basetpl : item?.guid)
    : "_".concat(soldierGuid, slotType ?? "", slotId ?? ""))
  let group = isInteractive ? ElemGroup() : null
  let dropData = { item, slotType, slotId, scheme }
  let isDraggable = item != null && canDrag
  let hasDropExceptionCb = onDropExceptionCb != null

  let canEquipBothItems = @(data)
    canEquip(data?.item, scheme) && ("guid" not in item || canEquip(item, data?.scheme))

  function canDrop(data) {
    if (dropData == data)
      return true
    if (data?.slotType == null && dropData.slotType == null)
      return false 
    return canEquipBothItems(data)
  }
  let canDropWithExceptionCB = @(data) canDrop(data) || (hasDropExceptionCb && data != null)
  let iconSize = (itemSize[1] * 0.5).tointeger()

  let isSelected = Computed(@() selectedKey.get() == selectKey)
  isAvailable = isAvailable ?? ((item?.guid ?? "") != "")

  let { growthTier = 0 } = item
  let slotName = needItemName && item != null
    ? mkSlotName(itemNameFromItem(item), isSelected, group, growthTier)
    : emptySlotName(slotType, group, isSelected)

  let isArmoryItem = (item?.links.len() ?? 0) == 1
  let unseenSign = item?.isFixed ? null
    : item?.itemtype == "vehicle" ? mkUnseenSign(notifierState) 
    : mkUpgradeSign(notifierState, isArmoryItem)

  let status = (hideStatus || !item) ? null : statusCtor(item, soldier)
  let itemObj = isAvailable || item != null
    ? itemSlotCtor(item, itemSize, itemCtor, group, isSelected, isAvailable, slotName, slotType,
        soldierGuid, mods, status, unseenSign, forceTypeIcon)
    : isDisabled || isLocked
      ? lockedSlotCtor(slotName, group, isLocked, hasWarningSign)
      : defEmptyItemCtor(slotName, mkEmptyItemSlotImg(slotImg, iconSize, group, isSelected),
          unseenSign)

  let override = {}
  if (isXmb)
    override.xmbNode <- XmbNode()
  if (isDraggable)
    override.cursor <- draggable

  return function() {
    let chContent = {
      rendObj = ROBJ_FRAME
      size = FLEX
      borderWidth = previewState == null ? 0 : hdpx(2)
      color = previewHighlightColor(previewState)
      children = itemObj
    }
    return {
      watch = [stateFlags, isSelected, itemDragData, curCampItems, curCampSoldiers]
      stopMouse = true
      size = FLEX
      children = {
        size = FLEX
        eventPassThrough = isDraggable
        transform = true
        behavior = isInteractive ? Behaviors.DragAndDrop : Behaviors.Button
        group
        children = itemDragData.get()
          ? chContent.__merge({
              behavior = Behaviors.RtPropUpdate
              rtAlwaysUpdate = true
            })
          : chContent
        clipChildren = true
        onDragMode = function(on, data) {
          if (on)
            sound_play("ui/inventory_item_take")
          itemDragData.set(on ? data : null)
        }
        onClick = function(event) {
          if (!isInteractive)
            return
          if (isLocked) {
            onResearchClickCb?(soldier.get(), slotType, slotId)
            return
          }
          onClickCb?(itemDesc.__merge({ rectOrPos = event.targetRect }))
        }
        onDoubleClick = function(event) {
          if (isLocked || !isInteractive || onDoubleClickCb == null)
            return
          onDoubleClickCb(itemDesc.__merge({ rectOrPos = event.targetRect }))
        }
        onDrop = function(data) {
          if (isLocked)
            return
          if (onDropExceptionCb != null && !canEquipBothItems(data) && data?.item != null) {
            onDropExceptionCb(data.item)
            return
          }
          let isItemEquipping = trySwapItems(soldierGuid, dropData, data)
          if (isItemEquipping)
            sound_play("ui/inventory_item_place")
        }
        onHover = function(on, elemPos) {
          curHoveredItem.set(on ? item : null)
          onHoverCb?(on)
          setTooltip(on && item && !pauseTooltip.get()
            ? makeToolTip(item, canDrag, slotType != null, canDrag && onDoubleClickCb != null,
                isShowClassesHint)
            : null,
            elemPos)
        }
        dropData = isDraggable ? dropData : null
        canDrop = canDropWithExceptionCB
        onElemState = isInteractive ? (@(sf) stateFlags.set(sf)) : null
      }.__update(bgStyle(stateFlags.get(), isSelected.get(), bgColor), override)
    }
  }
}

return {
  mkItem = kwarg(mkItem)
  amountText
  ItemNotifiers
}
