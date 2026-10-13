import "%ui/control/gui_buttons.nut" as JB
import "%ui/items/itemsMapping.nut" as itemMapping
import "%ui/components/faComp.nut" as faComp
import "%ui/components/spinner.nut" as spinner
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, casualFlagStyle
from "math" import rand
from "%ui/style/cursors.nut" import withTooltip
from "%ui/soldiers/model/cratesContent.nut" import crateContentWatch
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/style/designConst.nut" import titleTxtColor, smallPadding, commonBtnHeight, midPadding, smallOffset, defBgColor, defTxtColor, activeTxtColor
from "%ui/style/fontsStyle.nut" import fontTitle, fontHeading1, fontHeading2, fontBody, fontSub
from "%ui/components/defcomps.nut" import noteTextArea, txt
from "%ui/unlocks/dailyRewardsState.nut" import dailyRewardsUnlock, receiveDayReward,
  calcRewardCfg, isReceiveDayRewardInProgress, gotoNextStageOrClose,
  curBoosteredDailyTask, needOpenDailyRewards, getReceivedItems
from "%ui/items/crateInfo.nut" import makeCrateToolTip
from "%ui/components/mkProgressBar.nut" import progressBarHeight, completedProgressLine, acquiredProgressLine, progressContainerCtor
from "%ui/unlocks/dailyRewardsPkg.nut" import mkRewardCardByPresentation, mkAppearAnim, mkRollAnim, sizeCard, mkRewardCardByTemplate, animTrigger, mkMoveDownAnim
  , mkBoosterItemsView, wndParams, bigRewardSeparatorBoxes, bigRewardSeparatorArrows, rewardWidth
from "%ui/components/glareAnimation.nut" import glareAnimation, animChildren
from "%ui/battlepass/rewardsPkg.nut" import mkRewardImages, rewardWidthToHeight
from "%ui/unlocks/mkUnlockSlots.nut" import mkUnlockSlot
from "%ui/soldiers/model/boosters.nut" import boostersConfig
from "%ui/components/itemsInfo.nut" import boosterName
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/components/wndManager.nut" import registerWnd, Wnd, WndEvents
from "%ui/components/wndPermissionFlags.nut" import canShowRewards, autoClose
from "%ui/soldiers/model/newItemsToShow.nut" import unseenReward
from "%ui/ui_library.nut" import *

const WND_UID = "dailyRewardsWindow"
const REWARDS_IN_LINE = 7
const ROLL_CARD_COUNT = 10
const ROLL_ADD_COUNT  = 4
const ROLL_SPEED = 5
const SHOW_WND_DELAY  = 0.2
const SHOW_STAGE_DELAY = 0.1
const SHOW_TASK_BOOST = "show_task_boost"
const HIDE_TASK_BOOST = "hide_task_boost"


let hasRewardsAnim = Watched(false)

let waitingSpinner = spinner(hdpx(30))
const bigRewardDaySplitterWidth = hdpx(12)
const wndPadding = sh(1)
let wndWidth = REWARDS_IN_LINE * rewardWidth + wndPadding * 2 + bigRewardDaySplitterWidth
let imageHeight = rewardWidth - hdpx(30)
let imageSize = [(rewardWidthToHeight * imageHeight).tointeger(), imageHeight]
let btnSize = [hdpx(280), commonBtnHeight]

let dayProgressBar = progressContainerCtor(
  $"!ui/uiskin/battlepass/progress_bar_mask.svg",
  $"!ui/uiskin/battlepass/progress_bar_border.svg",
  [rewardWidth, progressBarHeight]
)

let mkImage = @(path, override = {}) {
  rendObj = ROBJ_IMAGE
  size = FLEX
  imageValign = ALIGN_TOP
  image = Picture(path)
}.__update(override)

let mkProgressText = @(progressText, color = null) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = progressText
  color
}.__update(fontBody)

function mkStageCardView(rewardItems, hasStageCompleted) {
  if (rewardItems.len() == 0)
    return null

  let moreNumber = rewardItems.len() - 1
  return {
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkRewardImages(rewardItems[0], imageSize, {
        pos = [0, -smallPadding]
        size = imageSize
      }, hasStageCompleted)
      moreNumber <= 0 ? null
        : txt({
            text = loc("plusMore", { number = moreNumber })
            padding = smallPadding
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            color = titleTxtColor
          })
    ]
  }
}

function mkToolTip(rewardCrate, rewardsCfgs) {
  let headerText = "\n".join(rewardsCfgs.map(@(cfg) loc(cfg.name)))
  return rewardCrate.get() != null
    ? makeCrateToolTip(rewardCrate, headerText)
    : tooltipCtor(noteTextArea({
        size = const [hdpx(400), SIZE_TO_CONTENT]
        text = headerText
        color = defTxtColor
      }).__update(fontSub))
}

function mkBoosterToolTip(bName, rewardsBoosters, rewardsItems, curArmyId) {
  let boostersItems = {
    reinforcing = []
    instant = []
  }
  foreach (content in rewardsBoosters)
    foreach (boosterPack in content) {
      let boostersPack = (boosterPack?.instantReward ?? false)
        ? boostersItems.instant
        : boostersItems.reinforcing
      foreach (mappedItem, count in boosterPack.items) {
        let { worth = 0, boosterId = null, itemTemplate = null } = rewardsItems?[mappedItem]
        boostersPack.append({
          count
          itemTemplate = itemTemplate ?? boosterId
          worth
        })
      }
    }

  return tooltipCtor({
    size = const [hdpx(400), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      noteTextArea({
        size = FLEX_H
        text = loc(bName)
        color = activeTxtColor
      }).__update(fontBody)
      mkBoosterItemsView(boostersItems, curArmyId)
    ]
  })
}

let rewardBreathAnim = [{
  prop = AnimProp.opacity, from = 0.8, to = 1, play = true, duration = 1.5,
  loop = true, easing = CosineFull
}]

let mkBackgroundWithGlareAnimation = @(background) {
  size = FLEX
  clipChildren = true
  children = [
    {
      size = FLEX
      children = background
      transform = true
      animations = rewardBreathAnim
    }
    animChildren(glareAnimation(3))
  ]
}

function mkProgressBar(idx, todayStage, pastDays, hasStageReward, hasStageCompleted,
  rewardData = null
) {
  let { progressConfig = null } = rewardData
  let background = progressConfig?.background
  let progressObj = background
    ? (hasStageReward ? mkBackgroundWithGlareAnimation(background) : background)
    : hasStageReward ? completedProgressLine(1, glareAnimation(3))
    : hasStageCompleted ? acquiredProgressLine(1)
    : null

  let isToday = (idx + pastDays == todayStage - 1)
  let isTomorrow = (idx + pastDays == todayStage)

  let progressText = isToday ? loc("today")
    : isTomorrow ? loc("tomorrow")
    : loc("dayWithNumber", { number = pastDays + idx + 1 })

  return dayProgressBar(progressObj, mkProgressText(progressText, progressConfig?.textColor))
}

let rewardBlinkAnim = [{
  prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], play = true,
  duration = 1.5, loop = true, easing = CosineFull
}]

let emptyStageCard = {
  size = [rewardWidth, rewardWidth]
  padding = wndPadding / 2
  children = {
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = FLEX
  }
}

let mkStageCard = @(rewardsData, hasReward, hasStageCompleted) {
  size = [rewardWidth, rewardWidth]
  clipChildren = true
  padding = wndPadding / 2
  skipDirPadNav = false
  children = {
    size = FLEX
    children = [
      rewardsData[0]?.background
      {
        rendObj = ROBJ_BOX
        size = FLEX
        borderWidth = hdpx(1)
        borderColor = hasReward
          ? wndParams.rewardColor
          : wndParams.baseColor
      }
      hasReward
        ? mkImage(rewardsData[0]?.rewardGlow ?? "ui/gameImage/enlisted_box_glow_small.avif", {
            keepAspect = KEEP_ASPECT_FIT
            transform = true
            animations = rewardBlinkAnim
          })
        : null
      mkStageCardView(rewardsData, hasStageCompleted)
    ]
  }
}

let mkDailyReward = @(progressBar, stageCard) {
  flow = FLOW_VERTICAL
  gap = wndPadding
  children = [
    progressBar
    stageCard
  ]
}

let mkDailyBigReward = @(progressBar, stageCard) {
  flow = FLOW_VERTICAL
  gap = wndPadding
  children = [
    {
      flow = FLOW_HORIZONTAL
      children = [
        bigRewardSeparatorArrows
        progressBar
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      children = [
        bigRewardSeparatorBoxes
        stageCard
      ]
    }
  ]
}

function getDisplayIndex(lastStage, stage) { 
  if (lastStage == 0 || stage <= lastStage)
    return stage
  let s = stage % lastStage
  return s == 0 ? lastStage : s
}

function mkDailyRewardsContent() {
  let watch = [dailyRewardsUnlock, curArmy, crateContentWatch, itemMapping]
  let unlock = dailyRewardsUnlock.get()
  if (unlock == null)
    return { watch }

  let {
    stage = 0, lastRewardedStage = 0, hasReward = false, stages = [], current = 0
  } = unlock

  let totalStages = stages.len()
  let passCycles = totalStages > 0 ? lastRewardedStage / totalStages : 0
  let pastDays = passCycles * totalStages
  let activeStage = getDisplayIndex(totalStages, stage)
  let rewardStage = clamp(activeStage + (lastRewardedStage - stage), 0, totalStages)
  local startStage = totalStages <= REWARDS_IN_LINE ? 0
    : hasReward ? rewardStage - 1
    : activeStage - 2
  startStage = clamp(startStage, 0, totalStages - REWARDS_IN_LINE)

  let isLastVisible = (startStage + REWARDS_IN_LINE == totalStages)
  let chunk = isLastVisible
    ? stages.slice(startStage, startStage + REWARDS_IN_LINE)
    : stages.slice(startStage, startStage + REWARDS_IN_LINE - 1).append(stages.top())

  let rewardsItems = itemMapping.get()
  let curArmyId = curArmy.get()
  let crateContent = crateContentWatch.get()
  return {
    watch
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    padding = const [sh(4), wndPadding, 0, wndPadding]
    clipChildren = true
    children = chunk.map(function(stageData, idx) {
      let hasStageReward = idx + startStage == rewardStage && hasReward
      let hasStageCompleted = hasReward
        ? idx + startStage < rewardStage
        : idx + startStage < activeStage

      local rewardData = null
      local stageCard = emptyStageCard
      if (stageData?.rewards) {
        let rewardsCfg = calcRewardCfg(stageData, rewardsItems, crateContent)
        let { rewardCrate, rewardsData } = rewardsCfg
        stageCard = withTooltip(mkStageCard(rewardsData, hasStageReward, hasStageCompleted),
          @() mkToolTip(rewardCrate, rewardsData))

        rewardData = rewardsData[0]
      }
      else if (stageData?.rewardsBoosters) {
        let uBoosterId = stageData.rewardsBoosters.keys()?[0]
        let uBoostersPres = rewardsItems?[uBoosterId]
        let bName = uBoostersPres?.name
        stageCard = withTooltip(mkStageCard([uBoostersPres], hasStageReward, hasStageCompleted),
          @() mkBoosterToolTip(bName, stageData.rewardsBoosters, rewardsItems, curArmyId))

        rewardData = uBoostersPres
      }

      let isLastInLine = (idx == REWARDS_IN_LINE - 1)
      let index = isLastInLine ? totalStages - 1 : idx + startStage
      let progBar = mkProgressBar(index, current, pastDays,
        hasStageReward, hasStageCompleted, rewardData)

      let mkReward = (!isLastVisible && isLastInLine) ? mkDailyBigReward : mkDailyReward
      return mkReward(progBar, stageCard).__update({
          transform = true
          animations = mkMoveDownAnim(SHOW_WND_DELAY + idx * SHOW_STAGE_DELAY)
        })
    })
  }
}

let dailyRewardsHeader = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    mkHeaderFlag({
      rendObj = ROBJ_TEXT
      text = loc("dailyRewards/header")
      padding = const [sh(1.5), sh(9), sh(1.5), sh(3)]
    }.__update(fontTitle),
    casualFlagStyle)
    noteTextArea({
      text = loc("dailyRewards/desc")
      size = const [pw(40), SIZE_TO_CONTENT]
      margin = const [0,sh(2),0,0]
      color = titleTxtColor
      hplace = ALIGN_RIGHT
    }).__update(fontHeading2)
  ]
}

let btnParams = {
  size = [SIZE_TO_CONTENT, btnSize[1]]
  minWidth = btnSize[0]
}

let busyBtn = btnParams.__merge({ children = waitingSpinner })

function skipRewardAnimCb() {
  anim_skip(animTrigger)
  anim_skip(HIDE_TASK_BOOST)
  anim_start(SHOW_TASK_BOOST)
  hasRewardsAnim.set(false)
}

let hotkeyB = { hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true } }]] }

let mkButton = @(receivedData) function() {
  let rData = receivedData.get()
  let { hasReward = false } = dailyRewardsUnlock.get()
  return {
    watch = [isReceiveDayRewardInProgress, receivedData, dailyRewardsUnlock, hasRewardsAnim]
    size = const [SIZE_TO_CONTENT, sh(7)]
    hplace = ALIGN_CENTER
    padding = wndPadding
    gap = smallPadding
    flow = FLOW_HORIZONTAL
    children = [
      isReceiveDayRewardInProgress.get() ? busyBtn
        : hasRewardsAnim.get() ? Regular(loc("Skip"), skipRewardAnimCb,
            btnParams.__merge(hotkeyB))
        : hasReward ? Primary(loc("bp/getNextReward"), @() receiveDayReward(rData),
            btnParams.__merge({ hotkeys = [[$"^{JB.A} | Esc | Enter | Space"]] }))
        : null
      Regular(loc("Close"),
        @() gotoNextStageOrClose(rData, hasReward),
        btnParams.__merge(hotkeyB))
    ]
  }
}

function mkRollReward(cratesContent, reward, numReceived, idx, onEnter, onFinish) {
  let rollCount = ROLL_CARD_COUNT + idx * ROLL_ADD_COUNT
  let rollDuration = rollCount.tofloat() / ROLL_SPEED

  let rollItems = [reward.__merge({ count = numReceived })]
  for (local i = 0; i < rollCount; i++)
    rollItems.append(cratesContent[rand() % cratesContent.len()])
  let key = $"anim_{reward?.itemTemplate}"

  return function() {
    let itemsMapping = itemMapping.get()
    return {
      key
      watch = itemMapping
      flow = FLOW_VERTICAL
      children = rollItems.map(function(item) {
        let { itemTemplate = null, count = 1 } = item
        let presentation = itemsMapping?[itemTemplate]
        return presentation == null
          ? mkRewardCardByTemplate(itemTemplate)
          : mkRewardCardByPresentation(presentation, count)
      })
      transform = true
      animations = mkRollAnim(rollDuration,
        -sizeCard[1] * (rollCount + 1),
        onEnter,
        onFinish,
        "ui/daily_rewards_end")
    }
  }
}

let rewardBg = {
  size = FLEX
  clipChildren = true
  children = mkImage("ui/gameImage/enlisted_box_glow_small.avif", {
    size = const [pw(160), ph(160)]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  })
}

function mkCrateReward(idx, reward, cratesContent, onEnter, onFinish) {
  let { itemTemplate = null, sClass = null, count = 1 } = reward
  let itemData = cratesContent.findvalue(@(v)
    v?.itemTemplate == itemTemplate || v?.itemTemplate == sClass)
  if (itemData == null)
    return null

  let itemTooltip = tooltipCtor(function() {
    let { name = "" } = itemMapping.get()?[itemTemplate]
    let isBooster = itemTemplate in boostersConfig.get()
    return {
      watch = [hasRewardsAnim, boostersConfig, itemMapping]
      children = txt(hasRewardsAnim.get() ? loc("definingReward")
        : isBooster ? boosterName({ template = boostersConfig.get()?[itemTemplate] })
        : name != "" ? loc(name)
        : sClass != null ? loc("rewardSoldierTitle", { name = loc(getClassCfg(sClass).locId) })
        : null)
    }
  })

  return {
    rendObj = ROBJ_BOX
    padding = hdpx(1)
    borderColor = wndParams.rewardColor
    children = {
      size = sizeCard
      clipChildren = true
      children = [
        rewardBg
        mkRollReward(cratesContent, itemData, count, idx, onEnter, onFinish)
        withTooltip({
          size = FLEX
          skipDirPadNav = false
        }, @() itemTooltip)
      ]
    }
  }
}

function mkRewards(receivedRewards) {
  let { cratesContent, crateItemsData = {} } = receivedRewards
  let cratesItemsTotal = crateItemsData.len()

  let res = []
  foreach (idx, reward in crateItemsData) {
    let onEnter = idx == 0 ? @() hasRewardsAnim.set(true) : null
    let onFinish = idx + 1 >= cratesItemsTotal
      ? function() {
          hasRewardsAnim.set(false)
          anim_skip(HIDE_TASK_BOOST)
          anim_start(SHOW_TASK_BOOST)
        }
      : null
    res.append(mkCrateReward(idx, reward, cratesContent, onEnter, onFinish))
  }

  return res
}

let mkAppearAnimations = @() [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = 10, play = true,
    trigger = HIDE_TASK_BOOST, easing = InOutCubic }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4,
    trigger = SHOW_TASK_BOOST, easing = InOutCubic }
  { prop = AnimProp.scale, from = [4,4], to = [1,1], duration = 0.8,
    trigger = SHOW_TASK_BOOST, easing = InOutCubic }
  { prop = AnimProp.translate, from = [hdpx(70), -hdpx(100)], to = [0,0],
    duration = 0.8, trigger = SHOW_TASK_BOOST, easing = OutQuart }
]

let mkRewardsWithTask = @(receivedRewards) {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = smallOffset
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      children = mkRewards(receivedRewards)
    }
    faComp("arrow-circle-right", {
      fontSize = hdpx(30)
      color = titleTxtColor
    })
    {
      rendObj = ROBJ_SOLID
      flow = FLOW_VERTICAL
      padding = midPadding
      color = defBgColor
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("unlockBoosterTitle")
          padding = midPadding
          hplace = ALIGN_CENTER
          color = titleTxtColor
        }.__update(fontSub)
        mkUnlockSlot({
          task = receivedRewards.boosteredTask
          rewardsAnim = mkAppearAnimations()
        })
      ]
    }
  ]
}

let mkDailyRewardsAnimation = @(receivedData) function() {
  let received = receivedData.get()
  let { boosteredTask = null } = received
  return {
    watch = receivedData
    size = const [FLEX, sh(25)]
    flow = FLOW_HORIZONTAL
    gap = wndPadding
    padding = wndPadding
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = received == null ? null
      : boosteredTask == null ? mkRewards(received)
      : mkRewardsWithTask(received)
  }
}

let mkDailyRewardsHeader = @(receivedData)
  @() {
    watch = receivedData
    size = const [FLEX, sh(6)]
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    children = receivedData.get() == null ? null
      : {
          rendObj = ROBJ_TEXT
          text = loc("youHaveReceived")
          transform = true
          animations = mkAppearAnim(0, null, "ui/daily_rewards_roll")
        }.__update(fontHeading1)
  }

function mkDailyRewards() {
  let receivedData = Computed(function() {
    let allCratesContent = crateContentWatch.get()
    let unlock = dailyRewardsUnlock.get()
    let itemsMapping = itemMapping.get()

    return getReceivedItems(unlock,
      curBoosteredDailyTask.get(),
      unseenReward.get(),
      itemsMapping,
      allCratesContent)
  })

  return {
    rendObj = ROBJ_SOLID
    size = [wndWidth, SIZE_TO_CONTENT]
    color = Color(9, 14, 25)
    children = [
      mkImage("ui/gameImage/daily_rewards_bg.avif", { keepAspect = KEEP_ASPECT_FIT })
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        children = [
          mkDailyRewardsHeader(receivedData)
          mkDailyRewardsAnimation(receivedData)
          dailyRewardsHeader
          mkDailyRewardsContent
          mkButton(receivedData)
        ]
        transform = true
        animations = mkMoveDownAnim()
      }
    ]
  }
}

console_register_command(@() needOpenDailyRewards.set(true), "ui.openDailyRewards")

let needOpenWindow = registerWnd({
  dataWatch = needOpenDailyRewards
  showWatch = canShowRewards
  closeWatch = autoClose
  name = Wnd.DAILY
  handlers = {
    [WndEvents.SUPPRESS] = @()
      receiveDayReward({ boosteredTask = curBoosteredDailyTask.get() })
  }
})

needOpenWindow.subscribe(function(v) {
  if (!v) {
    removeModalWindow(WND_UID)
    return
  }

  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    onClick = @() null
    children = mkDailyRewards()
  })
})

