import "%ui/control/gui_buttons.nut" as JB
import "%ui/items/itemsMapping.nut" as itemsMapping
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/spinner.nut" as spinner
import "%ui/shop/buyShopItem.nut" as buyShopItem
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/components/textButton.nut" import Regular
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/battlepass/rewardsPkg.nut" import mkRewardImages, prepareRewards, getRewardViewData
from "%ui/eventPass/eventTaskRewardsState.nut" import premiumUnlock, premiumStage0Unlock
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/showState.nut" import curSelectedItem
from "%ui/eventPass/eventPassPkg.nut" import bpHeader, bpTitle, mkBpIconBlock, previewImage, previewImageSize, getUniqueRewards
from "%ui/battlepass/bpPkg.nut" import hugePadding, btnBuyPremiumPass, btnSize, cardCountCircle, sizeCard, imageSize, gapCards
from "%ui/eventPass/eventPassState.nut" import seasonIndex
from "%ui/eventPass/eliteEventPass.nut" import elitePassItem, canBuyEventPass, hasEliteEventPass, isPurchaseBpInProgress
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/components/openUrl.nut" import openUrl
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, equipSchemesByArmy
from "%ui/style/designConst.nut" import midPadding, defTxtColor, isWide
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let circuitConf = get_circuit_conf()
let linkToOpen = circuitConf?.battlePassUrl

let curEliteRewardItem = mkWatched(persist, "curEliteRewardItem", null)
let isBuyEliteWndOpened = mkWatched(persist, "isBuyEliteWndOpened", false)

const HIGH_WORTH_REWARD = 3

let localGap = hugePadding * 2
let maxWidth = (sizeCard[0] + 3*gapCards) * (isWide ? 4 : 3) - 3*gapCards
const titleAndDescriptionBlockHeight = hdpx(330)
let cardBlockSize = isWide ? [hdpx(1600), SIZE_TO_CONTENT] : [hdpx(1400), SIZE_TO_CONTENT]

let showingItem = Computed(function() {
  if (curEliteRewardItem.get() == null)
    return null

  return getRewardViewData(curEliteRewardItem.get(), seasonIndex.get(),
    curArmy.get(),
    curArmiesList.get(),
    allItemTemplates.get(),
    equipSchemesByArmy.get())
})

showingItem.subscribe(function(item) {
  if (!isBuyEliteWndOpened.get())
    return

  if (item?.previewImage != null)
    curSelectedItem.set(null)
  else
    curSelectedItem.set(item)
})

hasEliteEventPass.subscribe(function(v) {
  if (v)
    isBuyEliteWndOpened.set(false)
})

let closeButton = closeBtnBase({ onClick = @() isBuyEliteWndOpened.set(false) })

let premItemsAnnouncement = Computed(function() {
  let immidiatelyGet = prepareRewards(getUniqueRewards(premiumStage0Unlock.get()).items, itemsMapping.get())
  let { items } = getUniqueRewards(premiumUnlock.get())
  let receiveLater = prepareRewards(items, itemsMapping.get())
  let sortedRewards = [
    { locId = "bp/getImmediately", rewards = immidiatelyGet }
    { locId = "eventPass/additional",
      rewards = receiveLater.filter(@(val) (val.reward?.worth ?? 0) >= HIGH_WORTH_REWARD) }
  ]
  return sortedRewards
})

let rewardBlock = @(allRewards) @(){
  hplace = ALIGN_CENTER
  size = [SIZE_TO_CONTENT, sizeCard[1]]
  children = makeHorizScroll({
    xmbNode = XmbContainer({
      canFocus = false
      scrollSpeed = 10.0
      isViewport = true
    })
    gap = gapCards
    flow = FLOW_HORIZONTAL
    children = allRewards.map(function(rewardData){
      if (rewardData == null)
        return null
      let {count, reward} = rewardData
      return watchElemState(@(sf) {
        watch = curEliteRewardItem
        rendObj = ROBJ_BOX
        size = sizeCard
        behavior = Behaviors.Button
        borderWidth = sf & S_HOVER ? hdpx(1) : 0
        onClick =  @() curEliteRewardItem.set({ reward = reward })
        children = [
          mkRewardImages(reward, imageSize)
          cardCountCircle(count)
        ]
      })
    })
  },{
    size = [SIZE_TO_CONTENT, sizeCard[1]]
    hplace = ALIGN_CENTER
    maxWidth
  })
}

let cardBlock = @(txt, val) {
  minHeight = hdpxi(360)
  flow = FLOW_VERTICAL
  gap = gapCards
  children = [
    {
      minWidth = hdpxi(240)
      rendObj = ROBJ_TEXTAREA
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      behavior = Behaviors.TextArea
      size = FLEX
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
    margin = gapCards
  }
  return {
    watch = premItemsAnnouncement
    size = cardBlockSize
    gap = separateLine
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
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
  if (!canBuyEventPass.get())
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
  size = const [FLEX, hdpx(150)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    function() {
      let action = linkToOpen != null ? @() openUrl(linkToOpen) : buyEliteBattlePass
      return {
        watch = [canBuyEventPass, isPurchaseBpInProgress]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = localGap
        size = FLEX
        children = [
          !canBuyEventPass.get() ? null
            : isPurchaseBpInProgress.get() ? bpPurchaseSpinner
            : btnBuyPremiumPass(loc("bp/Purchase"), action)
          Regular(loc("bp/close"), @() isBuyEliteWndOpened.set(false), {
            size = btnSize,
            hotkeys = [[$"^{JB.B}", { description = { skip = true }}]]
          })
        ]}
    }
    mkDescription(loc("bp/moreRewards"),
      {hplace = ALIGN_RIGHT, size =const [hdpx(150), SIZE_TO_CONTENT]}, fontSub)
  ]
}

let eliteEventPassWnd = @() {
  size = FLEX
  watch = [safeAreaBorders, showingItem, isBuyEliteWndOpened, bpEventSettings]
  padding = [safeAreaBorders.get()[0] + hdpx(30), safeAreaBorders.get()[1] + hdpx(25)]
  behavior = DngBhv.MenuCameraControl
  children = [
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        bpHeader(showingItem.get(), closeButton)
        {
          size = FLEX
          children = [
            {
              size = FLEX
              flow = FLOW_VERTICAL
              hplace = ALIGN_CENTER
              children = [
                {
                  size = const [FLEX, titleAndDescriptionBlockHeight]
                  gap = localGap
                  flow = FLOW_VERTICAL
                  margin = [midPadding, 0]
                  children = [
                    bpTitle(true, hdpx(100))
                    mkDescription(loc(bpEventSettings.get()?.premPassDesc))
                  ]
                }
                { size = FLEX }
                cardsBlock
                btnBlock
              ]
            }
            mkBpIconBlock()
          ]
        }
      ]
    }
    {
      size = previewImageSize
      pos = const [-sh(0.5), -sh(17)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = previewImage(showingItem.get())
    }
  ]
}

function open() {
  sceneWithCameraAdd(eliteEventPassWnd, "battle_pass")
  curSelectedItem.set(null)
  curEliteRewardItem.set(null)
}

function close() {
  sceneWithCameraRemove(eliteEventPassWnd)
  curSelectedItem.set(null)
  curEliteRewardItem.set(null)
}

if (isBuyEliteWndOpened.get())
  open()

isBuyEliteWndOpened.subscribe(@ (v) v ? open() : close())


console_register_command(@() isBuyEliteWndOpened.set(true), "ui.eventPassWindow")

return @() isBuyEliteWndOpened.set(true)
