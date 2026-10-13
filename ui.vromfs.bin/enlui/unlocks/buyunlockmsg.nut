import "%ui/items/itemsMapping.nut" as rewardsItemsMapping
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import defTxtColor, activeTxtColor
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/unlocks/taskRewardsState.nut" import doBuyUnlock, unlockPrices
from "%ui/battlepass/rewardsPkg.nut" import mkRewardImages, prepareRewards, mkRewardTooltip
from "%ui/battlepass/bpPkg.nut" import cardCountCircle, imageSize, gapCards
from "%ui/style/cursors.nut" import withTooltip
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/meta/profile.nut" import commonArmy
from "%ui/ui_library.nut" import *

let mkRewardsCards = @(rewards) {
  flow = FLOW_HORIZONTAL
  margin = const [fsh(2), 0, fsh(2), 0]
  gap = gapCards
  children = rewards.map(function(rewardData) {
    let { count, reward } = rewardData
    return {
      children = [
        withTooltip(mkRewardImages(reward, imageSize), @() mkRewardTooltip(reward))
        cardCountCircle(count)
      ]
    }
  })
}

function mkRewardName(reward, otherArmy) {
  let armyName = loc($"{reward?.armyId ?? commonArmy.get()}/full")
  return otherArmy
    ? $"{armyName}: {loc(reward.name)}"
    : loc(reward.name)
}

function mkRewardsView(task) {
  let { lastRewardedStage, stages } = task
  let { rewards = null } = stages?[lastRewardedStage]

  if (rewards == null)
    return null

  return function() {
    let countAll = rewards.len()
    let possibleArmies = ["", curArmy.get(), commonArmy.get()]
    let viewRewards = prepareRewards(rewards, rewardsItemsMapping.get())
      .filter(@(r) r != null)
    let rewardsForArmy = viewRewards
      .filter(@(r) possibleArmies.contains(r?.reward.armyId ?? "") )

    local otherArmy = false
    local countForArmy = rewardsForArmy.len()
    if (countForArmy == 0) {
      otherArmy = true
      countForArmy = 1
      rewardsForArmy.append(viewRewards[0])
    }

    let otherArmiesTxt = countForArmy == countAll ? null : {
      size = FLEX_H
      halign = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = loc("unlocks/eventMoreRewards", { count = countAll - countForArmy })
      color = activeTxtColor
    }.__update(fontBody)

    let children = []
    let { name = "" } = task?.localization
    if (name != "")
      children.append({
        rendObj = ROBJ_TEXT
        text = name
        color = defTxtColor
      }.__update(fontSub))

    let cards = mkRewardsCards(rewardsForArmy)
    children.append(cards)

    if (countForArmy == 1) {
      let mainReward = rewardsForArmy[0].reward
      if ("name" in mainReward)
        children.append({
          rendObj = ROBJ_TEXT
          text = mkRewardName(mainReward, otherArmy)
          color = activeTxtColor
        }.__update(fontBody))
      children.append(otherArmiesTxt)

      if ("description" in mainReward)
        children.append({
          size = FLEX_H
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc(mainReward.description)
          color = defTxtColor
        }.__update(fontSub))
    } else {
      children.append(otherArmiesTxt)
    }

    return {
      watch = [rewardsItemsMapping, curArmy, commonArmy]
      size = FLEX_H
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children
    }
  }
}

function buyUnlockMsg(task) {
  let { currency = "", price = 0 } = unlockPrices.get()?[task.name]
  if (price <= 0 || currency == "")
    return

  purchaseMsgBox({
    price
    currencyId = currency
    title = loc("unlocks/buyNextEventTask")
    productView = mkRewardsView(task)
    purchase = @() doBuyUnlock(task.name)
    alwaysShowCancel = true
    srcComponent = "buy_next_event_unlock"
  })
}

return buyUnlockMsg