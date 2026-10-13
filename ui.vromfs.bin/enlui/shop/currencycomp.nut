import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/colorize.nut" as colorize
from "%ui/shop/currencyPresentation.nut" import ticketGroups, getCurrencyPresentation
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/components/defcomps.nut" import txt
from "%ui/style/designConst.nut" import midPadding, bigGap, smallPadding, defTxtColor, activeTxtColor, isWide, accentTitleTxtColor
from "%ui/style/cursors.nut" import setTooltip
from "%ui/shop/numberUtils.nut" import abbreviateAmount
from "%sqstd/math.nut" import splitThousands
from "%ui/soldiers/model/state.nut" import curCampItemsCount
from "%ui/ui_library.nut" import *
from "types" import Integer, Float

let mkDefaultTooltipText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = activeTxtColor
}.__update(fontSub)

let mkCurrencyTooltipContainer = @(name, desc = null) tooltipCtor({
  flow = FLOW_VERTICAL
  gap = bigGap
  children = [
    mkDefaultTooltipText(name),
    (desc == null || desc == "") ? null : {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = const [fsh(30), SIZE_TO_CONTENT]
      text = desc
      color = defTxtColor
    }.__update(fontSub)
  ]
})

let mkCurrencyTooltip = @(currencyTpl) mkCurrencyTooltipContainer(
  loc($"items/{currencyTpl}"),
  loc($"items/{currencyTpl}/desc", "")
)

function mkCurrencyImage(icon, sizeArr = [hdpx(30), hdpx(30)]) {
  let svgSize = [sizeArr[0].tointeger(), sizeArr[1].tointeger()]
  return{
    rendObj = ROBJ_IMAGE
    size = sizeArr
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{icon}:{svgSize[0]}:{svgSize[1]}:K")
    fallbackImage = Picture($"!ui/uiskin/currency/weapon_order.svg:{svgSize[0]}:{svgSize[1]}:K")
  }
}


let iconTextRow = @(icon, text, sizeArr = [hdpx(10), hdpx(10)], textStyle = {}){
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    mkCurrencyImage(icon, sizeArr)
    {
      padding = const [0, hdpx(3)]
      rendObj = ROBJ_TEXT
      text
    }.__update(fontBody, textStyle)
  ]
}

let isNumber = @(value) value instanceof Integer || value instanceof Float

function cardsInRow(cards) {
  return {
    gap = hdpx(20)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children =
      cards.map(@(value)
        iconTextRow(value.icon, isNumber(value.amount)
            ? splitThousands(value.amount, loc("amount/separator"))
            : loc("currency/notAvailable"),
          [hdpx(20),hdpx(25)]))
  }
}

function mkCurrencyCardsTooltip(cardType, cards = [], expandOrders = false) {
  let descText = loc(ticketGroups[cardType].desc) ?? ""
  return tooltipCtor({
    flow = FLOW_VERTICAL
    gap = bigGap
    children = [
      {
        rendObj = ROBJ_TEXT
        minWidth = hdpx(300)
        text = loc(ticketGroups[cardType].name)
        color = activeTxtColor
      }
      expandOrders ? null : cardsInRow(cards)
      descText == "" ? null : {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = FLEX_H
        text = descText
        color = defTxtColor
      }.__update(fontSub)
    ]
  })
}

let mkCurrencyInShop = @(cards){
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = SIZE_TO_CONTENT
  text = "|".join(cards.map(@(value)
    colorize(value.color, value.amount)))
}.__update(fontBody)

let mkCurrencyCommon = @(sf, summ){
  rendObj = ROBJ_TEXT
  color = sf & S_HOVER ? activeTxtColor : defTxtColor
  text = abbreviateAmount(summ)
}.__update(fontBody)

function mkCurrencyOverall(cardType, cardsTable = {}, onClick = null,
                                  keySuffix = "", isShop = false) {

  let stateFlag = Watched(0)
  local currencySumm = 0
  let trigger = $"blink_{cardsTable}"
  let sortedCards = cardsTable
    .map(@(amount, key) getCurrencyPresentation(key).__merge({ amount }))
    .values()
    .sort(@(a, b) a.order <=> b.order)
  currencySumm = sortedCards.reduce(@(sum, value) sum + value.amount, 0)
  let expandOrders = isWide && isShop && (ticketGroups[cardType]?.expandedInShop ?? false)
  if (sortedCards.len() == 0)
    return null

  return @(){
    size = FLEX_V
    watch = stateFlag
    onElemState = @(sf) stateFlag.set(sf)
    minHeight = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = midPadding
    margin = const [0,0,0,hdpx(10)]
    onHover = @(on) setTooltip(on
      ? mkCurrencyCardsTooltip(cardType, sortedCards, expandOrders)
      : null)
    key = $"currency_{cardsTable}{keySuffix}"
    behavior = Behaviors.Button
    
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.scale, easing = InOutCubic, trigger,
        from = [1,1], to = [1.3,1.3], duration = 0.2 }
      { prop = AnimProp.scale, easing = InOutCubic, trigger,
        from = [1.3,1.3], to = [1.3,1.3], duration = 1.2, delay = 0.2 }
      { prop = AnimProp.scale, easing = InOutCubic, trigger,
        from = [1.3,1.3], to = [1,1], duration = 0.2, delay = 1.4 }
      { prop = AnimProp.rotate, easing = Discrete8, trigger,
        from = 0, to = 30, duration = 0.25, delay = 0.4 }
      { prop = AnimProp.rotate, easing = Discrete8, trigger,
        from = 30, to = -30, duration = 0.45, delay = 0.6 }
      { prop = AnimProp.rotate, easing = Discrete8, trigger,
        from = -30, to = 0, duration = 0.25, delay = 1 }
    ]
    onClick = onClick
    children = [
      mkCurrencyImage(ticketGroups[cardType].icon, [hdpx(30), hdpx(30)])
      expandOrders
        ? mkCurrencyInShop(sortedCards)
        : mkCurrencyCommon(stateFlag.get(), currencySumm)
    ]
  }
}

function mkItemCurrency(currencyTpl, count, keySuffix = "", textStyle = {},
  iconSize = [hdpx(25),hdpx(25)]
) {
  let currentCurrency = getCurrencyPresentation(currencyTpl)
  return {
    key = $"currency_{currencyTpl}{keySuffix}"
    size = FLEX_V
    minHeight = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    children = iconTextRow(currentCurrency?.icon, count, iconSize, textStyle)
  }
}

let mkLogisticsPromoMsgbox = @(currencies, buttons = []) showMessageWithContent({
  uid = "logistics_promo"
  content = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = fsh(3)
    children = [
      txt(loc("menu/enlistedShop")).__update({
        color = activeTxtColor
      }, fontHeading2)
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = const [sw(50), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        color = defTxtColor
        text = loc("menu/enlistedShopDesc")
      }
      {
        flow = FLOW_VERTICAL
        gap = bigGap
        children = currencies.map(@(currencyTpl) {
          gap = bigGap
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          children = [
            mkCurrencyImage(getCurrencyPresentation(currencyTpl).icon, [hdpx(70), hdpx(70)])
            {
              size = const [hdpx(300), SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              gap = smallPadding
              children = [
                txt(loc($"items/{currencyTpl}")).__update({
                  color = activeTxtColor
                }, fontSub)
                {
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  size = FLEX_H
                  text = loc($"items/{currencyTpl}/desc", "")
                  color = defTxtColor
                }.__update(fontSub)
              ]
            }
          ]
        })
      }
    ]
  }
  buttons
})

function mkDiscountWidget(discountInPercent, override = {}) {
  if (discountInPercent <= 0)
    return null

  let { size = const [hdpx(68), hdpx(34)] } = override

  return {
    size
    hplace = ALIGN_RIGHT
    children = [
      {
        rendObj = ROBJ_IMAGE
        size
        imageValign = ALIGN_TOP
        image = Picture($"!ui/gameImage/discount_corner.svg:{size[0].tointeger()}:{size[1].tointeger()}:K")
        color = accentTitleTxtColor
      }
      {
        rendObj = ROBJ_TEXT
        text = $"-{discountInPercent}%"
        color = Color(0,0,0)
        vplace = ALIGN_CENTER
        margin = [0, 0, 0, smallPadding]
      }.__update(override?.textStyle ?? fontBody)
    ]
  }.__update(override)
}

function mkCurrencyUi(currencyTpl) {
  let currencyCount = Computed(@() curCampItemsCount.get()?[currencyTpl] ?? 0)
  let onHover = @(on) setTooltip(on ? mkCurrencyTooltip(currencyTpl) : null)
  return watchElemState(@(sf) {
    watch = currencyCount
    behavior = Behaviors.Button
    onHover
    children = mkItemCurrency(currencyTpl, currencyCount.get(), "", {
      color = sf & S_HOVER ? activeTxtColor : defTxtColor
    })
  })
}

return {
  mkCurrencyOverall
  mkCurrencyTooltipContainer
  mkDefaultTooltipText
  mkCurrencyImage
  mkItemCurrency = kwarg(mkItemCurrency)
  mkLogisticsPromoMsgbox
  mkDiscountWidget
  mkCurrencyCardsTooltip
  mkCurrencyUi
}
