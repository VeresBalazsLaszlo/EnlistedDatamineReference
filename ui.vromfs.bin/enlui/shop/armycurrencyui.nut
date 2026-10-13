import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontawesome.map.nut" as fa
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
from "%ui/shop/currencyPresentation.nut" import ticketGroups, currencyPresentation,
  getCurrencyPresentation
from "%ui/components/msgbox.nut" import msgboxStyling
from "%ui/style/fontsStyle.nut" import fontBody, fontSub, fontawesome, fontHeading2
from "%ui/shop/numberUtils.nut" import abbreviateAmount
from "%ui/shop/currencyComp.nut" import mkCurrencyOverall, mkCurrencyImage, mkCurrencyCardsTooltip
from "%ui/mainMenu/sectionsState.nut" import setCurSection, curSection, Section
from "%ui/components/defcomps.nut" import txt
from "%ui/shop/armyShopState.nut" import realCurrencies, isItemsShopOpened
from "%ui/shop/shopState.nut" import setAutoGroup
from "%ui/growth/growthState.nut" import curGrowthFreeExp
from "%ui/style/designConst.nut" import midPadding, warningColor, bonusColor, defTxtColor,
  darkTxtColor, largePadding, panelBgColor, smallPadding, brightAccentColor, titleTxtColor,
  commonBtnHeight
from "%ui/style/cursors.nut" import setTooltip
from "%ui/components/textButton.nut" import FASecondary, Regular, Primary
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%sqstd/math.nut" import splitThousands
from "%ui/components/slider.nut" import Horiz
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/meta/clientApi.nut" import exchange_exp_to_silver
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/ui_library.nut" import *

const WND_UID = "ExchangeModal"
const GROWTH_ID = "growth_exp"
const SILVER_KEY = "enlisted_silver"
const SHOW_INTERVAL = 0.6

let ADDING_ORDER_SIZE = const [hdpxi(20), hdpxi(20)]

let isInShop = Computed(@() curSection.get() == Section.SHOP || isItemsShopOpened.get())
let isInGrowth = Computed(@() curSection.get() == Section.GROWTH)
let expExchangeRate = Computed(@() gameProfile.get()?.expExchangeRate ?? 0.0)

expExchangeRate.subscribe(function(v) {
  if (v <= 0.0)
    removeModalWindow(WND_UID)
})

let sliderWidth = const hdpxi(540)
let priceIconSize = const [hdpxi(22), hdpxi(22)]
let bigPriceIconSize = const [hdpxi(30), hdpxi(30)]
let activeZoneSlider = const hdpxi(30)
let widthBtn = const hdpxi(300)
let sizeIconExchange = const hdpxi(20)
let separator = const loc("amount/separator")

let mkExpIcon = @(size)
  mkCurrencyImage(getCurrencyPresentation(GROWTH_ID).icon, size)

let mkSilverIcon = @(size)
  mkCurrencyImage(getCurrencyPresentation(SILVER_KEY).icon, size)

let priceIconSilver = mkSilverIcon(priceIconSize)
let bigPriceIconSilver = mkSilverIcon(bigPriceIconSize)
let bigPriceIconExp = mkExpIcon(bigPriceIconSize)

let textColor = @(sf) sf & S_ACTIVE ? titleTxtColor
  : sf & S_HOVER ? darkTxtColor
  : titleTxtColor

let thousands = @(amount) splitThousands(amount.tointeger(), separator)

let filterCurrencies = @(currId) currId != SILVER_KEY
let filterCurrenciesSilver = @(currId) currId == SILVER_KEY

local diffAnimId = 0

function mkDiffCurrency(curr, idx, cbRemove) {
  let { count, currTpl, offset } = curr
  let delay = idx * SHOW_INTERVAL
  local diffComp
  diffComp = {
    key = $"{currTpl}_{diffAnimId}_{idx}"
    pos = [pw(offset), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    opacity = 0
    children = [
      count > 0
        ? txt({ text = $"+{count}", color = bonusColor })
        : txt({ text = $"{count}", color = warningColor })
      mkCurrencyImage(getCurrencyPresentation(currTpl).icon, ADDING_ORDER_SIZE)
    ]
    transform = true
    animations = [
      { prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.4,
        play = true, easing = InOutCubic, delay }
      { prop = AnimProp.opacity, from = 1, to = 1, duration = 0.4,
        play = true, easing = InOutCubic, delay = delay + 0.4 }
      { prop = AnimProp.opacity, from = 1, to = 0.2, duration = 0.2,
        play = true, easing = InOutCubic, delay = delay + 0.8 }
      { prop = AnimProp.translate, from = [0, hdpx(60)], to = [0, 0],
        play = true, easing = OutQuart, duration = 1.0, delay, onFinish = @() cbRemove(diffComp) }
    ]
  }
  return diffComp
}

function getSortedCards(armyCurrency, currencyPresentationList) {
  let sortedCards = []
  ticketGroups.each(function(groupContent, groupName) {
    let showInCurrentSection = groupContent?.showInSection.contains(curSection.get()) ?? true
    if (showInCurrentSection){
      let cardsTable = {
        groupOrder = groupContent.order
        cards = {}
        type = groupName
        showIfZero = groupContent.isShownIfEmpty
        isInteractive = groupContent.isInteractive
      }
      currencyPresentationList.each(function(value, key) {
        let { group = null } = value
        if (group == groupContent) {
          armyCurrency.each(function(val, k) {
            if (key == k)
              cardsTable.cards[k] <- val
          })
          if (key not in cardsTable.cards && !(value?.hideIfZero ?? false))
            cardsTable.cards[key] <- 0
        }
      })
      if (cardsTable.cards.findindex(@(v) v > 0) != null || cardsTable.showIfZero)
        sortedCards.append(cardsTable)
    }
  })

  return sortedCards.sort(@(a,b) a.groupOrder <=> b.groupOrder)
}

function mkCurrenciesDiffData(realCurr, lastCurr, currencyPresentationList) {
  if (isEqual(realCurr, lastCurr))
    return null

  let sortedCards = getSortedCards(realCurr, currencyPresentationList)
  let diff = []
  foreach (currTpl, count in realCurr) {
    if (currTpl in currencyPresentationList) {
      if (currTpl not in lastCurr) {
        lastCurr[currTpl] <- count
      }
      else {
        let prevCount = lastCurr?[currTpl] ?? 0
        if (prevCount != count) {
          let orderNumber = sortedCards.findindex(@(v) currTpl in v.cards) ?? 0
          diff.append({
            currTpl
            count = count - prevCount
            offset = sortedCards.len() == 0 ? 0 : 100 * orderNumber / sortedCards.len() + 10
          })
          lastCurr[currTpl] <- count
        }
      }
    }
  }

  if (diff.len() == 0)
    return null

  diff.sort(@(a, b) a.offset <=> b.offset)
  diffAnimId++
  return diff
}

function addClickAutoShop(value, isShop) {
  function openShop() {
    setAutoGroup(value.type)
    setCurSection(Section.SHOP)
  }
  return mkCurrencyOverall(
    value.type,
    value.cards,
    value.isInteractive && !isShop ? openShop : null,
    value,
    isShop)
}

let mkArmyCurrency = @(armyCurrency, currencyPresentationList, isShop)
  getSortedCards(armyCurrency, currencyPresentationList).map(@(v) addClickAutoShop(v, isShop))

let sectionCurrency = Computed(function() {
  let res = {}
  let currencies = realCurrencies.get()
  let curSectionId = curSection.get()
  foreach (currId, currData in currencyPresentation) {
    let isVisible = (currData?.isAlwaysVisible ?? false) || (curSectionId in currData?.sections)
    if (isVisible)
      res[currId] <- currencies?[currId] ?? 0
  }
  return res
})

function mkCurrencyUi(currencyWatch, filterFn = @(v) v) {
  let lastCurrencies = {}
  let filteredCurrencyPresentation = currencyPresentation.filter(@(_, k) filterFn(k))
  let storedDiffs = []
  let visibleDiffs = Watched([])
  local isVisible = false

  function removeComp(diffComp) {
    let index = visibleDiffs.get().indexof(diffComp)
    if (index != null)
      visibleDiffs.mutate(@(v) v.remove(index))
  }

  function updateComps() {
    if (storedDiffs.len() == 0 || !isVisible)
      return

    visibleDiffs.mutate(@(v)
      v.extend(storedDiffs.map(@(val, idx) mkDiffCurrency(val, idx, removeComp))))
    storedDiffs.clear()
  }

  function onAttach() {
    isVisible = true
    updateComps()
  }

  function onDetach() {
    isVisible = false
    visibleDiffs.set([])
  }

  currencyWatch.subscribe(function(realCurr) {
    let diffs = mkCurrenciesDiffData(realCurr, lastCurrencies, filteredCurrencyPresentation)
    if (diffs == null)
      return

    storedDiffs.extend(diffs)
    if (isVisible)
      gui_scene.resetTimeout(SHOW_INTERVAL, updateComps, filterFn)
  })

  return @() {
    size = FLEX_V
    minHeight = SIZE_TO_CONTENT
    children = [
      @() {
        watch = [currencyWatch, isInShop]
        size = FLEX_V
        minHeight = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        halign = ALIGN_RIGHT
        gap = midPadding
        children = mkArmyCurrency(
          currencyWatch.get(),
          filteredCurrencyPresentation,
          isInShop.get()
        )
      }
      @() {
        watch = visibleDiffs
        size = FLEX
        valign = ALIGN_CENTER
        children = visibleDiffs.get()
      }
    ]
    onAttach
    onDetach
  }
}

function changeSliderExp(delta, curPos, expRequired) {
  let step = (delta * (1.0 / expExchangeRate.get())).tointeger()
  return clamp(curPos + step, 0, expRequired)
}

let sliderBtnParams = { btnWidth = hdpxi(80) }.__update(fontSub)

let roundExp = @(value, rate) (value * rate).tointeger() * (1 / rate).tointeger()

let mkExpSlider = @(sliderWatch, expRequired, unit) function() {
  let rate = expExchangeRate.get()
  let exchangeMaxExp = roundExp(expRequired, rate)
  return {
    watch = expExchangeRate
    flow = FLOW_VERTICAL
    padding = largePadding
    rendObj = ROBJ_SOLID
    color = panelBgColor
    children = [
      function() {
        let addExp = roundExp(sliderWatch.get(), rate)
        let sliderTxt = $"{thousands(addExp)} / {thousands(expRequired)}"
        return {
          watch = sliderWatch
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = [
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              valign = ALIGN_CENTER
              children = [
                bigPriceIconExp
                {
                  rendObj = ROBJ_TEXT
                  color = brightAccentColor
                  text = sliderTxt
                }.__update(fontBody)
              ]
            }
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              valign = ALIGN_CENTER
              halign = ALIGN_CENTER
              children = [
                priceIconSilver
                {
                  rendObj = ROBJ_TEXT
                  color = titleTxtColor
                  text = $"+{thousands(addExp * rate)}"
                }.__update(fontSub)
              ]
            }
          ]
        }
      }
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          Regular(loc("-"), @() sliderWatch.set(
            changeSliderExp(-1, sliderWatch.get(), exchangeMaxExp)),
              sliderBtnParams.__merge({hotkeys = [["^J:LB"]]}))
          {
            size = [sliderWidth, activeZoneSlider]
            children = Horiz(sliderWatch, {
              min = 0
              max = exchangeMaxExp
              unit
              step = exchangeMaxExp * rate
              setValue = @(v) sliderWatch.set(v)
            })
          }
          Regular(loc("+"), @() sliderWatch.set(
            changeSliderExp(1, sliderWatch.get(), exchangeMaxExp)),
              sliderBtnParams.__merge({ hotkeys = [["^J:RB"]] }))
          Regular(loc("growth/maxBoost"), @() sliderWatch.set(exchangeMaxExp),
            fontSub.__merge({hotkeys = [["^J:X | Space"]]}))
        ]
      }
    ]
  }
}

let mkBtnExchange = @(exchangeSliderExp) function() {
  let rate = expExchangeRate.get()
  let count = roundExp(exchangeSliderExp.get(), rate)
  return {
    watch = [exchangeSliderExp, expExchangeRate]
    size = const [FLEX, hdpxi(70)]
    halign = ALIGN_RIGHT
    children = count <= 0 ? null
      : Primary(@(_textComp, params, handler, group, sf)
          textButtonTextCtor({
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            gap = midPadding
            padding = [0, midPadding]
            children = [
              bigPriceIconExp
              {
                rendObj = ROBJ_TEXT
                color = textColor(sf)
                text = thousands(count)
              }.__update(fontBody)
              {
                rendObj = ROBJ_TEXT
                color = textColor(sf)
                text = fa["long-arrow-right"]
              }.__update(fontawesome)
              bigPriceIconSilver
              {
                rendObj = ROBJ_TEXT
                color = textColor(sf)
                text = thousands(count * rate)
              }.__update(fontBody)
            ]
          }, params, handler, group, sf),
          function() {
            exchange_exp_to_silver(curArmy.get(), count)
            removeModalWindow(WND_UID)
          },
          {
            size = [SIZE_TO_CONTENT, commonBtnHeight]
            minWidth = widthBtn
            hotkeys = [[$"^J:Y | Enter"]]
        })
  }
}

function mkExchangeUi() {
  let exchangeSliderExp = Watched(0)
  return @() {
    watch = [safeAreaBorders, curGrowthFreeExp]
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = largePadding
    padding = safeAreaBorders.get()
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      msgboxStyling?.rootUpperDecor
      {
        size = FLEX_H
        valign = ALIGN_CENTER
        children = [
          Regular(loc("mainmenu/btnBack"), @() removeModalWindow(WND_UID), {
            hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]]
          })
          {
            rendObj = ROBJ_TEXT
            hplace = ALIGN_CENTER
            color = brightAccentColor
            text = utf8ToUpper(loc("growth/exchangeTitle"))
          }.__update(fontHeading2)
        ]
      }
      @() {
        watch = expExchangeRate
        flow = FLOW_VERTICAL
        gap = largePadding
        children = [
          mkExpSlider(exchangeSliderExp,
            curGrowthFreeExp.get(),
            1.0 / (curGrowthFreeExp.get() * expExchangeRate.get()))
          mkBtnExchange(exchangeSliderExp)
        ]
      }
      msgboxStyling?.rootLowerDecor
    ]
  }
}

let openExchangeWindow = @() addModalWindow({
  key = WND_UID
  size = FLEX
  rendObj = msgboxStyling.Root.rendObj
  fillColor = msgboxStyling.Root.fillColor
  onClick = @() null
  children = mkExchangeUi()
})

let getTooltipMsg = @(count) mkCurrencyCardsTooltip(GROWTH_ID, [{
  amount = count
  icon = getCurrencyPresentation(GROWTH_ID).icon
}])


function mkBtnOpenExchange() {
  let watch = [curGrowthFreeExp, expExchangeRate]
  if (expExchangeRate.get() <= 0.0)
    return { watch }

  return {
    watch
    children = curGrowthFreeExp.get() < 1.0 / expExchangeRate.get() ? null
      : FASecondary("exchange", openExchangeWindow, {
          btnWidth = sizeIconExchange
          btnHeight = sizeIconExchange
          style = {
            defTxtColor = defTxtColor
            hoverTxtColor = darkTxtColor
            activeTxtColor = darkTxtColor
            defBdColor = 0
            hoverBdColor = 0
            activeBdColor = 0
            defBgColor = 0
          }
          textParams = {
            font = fontawesome.font
            fontSize = hdpx(10)
          }
          onHover = function(on) {
            setTooltip(!on ? null
              : tooltipCtor({rendObj = ROBJ_TEXT, text = loc("currency/exchange_free_exp")}))
          }
        })
  }
}

let mkCountCurrency = @() {
  watch = curGrowthFreeExp
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = abbreviateAmount(curGrowthFreeExp.get())
}.__update(fontBody)

let mkCurrencyFreeExpUi = @(children) {
  watch = [isInGrowth, curGrowthFreeExp]
  behavior = Behaviors.Button
  onHover = @(on) setTooltip(!on ? null : getTooltipMsg(curGrowthFreeExp.get()))
  children = !isInGrowth.get() ? null : {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = midPadding
    children
  }
}

let freeExpWithExchangeUi = @() mkCurrencyFreeExpUi([
  bigPriceIconExp
  mkCountCurrency
  mkBtnOpenExchange
])

let freeExpUi = @() mkCurrencyFreeExpUi([
  bigPriceIconExp
  mkCountCurrency
])

return {
  currencyUi = mkCurrencyUi(sectionCurrency, filterCurrencies)
  currencySilverUi = mkCurrencyUi(sectionCurrency, filterCurrenciesSilver)
  freeExpUi
  freeExpWithExchangeUi
  mkExpIcon
}
