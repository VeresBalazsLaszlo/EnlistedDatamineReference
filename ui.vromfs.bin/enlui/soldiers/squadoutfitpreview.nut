import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/mkHeader.nut" as mkHeader
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
import "%ui/helpers/icon3dByGameTemplate.nut" as icon3dByGameTemplate
import "%ui/components/colorize.nut" as colorize
from "%ui/components/textButton.nut" import Regular
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/components/defcomps.nut" import sceneHeaderText
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/shop/currencyComp.nut" import mkDiscountWidget
from "%ui/currency/currencies.nut" import currenciesList
from "%ui/currency/currenciesComp.nut" import mkCurrency, currencyBtn
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/meta/clientApi.nut" import buy_outfit_bundle
from "%ui/soldiers/model/state.nut" import curArmyData, curSquad, armySquadsById
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/soldiers/soldierCustomizationPkg.nut" import mkPrice, armorIcon, amountText
from "%ui/soldiers/soldierCustomizationState.nut" import isCustomizationWndOpened,
  customizedSoldierInfo, getIconDataFromTemplate, curOutfitBundles
from "%ui/meta/curCampaign.nut" import outfitCampaignsByArmies
from "%ui/meta/servProfile.nut" import soldiersLook
from "%ui/helpers/metalink.nut" import getItemIndex, getLinkedArmyName, isObjLinkedToAnyOfObjects,
  getLinkedSquadGuid
from "%ui/soldiers/model/readySoldiers.nut" import curSquadSoldiersReady
from "%ui/soldiers/model/config/outfitConfig.nut" import outfitShopTypes, freeOutfitsForArmy,
  getSquadOutfit
from "%ui/soldiers/model/all_items_templates.nut" import findItemTemplate, allItemTemplates
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding, slotBaseSize,
  startBtnWidth, highlightLineTop,
  defTxtColor, titleTxtColor, activeTxtColor, darkTxtColor, attentionTxtColor, basePremiumColor,
  defBgColor, hoverSlotBgColor, defItemBlur, transpPanelBgColor, blurBgColor, blurBgFillColor
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/ui_library.nut" import *


const CURRENCY_ID = "EnlistedGold"
const bundleSize = [startBtnWidth, hdpxi(200)]
const iconHeight = hdpxi(124)
let iconWidth = slotBaseSize[0] / 2

let outfitPreview = Watched(null)
let isOutfitPreviewOpen = Computed(@() outfitPreview.get() != null)

function openBundleWnd(v) {
  let squadInfo = curSquad.get()
  let armyId = getLinkedArmyName(squadInfo)
  let { squadId = null } = squadInfo

  let curOutfit = getSquadOutfit(armyId, squadId, armySquadsById.get(), gameProfileLookCfg.get())
  let { campaigns = [] } = v?.bundle
  if (campaigns.contains(curOutfit)) {
    outfitPreview.set(v)
    return
  }

  let names = campaigns.map(function(name) {
    let txt = outfitCampaignsByArmies.get()?[armyId][name]
    return colorize(attentionTxtColor, loc($"outfit/{txt}"))
  })

  showMsgbox({
    text = loc("outfits/notSameCampaign", { campaigns = ", ".join(names) } )
    buttons = [{ text = loc("Ok"), isCurrent = true }]
  })
}

let closeBundleWnd = @(...) outfitPreview.set(null)

function bundleCampaign(campaigns) {
  if (campaigns.len() == 0)
    return null

  let campaignText = Computed(function() {
    let armyId = getLinkedArmyName(curSquad.get())
    return outfitCampaignsByArmies.get()?[armyId][campaigns[0]]
  })

  return function() {
    let watch = campaignText
    let text = campaignText.get()
    if (text == null)
      return watch

    return {
      watch
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      margin = bigPadding
      color = defTxtColor
      text = "{0}:\n{1}".subst(
        loc("outfits/campaign"),
        colorize(titleTxtColor, loc($"outfit/{text}")))
    }.__update(fontSub)
  }
}


function mkBundleItem(v) {
  let { discount = 0, campaigns = [] } = v?.bundle
  let { image = "", locId = "_" } = v?.presentation
  let imageCmp = {
    size = bundleSize
    children = [
      {
        size = bundleSize
        rendObj = ROBJ_IMAGE
        image = Picture("{0}:{1}:{2}".subst(image, bundleSize[0], bundleSize[1]))
        keepAspect = KEEP_ASPECT_FILL
      }
      {
        vplace = ALIGN_BOTTOM
        flow = FLOW_VERTICAL
        children = [
          mkDiscountWidget(discount, { vplace = ALIGN_CENTER, hplace = ALIGN_LEFT })
          bundleCampaign(campaigns)
        ]
      }
    ]
  }

  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR
    fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
    color = defItemBlur
    behavior = Behaviors.Button
    onClick = @() openBundleWnd(v)
    flow = FLOW_VERTICAL
    children = [
      imageCmp
      highlightLineTop
      {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        margin = bigPadding
        text = loc(locId)
      }.__update(fontBody, { color = sf & S_HOVER ?  darkTxtColor : defTxtColor })
    ]
  })
}

let bundlesHeader = @(count) count <= 0 ? null : {
  rendObj = ROBJ_WORLD_BLUR
  fillColor = transpPanelBgColor
  color = defItemBlur
  size = FLEX_H
  children = {
    size = FLEX_H
    rendObj = ROBJ_TEXT
    margin = bigPadding
    color = titleTxtColor
    halign = ALIGN_CENTER
    text = loc("outfits/bundles", { count })
  }.__update(fontBody)
}

let mkOutfitBundles = @() {
  watch = curOutfitBundles
  flow = FLOW_VERTICAL
  gap = midPadding
  size = FLEX_V
  pos = const [0, ph(10)]
  children = [
    bundlesHeader(curOutfitBundles.get().len())
  ].extend(curOutfitBundles.get().map(mkBundleItem))
}

let previewBundleData = Computed(function() {
  let { bundle = null} = outfitPreview.get()
  if (bundle == null)
    return {}

  let { suits = [] } = bundle
  let look = soldiersLook.get()

  let previewLook = {}
  let bundleItems = {}
  let guids = {}
  local armyId = ""
  foreach (soldier in curSquadSoldiersReady.get() ?? {}) {
    if (armyId == "")
      armyId = getLinkedArmyName(soldier)

    let index = getItemIndex(soldier)
    let newItems = suits?[index] ?? (suits.len() ? suits.top() : {})

    let { guid } = soldier
    let lookData = clone look?[guid] ?? {}
    lookData.items = lookData.items.__merge(newItems)
    previewLook[guid] <- lookData

    foreach (item in newItems)
      bundleItems[item] <- 1 + (bundleItems?[item] ?? 0)
    guids[guid] <- true
  }

  foreach (ownedItem in freeOutfitsForArmy.get()) {
    let { basetpl } = ownedItem
    let count = bundleItems?[basetpl] ?? 0
    if (count > 0
        && (ownedItem.links.len() <= 1 || isObjLinkedToAnyOfObjects(ownedItem, guids)))
      bundleItems[basetpl] = count - 1
  }

  let totalPrice = {}
  let priceByItem = {}
  let pricesCfg = outfitShopTypes.get()
  let itemTemplatesVal = allItemTemplates.get()
  foreach (item, count in bundleItems) {
    if (count <= 0)
      continue

    let { itemsubtype = null } = findItemTemplate(itemTemplatesVal, armyId, item)
    let itemPrice = pricesCfg?[itemsubtype] ?? {}
    priceByItem[item] <- itemPrice
    foreach (costData in itemPrice) {
      let { currencyId = "", orderTpl = "", price = 0 } = costData
      let key = currencyId != "" ? currencyId : orderTpl
      totalPrice[key] <- (totalPrice?[key] ?? 0) + price * count
    }
  }

  return {
    armyId
    previewLook
    totalPrice
    priceByItem
    bundleItems = bundleItems.filter(@(v) v > 0)
  }
})

let mkTotalCost = @(price, fullPrice) @() {
  
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  padding = smallPadding
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      color = defTxtColor
      text = loc("appearance/buyForSquad")
    }.__update(fontSub)
    mkCurrency({
      currency = currenciesList.get().findvalue(@(c) c.id == CURRENCY_ID)
      price
      fullPrice
      txtStyle = { color = activeTxtColor }.__update(fontBody)
      discountStyle = { color = activeTxtColor }.__update(fontBody)
      dimStyle = { color = basePremiumColor}.__update(fontBody)
    })
  ]
}

let mkItem = @(icon, hasArmor, price, count) {
  rendObj = ROBJ_SOLID
  color = defBgColor
  size = const [FLEX, SIZE_TO_CONTENT]
  padding = [bigPadding, smallPadding]
  children = [
    {
      halign = ALIGN_RIGHT
      children = [
        icon
        armorIcon(hasArmor, defTxtColor)
      ]
    }
    {
      hplace = ALIGN_RIGHT
      children = amountText(count)
    }
    {
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      padding = [0, smallPadding]
      children = mkPrice(CURRENCY_ID, price, {
        color = defTxtColor
      }.__update(fontBody))
    }
  ]
}

function itemsList() {
  let { armyId = null, bundleItems = {}, priceByItem = {},
    totalPrice = {} } = previewBundleData.get()

  let children = []
  let itemTemplatesVal = allItemTemplates.get()
  foreach (item, count in bundleItems) {

    let { price = 0 } = priceByItem?[item][CURRENCY_ID]
    if (price == 0)
      continue

    let { iconAttachments, gametemplate, hasArmor } =
      getIconDataFromTemplate(itemTemplatesVal, armyId, item)
    let icon = icon3dByGameTemplate(gametemplate, {
      genOverride = { iconAttachments }
      shading = "same"
      width = iconWidth
      height = iconHeight
      hplace = ALIGN_LEFT
    })

    children.append(mkItem(icon, hasArmor, price, count))
  }

  let squadGuid = getLinkedSquadGuid(customizedSoldierInfo.get())
  let { bundle = null, id = "" } = outfitPreview.get()
  let { discount = 0 } = bundle
  let fullPrice = totalPrice?[CURRENCY_ID] ?? 0
  let price = (0.5 + (100 - discount).tofloat() / 100 * fullPrice)
    .tointeger()

  return {
    watch = [previewBundleData, outfitPreview, customizedSoldierInfo, allItemTemplates]
    size = FLEX_V
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      makeVertScroll({
        flow = FLOW_VERTICAL
        gap = midPadding
        rendObj = ROBJ_WORLD_BLUR_PANEL
        color = blurBgColor
        fillColor = blurBgFillColor
        padding = smallPadding
        children = [mkTotalCost(price, fullPrice)].extend(children)
      }, { size = FLEX_V, styling = thinStyle })

      currencyBtn({
        btnText = loc("btn/buy")
        currencyId = CURRENCY_ID
        price
        cb = @() purchaseMsgBox({
          title = loc("appearance/header")
          productView = mkBundleItem(outfitPreview.get())
          price
          currencyId = CURRENCY_ID
          purchase = @() buy_outfit_bundle(squadGuid, id, price, closeBundleWnd)
          alwaysShowCancel = true
          srcComponent = "outfit_bundle"
        })
        style = {
          size = FLEX_H
          margin = midPadding
          hotkeys = [["^J:Y", { description = { skip = true }}]]
        }
      })
    ]
  }
}

let topBar = @() {
  watch = [curArmyData, outfitPreview]
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = [
    Regular(loc("BackBtn"), closeBundleWnd, { margin = 0, hotkeys = [[$"^{JB.B}"]] })
    mkHeader({
      armyId = curArmyData.get()?.guid
      textLocId = ""
      addAfterText = sceneHeaderText("{0} {1}".subst(
        loc("outfits/bundles", { count = 1 })
        loc(outfitPreview.get()?.presentation.locId ?? "")
      ))
      addToRight = {
        size = FLEX_V
        valign = ALIGN_CENTER
        children = currenciesWidgetUi
      }
      closeButton = closeBtnBase({ onClick = closeBundleWnd })
    })
  ]
}

let squadOutfitPreview = @() {
  size = FLEX
  watch = [safeAreaBorders, outfitPreview]
  padding = [safeAreaBorders.get()[0] + hdpx(30), safeAreaBorders.get()[1] + hdpx(25)]
  behavior = DngBhv.MenuCameraControl
  flow = FLOW_VERTICAL
  children = [
    topBar
    {
      size = FLEX
      halign = ALIGN_RIGHT
      children = itemsList
    }
  ]
}

isOutfitPreviewOpen.subscribe(function(v) {
  if (v)
    sceneWithCameraAdd(squadOutfitPreview, "main_menu")
  else {
    sceneWithCameraRemove(squadOutfitPreview)
    isCustomizationWndOpened.set(true)
  }
})

return {
  mkOutfitBundles
  isOutfitPreviewOpen
  previewSoldiersLook = Computed(@() previewBundleData.get()?.previewLook ?? {})
}
