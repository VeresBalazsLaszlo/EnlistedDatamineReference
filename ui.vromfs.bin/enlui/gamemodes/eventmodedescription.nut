import "%ui/items/itemsMapping.nut" as rewardsItemMapping
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/unlocks/buyUnlockMsg.nut" as buyUnlockMsg
import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/gameModes/eventModesState.nut" import selEvent, selLbMode, selEventEndTime, inactiveEventsToShow
from "%ui/gameModes/eventModeStyle.nut" import verticalGap, localPadding, localGap,
  armieChooseBlockWidth, eventBlockWidth
from "%ui/style/designConst.nut" import brightAccentColor, startBtnWidth, mkTimerIcon, midPadding,
  isWide, defTxtColor, smallPadding, maxContentWidth, accentTitleTxtColor
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/battlepass/rewardsPkg.nut" import mkRewardImages, mkRewardTooltip, rewardWidthToHeight,
  mkSeasonTimeWithText, mkRewardText
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/components/textButton.nut" import Regular, Purchase
from "%ui/components/openUrl.nut" import openUrl
from "%ui/gameModes/eventRewardsState.nut" import eventRewardsUnlocks, lbRewards, lbRewardsTypes
from "%ui/style/cursors.nut" import withTooltip
from "%ui/battlepass/bpPkg.nut" import cardCountCircleSmall
from "%ui/gameModes/eventModesPkg.nut" import mkWindowHeader
from "%ui/profile/medalsPkg.nut" import mkMedalCard
from "%ui/leaderboard/lbState.nut" import curLbIdx
from "%ui/profile/decoratorState.nut" import availPortraits, availNickFrames
from "%ui/meta/servProfile.nut" import medals
from "%ui/eventPass/gameModesDescription.nut" import mkEventConsumables, eventPassWdiget,
  eventWithStages
from "%ui/eventPass/eventTaskRewardsState.nut" import dailyEventUnlock
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings, needShowPass
from "%ui/ui_library.nut" import *
from "math" import min


const REWARDS_IN_ROW = 3

let sizeCard    = [hdpx(138), hdpx(138)]
const imageHeight = hdpx(138)
let imageSize   = [rewardWidthToHeight * imageHeight, imageHeight]
let eventPassWidth = const hdpxi(400)

let descriptionBlockWidth = Computed(@()
  min(sw(100) - safeAreaBorders.get()[1] - safeAreaBorders.get()[3], maxContentWidth)
  - armieChooseBlockWidth - startBtnWidth - eventBlockWidth - midPadding * 3 - localPadding * 2)
let isEnded = Computed(@() inactiveEventsToShow.get().contains(selEvent.get()) &&
  (selEvent.get()?.leaderboardTableIdx ?? curLbIdx.get()) < curLbIdx.get() )
let isLeaderboardVisible = Computed(@() selEvent.get()?.isLeaderboardVisible ?? false)

let participationRewards = Computed(function() {
  let unlocks = []
  let lbRew = clone lbRewards.get()
  let localization = {
    description = "events/endGiven"
  }
  let currentEvent = selLbMode.get()
  lbRew?[currentEvent].each(@(val) val.stages.each(function(v) {
    if (v.progress == 100) {
      val.localization <- localization
      unlocks.append(val)
    }
  }))
  if (unlocks.len() == 0)
    return {}
  return { [currentEvent] = unlocks }
})

let shadowParams = {
  fontFx = FFT_BLUR
  fontFxColor = Color(0,0,0,50)
  fontFxFactor = min(64, hdpx(64))
  fontFxOffsY = hdpx(0.9)
}

function mkEventsTimer() {
  let needShowTimer = Computed(@() !isEnded.get() && selEventEndTime.get() - serverTime.get() > 0)
  return @() {
    watch = needShowTimer
    children = !needShowTimer.get() ? null
      : mkSeasonTimeWithText(selEventEndTime, { padding = midPadding },
        { color = accentTitleTxtColor }.__update(fontSub, shadowParams), shadowParams)
  }
}

let infoBlock = @() {
  rendObj = ROBJ_TEXTAREA
  watch = selEvent
  size = FLEX_H
  margin = isWide ? [0, hdpx(100),0,0] : 0
  behavior = Behaviors.TextArea
  text = selEvent.get()?.description
}

let completedRewardSign = {
  size = hdpx(28)
  pos = const [0, -hdpx(28)]
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  fillColor = Color(0,0,0)
  hplace = ALIGN_CENTER
  children = faComp("check", { fontSize = hdpx(15) })
}

let completedRewardSignBottom = completedRewardSign.__merge({
  pos = const [0, hdpx(9)]
  vplace = ALIGN_BOTTOM
})

let mkRewardTitle = @(text, isCompleted) {
  children = [
    isCompleted ? completedRewardSign : null
    {
      size = [sizeCard[0], SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text
    }
  ]
}

let mkRewardsBlockTitle = @(text) {
  rendObj = ROBJ_TEXT
  halign = ALIGN_CENTER
  text
}.__update(fontBody)

function temporarySign() {
  let size = hdpxi(24)
  return{
    rendObj = ROBJ_IMAGE
    size = [size, size]
    color = Color(0,0,0)
    image = Picture($"!ui/uiskin/battlepass/Ellipse.svg:{size}:{size}:K")
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    margin = smallPadding
    children = mkTimerIcon(size, { color = accentTitleTxtColor })
  }
}

let extraRewardText = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_LEFT
  text = loc("includingRewardsBelow")
  color = defTxtColor
}.__update(fontSub)

function mkReward(rewardData) {
  let { count, reward, hasReceived } = rewardData
  local rewardToShow = mkRewardImages(reward, imageSize)
    ?? mkRewardText(reward, hdpx(60), {size = sizeCard})
  if (rewardData.reward?.stackImages != null) {
    let r = rewardData.reward
    rewardToShow = mkMedalCard(r.bgImage, r.stackImages, hdpx(138))
  }
  return {
    size = sizeCard
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      withTooltip(rewardToShow, @() mkRewardTooltip(reward))
      hasReceived ? completedRewardSignBottom : null
      count > 1 ? cardCountCircleSmall(count) : null
      reward?.isTemporary ? temporarySign : null
    ]
  }
}

let mkProgress = @(current, required, _stageProg) required <= 1 || current == required
  ? null
  : {
      rendObj = ROBJ_TEXT
      text = $"{current} / {required}"
      color = accentTitleTxtColor
    }.__update(fontSub)

let rewardsWrapParams = {
  width = descriptionBlockWidth.get()
  vGap = localGap
  hGap = localGap
}


function prepareRewards(rewards, itemsMappingVal,
    availPortraitsVal, medalsVal, availNickFramesVal) {
  let list = []
  foreach (key, count in rewards) {
    if (count <= 0)
      continue

    let reward = itemsMappingVal?[key]
    if (reward == null)
      continue

    local specialItemGuid = reward?.medals[0]
    local hasReceived = specialItemGuid != null
      && medalsVal.findindex(@(v) v.id == specialItemGuid) != null

    if (!hasReceived) {
      specialItemGuid = reward?.decorators[0].guid
      hasReceived = specialItemGuid != null
        && (specialItemGuid in availNickFramesVal
          || specialItemGuid in availPortraitsVal)
    }

    let { itemCount = 1 } = reward
    list.append({ reward, count = count * itemCount, hasReceived })
  }
  return list
}

function mkTasksBlock(
  unlocks, rewardType = null, mkChild = @(_) null, rewardExtraObj = null, isLastType = false,
  mkProgressFn = mkProgress
) {
  unlocks = unlocks ?? []
  if (unlocks.len() == 0)
    return null

  if (rewardType == null)
    unlocks = clone unlocks
      .map(@(v) v.__merge({ maxProgress =
        v.stages.reduce(@(res, val) val.progress > res ? val.progress : res, 0) }))
      .sort(@(a, b) a.maxProgress <=> b.maxProgress)

  return function() {
    let watch = [descriptionBlockWidth, rewardsItemMapping, participationRewards,
      availPortraits, medals, availNickFrames]

    let rewardsChildren = []
    foreach (uIdx, unlock in unlocks) {
      let { name, stages = [], current = 0, required = 0, isCompleted = false } = unlock
      let totalStages = stages.len()
      foreach (sIdx, stage in stages) {
        let { progress = 1, currencyCode = "", price = 0 } = stage
        if ((rewardType != null && name != rewardType) || (rewardType != null && progress == 100))
          continue

        let curUnlock = unlock
        let isPurchasable = !isCompleted && price > 0 && currencyCode != ""

        let isLast = isLastType && uIdx == unlocks.len() - 1 - participationRewards.get().len()
          && sIdx == totalStages - 1
        let rewardCards = prepareRewards(stage?.rewards ?? {}, rewardsItemMapping.get(),
            availPortraits.get(), medals.get(), availNickFrames.get())
          .sort(@(a,b) (b?.reward.medals.len() ?? 0) <=> (a?.reward.medals.len() ?? 0)
            || (a?.reward.cardText ?? "") <=> (b?.reward.cardText ?? "")
            || (a?.reward.isTemporary ?? false) <=> (b?.reward.isTemporary ?? false))
          .map(mkReward)

        let isFitWidth = rewardCards.len() >= REWARDS_IN_ROW
        let size = isFitWidth ? FLEX_H : SIZE_TO_CONTENT
        let cardGap = isFitWidth ? { size = FLEX } : midPadding

        rewardsChildren.append({
          size
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          gap = midPadding
          children = [
            mkChild?(progress)
            {
              size
              flow = FLOW_HORIZONTAL
              halign = ALIGN_CENTER
              gap = cardGap
              children = rewardType != null
                ? wrap(rewardCards, rewardsWrapParams)
                : rewardCards
            }
            unlock?.localization.description != null
              ? mkRewardTitle(loc(unlock?.localization.description), isCompleted ?? false)
              : null
            isLast ? null : rewardExtraObj
            mkProgressFn(current, required, progress)
            isPurchasable ? Purchase(loc("bp/Purchase"), @() buyUnlockMsg(curUnlock)) : null
          ]
        })
      }
    }

    return {
      watch
      size = FLEX_H
      flow = rewardType == null ? FLOW_HORIZONTAL : FLOW_VERTICAL
      gap = rewardType == null ? localGap : verticalGap
      children = rewardsChildren
    }
  }
}

let eventsProgressChild = @(progress, rType) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_LEFT
  text = rType != "tillPercent" ? loc("events/getTop", {progress})
    : progress == 100 ? loc("events/participationReward")
    : $"{loc("events/getTop", {progress})}%"
}.__update(fontBody)


function rewardsBlock() {
  let lbTotal = lbRewardsTypes.len()
  return {
    size = FLEX_H
    watch = [participationRewards, eventRewardsUnlocks, lbRewards, selLbMode, isEnded]
    flow = FLOW_VERTICAL
    gap = localGap
    children = [
      isEnded.get() ? null : {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = localGap
        children = [
          participationRewards.get().len() > 0
              || (eventRewardsUnlocks.get()?[selLbMode.get()].len() ?? 0) > 0
            ? mkRewardsBlockTitle(loc("events/participationReward"))
            : null
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            gap = localGap
            children = [
              mkTasksBlock(participationRewards.get()?[selLbMode.get()])
              mkTasksBlock(eventRewardsUnlocks.get()?[selLbMode.get()])
            ]
          }
        ]
      }
    ].extend(lbRewardsTypes
      .map(@(rType, idx)
        mkTasksBlock(lbRewards.get()?[selLbMode.get()], rType,
          @(progress) eventsProgressChild(progress, rType),
          extraRewardText, idx == lbTotal - 1)
      ))
  }
}

let mkEventDailyProgress = @(current, _required, stageProg) {
  rendObj = ROBJ_TEXT
  text = "{0} / {1}".subst(min(current, stageProg), stageProg)
  color = accentTitleTxtColor
}.__update(fontSub)

function dailyEventRewards() {
  let watch = dailyEventUnlock
  if (dailyEventUnlock.get() == null)
    return { watch }

  return {
    size = FLEX_H
    watch
    flow = FLOW_VERTICAL
    gap = localGap
    children = [
      {
        rendObj = ROBJ_TEXT
        halign = ALIGN_CENTER
        text = loc("events/dailyRewards")
      }.__update(fontSub)
      mkTasksBlock([ dailyEventUnlock.get() ], null, @(_) null, null, false,
        mkEventDailyProgress)
    ]
  }
}

function eventPassBlock() {
  if (isEnded.get())
    return { watch = isEnded }

  if (bpEventSettings.get()?.isMarathonEvent ?? false)
    return {
      watch = [isEnded, bpEventSettings]
      size = FLEX_H
      children = eventWithStages
    }

  return {
    size = [eventPassWidth, SIZE_TO_CONTENT]
    watch = [participationRewards, eventRewardsUnlocks, selLbMode, isEnded, bpEventSettings]
    flow = FLOW_VERTICAL
    gap = localGap
    children = [
      mkRewardsBlockTitle(loc("events/participationReward"))
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = localGap
        children = [
          eventPassWdiget
          mkTasksBlock(participationRewards.get()?[selLbMode.get()])
          mkTasksBlock(eventRewardsUnlocks.get()?[selLbMode.get()])
        ]
      }
      dailyEventRewards
    ]
  }
}

function leaderBoardBlock() {
  let watch = [needShowPass, bpEventSettings, isLeaderboardVisible]
  let { getEventLbUrl = null } = bpEventSettings.get()
  if (!needShowPass.get() || !isLeaderboardVisible.get() || getEventLbUrl == null)
    return { watch }

  let eventWebsiteLink = Regular(loc("eventPass/goToSite"),
    @() openUrl(getEventLbUrl()))

  return {
    watch
    flow = FLOW_VERTICAL
    gap = localGap
    children = [
      mkRewardsBlockTitle(loc("Leaderboard"))
      eventWebsiteLink
    ]
  }
}

function eventModeDescription() {
  let watch = [descriptionBlockWidth, selEvent, needShowPass]
  if (selEvent.get() == null)
    return {
      watch
      rendObj = ROBJ_TEXT
      size = FLEX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      color = brightAccentColor
      text = loc("events/noEvents")
    }.__update(fontBody)

  let { title = null, image = null } = selEvent.get()
  let { imageEventHeader = image } = selEvent.get()?.queues[0].extraParams
  let width = descriptionBlockWidth.get()
  return {
    watch
    flow = FLOW_VERTICAL
    gap = midPadding
    size = [width, FLEX]
    children = [
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          mkWindowHeader(title, imageEventHeader)
          mkEventsTimer()
        ]
      }
      makeVertScroll({
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = localPadding
        children = [
          infoBlock
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            children = [
              needShowPass.get() ? eventPassBlock : rewardsBlock
              mkEventConsumables(width - eventPassWidth)
            ]
          }
          leaderBoardBlock
        ]
      })
    ]
  }
}

return eventModeDescription