import "%ui/components/colorize.nut" as colorize
import "%ui/components/spinner.nut" as spinner
import "%ui/eventPass/buyEliteEventPassWnd.nut" as eliteEventPassWnd
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/notifications/mkServiceNotification.nut" as mkServiceNotification
from "%ui/style/fontsStyle.nut" import fontBody, fontSub, fontawesome
from "%ui/style/designConst.nut" import smallPadding, midPadding, startBtnWidth, attentionTxtColor, titleTxtColor, activeTxtColor
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/components/textButton.nut" import Primary, Regular
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/showState.nut" import curSelectedItem
from "%ui/eventPass/eventPassState.nut" import progressCounters, currentProgress, hasReward, receiveAllRewards, buyNextStage, nextUnlockPrice, buyUnlockInProgress
  , receiveRewardInProgress, seasonIndex
from "%ui/eventPass/eliteEventPass.nut" import hasEliteEventPass, canBuyEventPass
from "%ui/currency/currenciesComp.nut" import currencyBtn
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/eventPass/eventPassPkg.nut" import bpHeader, bpTitle, lockScreen, previewImage,
  previewImageSize, mkBpIconBlock, mkPreviewCb
from "%ui/battlepass/bpPkg.nut" import btnSize, btnBuyPremiumPass
from "%ui/battlepass/rewardsPkg.nut" import getRewardViewData
from "%ui/eventPass/eventPassIconPkg.nut" import tokenIconCmp
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, equipSchemesByArmy
from "%ui/eventPass/eventPassWindowState.nut" import isPassWindowOpened, isPassWindowVisible,
  curRewardItem, unlockToShow, curItemUpdate
from "%ui/navState.nut" import scenesListGeneration, getTopScene
from "%ui/notifications/serviceNotificationsList.nut" import serviceNotificationsList
from "%ui/eventPass/taskWidgetUi.nut" import eventTasksUi
from "%ui/eventPass/taskListState.nut" import canTakeDailyTaskReward
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/soldiers/model/cratesContent.nut" import crateContentWatch
from "%ui/eventPass/bpUnlocksList.nut" import bpUnlocksList
from "%ui/ui_library.nut" import *

let waitingSpinner = spinner(hdpx(35))
const sizeBlocks    = fsh(40)
const sizeStar      = hdpx(15)

let showingItem = Computed(function() {
  if (curRewardItem.get() == null || !isPassWindowOpened.get() || !isPassWindowVisible.get())
    return null

  return getRewardViewData(curRewardItem.get(), seasonIndex.get(),
    curArmy.get(),
    curArmiesList.get(),
    allItemTemplates.get(),
    equipSchemesByArmy.get(),
    unlockToShow.get())
})

showingItem.subscribe(function(item) {
  if (!isPassWindowOpened.get() || !isPassWindowVisible.get())
    return

  if (item?.previewImage != null)
    curSelectedItem.set(null)
  else
    curSelectedItem.set(item)
})

let progressStyles = {
  fa = { color = attentionTxtColor, font = fontawesome.font, fontSize = sizeStar }
}

let mkTextProgress = @(locName) @() {
  watch = progressCounters
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  halign = ALIGN_CENTER
  behavior = Behaviors.TextArea
  text = loc(locName, progressCounters.get())
  color = activeTxtColor
}.__update(fontBody)

let bpInfoStage = @() {
  watch = [hasEliteEventPass, progressCounters, bpEventSettings]
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  size = FLEX_H
  children = hasEliteEventPass.get() ? null
    : [
        progressCounters.get().allowedFreeRewarded > 0
          ? mkTextProgress("bp/freeRewards") : null
        progressCounters.get().allowedPremRewarded > 0
          ? mkTextProgress(bpEventSettings.get().passRewardsPrem) : null
      ]
}

function rewardProgress() {
  let { current, required, interval } = currentProgress.get()
  let value = current >= required || hasReward.get()
    ? interval
    : clamp(current - required + interval, 0, interval)
  return {
    valign = ALIGN_CENTER
    watch = [currentProgress, hasReward]
    flow = FLOW_HORIZONTAL
    margin = [0, 0, 0, midPadding]
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        text = loc("eventPass/nextReward", { value, required = colorize(attentionTxtColor, interval) })
        color = hasReward.get() ? attentionTxtColor : activeTxtColor
        behavior = Behaviors.TextArea
      }.__update(fontBody)
      tokenIconCmp
    ]
  }
}

let bpInfoDetails = @() {
  watch = [hasEliteEventPass, canTakeDailyTaskReward, bpEventSettings]
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  margin = [0, midPadding]
  text = !canTakeDailyTaskReward.get() ? loc("unlocks/dailyTasksLimit")
    : hasEliteEventPass.get() ? loc(bpEventSettings.get().passProgressPrem)
    : loc(bpEventSettings.get().passProgress)
  behavior = Behaviors.TextArea
  color = activeTxtColor
  tagsTable = progressStyles
  transform = true
  animations = [
    { prop = AnimProp.translate, from = [-sizeBlocks, 0], to = [0, 0], duration = 0.2,
      easing = InOutCubic, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
      easing = InOutCubic, play = true}
  ]
}.__update(fontSub)

function bpInfoPremPass() {
  let res = { watch = hasEliteEventPass }
  if (!hasEliteEventPass.get())
    return res

  return res.__update({
    rendObj = ROBJ_TEXT
    text = loc("eventPass/bought")
    color = attentionTxtColor
  }, fontBody)
}

function btnReceiveAllRewards() {
  let res = {watch = hasReward}
  if (!hasReward.get())
    return res
  return res.__update({
    watch = [hasReward, receiveRewardInProgress, progressCounters]
    halign = ALIGN_CENTER
    size = btnSize
    children = receiveRewardInProgress.get() ? waitingSpinner
      : Primary(loc("bp/getAllRewardWithCount", progressCounters.get()), receiveAllRewards, {
          hotkeys = [["^J:X | Enter | Space", { skip = true }]]
          size = btnSize
        })
  })
}

let mkBtnBuySkipStage = @(price) currencyBtn({
  btnText = loc("bp/buy")
  currencyId = price.currency
  price = price.price
  cb = @() purchaseMsgBox({
    price = price.price
    currencyId = price.currency
    description = loc("bp/buyNextStageConfirm")
    purchase = buyNextStage
    alwaysShowCancel = true
    srcComponent = "buy_battlepass_level"
  })
  style = ({
    margin = 0
    hotkeys = [["^J:Y", { description = { skip = true }}]]
    size = btnSize
    minWidth = btnSize[0]
  })
})

let mkBuySkipStageBlock = @(price) {
  flow = FLOW_VERTICAL
  size = [btnSize[0], SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  padding = [midPadding, 0, 0, 0]
  gap = midPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/buyNextStage")
      color = titleTxtColor
    }.__update(fontBody)
    mkBtnBuySkipStage(price)
  ]
}

function buttonsBlock() {
  let res = { watch = [ hasEliteEventPass, canBuyEventPass, nextUnlockPrice,
    buyUnlockInProgress, hasReward] }

  let price = nextUnlockPrice.get()
  return res.__update({
    transform = true
    animations = [
      { prop = AnimProp.translate, from = [sizeBlocks, 0], to = [0, 0], duration = 0.2,
        easing = InOutCubic, play = true }
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
        easing = InOutCubic, play = true }
    ]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    margin = [midPadding, 0, 0, 0]
    gap = midPadding
    children = [
      hasEliteEventPass.get() || !canBuyEventPass.get() ? null
        : btnBuyPremiumPass(loc("bp/buy"), eliteEventPassWnd )
      buyUnlockInProgress.get() ? waitingSpinner
        : price && !hasReward.get() ? mkBuySkipStageBlock(price)
        : null
      btnReceiveAllRewards
    ]
  })
}

let bpTasksBlock = @() {
  watch = serviceNotificationsList
  size = [startBtnWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = midPadding
  margin = [0,0,0,midPadding]
  children = serviceNotificationsList.get().len() > 0
    ? mkServiceNotification(serviceNotificationsList.get(), { hplace = ALIGN_RIGHT })
    : eventTasksUi
}

let bpRightBlock = mkBpIconBlock([
  bpInfoPremPass
  buttonsBlock
  bpInfoStage
])

let closeButton = closeBtnBase({ onClick = @() isPassWindowOpened.set(false) })

let bpLeftBlock = {
  size = FLEX_V
  hplace = ALIGN_LEFT
  flow = FLOW_VERTICAL
  gap = midPadding
  children = [
    @() {
      watch = [hasEliteEventPass]
      margin = [midPadding,0,midPadding,0]
      children = bpTitle(hasEliteEventPass.get(), hdpx(100))
    }
    {
      flow = FLOW_VERTICAL
      size = FLEX_V
      valign = ALIGN_CENTER
      gap = midPadding
      children = [
        rewardProgress
        bpTasksBlock
        bpInfoDetails
      ]
    }
  ]
}

function bpWindow() {
  let reward = showingItem.get()
  return {
    size = FLEX
    watch = [safeAreaBorders, showingItem]
    padding = [
      safeAreaBorders.get()[0] + hdpx(30),
      safeAreaBorders.get()[1] + hdpx(25),
      safeAreaBorders.get()[0] + hdpx(60),
      safeAreaBorders.get()[1] + hdpx(25)
    ]
    children = [
      {
        size = FLEX
        flow = FLOW_VERTICAL
        children = [
          {
            flow = FLOW_VERTICAL
            behavior = DngBhv.MenuCameraControl
            size = FLEX
            children = [
              function() {
                local infoObject = null
                let templates = allItemTemplates.get()
                let armies = curArmiesList.get()
                let crateContentVal = crateContentWatch.get()
                let onClick = mkPreviewCb(reward, crateContentVal, templates, armies)

                if (onClick != null)
                  infoObject = Regular(loc("btn/view"), onClick)
                return {
                  watch = [crateContentWatch, allItemTemplates, curArmiesList]
                  size = FLEX_H
                  children = bpHeader(reward, closeButton, infoObject)
                }
              }
              {
                size = FLEX
                children = [
                  bpLeftBlock
                  bpRightBlock
                ]
              }
            ]
          }
          bpUnlocksList
        ]
      }
      {
        size = previewImageSize
        pos = const [-sh(0.5), -sh(12)]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          previewImage(showingItem.get())
          lockScreen(showingItem.get())
        ]
      }
    ]
  }
}

function setCurrentItem() {
  if (curRewardItem.get() == null)
    curItemUpdate()
}

scenesListGeneration.subscribe(@(_)
  isPassWindowVisible.set(getTopScene() == bpWindow))

function open() {
  sceneWithCameraAdd(bpWindow, "battle_pass")
  setCurrentItem()
}

function close() {
  sceneWithCameraRemove(bpWindow)
  curSelectedItem.set(null)
  curRewardItem.set(null)
}

if (isPassWindowOpened.get())
  open()

isPassWindowOpened.subscribe(@ (v) v ? open() : close())