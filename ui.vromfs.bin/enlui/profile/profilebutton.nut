import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/profile/profileScene.nut" as profileScene
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/style/cursors.nut" import setTooltip
from "%ui/profile/unseenProfileState.nut" import hasUnseenDecorators, hasUnseenMedals, hasUnseenWallposters, hasUnopenedDecorators, hasUnopenedMedals, hasUnopenedWallposters
from "%ui/unlocks/taskListState.nut" import hasAchievementsReward
from "%ui/profile/decoratorState.nut" import chosenNickFrame, chosenPortrait
from "%ui/components/decoratorsPresentation.nut" import frameNick, getPortrait
from "%ui/style/designConst.nut" import midPadding, titleTxtColor, darkTxtColor, panelBgColor, bigPadding, hoverSlotBgColor
from "%ui/profile/decoratorPkg.nut" import mkPortraitIcon
from "%ui/components/rankPresentation.nut" import mkRankImage, getRankConfig
from "%ui/profile/rankState.nut" import playerRank
from "%ui/currency/premiumComp.nut" import premiumBtnSize
from "%ui/components/unseenComponents.nut" import blinkUnseen, unblinkUnseen
from "%ui/unlocks/unseenUnlocksState.nut" import hasUnopenedAchievements, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
from "%ui/ui_library.nut" import *

const portraitWidth = hdpxi(62)
let squareBlockSize= [portraitWidth, portraitWidth]
const maxNicknameWidth = hdpxi(180)


let hasUnseenElements = Computed(@() hasUnseenDecorators.get()
  || hasUnseenMedals.get()
  || hasUnseenWallposters.get()
  || hasAchievementsReward.get()
  || hasUnseenWeeklyTasks.get())

let hasUnopenedElements = Computed(@() hasUnopenedDecorators.get()
  || hasUnopenedMedals.get()
  || hasUnopenedWallposters.get()
  || hasUnopenedAchievements.get()
  || hasUnopenedWeeklyTasks.get())


let playerRankBlock = @(sf) @() {
  watch = playerRank
  rendObj = ROBJ_SOLID
  size = squareBlockSize
  color = sf & S_HOVER ? hoverSlotBgColor : panelBgColor
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkRankImage(playerRank.get()?.rank)
}


let playerPortrait = @() {
  watch = [hasUnseenElements, hasUnopenedElements, chosenPortrait]
  size = squareBlockSize
  children = [
    mkPortraitIcon(getPortrait(chosenPortrait.get()?.guid), portraitWidth)
    {
      pos = [0, midPadding]
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      children = !hasUnseenElements.get() ? null
        : hasUnopenedElements.get() ? blinkUnseen
        : unblinkUnseen
    }
  ]
}

let nickNameBlock = @(sf, group) function() {
  let { rank = 0 } = playerRank.get()
  let curRank = rank == 0 ? null : getRankConfig(rank)
  let pNick = userInfo.get()?.nameorig ?? ""
  let nickFrame = chosenNickFrame.get()?.guid
  return {
    watch = [playerRank, chosenNickFrame, userInfo]
    size = FLEX_V
    padding = [0, bigPadding]
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        delay = 0.5
        speed = 60
        scrollOnHover = true
        group
        maxWidth = maxNicknameWidth
        text = frameNick(pNick, nickFrame)
        vplace = ALIGN_CENTER
        color = sf & S_HOVER ? darkTxtColor : titleTxtColor
      }.__update(fontBody)
      curRank == null ? null : {
        rendObj = ROBJ_TEXT
        text = loc(curRank.locId)
        color = sf & S_HOVER ? darkTxtColor : titleTxtColor
      }.__update(fontSub)
    ]
  }
}


let profileButtonUi = watchElemState(function(sf) {
  let group = ElemGroup()
  return {
    rendObj = ROBJ_SOLID
    behavior = Behaviors.Button
    size = [SIZE_TO_CONTENT, premiumBtnSize]
    flow = FLOW_HORIZONTAL
    color = sf & S_HOVER ? hoverSlotBgColor : panelBgColor
    onHover = @(on) setTooltip(on ? loc("btn/openProfile") : null)
    onClick = profileScene
    group
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
      active = "ui/enlist/button_action"
    }
    children = [
      playerPortrait
      nickNameBlock(sf, group)
      playerRankBlock(sf)
    ]
  }
})

return profileButtonUi
