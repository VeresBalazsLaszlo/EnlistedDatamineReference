from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor, smallPadding,
  inventoryItemDetailsWidth, midPadding, defItemBlur, transpDarkPanelBgColor,
  largePadding
from "%ui/components/itemPkg.nut" import statusTier, statusHintText, statusIconCtor
from "%ui/components/itemsInfo.nut" import itemNameFromItem, getItemSubtitle, getItemDesc, getItemTypeName
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/soldiers/model/mkItemModifyData.nut" import mkItemUpgradeData
from "%ui/soldiers/components/itemDetailsPkg.nut" import mkItemDescription, mkVehicleDetails,
  mkItemDetails, mkUpgrades, BASE_COLOR
from "%ui/soldiers/model/config/equipIncreaseConfig.nut" import equipSlotIncreaseCfg, equipAmmoIncreaseCfg
from "%ui/components/mkSpecialItemIcon.nut" import mkSpecialItemIcon
from "%ui/soldiers/model/selectItemState.nut" import inventoryItems
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/components/battleRatingPkg.nut" import mkBattleRating
from "%ui/items/detailsMode.nut" import detailsModeCheckbox, isDetailsFull
from "%ui/ui_library.nut" import *

let itemIconSize = [hdpxi(32), hdpxi(32)]
let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic,
    play = true, trigger = "itemDetailsAnim"}
  { prop = AnimProp.translate, from =[0, hdpx(100)], to = [0, 0], duration = 0.15, easing = OutQuad,
    play = true, trigger = "itemDetailsAnim"}
]

let inStockInfo = @(item) function() {
  let count = inventoryItems.get()?[item.basetpl].count ?? 0
  return count < 1 ? { watch = inventoryItems } : {
    watch = inventoryItems
    hplace = ALIGN_RIGHT
    children = {
      rendObj = ROBJ_TEXT
      maxWidth = inventoryItemDetailsWidth
      halign = ALIGN_RIGHT
      text = loc("itemCurrentCount", { count })
      color = BASE_COLOR
    }.__update(fontSub)
  }
}

let lockedInfo = @(demands) {
  size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  children = [
    statusHintText(demands)
    statusIconCtor(demands)
  ]
}

let mkInfoRow = @(text, value) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_RIGHT
  text = $"{text}: {value}"
  color = defTxtColor
}.__update(fontSub)

let mkSlotIncreaseInfo = @(item) function() {
  let watch = equipSlotIncreaseCfg
  let incInfo = {}
  foreach (slotType, tplsList in equipSlotIncreaseCfg.get())
    if (item.basetpl in tplsList)
      incInfo[slotType] <- tplsList[item.basetpl]
  if (incInfo.len() == 0)
    return { watch }

  return {
    watch
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = incInfo
      .map(@(count, slotType) mkInfoRow(loc($"itemDetails/slotsIncrease/{slotType}"), count))
      .values()
  }
}

let mkAmmoIncreaseInfo = @(item) function() {
  let watch = equipAmmoIncreaseCfg
  let value = equipAmmoIncreaseCfg.get()?[item.basetpl] ?? 0
  if (value == 0)
    return { watch }

  let perc = (100.0 * value + 0.5).tointeger()
  return mkInfoRow(loc("itemDetails/ammoIncrease"), $"+{perc}%").__update({ watch })
}

let itemTitle = @(item) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  text = itemNameFromItem(item)
  color = titleTxtColor
  lineSpacing = hdpx(-4)
}.__update(fontBody)

let detailsStatusTier = @(item) statusTier(item, mkItemUpgradeData(item), @(v) v)

local lastTpl = null

let mkRow = @(children) {
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  valign = ALIGN_CENTER
  children
}

function mkItemHeader(item) {
  let specialIcon = mkSpecialItemIcon(item, hdpxi(27))
  local typeLoc = getItemTypeName(item)
  typeLoc = typeLoc == "" ? null
    : {
        rendObj = ROBJ_TEXT
        text = typeLoc
        color = BASE_COLOR
      }.__update(fontSub)
  let { growthTier = 0 } = item
  return {
    flow = FLOW_VERTICAL
    size = FLEX_H
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = midPadding
        children = [
          mkRow([
            specialIcon
            itemTypeIcon(item?.itemtype, item?.itemsubtype, {
              size = itemIconSize
              color = titleTxtColor
            })
          ])
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              itemTitle(item)
              typeLoc
            ]
          }
        ]
      }
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = { size = FLEX }
        children = [
          mkRow([
            detailsStatusTier(item)
            mkBattleRating(growthTier)
          ])
          inStockInfo(item)
        ]
      }
    ]
  }
}


function setlastTpl(item) {
  let tpl = item?.basetpl
  if (lastTpl != tpl)
    lastTpl = tpl
  if (!tpl)
    return null

  anim_start("itemDetailsAnim")
  return tpl
}

let panelStyle = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = transpDarkPanelBgColor
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = largePadding
  transform = true
  animations = animations
}

let contentStyle = {
  color = defItemBlur
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = midPadding
  padding = midPadding
  size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
  valign = ALIGN_BOTTOM
}

function mkViewDetailsContent(item, isFull) {
  let isVehicle = item?.itemtype == "vehicle"
  let itemName = itemNameFromItem(item)
  let itemSubtitle = getItemSubtitle(item)
  let itemDesc = getItemDesc(item)
  let showDesc = isFull && itemDesc != itemName

  return isVehicle
    ? [
        mkItemHeader(item)
        isFull ? mkItemDescription(itemSubtitle) : null
        showDesc ? mkItemDescription(itemDesc) : null
        mkVehicleDetails(item)
        mkUpgrades(item, isFull)
      ]
    : [
        mkItemHeader(item)
        isFull ? mkItemDescription(itemSubtitle) : null
        showDesc ? mkItemDescription(itemDesc) : null
        mkSlotIncreaseInfo(item)
        mkAmmoIncreaseInfo(item)
        mkItemDetails(item, isFull)
        mkUpgrades(item, isFull)
      ]
}

let briefChildrenComp = @(item) {
  children = {
    vplace = ALIGN_BOTTOM
    children = mkViewDetailsContent(item, false)
  }.__update(contentStyle)
}

let fullChildrenCompWithScroll = @(item, maxHeight)
  makeVertScroll({
    vplace = ALIGN_TOP
    children = mkViewDetailsContent(item, true)
  }.__update(contentStyle), {
    size = SIZE_TO_CONTENT
    maxHeight
  })

let mkViewItemWatchDetails = @(viewItemWatch, maxHeight = SIZE_TO_CONTENT) function() {
  let watch = viewItemWatch
  let item = viewItemWatch.get()
  let tpl = setlastTpl(item)
  if (!tpl)
    return { watch }

  return {
    watch
    key = tpl
    children = fullChildrenCompWithScroll(item, maxHeight)
  }.__update(panelStyle)
}

function mkViewDetailsBrief(item) {
  let tpl = setlastTpl(item)
  if (!tpl)
    return null

  return {
    key = tpl
    children = briefChildrenComp(item)
  }.__update(panelStyle)
}

function mkViewDetailsFull(item, maxHeight = SIZE_TO_CONTENT) {
  let tpl = setlastTpl(item)
  if (!tpl)
    return null

  return {
    key = tpl
    children = fullChildrenCompWithScroll(item, maxHeight)
  }.__update(panelStyle)
}

function mkViewDetailsSwitchable(item, maxHeight = SIZE_TO_CONTENT) {
  let tpl = setlastTpl(item)
  if (!tpl)
    return null
  return @() {
    watch = isDetailsFull
    key = tpl
    children = [
      isDetailsFull.get()
        ? fullChildrenCompWithScroll(item, maxHeight)
        : briefChildrenComp(item)
      {
        padding = [0, midPadding]
        children = detailsModeCheckbox
      }
    ]
  }.__update(panelStyle)
}

function mkViewDetailsCard(item) {
  let tpl = setlastTpl(item)
  if (!tpl)
    return null

  return {
    children = {
      vplace = ALIGN_BOTTOM
      children = mkItemHeader(item)
    }.__update(contentStyle)
  }.__update(panelStyle)
}

return {
  mkViewDetailsSwitchable
  mkViewDetailsFull
  mkViewDetailsBrief
  mkViewItemWatchDetails
  mkViewDetailsCard
  lockedInfo
  detailsStatusTier
}
