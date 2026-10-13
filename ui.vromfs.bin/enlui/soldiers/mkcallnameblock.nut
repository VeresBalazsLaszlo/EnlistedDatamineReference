import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
import "%ui/helpers/obsceneFilter.nut" as obsceneFilter
import "%ui/components/spinner.nut" as spinner
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import defTxtColor, activeTxtColor, smallPadding, commonBtnHeight, titleTxtColor, blurBgColor, blurBgFillColor, midPadding
from "%ui/components/defcomps.nut" import txt
from "%ui/soldiers/model/state.nut" import curCampItemsCount
from "%ui/meta/profile.nut" import curCampItems
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/meta/clientApi.nut" import use_callname_change_order, buy_callname_change
from "%sqstd/string.nut" import clearBorderSymbols
from "%ui/components/itemsInfo.nut" import localizeSoldierName
from "%ui/soldiers/components/currencyButton.nut" import canUseOrder, mkCurrencyButton
from "%ui/quickMatch.nut" import mkQuestionMarkWithTooltip
from "%ui/ui_library.nut" import *

let textInput = require("%ui/components/textInput.nut")
let popupsState = require("%ui/popup/popupsState.nut")


const MAX_CHARS = 16
const CALLNAME_ORDER_TPL = "callname_change_order"

let changeCallnameGoldCost = mkComputedConfigGet(["gameProfile","changeCallnameGoldCost"])
let callnameChangeInProgress = Watched(false)
let isWaitingObsceneFilter = Watched(false)
let waitingSpinner = spinner(commonBtnHeight/2)

let tiOptions = {
  margin = 0
  padding = 0
  textmargin = hdpx(5)
  maxChars = MAX_CHARS
  colors = { backGroundColor = Color(0, 0, 0, 255) }
  placeholder = loc("customize/writeCallsign")
}.__update(fontBody)

function callnameChangeAction(soldier, prevCallname, callname) {
  if (prevCallname == callname)
    return

  const orderTpl = CALLNAME_ORDER_TPL
  const orderReq = 1
  let campItems = curCampItemsCount.get()
  if (canUseOrder(orderTpl, orderReq, campItems)) {
    let payData = getPayItemsData({ [orderTpl] = orderReq }, curCampItems.get())
    if (payData != null){
      callnameChangeInProgress.set(true)
      use_callname_change_order(soldier.guid, callname, payData, function(_){
        callnameChangeInProgress.set(false)
      })
    }
    return
  }

  purchaseMsgBox({
    price = changeCallnameGoldCost
    currencyId = "EnlistedGold"
    title = loc("customize/chooseForGoldConfirm")
    description = loc("customize/callnameAcception", { callSign = callname })
    purchase = function() {
      callnameChangeInProgress.set(true)
      buy_callname_change(soldier.guid, callname, changeCallnameGoldCost.get(), function(_){
        callnameChangeInProgress.set(false)
      })
    }
    srcComponent = "buy_change_soldier_callname"
    productView = null
  })
}

let callnameHeader = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("customize/callnameTitle")
      color = titleTxtColor
    }.__update(fontSub)
    mkQuestionMarkWithTooltip(defTxtColor, loc("customize/callnameDescription"))
  ]
}

function mkSoldierNameColorized(soldier, callname) {
  let { name, surname } = localizeSoldierName(soldier)
  return function() {
    let callnameText = (callname.get() ?? "") == "" ? null : {
      rendObj = ROBJ_TEXT
      color = activeTxtColor
      text = loc("callname/quotes", { callname = callname.get() })
    }
    return {
      watch = callname
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = [
        callnameHeader
        txt(name)
        callnameText
        txt(surname)
      ]
    }
  }
}

async function filterAndSetCallname(callNameToSet, soldier, prevCallname) {
  if (isWaitingObsceneFilter.get())
    return
  isWaitingObsceneFilter.set(true)
  let filteredCallName = await obsceneFilter(callNameToSet)
  isWaitingObsceneFilter.set(false)
  if (filteredCallName != callNameToSet){
    return popupsState.addPopup({
      id = "prohibited_callname"
      text = loc("prohibitedCallname")
      styleName = "error"
    })
  }
  callnameChangeAction(soldier, prevCallname, filteredCallName)
}

function mkCallnameBlock(soldier) {
  let callnameEditWatch = Watched("")
  let callnameCleaned = Computed(@() clearBorderSymbols(callnameEditWatch.get()))

  return function() {
    let soldierData = soldier.get()
    let ordersAvailable = curCampItemsCount.get()?[CALLNAME_ORDER_TPL] ?? 0
    let prevCallname = soldierData?.callname ?? ""
    let isChanged = Computed(@() callnameCleaned.get() != prevCallname)
    callnameEditWatch.set(prevCallname)

    let blockComp = @() {
      watch = [ curCampItemsCount, changeCallnameGoldCost, isChanged, callnameChangeInProgress,
        isWaitingObsceneFilter]
      rendObj = ROBJ_WORLD_BLUR_PANEL
      color = blurBgColor
      fillColor = blurBgFillColor
      flow = FLOW_VERTICAL
      size = FLEX_H
      padding = midPadding
      gap = midPadding
      children = [
        mkSoldierNameColorized(soldierData, callnameCleaned)
        textInput(callnameEditWatch,
          tiOptions.__merge({
            onEscape = @() callnameEditWatch.set(prevCallname)
            onReturn = @() filterAndSetCallname(callnameCleaned.get(), soldierData, prevCallname)
          }))
        isWaitingObsceneFilter.get()
          ? {
              size =FLEX_H
              halign = ALIGN_CENTER
              children = waitingSpinner
            }
          : {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              valign = ALIGN_CENTER
              vplace = ALIGN_CENTER
              children = [
                {
                  size = FLEX_H
                  flow = FLOW_HORIZONTAL
                  hplace = ALIGN_CENTER
                  valign = ALIGN_CENTER
                  gap = hdpx(5)
                  children = [
                    txt(loc(ordersAvailable == 0 ? "shop/noOrdersAvailable" : "shop/youHave"))
                    mkItemCurrency({
                      currencyTpl = CALLNAME_ORDER_TPL
                      count = ordersAvailable > 0 ? ordersAvailable : null
                      textStyle = { color = defTxtColor, vplace = ALIGN_BOTTOM }
                    })
                  ]
                }
                mkCurrencyButton({
                  text = loc("customize/confirmBtn")
                  cb = @() filterAndSetCallname(callnameCleaned.get(), soldier.get(), prevCallname)
                  orderTpl = CALLNAME_ORDER_TPL
                  orderCount = 1
                  cost = changeCallnameGoldCost.get()
                  campItems = curCampItemsCount.get()
                  isEnabled = isChanged.get() && !callnameChangeInProgress.get()
                })
              ]
            }
      ]
    }

    return {
      watch = soldier
      size = FLEX_H
      children = blockComp
    }
  }
}

return mkCallnameBlock
