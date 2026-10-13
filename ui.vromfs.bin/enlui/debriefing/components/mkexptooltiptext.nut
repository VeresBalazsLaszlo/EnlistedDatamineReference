from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM
from "%ui/ui_library.nut" import *

let colon = loc("ui/colon")
const tabulation = "\u2007" 
const separator = ""

let commonMultipliersCfg = [
  { stat = "winMult", locId = "debriefing/tooltipWinMult"},
  { stat = "defeatMult", locId = "debriefing/tooltipDefeatMult"},
  { stat = "deserterMult", locId = "debriefing/tooltipDeserterMult"},
  { stat = "premiumSquadMult", locId = "debriefing/tooltipPremiumSquadMult"},
  { stat = "squadBonusMult", locId = "debriefing/squadBonusExp"},
  { stat = "squadRentedMult", locId = "debriefing/squadRentedMult"},
  { stat = "premiumMult", locId = "debriefing/tooltipPremiumMult"},
  { stat = "premiumSquadAndPremiumMult", locId = "debriefing/tooltipPremiumSquadAndPremiumMult"},
  { stat = "premiumAndSquadBonusMult", locId = "debriefing/premiumAndSquadBonusMult"},
  { stat = "battleHeroAwardsMult", locId = "debriefing/tooltipBattleHeroAwardsMult"},
  { stat = "playerCountMult", locId = "debriefing/tooltipPlayerCountMult"},
  { stat = "anyTeamMult", locId = "debriefing/anyTeamMult"},
  { stat = "lastGameDeserterMult", locId = "debriefing/lastGameDeserterMult"},
  { stat = "soldierExpMult", locId = "debriefing/soldierExpMult" },
  { stat = "premiumAndSoldierExpMult", locId = "debriefing/premiumAndSoldierExpMult"}
]

function getAdditiveMultiplier(stats) {
  let {
    isRented = false, premSquadExpBonus = 0, premAccountExpBonus = 0, soldierExpBonus = 0,
    sign = SIGN_NONE
  } = stats
  let mult = 1 + premSquadExpBonus + premAccountExpBonus + soldierExpBonus

  if (isRented) return { squadRentedMult = mult }

  let isPremiumSquad = sign == SIGN_PREMIUM
  if (premAccountExpBonus > 0) {
    let squadBonusStat = isPremiumSquad ? "premiumSquadAndPremiumMult" : "premiumAndSquadBonusMult"
    let stat = premSquadExpBonus > 0 ? squadBonusStat
      : soldierExpBonus > 0 ? "premiumAndSoldierExpMult"
      : "premiumMult"
    return { [stat] = mult }
  }

  let squadBonusStat = isPremiumSquad ? "premiumSquadMult" : "squadBonusMult"
  let stat = premSquadExpBonus > 0 ? squadBonusStat
    : soldierExpBonus > 0 ? "soldierExpMult"
    : ""
  return stat == "" ? {} : { [stat] = mult }
}

function getBattleResultMultiplier(stats, result) {
  let mult = stats?.battleResultMult ?? 0
  return (result?.deserter ?? false) ? {deserterMult = mult} :
         (result?.success ?? false) ? {winMult = mult} :
         (result?.fail ?? false) ? {defeatMult = mult} :
         {}
}

let squadMultipliersCfg = [].extend(commonMultipliersCfg, [
  { stat = "expBonus", locId = "debriefing/squadBonusExp", convertVal = @(v) 1 + v },
  { stat = "squadExpBoost", locId = "debriefing/squadExpBoost", convertVal = @(v) 1 + v },
]).map(@(s) { toString = @(v) v.tostring() }.__update(s))

let soldierMultipliersCfg = [].extend(commonMultipliersCfg, [
  { stat = "classBonus", locId = "debriefing/classBonusExp", convertVal = @(v) 1 + v },
  { stat = "soldierExpBoost", locId = "debriefing/soldierExpBoost", convertVal = @(v) 1 + v },
]).map(@(s) { toString = @(v) v.tostring() }.__update(s))

function mkTooltipMultipliersText(stats, cfg) {
  let textList = []
  foreach (s in cfg) {
    let { stat, convertVal = null } = s
    local value = stats?[stat]
    if (value == null)
      continue

    value = convertVal?(value) ?? value

    if (value != 1.0)
      textList.append("".concat(tabulation, loc(s.locId), colon, s.toString(value)))
  }

  return "\n".join(textList)
}

let tooltipField = @(locId, value) "".concat(loc(locId), colon, value)

function mkExperienceTooltipText(stats, cfg) {
  local expText = stats?.toLevelExp == 0
    ? loc("squad/squadMaxLvl")
    : tooltipField("debriefing/expAdded", stats?.exp ?? 0)
  let multipliers = mkTooltipMultipliersText(stats, cfg)
  if (multipliers != "") expText = "\n".join([
    tooltipField("debriefing/tooltipBaseExp", stats?.baseExp ?? 0)
    "".concat(loc("debriefing/tooltipExpMultipliers"), colon)
    multipliers
    separator
    expText
  ])
  return expText
}

let mkSquadExpTooltipText = @(stats, result) mkExperienceTooltipText(
  stats.__merge(getAdditiveMultiplier(stats), getBattleResultMultiplier(stats, result)),
  squadMultipliersCfg)

let mkSoldierExpTooltipText = @(stats, result) mkExperienceTooltipText(
  stats.__merge(getAdditiveMultiplier(stats), getBattleResultMultiplier(stats, result)),
  soldierMultipliersCfg)

return {
  mkSquadExpTooltipText
  mkSoldierExpTooltipText
}
