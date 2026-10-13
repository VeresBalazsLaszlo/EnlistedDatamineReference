import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/currency/currenciesList.nut" import enlistedGold
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import bigPadding, defTxtColor, darkTxtColor
from "%ui/ui_library.nut" import *


let mkTxtColor = @(sf) (sf & S_ACTIVE) ? defTxtColor
  : (sf & S_HOVER) ? darkTxtColor
  : defTxtColor

let priceText = @(locId, locParam, orderData, goldData, mkColor)
  function(_textField, params, handler, group, sf) {
    let txtStyle = { color = mkColor(sf) }.__update(fontBody)
    return textButtonTextCtor({
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = const [hdpx(10), hdpx(20)]
      children = mkTextRow(loc(locId),
        @(text) {
          rendObj = ROBJ_TEXT
          text
        }.__update(txtStyle),
        {
          [locParam] = {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            gap = {
                padding = bigPadding
                rendObj = ROBJ_TEXT
                text = loc("mainmenu/or")
              }.__update(txtStyle)

            children = [
              orderData == null ? null
                : mkItemCurrency({
                    currencyTpl = orderData.currencyTpl
                    count = orderData.count
                    textStyle = txtStyle
                  })
              goldData == null ? null
                : mkCurrency({
                    currency = enlistedGold
                    price = goldData.count
                    txtStyle
                  })
            ]
          }
        }
      )
    }, params, handler, group, sf)
  }

const LOC_PRICE = "{price}" 

let priceOrders = @(locId, orderData, mkColor = mkTxtColor)
  priceText(locId, LOC_PRICE, orderData, null, mkColor)

let priceGold = @(locId, goldData, mkColor = mkTxtColor)
  priceText(locId, LOC_PRICE, null, goldData, mkColor)

let priceGoldOrOrders = @(locId, orderData, goldData, mkColor = mkTxtColor)
  priceText(locId, LOC_PRICE, orderData, goldData, mkColor)

return {
  priceGold
  priceOrders
  priceGoldOrOrders
}
