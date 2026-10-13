import "%ui/components/fontawesome.map.nut" as fa
import "%ui/items/itemsMapping.nut" as itemsMapping
import "%ui/components/faComp.nut" as faComp
import "%ui/components/spinner.nut" as spinner
import "%ui/battlepass/eliteBattlePassWnd.nut" as eliteBattlePassWnd
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/unlocks/weeklyTasksBtn.nut" as weeklyTasksUi
import "%ui/notifications/mkServiceNotification.nut" as mkServiceNotification
import "%ui/soldiers/components/viewItemScene.nut" as viewItemScene
from "%ui/style/fontsStyle.nut" import fontBody, fontSub, fontawesome
from "%ui/style/designConst.nut" import smallPadding, midPadding, startBtnWidth, attentionTxtColor, titleTxtColor, activeTxtColor, soldierLvlColor
from "%ui/components/mkProgressBar.nut" import progressBarHeight
from "%ui/state/safeArea.nut" import safeAreaSize, safeAreaBorders
from "%ui/components/textButton.nut" import Primary, Regular
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/showState.nut" import curSelectedItem
from "%ui/battlepass/bpState.nut" import basicProgress, combinedUnlocks, nextUnlock, progressCounters, currentProgress, hasReward, receiveAllRewards
  , buyNextStage, nextUnlockPrice, buyUnlockInProgress, receiveRewardInProgress, seasonIndex
from "%ui/battlepass/bpConst.nut" import BP_INTERVAL_STARS
from "%ui/unlocks/taskRewardsState.nut" import premiumStage0Unlock, isSeasonEnds
from "%ui/battlepass/eliteBattlePass.nut" import hasEliteBattlePass, canBuyBattlePass
from "%ui/battlepass/rewardsPkg.nut" import prepareRewards, getRewardViewData
from "%ui/currency/currenciesComp.nut" import currencyBtn
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/battlepass/bpPkg.nut" import bpHeader, bpTitle, sizeCard, mkCard, btnSize,
  btnBuyPremiumPass, gapCards, lockScreen, previewImageCmp, previewImageSize, mkBpIconBlock,
  cardPremiumHeader, mkCardProgressBar
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, equipSchemesByArmy,
  findTemplateInArmies, getArmyByTemplateId
from "%ui/soldiers/model/boosters.nut" import boostersConfig
from "%ui/battlepass/bpWindowState.nut" import isOpened, isVisible, curItem, unlockToShow, combinedRewards, curItemUpdate
from "%ui/navState.nut" import scenesListGeneration, getTopScene
from "%ui/notifications/serviceNotificationsList.nut" import serviceNotificationsList
from "%ui/unlocks/taskWidgetUi.nut" import mkDailyTasksUi
from "%ui/unlocks/taskListState.nut" import canTakeDailyTaskReward
from "%ui/soldiers/model/cratesContent.nut" import crateContentWatch
from "%ui/vehicles/vehiclesListState.nut" import viewVehicle, selectVehParams
from "%ui/vehicles/customizeState.nut" import curCamouflageId
from "%ui/ui_library.nut" import *

let waitingSpinner = spinner(hdpx(35))
const sizeBlocks    = fsh(40)
const sizeStar      = hdpx(15)
let hugePadding   = midPadding * 4

let tblScrollHandler = ScrollHandler()

let showingItem = Computed(function() {
  if (curItem.get() == null || !isOpened.get() || !isVisible.get())
    return null

  return getRewardViewData(curItem.get(), seasonIndex.get(),
    curArmy.get(),
    curArmiesList.get(),
    allItemTemplates.get(),
    equipSchemesByArmy.get(),
    unlockToShow.get())
})

showingItem.subscribe(function(item) {
  if (!isOpened.get() || !isVisible.get())
    return

  if (item?.previewImage != null)
    curSelectedItem.set(null)
  else
    curSelectedItem.set(item)
})

function scrollToCurrent() {
  let cardIdx = (curItem.get()?.stageIdx ?? "0").tointeger()
    + (premiumStage0Unlock.get()?.stages[0].rewards.len() ?? 0)
  tblScrollHandler.scrollToX((sizeCard[0] + gapCards) * (cardIdx + 0.5) - gapCards
    - safeAreaSize.get()[0] / 2)
}

nextUnlock.subscribe( function(_) {
  curItemUpdate()
  scrollToCurrent()
})

function cardsList() {
  let { isFinished = false } = premiumStage0Unlock.get()
  let { rewards  = {} } = premiumStage0Unlock.get()?.stages[0]

  let boostersConfigVal = boostersConfig.get()

  let children = [
    {
      size = FLEX_V
      flow = FLOW_VERTICAL
      gap = midPadding * 2
      valign = ALIGN_BOTTOM
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = gapCards
          children = prepareRewards(rewards, itemsMapping.get())
            .map(@(r, idx) mkCard(r.reward, r.count, boostersConfigVal,
              @() curItem.set({ reward = r.reward, stage0idx = idx }),
              Computed(@() curItem.get()?.stage0idx == idx),
              isFinished, true, false, null, cardPremiumHeader))
        }
        {
          size = [FLEX, progressBarHeight]
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = {
            rendObj = ROBJ_TEXT
            color = activeTxtColor
            text = loc("bp/eliteBPRewards")
          }
        }
      ]
    }
  ].extend(combinedRewards.get().map(function(r) {
    let { reward, count, stageIdx, isReceived, isPremium, isLooped } = r
    return mkCard(reward, count, boostersConfigVal, @() curItem.set({ reward, stageIdx }),
      Computed(@() curItem.get()?.stageIdx == stageIdx), isReceived, isPremium, isLooped,
      mkCardProgressBar(r),
      cardPremiumHeader
    )
  }))

  return {
    watch = [combinedRewards, premiumStage0Unlock, itemsMapping, boostersConfig]
    flow = FLOW_HORIZONTAL
    gap = gapCards
    children
  }
}

let bpUnlocksList = @() {
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  watch = safeAreaSize
  xmbNode = XmbContainer({
    canFocus = false
    scrollSpeed = 5.0
    isViewport = true
  })

  children = makeHorizScroll({
    flow = FLOW_VERTICAL
    padding = [hugePadding, 0, hugePadding, 0]
    gap = gapCards
    children = cardsList
    onAttach = scrollToCurrent
  }, {
    size = SIZE_TO_CONTENT
    maxWidth = safeAreaSize.get()[0]
    scrollHandler = tblScrollHandler
    rootBase = {
      key = "battlepassUnlocksRoot"
      behavior = Behaviors.Pannable
      wheelStep = 0.82
    }
  })
}

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
  watch = [hasEliteBattlePass, progressCounters]
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  size = FLEX_H
  children = hasEliteBattlePass.get() ? null
    : [
        progressCounters.get().allowedFreeRewarded > 0 ? mkTextProgress("bp/freeRewards") : null
        progressCounters.get().allowedPremRewarded > 0 ? mkTextProgress("bp/premiumRewards") : null
      ]
}

let starFilled = faComp("star", { fontSize = sizeStar, color = attentionTxtColor })
let starEmpty = faComp("star-o", { fontSize = sizeStar, color = attentionTxtColor })

function bpInfoProgress () {
  let { current, required, interval } = currentProgress.get()
  let starFactor = (interval / BP_INTERVAL_STARS).tointeger()
  let filledStars = current >= required || hasReward.get() || starFactor == 0
    ? BP_INTERVAL_STARS
    : min(BP_INTERVAL_STARS - 1, ((current + interval - required) / starFactor).tointeger())

  return {
    valign = ALIGN_CENTER
    watch = [currentProgress, hasReward, basicProgress, combinedUnlocks, progressCounters]
    flow = FLOW_HORIZONTAL
    gap = midPadding
    margin = [0,0,0,midPadding]
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("nextReward")
        color = hasReward.get() ? soldierLvlColor: activeTxtColor
      }.__update(fontBody)
      {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = array(filledStars).map(@(_) starFilled)
          .extend(array(BP_INTERVAL_STARS - filledStars).map(@(_) starEmpty))
      }
    ]
  }
}

let bpInfoDetails = @() {
  watch = [hasEliteBattlePass, canTakeDailyTaskReward]
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  margin = [0, midPadding]
  text = !canTakeDailyTaskReward.get() ? loc("unlocks/dailyTasksLimit")
    : hasEliteBattlePass.get() ? loc("bp/progressWithPremium", fa)
    : loc("bp/howToProgress", fa)
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
  let res = { watch = hasEliteBattlePass }
  if (!hasEliteBattlePass.get())
    return res

  return res.__update({
    rendObj = ROBJ_TEXT
    text = loc("bp/battlePassBought")
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
  let res = { watch = [ hasEliteBattlePass, canBuyBattlePass, nextUnlockPrice,
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
      hasEliteBattlePass.get() || !canBuyBattlePass.get() ? null
        : btnBuyPremiumPass(loc("bp/buy"), eliteBattlePassWnd )
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
    : [
        mkDailyTasksUi(false, null, true)
        weeklyTasksUi
      ]
}

let bpRightBlock = mkBpIconBlock([
  bpInfoPremPass
  buttonsBlock
  bpInfoStage
])

let closeButton = closeBtnBase({ onClick = @() isOpened.set(false) })

let bpLeftBlock = {
  size = FLEX_V
  hplace = ALIGN_LEFT
  flow = FLOW_VERTICAL
  gap = midPadding
  children = [
    @() {
      watch = [hasEliteBattlePass]
      margin = [midPadding,0,midPadding,0]
      children = bpTitle(hasEliteBattlePass.get(), hdpx(100))
    }
    {
      flow = FLOW_VERTICAL
      size = FLEX_V
      valign = ALIGN_CENTER
      gap = midPadding
      children = [
        bpInfoProgress
        bpTasksBlock
        bpInfoDetails
      ]
    }
  ]
}

function getCamoPreviewBtn(showingItemVal, templates) {
  let { vehicle = null, camouflage = null } = showingItemVal
  if (vehicle == null || camouflage == null)
    return null

  let army = getArmyByTemplateId(vehicle)
  let template = templates?[army][vehicle]
  if (template == null)
    return null

  return Regular(loc("btn/view"), function() {
    if (curCamouflageId.get() == camouflage)
      isOpened.set(false)
    else {
      if (viewVehicle.get() != null)
        isOpened.set(false)

      selectVehParams.set({
        isCustomMode = true
        isHitcamMode = false
        isForced = true
        skin = { id = camouflage }
      })
      viewVehicle.set({
        basetpl = vehicle
        gametemplate = vehicle
        guid = ""
        links = { [army] = "army" }
      }.__update(template))
    }
  })
}

function previewBtn() {
  let templates = allItemTemplates.get()
  let rewardItem = showingItem.get()
  local infoObject = getCamoPreviewBtn(rewardItem, templates)
  if (infoObject == null) {
    let { crateId = null, itemTemplate = null } = rewardItem
    let crateContent = crateContentWatch.get()
    let armies = curArmiesList.get()
    let templateId = crateContent?[crateId].items[0][0].id ?? itemTemplate
    if (templateId != null) {
      let templateInfo = findTemplateInArmies(templates, armies, templateId)
      if (templateInfo != null)
        infoObject = Regular(loc("btn/view"), function() {
          viewItemScene({
            basetpl = templateId
            guid = ""
            links = { [templateInfo.armyId] = "army" }
          }.__update(templateInfo.template))
        })
    }
  }
  return {
    watch = [showingItem, crateContentWatch, allItemTemplates, curArmiesList]
    size = FLEX_H
    children = bpHeader(showingItem.get(), closeButton, infoObject)
  }
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
        size = previewImageSize
        pos = const [-sh(0.5), -sh(12)]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          previewImageCmp(reward)
          lockScreen(reward)
        ]
      }
      {
        size = FLEX
        flow = FLOW_VERTICAL
        children = [
          {
            flow = FLOW_VERTICAL
            behavior = DngBhv.MenuCameraControl
            size = FLEX
            children = [
              previewBtn
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
    ]
  }
}

scenesListGeneration.subscribe(function(_v){
  isVisible.set(getTopScene() == bpWindow)
})

function open() {
  sceneWithCameraAdd(bpWindow, "battle_pass")
  if (curItem.get() == null)
    curItemUpdate()
}

function close() {
  sceneWithCameraRemove(bpWindow)
  curSelectedItem.set(null)
  curItem.set(null)
}

if (isOpened.get())
  open()

isOpened.subscribe(@(v) v ? open() : close())
isSeasonEnds.subscribe(function(isEnds) {
  if (isEnds)
    isOpened.set(false)
})
