import "%ui/soldiers/components/viewItemScene.nut" as viewItemScene
import "%ui/items/itemsMapping.nut" as itemMapping
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor, activeTxtColor, titleTxtColor, fadedTxtColor,
  attentionTxtColor, smallPadding, bigPadding, largePadding, unitSize, transpDarkPanelBgColor
from "auth" import get_country_code
from "%ui/soldiers/model/state.nut" import lockedArmySquadsById
from "%ui/soldiers/model/cratesContent.nut" import getPossibleItemsList, DropKind
from "%ui/components/itemsInfo.nut" import itemNameFromItem
from "%ui/components/msgbox.nut" import showMessageWithContent, removeAllMsgboxes
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/items/crateUtils.nut" import mkCrateItemView, smallRewardSize, getMainVehicles
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/items_list_lib.nut" import mkShopItem
from "%ui/shop/dropRouletteState.nut" import needOpenRouletteWnd
from "%ui/vehicles/vehDecorState.nut" import vehCustomizationCfg, vehCamouflageCfg
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_PREMIUM
from "%ui/soldiers/mkSquadPromo.nut" import mkDescBlock, mkBackWithImage, mkSquadBodyBig,
  mkPromoSquadIcon, mkFullScreenBack
from "%ui/state/safeArea.nut" import safeAreaSize
from "%ui/meta/profile.nut" import commonArmy
from "%ui/shop/shopPkg.nut" import mkAlertObject
from "%ui/ui_library.nut" import *


let defTxtStyle = { color = defTxtColor }.__update(fontSub)
let titleTxtStyle = { color = titleTxtColor }.__update(fontSub)
let mkText = @(text, override = defTxtStyle) {
  rendObj = ROBJ_TEXT
  text
}.__update(override)

let crateDetailsWidth = (unitSize * 20 + bigPadding * 4).tointeger()
const crateDetailsHeight = hdpxi(520)

let lootboxAlert = @(code) mkAlertObject(loc("shop/isLootbox",
  { country = loc("country/{0}".subst(code.tolower()))} ))

let rateText = @(rate, style = defTxtStyle)
  mkText(loc("ui/parentheses", { text = $"{rate}%" }), style)

function itemPreview(item) {
  let { id } = item
  let armyId = allItemTemplates.get().findindex(@(templates) id in templates)
  if (armyId == null)
    return null

  let shopItem = mkShopItem(id, allItemTemplates.get()[armyId][id], armyId)
  if (armyId == commonArmy.get() || needOpenRouletteWnd.get())
    return null

  viewItemScene(shopItem)
  removeAllMsgboxes()
}

function squadPreview(item) {
  let { id } = item
  let armyId = lockedArmySquadsById.get().findindex(@(squadsCfg) id in squadsCfg)
  let squadCfg = squadsCfgById.get()?[armyId][id]
  if (squadCfg == null)
    return null

  let descBlock = mkDescBlock(squadCfg.announceLocId)
  let isPrimeSquad = squadCfg?.sign == SIGN_PREMIUM
  let squadCfgExt = squadCfg.__merge({ armyId, isPrimeSquad, hasReceived = false })
  showMessageWithContent({
    content = @() {
      watch = safeAreaSize
      size = [safeAreaSize.get()[0], safeAreaSize.get()[1] - fsh(15)]
      children = mkFullScreenBack(
        mkBackWithImage(squadCfg?.image),
        [
          mkSquadBodyBig(squadCfgExt, descBlock, null)
          mkPromoSquadIcon(squadCfg?.icon)
        ]
      )
    }
  })
}

let openPreviewFn = {
  [DropKind.SQUAD] = squadPreview,
  [DropKind.ITEM] = itemPreview,
  [DropKind.VEHICLE] = itemPreview,
}

function addItemCard(items, possibleDrop, params) {
  let { item, rate } = possibleDrop
  let { itemData = [], kind } = item
  let count = itemData?[1] ?? 1
  let previewCb = openPreviewFn?[kind]

  items.append(watchElemState(@(sf) {
    behavior = Behaviors.Button
    onClick = @() previewCb?(item)
    rendObj = ROBJ_FRAME
    padding = smallPadding
    color = sf & S_HOVER ? attentionTxtColor : fadedTxtColor
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      mkCrateItemView(item.__merge({ count }), params)
      rateText(rate)
    ]
  }))
}

function showCrateContent(dropId, isLootBoxProhibited) {
  let dropItems = getPossibleItemsList(dropId)

  let camoItems = []
  foreach (dropList in dropItems)
    foreach (drop in dropList)
      if (drop.item.kind == DropKind.CAMOUFLAGE)
        camoItems.append(drop.item)

  let params = {
    mapping = itemMapping.get()
    templates = allItemTemplates.get()
    commonArmyId = commonArmy.get()
    vCustCfg = vehCustomizationCfg.get()
    camoCfg = vehCamouflageCfg.get()
    camoVehicles = getMainVehicles(vehCamouflageCfg.get(), allItemTemplates.get(), camoItems)
    size = smallRewardSize
  }

  let children = []
  foreach (dropData in dropItems)
    if (isLootBoxProhibited)
      addItemCard(children, dropData.top().__merge({ rate = 100 }), params)
    else
      foreach (possibleDrop in dropData)
        addItemCard(children, possibleDrop, params)

  showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      gap = 2 * largePadding
      valign = ALIGN_TOP
      halign = ALIGN_CENTER
      children = [
        mkText(loc("inventory/oneOf", { total = children.len() }), {
          size = FLEX_H
          halign = ALIGN_CENTER
        }.__update(titleTxtStyle))
        isLootBoxProhibited ? lootboxAlert(get_country_code()) : null
        makeVertScroll(wrap(children, {
          width = crateDetailsWidth
          vGap = bigPadding
          hGap = bigPadding
        }), {
          maxHeight = crateDetailsHeight
          size = SIZE_TO_CONTENT
          styling = thinStyle
        })
      ]
    }
  })
}

function mkDropCmp(dropData, isLootBoxProhibited) {
  let { isUnpacked, rate = 0, item } = dropData
  let { id, itemData = [] } = item
  let count = itemData?[1] ?? 1
  let text = itemNameFromItem({ basetpl = id })
  return watchElemState(function(sf) {
    let txtStyle = {
      color = sf & S_HOVER ? activeTxtColor : defTxtColor
    }.__update(fontSub)

    return {
      rendObj = sf & S_HOVER ? ROBJ_SOLID : null
      color = transpDarkPanelBgColor
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      behavior = Behaviors.Button
      onClick = isUnpacked ? null : @() showCrateContent(id, isLootBoxProhibited)
      children = [
        mkText(loc("listWithDot", { text }), txtStyle)
        count > 1 ? mkText(loc("common/amountShort", { count }), txtStyle) : null
        rateText(rate, txtStyle)
        isUnpacked ? null : {
          rendObj = ROBJ_TEXT
          text = loc("btn/view")
          color = sf & S_HOVER ? defTxtColor : fadedTxtColor
        }.__update(fontSub)
      ]
    }
  })
}

let itemSeparator = { rendObj = ROBJ_SOLID, size = const [FLEX, hdpxi(1)], color = defTxtColor }

function dropDetails(items, isLootBoxProhibited) {
  if (items.len() == 0)
    return null

  let children = []
  foreach (idx, possibleDrops in items) {
    if (idx > 0)
      children.append(itemSeparator)
    if (isLootBoxProhibited) {
      let lootboxItem = possibleDrops.top().__merge({ rate = 100 })
      children.append(mkDropCmp(lootboxItem, isLootBoxProhibited))
      children.append(lootboxAlert(get_country_code()))
    } else
      foreach (probableItem in possibleDrops)
        children.append(mkDropCmp(probableItem, isLootBoxProhibited))
  }

  children.insert(0, mkText(loc("inventory/oneOf", { total = children.len() }) ))

  return {
    flow = FLOW_VERTICAL
    gap = hdpxi(7)
    children
  }
}

return {
  dropDetails
  squadPreview
  itemPreview
}
