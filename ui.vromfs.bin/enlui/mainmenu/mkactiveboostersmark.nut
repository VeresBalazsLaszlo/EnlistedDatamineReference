import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/colorize.nut" as colorize
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/style/designConst.nut" import defTxtColor, activeTxtColor, msgHighlightedTxtColor
from "%ui/soldiers/model/boosters.nut" import allBoosters, showHintActivateBoosters, showHintExpiringBoosters, nextExpireTime, battleLeftCount
from "%ui/components/mkBoosterMark.nut" import mkBoostersEmpty, mkBoosterMark
from "%ui/helpers/time.nut" import secondsToHoursLoc, secondsToShortestloc
from "%ui/style/cursors.nut" import withTooltip, normalTooltipTop
from "%ui/ui_library.nut" import *
from "math" import round

let sumBoosters = Computed(function() {
  let res = { positive = 0.0, negative = 0.0 }
  foreach (boosterObj in allBoosters.get()) {
    if ((boosterObj.booster?.activeTs ?? 0) == 0)
      continue

    let { expMul } = boosterObj.template
    if (expMul > 0)
      res.positive += expMul
    else
      res.negative += expMul
  }
  return res
})

let percentSign = @(num) num > 0 ? $"+{round(num * 100.0)}" : round(num * 100.0)

let toPercentColored = @(v) colorize(msgHighlightedTxtColor, percentSign(v))

function mkBoosterInfoText(boosterObj, curTime) {
  let { booster, template } = boosterObj
  let { expireTs } = booster
  let leftBattles = battleLeftCount(boosterObj)

  let percent = toPercentColored(template.expMul)
  let limitsList = []
  if (expireTs > 0)
    limitsList.append(secondsToHoursLoc(max(0, expireTs - curTime)))
  if (leftBattles > 0)
    limitsList.append(loc("boostName/battlesLimit", { battles = leftBattles }))
  let limits = loc("boostName/limit", { limits = " / ".join(limitsList) })
  return loc("startBtn/boosterRow", { percent, limits })
}

let mkBlock = @(locId, percent, boosters, totalLocId, modifier, isDetailed) function() {
  let blockHeader = colorize(activeTxtColor, loc(locId, { percent }))
  let blockLines = boosters.map(@(b) mkBoosterInfoText(b, serverTime.get()))
  let lines = [blockHeader].extend(blockLines)
  if (isDetailed)
    lines.append(loc(totalLocId, { modifier }))

  return {
    rendObj = ROBJ_TEXTAREA
    watch = serverTime
    behavior = Behaviors.TextArea
    color = defTxtColor
    text = "\n".join(lines)
  }
}

let mkTooltip = @() tooltipCtor(function() {
  let bonuses = []
  let penalties = []
  foreach (boosterObj in allBoosters.get()) {
    if ((boosterObj.booster?.activeTs ?? 0) == 0)
      continue
    if (boosterObj.template.expMul > 0)
      bonuses.append(boosterObj)
    else
      penalties.append(boosterObj)
  }
  let { positive, negative } = sumBoosters.get()
  let positiveMult = positive + 1.0
  let negativeMult = negative + 1.0
  let expMult = positiveMult * negativeMult
  let infoRows = []
  let isDetailed = bonuses.len() && penalties.len()

  if (bonuses.len())
    infoRows.append(mkBlock("startBtn/boosterBonus", percentSign(positive), bonuses,
      "startBtn/modifierBonus", positiveMult, isDetailed))

  if (penalties.len())
    infoRows.append(mkBlock("startBtn/boosterPenalty", percentSign(negative), penalties,
      "startBtn/modifierPenalty", negativeMult, isDetailed))

  if (isDetailed)
    infoRows.append({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = activeTxtColor
      text = loc("startBtn/boosterTotal", {
        bonus = positiveMult
        penalty = negativeMult
        value = expMult
      })
    }, {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = activeTxtColor
      text = loc("startBtn/boosterPercent", {
        percent = percentSign(expMult - 1.0)
      })
    })

  return {
    watch = [allBoosters, sumBoosters]
    flow = FLOW_VERTICAL
    gap = hdpxi(15)
    children = infoRows
  }
})

let hasBoostersMark = Computed(@() sumBoosters.get().positive > 0
  || sumBoosters.get().negative < 0
  || showHintExpiringBoosters.get()
  || showHintActivateBoosters.get())

function mkActiveBoostersMark(override) {
  let timeLeftText = Computed(function() {
    let time = nextExpireTime.get() - serverTime.get()
    return time <= 0 ? "" : secondsToShortestloc(time)
  })

  return function() {
    let watch = [sumBoosters, hasBoostersMark, timeLeftText]
    if (!hasBoostersMark.get())
      return { watch }

    let { positive, negative } = sumBoosters.get()
    let boosterBtn = positive > 0 || negative < 0
      ? withTooltip(mkBoosterMark(positive, negative, timeLeftText.get(),
          { cursor = normalTooltipTop }), mkTooltip)
      : showHintExpiringBoosters.get()
        ? withTooltip(mkBoostersEmpty(true), @() loc("profile/expiringBoosters"))
        : withTooltip(mkBoostersEmpty(), @() loc("profile/inactiveBoosters"))

    return {
      watch
      children = boosterBtn
    }.__update(override)
  }
}

return {
  hasBoostersMark
  mkActiveBoostersMark
}
