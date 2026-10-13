import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/components/textButton.nut" import Regular, textColor
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/currency/currenciesList.nut" import enlistedGold
from "%ui/style/colors.nut" import HighlightFailure
from "%ui/style/designConst.nut" import bigPadding
from "%ui/ui_library.nut" import *

let canUseOrder = @(orderTpl, orderCount, campItems) (orderTpl ?? "") != ""
  && (orderCount ?? 0) > 0
  && (campItems?[orderTpl] ?? 0) >= orderCount

function mkCurrencyButton(
  text, cb, campItems, cost = null, orderTpl = null, orderCount = null,
  isEnabled = true, override = {}
) {
  let isEnough = (campItems?[orderTpl] ?? 0) >= (orderCount ?? 0)
  let priceCtor = canUseOrder(orderTpl, orderCount, campItems) || cost == null
    ? @(sf) mkItemCurrency({
        currencyTpl = orderTpl
        count = orderCount
        textStyle = { color = isEnough ? textColor(sf, {}, isEnabled) : HighlightFailure }
      })
    : @(sf) mkCurrency({
        currency = enlistedGold
        price = cost
        txtStyle = { color = textColor(sf, {}, isEnabled) }
      })
  return Regular(@(_textField, params, handler, group, sf) textButtonTextCtor({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = bigPadding
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        color = textColor(sf, {}, isEnabled)
        text
      }.__update(fontBody)
      priceCtor(sf)
    ]
  }, params, handler, group, sf), cb, { isEnabled }.__update(override))
}

return {
  canUseOrder
  mkCurrencyButton = kwarg(mkCurrencyButton)
}