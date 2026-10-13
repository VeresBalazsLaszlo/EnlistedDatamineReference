import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/battlepass/rewardsPkg.nut" import mkSeasonTimeWithText
from "%ui/battlepass/bpState.nut" import seasonEndTime
from "%ui/profile/rankState.nut" import playerRank, rankUnlock
from "%ui/components/textButton.nut" import FARegular
from "%ui/profile/profileState.nut" import isRanksInfoVisible
from "%ui/components/rankPresentation.nut" import mkRankIcon, getRankConfig
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/style/cursors.nut" import setTooltip
from "%ui/battlepass/bpPkg.nut" import mkLessRankAlert
from "%ui/style/designConst.nut" import bigPadding, smallOffset, bigOffset, accentTitleTxtColor, defTxtColor, blurBgFillColor, mainContentOffset
  , idleBgColor, rowBg, positiveTxtColor
from "%ui/components/tasksPkg.nut" import mkGetTaskRewardBtn
from "%ui/unlocks/taskListState.nut" import receiveTaskRewards
from "%ui/userstats/userstat.nut" import unlockRewardsInProgress
from "%ui/ui_library.nut" import *

const buttonSize = hdpxi(36)
const rewardIconSize = hdpxi(28)
const valueColumnSize = hdpx(70)
const infoColumnSize = hdpx(360)
const rankRowHeight = hdpx(60)

let infoPanelBgColor = rowBg(0, 0)

let completeIcon = faComp("check", {
  fontSize = rewardIconSize
  color = positiveTxtColor
  margin = [0, bigOffset]
})


let rewardImg = Picture($"!ui/uiskin/reward_player_icon.svg:{rewardIconSize}:{rewardIconSize}:K")


let ranksHeaderBlock = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = smallOffset
  padding = [bigPadding, bigOffset]
  rendObj = ROBJ_SOLID
  color = blurBgFillColor
  children = [
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = FLEX_H
          rendObj = ROBJ_TEXT
          text = loc("rank/title")
        }.__update(fontHeading2)
        FARegular("question", @() isRanksInfoVisible.set(!isRanksInfoVisible.get()), {
          btnWidth = buttonSize
          btnHeight = buttonSize
          hotkeys = [["^J:Start", { description = { skip = true }}]]
        })
      ]
    }
    {
      size = FLEX_H
      children = [
        mkSeasonTimeWithText(seasonEndTime, {}, fontBody, fontBody)
        mkLessRankAlert()
        {
          hplace = ALIGN_RIGHT
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          children = [
            {
              rendObj = ROBJ_TEXT
              hplace = ALIGN_RIGHT
              text = loc("rank/playerRating")
            }.__update(fontBody)
            @() {
              rendObj = ROBJ_TEXT
              watch = playerRank
              text = $"{(playerRank.get()?.rating ?? 0) / 100}"
              color = accentTitleTxtColor
            }.__update(fontBody)
          ]
        }
      ]
    }
  ]
}


let mkColumnText = @(text, width = SIZE_TO_CONTENT, override = {}) {
  size = [width, SIZE_TO_CONTENT]
  margin = [0, smallOffset]
  rendObj = ROBJ_TEXT
  text
}.__update(fontBody, override)


let mkTooltipText = @(text) {
  margin = [0, smallOffset]
  rendObj = ROBJ_TEXT
  text
}.__update(fontSub)


let mkRewardInfo = @(unlockName, isCompleted) {
  size = const [rewardIconSize, rewardIconSize]
  rendObj = ROBJ_IMAGE
  color = unlockName == null ? idleBgColor
    : isCompleted ? accentTitleTxtColor
    : defTxtColor
  image = rewardImg
  behavior = Behaviors.Button
  margin = [0, bigOffset]
  onHover = @(on) setTooltip(!on || unlockName == null ? null
    : tooltipCtor(mkTooltipText(loc($"rank/{unlockName}/info"))))
}


let mkStatus = @(isCompleted, hasReward, unlock) {
  size = FLEX
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    isCompleted ? completeIcon : null
    {
      size = [pw(50), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      children = hasReward
        ? mkGetTaskRewardBtn(unlock, receiveTaskRewards, unlockRewardsInProgress)
        : null
    }
  ]
}


function mkRankRow(rank, playerRating) {
  let { progress, ratingOnNextSeason, index, hasReward = false, unlock = null } = rank
  let nextSeasonPoints = ratingOnNextSeason > 0 ? ratingOnNextSeason.tostring() : ""
  let isCompleted = playerRating >= progress
  return {
    flow = FLOW_HORIZONTAL
    size = const [FLEX, rankRowHeight]
    gap = hdpx(10)
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = rowBg(0, index)
    children = [
      mkColumnText(index, valueColumnSize, { halign = ALIGN_RIGHT })
      {
        margin = [0, bigOffset]
        children = mkRankIcon(index)
      }
      mkColumnText(loc(getRankConfig(index).locId), infoColumnSize)
      {
        size = [valueColumnSize, SIZE_TO_CONTENT]
        behavior = Behaviors.Button
        onHover = @(on) setTooltip(!on ? null
          : tooltipCtor(mkTooltipText(loc("rank/needAchieve"))))
        children = mkColumnText(progress)
      }
      {
        size = [valueColumnSize, SIZE_TO_CONTENT]
        behavior = nextSeasonPoints == "" ? null : Behaviors.Button
        onHover = @(on) setTooltip(!on || nextSeasonPoints == "" ? null
          : tooltipCtor(mkTooltipText(loc("rank/nextSeasonPoints", {
              rating = nextSeasonPoints
            }))))
        children = mkColumnText(nextSeasonPoints)
      }
      mkRewardInfo(unlock?.name, isCompleted)
      mkStatus(isCompleted, hasReward, unlock)
    ]
  }
}


function ranksTableUi() {
  let watch = [ rankUnlock, playerRank ]
  if (rankUnlock.get() == null)
    return { watch }

  let playerRating = (playerRank.get()?.rating ?? 0) / 100
  return {
    watch
    size = FLEX
    children = makeVertScroll({
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(1)
      children = rankUnlock.get().map(@(rank) mkRankRow(rank, playerRating))
    }, {
      size = FLEX
      needReservePlace = false
      styling = thinStyle
      rootBase = {
        behavior = Behaviors.Pannable
        wheelStep = 1
      }
    })
  }
}


let ranksInfoBlock = @() {
  watch = isRanksInfoVisible
  size = FLEX
  margin = bigPadding
  children = isRanksInfoVisible.get()
    ? {
        size = FLEX
        margin = [bigOffset, mainContentOffset]
        padding = [0, mainContentOffset]
        valign = ALIGN_CENTER
        rendObj = ROBJ_SOLID
        color = infoPanelBgColor
        children = {
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          behavior = Behaviors.TextArea
          text = loc("rank/description")
        }.__update(fontBody)
      }
    : ranksTableUi
}


return {
  size = FLEX
  flow = FLOW_VERTICAL
  children = [
    ranksHeaderBlock
    ranksInfoBlock
  ]
}
