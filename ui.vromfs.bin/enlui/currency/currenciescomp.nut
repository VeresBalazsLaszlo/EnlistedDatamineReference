import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/textButton.style.nut" import TextHover, TextNormal
from "%ui/components/textButton.nut" import Purchase
from "%ui/currency/currencies.nut" import currenciesExpiring, currenciesById, currenciesBalance
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/shop/currencyComp.nut" import mkCurrencyTooltipContainer, mkDefaultTooltipText, mkCurrencyCardsTooltip
from "%ui/style/designConst.nut" import smallPadding, midPadding, defTxtColor, titleTxtColor, positiveTxtColor
from "%ui/shop/numberUtils.nut" import abbreviateAmount
from "%ui/shop/currencyPresentation.nut" import currencyPresentation
from "%ui/ui_library.nut" import *

let CURRENCY_PARAMS = {
  iconSize = hdpxi(16)
  txtStyle = { color = titleTxtColor }
  dimStyle = { color = defTxtColor }.__update(fontSub)
  discountStyle = { color = positiveTxtColor }
}


let currencyById = @(currencyId) currenciesById.get()?[currencyId]

let oldPriceLine = {
  size = FLEX
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(1)
  commands = [[ VECTOR_LINE, -5, 50, 105, 50 ]]
}

let mkCurrencyImg = @(currency, iconSize) {
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  image = Picture(currency.image(iconSize))
}

let mkCurrencyCount = @(count, txtStyle = null) {
  rendObj = ROBJ_TEXT
  text = abbreviateAmount(count)
}.__update(fontBody, txtStyle ?? CURRENCY_PARAMS.txtStyle)

let mkCurrencyStroke = @(count, txtStyle = null) {
  children = [
    mkCurrencyCount(count, txtStyle)
    oldPriceLine.__merge(txtStyle ?? CURRENCY_PARAMS.txtStyle)
  ]
}

let mkCurrency = kwarg(
  function(currency, price, fullPrice = null, iconSize = null,
    txtStyle = null, discountStyle = null, dimStyle = null,
    objectsGap = smallPadding
  ) {
    let hasPrice = price != null
    let hasDiscount = (fullPrice ?? 0) > price && (price ?? 0) >= 0
    let countStyle = hasDiscount
      ? (discountStyle ?? CURRENCY_PARAMS.discountStyle)
      : (txtStyle ?? CURRENCY_PARAMS.txtStyle)
    return {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = midPadding
      children = [
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = objectsGap
          children = [
            mkCurrencyImg(currency, iconSize ?? CURRENCY_PARAMS.iconSize)
            hasPrice
              ? mkCurrencyCount(price, countStyle)
              : mkDefaultTooltipText(loc("currency/notAvailable"))
          ]
        }
        hasPrice && hasDiscount
          ? mkCurrencyStroke(fullPrice, dimStyle ?? CURRENCY_PARAMS.dimStyle)
          : null
      ]
    }

  })

function currencyBtn(
    btnText, currencyId, price = null, priceFull = null, cb = @() null,
    style = {}, txtColor = TextNormal, txtHoverColor = TextHover,
    discountStyle = null
) {
    let hasPrice = "" != (price ?? "")
    let hasPriceFull = "" != (priceFull ?? "")
    let colorStyle = @(sf) (sf & S_ACTIVE) ? txtColor
      : (sf & S_HOVER) ? txtHoverColor
      : txtColor
    return Purchase(function(_textField, params, handler, group, sf) {
      let textStyle = { color = colorStyle(sf) }.__update(fontBody)
      return textButtonTextCtor({
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = smallPadding
        margin = const [0, hdpx(20)]
        children = [
          {
            rendObj = ROBJ_TEXT
            margin = const [0, hdpx(10), 0, 0]
            text = btnText
          }.__merge(textStyle)
          mkCurrencyImg(currencyById(currencyId), hdpxi(30))
          hasPrice
            ? mkCurrencyCount(price, hasPriceFull
                ? discountStyle ?? CURRENCY_PARAMS.discountStyle
                : textStyle)
            : null
          hasPrice && hasPriceFull
            ? mkCurrencyStroke(priceFull, textStyle)
            : null
        ]
      }, params, handler, group, sf)},
      cb,
      style)
}

function mkExpireRow(expData, currency) {
  let { expireAt, amount } = expData
  let timeText = Computed(function() {
    let timeLeft = expireAt - serverTime.get()
    return timeLeft > 0 ? secondsToHoursLoc(timeLeft) : loc("expired")
  })

  let replaceList = {
    ["{amount}"] = [ 
      mkCurrencyImg(currency, hdpxi(20))
      mkDefaultTooltipText(amount)
    ],
    ["{time}"] = @() mkDefaultTooltipText(timeText.get()).__update({watch = timeText}) 
  }
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = mkTextRow(loc("currency/expireAt"), mkDefaultTooltipText, replaceList)
  }
}

let mkCurrencyTooltip = @(currency) function() {
  let exp = currenciesExpiring.get()?[currency.id]
  if (exp == null) {
    let presentation = currencyPresentation?[currency.id]
    if (presentation)
      return mkCurrencyCardsTooltip(currency.id,
        [{
          amount = currenciesBalance.get()?[currency.id]
          icon = presentation.icon
        }]
      )

    return mkCurrencyTooltipContainer(
      loc(currency?.locId),
      loc(currency?.descLocId)
    )
  }

  return tooltipCtor({
    flow = FLOW_VERTICAL
    children = exp.sort(@(a, b) a.expireAt <=> b.expireAt)
      .map(@(e) mkExpireRow(e, currency))
  })
}

return {
  mkCurrency
  currencyBtn = kwarg(currencyBtn)
  mkCurrencyImg
  mkCurrencyCount
  mkCurrencyTooltip
  oldPriceLine
}
