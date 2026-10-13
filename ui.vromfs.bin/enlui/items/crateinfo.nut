import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/colorize.nut" as colorize
import "%ui/components/spinner.nut" as spinner
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/style/fontsStyle.nut" import fontBody
from "%sqstd/string.nut" import utf8ToLower
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/meta/profile.nut" import commonArmy
from "%ui/components/soldierClasses.nut" import getClassCfg
from "dagor.localize" import doesLocTextExist
from "%ui/style/designConst.nut" import midPadding, activeTxtColor, soldierLvlColor
from "%ui/components/itemsInfo.nut" import itemNameFromItem, boosterName, trimUpgradeSuffix
from "%ui/components/defcomps.nut" import txt
from "%ui/components/soldiersUiComps.nut" import kindIcon, className, classIcon
from "%ui/meta/metaConfigUpdater.nut" import isLootBoxProhibited
from "%ui/soldiers/model/boosters.nut" import boostersConfig, isBooster
from "%ui/ui_library.nut" import *

let { itemWeights } = require("%ui/soldiers/model/items_list_lib.nut")


let waitingSpinner = spinner(hdpx(40), 0.7)

let mkTextArea = @(text) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  color = activeTxtColor
  text = text
}

let mkItemRow = @(item) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(5)
  children = [
    itemTypeIcon(item?.itemtype, item?.itemsubtype)
    txt(isBooster(item) ? boosterName(item) : itemNameFromItem(item))
  ]
}

let getExpBoost = @(item) item?.template.expMul ?? 0.0
let getItemtype = @(item) item?.itemtype ?? 0
let getWeights = @(item) itemWeights?[getItemtype(item)] ?? 0
let getWorth = @(item) item?.worth ?? 0
let getCount = @(item) item?.count ?? 0
let getBasetpl = @(item) item?.basetpl ?? item?.gametemplate ?? 0

let crateItemsSort = @(a, b)
  getWeights(a) <=> getWeights(b)
    || getWorth(a) <=> getWorth(b)
    || getExpBoost(a) <=> getExpBoost(b)
    || getCount(a) <=> getCount(b)
    || getBasetpl(a) <=> getBasetpl(b)

let mkItemsListWithHeader = @(itemTpls, armyId, header = null) function() {
  let templates = allItemTemplates.get()
  let armyTemplates = templates?[armyId]
  let commonTemplates = templates?[commonArmy.get()]
  let boosters = boostersConfig.get()
  return {
    watch = [commonArmy, allItemTemplates, boostersConfig]
    minWidth = fsh(30)
    flow = FLOW_VERTICAL
    gap = midPadding
    children = (header == null ? [] : [mkTextArea(header)]) 
      .append({
        flow = FLOW_VERTICAL
        children = itemTpls
          .map(function(basetpl) {
            if (basetpl in boosters)
              return { basetpl, itemtype = "booster", template = boosters[basetpl] }
            let template = armyTemplates?[basetpl] ?? commonTemplates?[basetpl]
            return template == null ? null : template.__merge({ basetpl })
          })
          .filter(@(i) i != null)
          .reduce(function(tbl, item) {
            let tplId = trimUpgradeSuffix(item.basetpl)
            tbl[tplId] <- item
            return tbl
          }, {})
          .values()
          .sort(crateItemsSort)
          .map(mkItemRow)
      })
  }
}

function mkCrateItemsInfo(armyId, content, header = null, addChild = null, isRestrictedItem = false) {
  let { items = null, groupLocId = "" } = content
  if ((items?.len() ?? 0) == 0)
    return null

  if (header == null) {
    let minAmount = content?.amount ?? 1
    let maxAmount = max(minAmount, content?.maxAmount ?? 1)
    header = minAmount == maxAmount
      ? loc("crateContentHeader", {
          amountText = colorize(soldierLvlColor, minAmount)
          amount = minAmount
        })
      : loc("crateContentHeaderRandItems", {
          amountText = colorize(soldierLvlColor, $"{minAmount} - {maxAmount}")
        })
  }

  local groupedItems = []
  if (typeof items == "array")
    groupedItems.append({ header, items }) 
  else if (groupLocId == "")
    groupedItems.append({ header, items = items.keys() })
  else {
    let ungroupedItems = []
    foreach (tplId, idx in items) {
      let locId = $"crategroup/{groupLocId}_{idx}"
      if (!isRestrictedItem && doesLocTextExist(locId)) {
        local data = groupedItems?[idx]
        if (data == null) {
          data = {
            header = loc(locId)
            items = []
          }
          if (groupedItems.len() <= idx)
            groupedItems.resize(idx + 1)
          groupedItems[idx] = data
        }
        data.items.append(tplId)
      } else {
        ungroupedItems.append(tplId)
      }
    }
    if (ungroupedItems.len() > 0)
      groupedItems.append({ header, items = ungroupedItems })
  }
  groupedItems = groupedItems.filter(@(l) l != null)

  let children = []
  foreach (group in groupedItems)
    children.append(mkItemsListWithHeader(group.items, armyId, group.header))
  children.append(addChild)

  return {
    minWidth = fsh(30)
    flow = FLOW_VERTICAL
    gap = midPadding
    children
  }
}

function mkCrateShuffleInfo(armyId, content) {
  let mainItemsData = (content?.mainItemsData ?? {}).filter(@(d) (d?.shuffleMax ?? 0) > 0)
  if (mainItemsData.len() == 0)
    return null

  let isOpenedOnce = content.openingsCount > 0
  let children = mainItemsData.values()
    .map(@(data) mkCrateItemsInfo(armyId, data, loc("shop/guaranteedContent", data),
      isOpenedOnce
        ? txt({ text = loc("shop/alreadyReceived", data), color = activeTxtColor })
        : null
    ))
    .filter(@(v) v != null)

  if (isOpenedOnce)
    children.append(txt({ text = loc("shop/totalOpened", content), color = activeTxtColor }))

  return children.len() == 0 ? null : {
    gap = midPadding
    flow = FLOW_VERTICAL
    children
  }
}

let mkSClassRow = @(sClass, armyId) @() {
  watch = sClassesCfg
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(5)
  children = [
    kindIcon(sClassesCfg.get()?[sClass].kind ?? sClass, hdpx(22))
    className(sClass)
    classIcon(armyId, sClass, hdpxi(22))
  ]
}

function mkCrateSoldiersInfo(armyId, content) {
  let { soldierClasses = [], soldierTierMin = -1 } = content
  if (soldierClasses.len() == 0 || soldierTierMin <= 0)
    return null

  let sClasses = soldierClasses.map(function(sClass) {
    let locId = getClassCfg(sClass)?.locId ?? ""
    return locId == "" ? null
      : {
          sClass = sClass
          sortLoc = utf8ToLower(loc(locId))
        }
  })
    .filter(@(s) s != null)
    .sort(@(a, b) a.sortLoc <=> b.sortLoc)
    .map(@(s) s.sClass)

  let { soldierTierMax } = content
  let tiersText = soldierTierMin == soldierTierMax ? getRomanNumeral(soldierTierMin)
    : $"{getRomanNumeral(soldierTierMin)}-{getRomanNumeral(soldierTierMax)}"
  let locId = "crateContentSoldiers"

  return {
    minWidth = fsh(30)
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      mkTextArea(loc(locId, { tiers = colorize(soldierLvlColor, tiersText) }))
      {
        flow = FLOW_VERTICAL
        children = sClasses.map(@(sClass) mkSClassRow(sClass, armyId))
      }
    ]
  }
}

function makeCrateToolTip(crateContent, headerTxt = "", size = SIZE_TO_CONTENT) {
  if (crateContent == null)
    return null

  let header = headerTxt == "" ? null : mkTextArea(headerTxt).__update(fontBody)
  return tooltipCtor(function() {
    let { armyId = "", content = null } = crateContent.get()
    return {
      watch = [crateContent, isLootBoxProhibited]
      gap = midPadding
      flow = FLOW_VERTICAL
      children = content == null ? waitingSpinner
        : [
            header
            mkCrateItemsInfo(armyId, content, null, null, isLootBoxProhibited.get())
            mkCrateShuffleInfo(armyId, content)
            mkCrateSoldiersInfo(armyId, content)
          ]
    }
  }, size)
}

return {
  makeCrateToolTip
  crateItemsSort
}
