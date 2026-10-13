from "%ui/style/designConst.nut" import fullTransparentBgColor, modsBgColor, smallPadding, unitSize, midPadding, soldierWndWidth, hoverBgColor
from "%ui/soldiers/model/state.nut" import getModSlots, curArmy
from "%ui/meta/profile.nut" import curCampItems
from "%ui/soldiers/components/itemComp.nut" import mkItem, ItemNotifiers
from "%ui/components/itemsInfo.nut" import iconByItem
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/ui_library.nut" import *

let defItemSize = [soldierWndWidth - 2 * midPadding, 2 * unitSize] 
let MAKE_PARAMS = { 
  item = null
  itemSize = defItemSize
  soldierGuid=null
  isInteractive = true
  isDisabled = false
  isNew = false
  canDrag = false
  onClickCb = @(_) null
  onDoubleClickCb = null
  onDropExceptionCb = null
  onHoverCb = null
  selectedKey = Watched(null)
  isXmb = false
  notifierState = Watched(ItemNotifiers.EMPTY)
}

let modItemCtor = @(item, itemSize) iconByItem(item, {
  width = itemSize[0] - 2 * smallPadding
  height = itemSize[1] - 2 * smallPadding
}) 

let modsColor = mul_color(modsBgColor, 0.6)

let modBgStyle = @(sf, _isSelected, _bgColor) {
  rendObj = ROBJ_WORLD_BLUR
  color = fullTransparentBgColor
  fillColor = sf & S_HOVER ? hoverBgColor
    : modsColor
}

function getModData(mainItem, slot) {
  if ((mainItem?.guid ?? "") != "")
    return curCampItems.get()?[slot.equipped]

  let [ basetpl = null ] = slot?.scheme.items
  return allItemTemplates.get()?[curArmy.get()][basetpl]
}

function mkItemMods(p) {
  let slots = getModSlots(p.item)
  if (slots.len() == 0)
    return null

  let modHeight = 0.45 * p.itemSize[1]
  let modSize = [1.8 * modHeight, modHeight]
  return {
    size = modSize
    vplace = ALIGN_TOP
    hplace = ALIGN_LEFT
    flow = FLOW_HORIZONTAL
    stopHover = true
    children = slots.map(@(slot) mkItem({
      isXmb = p.isXmb
      item = getModData(p.item, slot)
      itemSize = modSize
      scheme = slot.scheme
      soldierGuid = p.item.guid
      slotType = slot.slotType
      bgStyle = modBgStyle
      isInteractive = p.isInteractive
      isDisabled = p.isDisabled
      canDrag = p.canDrag
      onClickCb = p.onClickCb
      onDoubleClickCb = p.onDoubleClickCb
      onHoverCb = p.onHoverCb
      selectedKey = p.selectedKey

      itemCtor = modItemCtor
      needItemName = false
      emptySlotName = @(...) null
    }))
  }
}

function mkItemWithMods(p = MAKE_PARAMS) {
  p = MAKE_PARAMS.__merge(p)
  let mods = mkItemMods(p)
  if (mods)
    p.__update({ mods })

  return {
    size = p.itemSize
    children = mkItem(p, KWARG_NON_STRICT)
  }
}

return mkItemWithMods