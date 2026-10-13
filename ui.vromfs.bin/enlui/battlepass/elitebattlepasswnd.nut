import "%ui/control/gui_buttons.nut" as JB
import "%ui/items/itemsMapping.nut" as itemsMapping
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/spinner.nut" as spinner
import "%ui/shop/buyShopItem.nut" as buyShopItem
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/components/textButton.nut" import Regular
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/battlepass/rewardsPkg.nut" import mkRewardImages, prepareRewards, getRewardViewData
from "%ui/unlocks/taskRewardsState.nut" import premiumUnlock, premiumStage0Unlock, isSeasonEnds
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/showState.nut" import curSelectedItem
from "%ui/battlepass/bpPkg.nut" import bpHeader, hugePadding, btnBuyPremiumPass, bpTitle, btnSize, cardCountCircle, sizeCard
  , imageSize, gapCards, mkBpIconBlock, previewImageCmp, previewImageSize
from "%ui/battlepass/bpState.nut" import seasonIndex
from "%ui/battlepass/eliteBattlePass.nut" import elitePassItem, canBuyBattlePass, hasEliteBattlePass, isPurchaseBpInProgress
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/components/openUrl.nut" import openUrl
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, equipSchemesByArmy
from "%ui/style/designConst.nut" import midPadding, defTxtColor, isWide
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let circuitConf = get_circuit_conf()
let linkToOpen = circuitConf?.battlePassUrl

let curItem = mkWatched(persist, "curItem", null)
let isOpened = mkWatched(persist, "isOpened", false)

const HIGH_WORTH_REWARD = 3

let localGap = hugePadding * 2
let maxWidth = (sizeCard[0] + 3*gapCards) * (isWide ? 4 : 3) - 3*gapCards
const titleAndDescriptionBlockHeight = hdpx(330)
let cardBlockSize = isWide ? [hdpx(1600), SIZE_TO_CONTENT] : [hdpx(1400), SIZE_TO_CONTENT]

let showingItem = Computed(function() {
  if (curItem.get() == null)
    return null

  return getRewardViewData(curItem.get(), seasonIndex.get(),
    curArmy.get(),
    curArmiesList.get(),
    allItemTemplates.get(),
    equipSchemesByArmy.get())
})

showingItem.subscribe(function(item) {
  if (isOpened.get())
    curSelectedItem.set(item)
})

hasEliteBattlePass.subscribe(function(v) {
  if (v)
    isOpened.set(false)
})

let closeButton = closeBtnBase({ onClick = @() isOpened.set(false) })

function getUniqueRewards(unlock) {
  let items = {}
  let currency = {}
  foreach (stage in unlock?.stages ?? []){
    let { rewards = {}, currencyRewards = {} } = stage
    foreach (idStr, amount in rewards)
      items[idStr] <- (items?[idStr] ?? 0) + amount
    foreach (idStr, amountStr in currencyRewards)
      currency[idStr] <- (currency?[idStr] ?? 0) + amountStr.tointeger()
  }
  return { items, currency }
}


let premItemsAnnouncement = Computed(function() {
  let immidiatelyGet = prepareRewards(getUniqueRewards(premiumStage0Unlock.get()).items, itemsMapping.get())
  let { items, currency } = getUniqueRewards(premiumUnlock.get())
  let receiveLater = prepareRewards(items, itemsMapping.get())
  let currencyBack = prepareRewards(currency, itemsMapping.get())
  let sortedRewards = [
    { locId = "bp/getImmediately", rewards = immidiatelyGet }
    { locId = "bp/additional",
      rewards = receiveLater.filter(@(val) (val.reward?.worth ?? 0) >= HIGH_WORTH_REWARD) }
    { locId = "bp/goldBack", rewards = currencyBack }
  ]

  return sortedRewards
})

let rewardBlock = @(allRewards) @(){
  hplace = ALIGN_CENTER
  size = FLEX_V
  children = makeHorizScroll({
    xmbNode = XmbContainer({
      canFocus = false
      scrollSpeed = 10.0
      isViewport = true
    })
    gap = gapCards
    flow = FLOW_HORIZONTAL
    vplace = ALIGN_BOTTOM
    children = allRewards.map(function(rewardData){
      if (rewardData == null)
        return null
      let {count, reward} = rewardData
      return {
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        children = watchElemState(@(sf){
          watch = curItem
          rendObj = ROBJ_BOX
          size = sizeCard
          behavior = Behaviors.Button
          borderWidth = sf & S_HOVER ? hdpx(1) : 0
          onClick =  @() curItem.set({ reward = reward })
          children = [
            mkRewardImages(reward, imageSize)
            cardCountCircle(count)
          ]
        })
      }
    })
  },{
    size = FLEX_V
    hplace = ALIGN_CENTER
    maxWidth
  })
}

let cardBlock = @(txt, val) {
  minHeight = hdpx(330)
  padding = [0, gapCards]
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      halign = ALIGN_CENTER
      vplace = ALIGN_TOP
      behavior = Behaviors.TextArea
      size = FLEX_H
      text = loc(txt)
    }.__update(fontBody)
    rewardBlock(val)
  ]
}

function cardsBlock(){
  let separateLine = {
    rendObj = ROBJ_SOLID
    size = const [hdpx(1), FLEX]
    color = defTxtColor
  }
  return {
    watch = premItemsAnnouncement
    size = cardBlockSize
    gap = separateLine
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    children = premItemsAnnouncement.get().map(@(val) cardBlock(val.locId, val.rewards))
  }
}

let mkDescription = @(text, params = {}, txtSize = fontBody){
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = const [hdpx(500), SIZE_TO_CONTENT]
  text
}.__update(txtSize, params)

function buyEliteBattlePass() {
  if (!canBuyBattlePass.get())
    return
  buyShopItem({ shopItem = elitePassItem.get() })
}

let bpPurchaseSpinner = {
  size = btnSize
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = spinner(hdpx(35))
}

let btnBlock = {
  size = const [FLEX, hdpx(120)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    function() {
      let action = linkToOpen != null ? @() openUrl(linkToOpen) : buyEliteBattlePass
      return {
        watch = [canBuyBattlePass, isPurchaseBpInProgress]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = localGap
        size = FLEX
        children = [
          !canBuyBattlePass.get() ? null
            : isPurchaseBpInProgress.get() ? bpPurchaseSpinner
            : btnBuyPremiumPass(loc("bp/Purchase"), action)
          Regular(loc("bp/close"), @() isOpened.set(false), {
            size = btnSize,
            hotkeys = [[$"^{JB.B}", { description = { skip = true }}]]
          })
        ]}
    }
    mkDescription(loc("bp/moreRewards"),
      {hplace = ALIGN_RIGHT, size =const [hdpx(150), SIZE_TO_CONTENT]}, fontSub)
  ]
}

let eliteBattlePassWnd = @(){
  size = FLEX
  watch = [safeAreaBorders, showingItem, isOpened]
  padding = [safeAreaBorders.get()[0] + hdpx(30), safeAreaBorders.get()[1] + hdpx(25)]
  behavior = DngBhv.MenuCameraControl
  children = [
    {
      size = previewImageSize
      pos = const [-sh(0.5), -sh(16)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = previewImageCmp(showingItem.get())
    }
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        bpHeader(showingItem.get(), closeButton)
        {
          size = FLEX
          hplace = ALIGN_CENTER
          flow = FLOW_VERTICAL
          children = [
            {
              size = const [FLEX, titleAndDescriptionBlockHeight]
              gap = localGap
              flow = FLOW_VERTICAL
              margin = [midPadding, 0]
              children = [
                bpTitle(true, hdpx(100))
                mkDescription(loc("bp/description"))
              ]
            }
            { size = FLEX }
            cardsBlock
            btnBlock
          ]
        }
      ]
    }
    mkBpIconBlock()
  ]
}

function open() {
  sceneWithCameraAdd(eliteBattlePassWnd, "battle_pass")
  curSelectedItem.set(null)
  curItem.set(null)
}

function close() {
  sceneWithCameraRemove(eliteBattlePassWnd)
  curSelectedItem.set(null)
  curItem.set(null)
}

if (isOpened.get())
  open()

isOpened.subscribe(@ (v) v ? open() : close())
isSeasonEnds.subscribe(function(isEnds) {
  if (isEnds)
    isOpened.set(false)
})

console_register_command(@() isOpened.set(true), "ui.battlepassWindow")

return @() isOpened.set(true)
