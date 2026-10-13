from "%ui/userLog/userLogState.nut" import purchaseUserLogs, UserLogType, extractLogData
from "%ui/userLog/userLogPkg.nut" import mkUserLogHeader, mkRowText
, rowStyle, userLogStyle, userLogRowStyle
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/soldiers/components/itemDetailsComp.nut" import detailsStatusTier
from "%ui/components/itemsInfo.nut" import itemNameFromTemplate
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/style/designConst.nut" import accentColor, smallPadding, defTxtColor, hoverSlotBgColor
, panelBgColor, selectedPanelBgColor, accentTitleTxtColor
from "%ui/ui_library.nut" import *


let selectedIdx = Watched(0)

function mkReceivedItem(row, allTpl) {
  let { baseTpl = null, count = 0 } = row
  if (baseTpl == null)
    return null

  local template = null
  foreach (armyTemplates in allTpl)
    if (baseTpl in armyTemplates) {
      template = armyTemplates[baseTpl]
      break
    }

  if (template == null)
    return null

  return {
    children = [
      mkRowText(loc("listWithDot", { text = itemNameFromTemplate(template) }), defTxtColor)
      detailsStatusTier(template)
      count <= 1 ? null : mkRowText(loc("common/amountShort", { count }), accentTitleTxtColor)
    ]
  }.__update(rowStyle)
}

function mkReceivedSoldier(row, _allTpl = null) {
  let { name, surname, sClass } = row
  let { locId } = getClassCfg(sClass)
  return {
    children = [
      mkRowText(loc("listWithDot", { text = $"{loc(name)} {loc(surname)}" }), defTxtColor)
      mkRowText(loc(locId), accentTitleTxtColor)
    ]
  }.__update(rowStyle)
}

function mkReceivedPremium(row, _allTpl = null) {
  let { premiumDays } = row
  return {
    children = [
      mkRowText(loc("listWithDot", { text = loc("premium/title") }), defTxtColor)
      mkRowText("{0} {1}".subst(premiumDays, loc("premiumDays", { days = premiumDays })),
        accentTitleTxtColor)
    ]
  }.__update(rowStyle, { gap = smallPadding })
}

function mkReceivedWallposter(row, _allTpl = null) {
  let { wallposterId, armyId } = row
  return {
    children = [
      mkRowText(loc("listWithDot", { text = loc("userLogRow/wallposter") }), defTxtColor)
      mkRowText("{0} ({1})".subst(loc($"wp/{wallposterId}/name"), loc(armyId)),
        accentTitleTxtColor)
    ]
  }.__update(rowStyle, { gap = smallPadding })
}

let purchaseRowView = {
  [UserLogType.ITEM] = mkReceivedItem,
  [UserLogType.SOLDIER] = mkReceivedSoldier,
  [UserLogType.PREMDAYS] = mkReceivedPremium,
  [UserLogType.WALLPOSTER] = mkReceivedWallposter,
  [UserLogType.BONUS] = null
}

let mkPurchaseLogRows = @(uLogRows, allTpl) {
  children = uLogRows.map(function(row) {
    let { rType, data } = extractLogData(row)
    return purchaseRowView?[rType](data, allTpl)
  })
}.__update(userLogRowStyle)

function mkPurchaseLog(uLog, shopItem, allTpl, isSelected, sf) {
  let { nameLocId = "Undefined" } = shopItem
  let shortItemTitle = utf8ToUpper(loc(nameLocId).split("\r\n")?[0] ?? "")
  let { ts, records = [] } = uLog
  return {
    children = [
      mkUserLogHeader(isSelected, ts,
        loc("userLog/purchase", { name = shortItemTitle }), sf)
      isSelected && records.len() > 0 ? mkPurchaseLogRows(records, allTpl) : null
    ]
  }.__update(userLogStyle)
}
function mkLog(uLog, idx, sItems, allTpl) {
  let { records = [] } = uLog
  let mainRecord = records.findvalue(@(r) UserLogType.PURCHASE in r) ?? records.findvalue(@(_) true)
  let { data } = extractLogData(mainRecord)

  let shopItem = sItems?[data?.shopItemId]
  if (shopItem == null)
    return null

  let isSelected = Computed(@() idx == selectedIdx.get())
  return watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    watch = isSelected
    size = FLEX_H
    behavior = Behaviors.Button
    onClick = @() selectedIdx.set(idx)
    xmbNode = XmbNode()
    borderColor = accentColor
    fillColor = sf & S_HOVER ? hoverSlotBgColor
      : isSelected.get() ? selectedPanelBgColor
      : panelBgColor
    borderWidth = isSelected.get() ? [0, 0, hdpx(2), 0] : 0
    children = mkPurchaseLog(uLog, shopItem, allTpl, isSelected.get(), sf)
  })
}

return function() {
  let sItems = shopItems.get()
  let allTpl = allItemTemplates.get()
  return {
    watch = [purchaseUserLogs, shopItems, allItemTemplates]
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(2)
    xmbNode = XmbContainer({
      canFocus = false
      wrap = false
      scrollSpeed = 10.0
      isViewport = true
    })
    children = purchaseUserLogs.get().map(@(uLog, idx) mkLog(uLog, idx, sItems, allTpl))
  }
}
