import "%ui/style/colors.nut" as colors
import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/checkbox.nut" as checkbox
import "%ui/components/colorize.nut" as colorize
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/components/msgbox.nut" import showMsgboxWithCloseButton
from "%ui/currency/currencies.nut" import currenciesById, currenciesBalance
from "%ui/options/dontShowAgain.nut" import mkDontShowTodayComp, setDontShowToday
from "%ui/components/priceWidget.nut" import priceWidget
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/style/designConst.nut" import smallPadding
from "%ui/style/buttonsStyle.nut" import purchaseButtonStyle
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/components/textButton.nut" import textColor, primaryStyle
from "%ui/ui_library.nut" import *

const defGap = fsh(3)
const currencySize = hdpx(29)
let openShopByCurrencyId = {}

let mkItemDescription = @(description) makeVertScroll({
    size = FLEX_H
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = description
  }.__update(fontBody)
  {
    size = FLEX_H
    maxHeight = hdpx(300)
    styling = thinStyle
  })

let currencyImage = @(currency) currency
  ? {
      size = const [currencySize, currencySize]
      rendObj = ROBJ_IMAGE
      image = Picture(currency.image(currencySize))
    }
  : null

function mkItemCostInfo(price, fullPrice, currencyId) {
  let currency = currenciesById.get()?[currencyId]
  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = "{0} ".subst(loc("shop/willCostYou"))
      }.__update(fontSub)
      mkCurrency({
        currency
        price
        fullPrice
        iconSize = hdpxi(20)
      })
    ]
  }
}

function buyCurrencyText(currency, sf) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = const [hdpx(10), hdpx(20), hdpx(10), hdpx(50)]
    gap = currencyImage(currency)
    children = loc("btn/buyCurrency").split("{currency}").map(@(text) {
      rendObj = ROBJ_TEXT
      color = textColor(sf, primaryStyle)
      text
    }.__update(fontBody))
  }
}

let notEnoughMoneyInfo = @(price, currencyId) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      color = colors.HighlightFailure
      text = loc("shop/notEnoughCurrency", {
        priceDiff = price - (currenciesBalance.get()?[currencyId] ?? 0)
      })
    }.__update(fontBody)
    currencyImage(currenciesById.get()?[currencyId])
  ]
}

function show(price, currencyId, purchase, fullPrice = null, title = "", productView = null,
  description = null, purchaseCurrency = null, dontShowMeTodayId = null, srcWindow = null,
  srcComponent = null, alwaysShowCancel = false, showOnlyWhenNotEnoughMoney = false,
  gap = defGap, additionalButtons = [], purchaseText = null
) {
  let bqBuyCurrency = @() sendBigQueryUIEvent("action_buy_currency", srcWindow, srcComponent)
  let currency = currenciesById.get()?[currencyId]
  purchaseCurrency = purchaseCurrency ?? openShopByCurrencyId?[currencyId]

  if (!(isObservable(price)))
    price = Watched(price)
  if (!(isObservable(fullPrice)))
    fullPrice = Watched(fullPrice)

  let notEnoughMoney = currency == null
    ? Watched(false)
    : Computed(@() (currenciesBalance.get()?[currencyId] ?? 0) < price.get())

  if (showOnlyWhenNotEnoughMoney && !notEnoughMoney.get()) {
    purchase()
    bqBuyCurrency()
    return
  }

  local dontShowCheckbox = null
  if (dontShowMeTodayId != null && !notEnoughMoney.get()) {
    let dontShowMeToday = mkDontShowTodayComp(dontShowMeTodayId)
    if (dontShowMeToday.get()) {
      purchase()
      bqBuyCurrency()
      return
    }
    dontShowCheckbox = checkbox(dontShowMeToday, loc("dontShowMeAgainToday"),
      { setValue = @(v) setDontShowToday(dontShowMeTodayId, v) })
  }

  let buttons = Computed(function() {
    if (!notEnoughMoney.get())
      return [{
        text = purchaseText ?? loc("btn/buy")
        action = function() {
          purchase()
          bqBuyCurrency()
        }
        customStyle = {
          hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
        }.__update(purchaseButtonStyle)
      }]
      .extend(alwaysShowCancel ? [{ text = loc("Cancel"),
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }] : [])
      .extend(additionalButtons)

    let res = []
    if (purchaseCurrency != null)
      res.append({
        text = function(textComp, params, handler, group, sf) {
          textComp = buyCurrencyText(currency, sf)
          params = params.__merge(fontHeading2)
          return textButtonTextCtor(textComp, params, handler, group, sf)
        }
        customStyle = {
          hotkeys = [[ "^J:Y | Enter" ]]
        },
        action = function() {
          purchaseCurrency()
          sendBigQueryUIEvent("event_low_currency", srcWindow, srcComponent)
        }
      })
    res.extend(additionalButtons)
    if (alwaysShowCancel || purchaseCurrency == null)
      res.append({ text = loc("Cancel"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } })
    return res
  })

  let params = {
    text = colorize(colors.MsgMarkedText, title)
    fontStyle = fontBody
    children = {
      size = const [fsh(80), SIZE_TO_CONTENT]
      margin = [defGap, 0, 0, 0]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap
      children = [
        productView
        typeof description == "string" ? mkItemDescription(description) : description
        @() {
          watch = [price, fullPrice, notEnoughMoney]
          halign = ALIGN_CENTER
          flow = FLOW_VERTICAL
          gap = smallPadding
          children = [
            mkItemCostInfo(price.get(), fullPrice.get(), currencyId)
            notEnoughMoney.get()
              ? notEnoughMoneyInfo(price.get(), currencyId)
              : dontShowCheckbox
          ]
        }
      ]
    }
    topPanel = currencyId in currenciesById.get()
      ? priceWidget(currenciesBalance.get()?[currencyId] ?? loc("currency/notAvailable"), currencyId)
          .__update({
            size = FLEX_V
            gap = hdpx(10)
          })
      : null
    buttons
  }

  showMsgboxWithCloseButton(params)
  sendBigQueryUIEvent("open_buy_currency_window", srcWindow, srcComponent)
}

return {
  purchaseMsgBox = kwarg(show)
  buyCurrencyText
  currencyImage
  mkItemCostInfo
  openShopByCurrencyId
  setOpenShopFunctions = @(list) openShopByCurrencyId.__update(list)
}