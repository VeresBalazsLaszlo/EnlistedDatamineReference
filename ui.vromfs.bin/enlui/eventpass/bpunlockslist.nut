import "%ui/items/itemsMapping.nut" as itemsMapping
from "%ui/style/designConst.nut" import midPadding, bigPadding, activeTxtColor, defTxtColor
from "%ui/components/mkProgressBar.nut" import progressBarHeight
from "%ui/eventPass/eventPassPkg.nut" import eventCardPremiumIcon, mkSmallCard
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/state/safeArea.nut" import safeAreaSize
from "%ui/eventPass/eventTaskRewardsState.nut" import premiumStage0Unlock
from "%ui/soldiers/model/boosters.nut" import boostersConfig
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/cratesContent.nut" import crateContentWatch
from "%ui/eventPass/eventPassState.nut" import nextUnlock
from "%ui/eventPass/eventPassWindowState.nut" import curRewardItem, combinedRewards, curItemUpdate
from "%ui/battlepass/rewardsPkg.nut" import prepareRewards
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/battlepass/bpPkg.nut" import sizeCard, mkCard, gapCards, mkCardProgressBar
from "%ui/ui_library.nut" import *

let hugePadding = midPadding * 4
let tblScrollHandler = ScrollHandler()

const cardInfoIconSize = hdpxi(22)

function scrollToCurrent() {
  let cardIdx = (curRewardItem.get()?.stageIdx ?? "0").tointeger()
    + (premiumStage0Unlock.get()?.stages[0].rewards.len() ?? 0)
  tblScrollHandler.scrollToX((sizeCard[0] + gapCards) * (cardIdx + 0.5) - gapCards
    - safeAreaSize.get()[0] / 2)
}

nextUnlock.subscribe(function(_) {
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
              @() curRewardItem.set({ reward = r.reward, stage0idx = idx }),
              Computed(@() curRewardItem.get()?.stage0idx == idx),
              isFinished, true, false, null, eventCardPremiumIcon))
        }
        {
          size = [FLEX, progressBarHeight]
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = {
            rendObj = ROBJ_TEXT
            color = activeTxtColor
            text = loc("eventPass/elitePassRewards")
          }
        }
      ]
    }
  ].extend(combinedRewards.get().map(function(r) {
    let { reward, count, stageIdx, isReceived, isPremium, isLooped } = r
    return mkCard(reward, count, boostersConfigVal, @() curRewardItem.set({ reward, stageIdx }),
      Computed(@() curRewardItem.get()?.stageIdx == stageIdx), isReceived, isPremium, isLooped,
      mkCardProgressBar(r),
      eventCardPremiumIcon
    )
  }))

  return {
    watch = [combinedRewards, premiumStage0Unlock, itemsMapping, boostersConfig]
    flow = FLOW_HORIZONTAL
    gap = gapCards
    children
  }
}

let mkInfoIcon = @(color) {
  rendObj = ROBJ_IMAGE
  size = const [cardInfoIconSize, cardInfoIconSize]
  color
  hplace = ALIGN_RIGHT
  margin = const [bigPadding, bigPadding * 3]
  image = Picture("ui/skin#info/info_icon.svg:{0}:{0}:K".subst(cardInfoIconSize))
}

function eventCardsList() {
  let armies = curArmiesList.get()
  let crateContent = crateContentWatch.get()
  let templates = allItemTemplates.get()
  let boostersConfigVal = boostersConfig.get()
  let { infoIconColor = defTxtColor } = bpEventSettings.get()
  let infoIcon = mkInfoIcon(infoIconColor)

  return {
    watch = [combinedRewards, boostersConfig, allItemTemplates, curArmiesList, crateContentWatch,
      bpEventSettings]
    flow = FLOW_HORIZONTAL
    gap = gapCards
    children = combinedRewards.get().map(@(r)
      mkSmallCard(r, armies, crateContent, templates, boostersConfigVal,
        mkCardProgressBar(r), infoIcon)
    )
  }
}


let mkUlocksList = @(list) @() {
  size = FLEX_H
  valign = ALIGN_BOTTOM
  watch = safeAreaSize
  xmbNode = XmbContainer({
    canFocus = false
    scrollSpeed = 5.0
    isViewport = true
  })

  children = makeHorizScroll({
    padding = [hugePadding, 0]
    children = list
    onAttach = scrollToCurrent
  }, {
    size = FLEX_H
    maxWidth = safeAreaSize.get()[0]
    scrollHandler = tblScrollHandler
    rootBase = {
      key = "eventUnlocksRoot"
      behavior = Behaviors.Pannable
      wheelStep = 0.82
    }
  })
}

return {
  bpUnlocksList = mkUlocksList(cardsList)
  eventRewardsList = mkUlocksList(eventCardsList)
}
