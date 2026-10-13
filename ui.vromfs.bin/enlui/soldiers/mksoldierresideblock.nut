import "%ui/control/gui_buttons.nut" as JB
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
import "%ui/components/faComp.nut" as faComp
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/defcomps.nut" import txt
from "%ui/style/designConst.nut" import defTxtColor, smallPadding, titleTxtColor, blurBgColor, blurBgFillColor, midPadding
from "%ui/soldiers/model/state.nut" import curCampItemsCount
from "%ui/meta/profile.nut" import curCampItems
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/soldiers/components/currencyButton.nut" import canUseOrder, mkCurrencyButton
from "%ui/soldiers/model/config/soldierResideConfig.nut" import soldierResideTpl, soldierResideGoldCost, soldierReside, resideCustomization, canResideSoldier
from "%ui/meta/clientApi.nut" import use_orders_soldier_reside, buy_soldier_reside
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/helpers/metalink.nut" import getLinkedArmyName, isLinkedTo, hasLinkByType
from "%ui/soldiers/model/config/outfitConfig.nut" import equippedOutfitsForArmy
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/quickMatch.nut" import mkQuestionMarkWithTooltip
from "%ui/ui_library.nut" import *

let soldierResideInProgress = Watched(false)

let countryLoc = @(country) loc($"country/{country}", country)

function openResideWindow(soldier, resideData) {
  let { guid } = soldier
  let { toCountry, toTemplate } = resideData
  let orderTpl = soldierResideTpl.get()
  const orderReq = 1
  if (canUseOrder(orderTpl, orderReq, curCampItemsCount.get())) {
    let payData = getPayItemsData({ [orderTpl] = orderReq }, curCampItems.get())
    if (payData != null) {
      soldierResideInProgress.set(true)
      use_orders_soldier_reside([guid], toTemplate, payData,
        @(_) soldierResideInProgress.set(false))
    }
    return
  }

  purchaseMsgBox({
    price = soldierResideGoldCost
    currencyId = "EnlistedGold"
    title = loc("customize/chooseForGoldConfirm")
    description = loc("customize/resideAcceptance", { country = countryLoc(toCountry) })
    purchase = function() {
      soldierResideInProgress.set(true)
      buy_soldier_reside([guid], toTemplate, soldierResideGoldCost.get(),
        @(_) soldierResideInProgress.set(false))
    }
    srcComponent = "buy_soldier_reside"
    productView = null
  })
}

function doReside(soldier, resideData) {
  let { guid } = soldier
  let { toTemplate } = resideData
  let armyId = getLinkedArmyName(soldier)
  let { gametemplate = null } = findItemTemplate(allItemTemplates.get(), armyId, toTemplate)
  let allowedCustomization = resideCustomization.get()?[gametemplate] ?? {}
  let slotsToRemove = {}
  foreach (outfit in equippedOutfitsForArmy.get())
    if (isLinkedTo(outfit, guid))
      foreach (slotId, allowedList in allowedCustomization)
        if (hasLinkByType(outfit, slotId) && !allowedList.contains(outfit.basetpl))
          slotsToRemove[slotId] <- outfit.guid

  if (slotsToRemove.len() == 0) {
    openResideWindow(soldier, resideData)
    return
  }

  showMsgbox({
    text = loc("customize/resideLostCustomization")
    buttons = [
      {
        text = loc("Cancel"), isCurrent = true, isCancel = true,
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
      {
        text = loc("Ok"), customStyle = { hotkeys = [["^J:X"]] },
        action = @() openResideWindow(soldier, resideData)
      }
    ]
  })
}


let mkCountry = @(country) {
  rendObj = ROBJ_TEXT
  text = countryLoc(country)
  color = titleTxtColor
}.__update(fontSub)

let arrowTo = faComp("long-arrow-right", { fontSize = hdpx(17) })

let mkResideHeader = @(resideData) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("customize/resideTitle")
      color = titleTxtColor
    }.__update(fontSub)
    mkQuestionMarkWithTooltip(titleTxtColor, loc("customize/resideDescription"))
    { size = FLEX }
    mkCountry(resideData.fromCountry)
    arrowTo
    mkCountry(resideData.toCountry)
  ]
}


function mkResideBlock(soldier) {
  let resideData = Computed(function() {
    if (!canResideSoldier(soldier.get(), sClassesCfg.get()))
      return null

    return soldierReside.get()?[soldier.get()?.basetpl].top()
  })

  return function() {
    let vResideData = resideData.get()
    if (vResideData == null)
      return { watch = resideData }

    let ordersAvailable = curCampItemsCount.get()?[soldierResideTpl.get()] ?? 0
    return {
      watch = [resideData, soldierResideTpl, soldierResideGoldCost, curCampItemsCount,
        soldierResideInProgress]
      rendObj = ROBJ_WORLD_BLUR_PANEL
      color = blurBgColor
      fillColor = blurBgFillColor
      flow = FLOW_VERTICAL
      size = FLEX_H
      padding = midPadding
      gap = smallPadding
      children = [
        mkResideHeader(vResideData)
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          children = [
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              hplace = ALIGN_CENTER
              valign = ALIGN_CENTER
              gap = smallPadding
              children = [
                txt(loc(ordersAvailable == 0 ? "shop/noOrdersAvailable" : "shop/youHave"))
                mkItemCurrency({
                  currencyTpl = soldierResideTpl.get()
                  count = ordersAvailable > 0 ? ordersAvailable : null
                  textStyle = { color = defTxtColor, vplace = ALIGN_BOTTOM }
                })
              ]
            }
            mkCurrencyButton({
              text = loc("customize/confirmBtn")
              cb = @() doReside(soldier.get(), vResideData)
              orderTpl = soldierResideTpl.get()
              orderCount = 1
              cost = soldierResideGoldCost.get()
              campItems = curCampItemsCount.get()
              isEnabled = !soldierResideInProgress.get()
            })
          ]
        }
      ]
    }
  }
}

return mkResideBlock
