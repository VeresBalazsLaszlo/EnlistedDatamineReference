import "%ui/debriefing/components/mkAward.nut" as mkAward
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor, smallPadding
from "%ui/components/defcomps.nut" import txt
from "%ui/debriefing/components/mkXpImage.nut" import mkWinXpImage, mkBattleHeroAwardXpImage, mkPremiumAccountXpImage, mkBoosterXpImage
from "%ui/shop/currencyPresentation.nut" import getCurrencyPresentation
from "%ui/shop/currencyComp.nut" import mkCurrencyImage
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM
from "%ui/ui_library.nut" import *

const multiplySign = "\u00D7"
const awardPositiveColor = Color(252, 186, 3, 255)
const awardNegativeColor = Color(252, 0, 0, 255)
const tooltipIconSize = hdpxi(20)

let mkTooltipHeader = @(text, val) {
  flow = FLOW_HORIZONTAL
  children = [
    txt("{0}{1}".subst(text, loc("ui/colon")))
    txt({text=val, color=awardPositiveColor})
  ]
}

let mkArmyExpTooltip = @(header, exp, squads, expCtor) tooltipCtor({
  flow = FLOW_VERTICAL
  children = [
    mkTooltipHeader(header, exp)
    {
      flow = FLOW_VERTICAL
      children = squads.values().filter(@(squad) (squad?.baseExp ?? 0) > 0).map(function(squad) {
        let expDetailed = expCtor(squad)
        return expDetailed != null ? {
          flow = FLOW_HORIZONTAL
          children = [
            txt("{0} - {1} {2}, {3} ".subst(
              loc(squad.nameLocId)
              loc("debriefing/tooltipScore")
              squad?.awardScore ?? 0
              loc("debriefing/tooltipExp")))
            expDetailed
          ]
        } : null
      })
    }
  ]
})

let mkValueWithIcon = @(value, icon) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    txt(value)
    icon
  ]
}


let mkPremSquadXpImage = @(size, override = {}) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [size, size]
      image = Picture($"ui/skin#premium/prem_squad_debrif_icon.svg:{size}:{size}")
    }
  ]
}.__update(override)


function getSquadExpDetailed(info) {
  let {
    baseExp = 0,
    resultMult = 1.0,
    anyTeamMult = 1.0,
    lastGameDeserterMult = 1.0,
    awardsMult = 1.0,
    playerCountMult = 1.0,
    boostBonus = 0,
    premAccountBonus = 0,
    premSquadBonus = 0,
    isDeserter = false
  } = info

  let battleResultIcon = !isDeserter
    ? mkWinXpImage(tooltipIconSize)
    : txt({text=loc("debriefing/battleResultDeserterMultShort"), color = awardNegativeColor})
  let anyTeamIcon = txt({text=loc("debriefing/anyTeamMultShort"), color = awardPositiveColor})
  let lastGameDeserterIcon = txt({text=loc("debriefing/lastGameDeserterShort"), color = awardNegativeColor})
  let mkPlayerCountTxt = txt({text=loc("debriefing/playerCountMultArmyExpTooltipShort"), color = awardNegativeColor})
  let battleResultMultIcon = resultMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {resultMult}",
        battleResultIcon)
  let lastGameDeserterMultIcon = lastGameDeserterMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {lastGameDeserterMult}",
        lastGameDeserterIcon)
  let anyTeamMultIcon = anyTeamMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {anyTeamMult}",
        anyTeamIcon)
  let battleHeroMultIcon = awardsMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {awardsMult}",
        mkBattleHeroAwardXpImage(tooltipIconSize))
  let expBoostIcon = boostBonus <= 0 ? null
    : mkValueWithIcon(
        $"+{boostBonus}",
        mkBoosterXpImage(tooltipIconSize))
  let premAccountIcon = premAccountBonus <= 0
    ? null
    : mkValueWithIcon(
        $"+{premAccountBonus}",
        mkPremiumAccountXpImage(tooltipIconSize))
  let premSquadIcon = premSquadBonus <= 0
    ? null
    : mkValueWithIcon(
        $"+{premSquadBonus}",
        mkPremSquadXpImage(tooltipIconSize))
  let playerCountMultIcon = playerCountMult == 1.0
    ? null
    : mkValueWithIcon(
        $" {multiplySign} {playerCountMult}",
        mkPlayerCountTxt)

  let needsParentheses = ((resultMult != 1.0) || (awardsMult != 1.0))
    && (boostBonus > 0 || premAccountBonus > 0 || premSquadBonus > 0)

  let resultExp = ((baseExp + boostBonus + premAccountBonus + premSquadBonus)
    * awardsMult
    * resultMult
    * lastGameDeserterMult
    * anyTeamMult
    * playerCountMult).tointeger()
  let showDetailed = baseExp != resultExp
  let resultTxt = txt({text=resultExp, color = awardPositiveColor})
  let baseExpTxt = baseExp != 0 && showDetailed ? txt(baseExp) : null

  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = showDetailed
      ? [
          needsParentheses ? txt("(") : null
          baseExpTxt
          expBoostIcon
          premAccountIcon
          premSquadIcon
          needsParentheses ? txt(")") : null
          battleResultMultIcon
          lastGameDeserterMultIcon
          anyTeamMultIcon
          battleHeroMultIcon
          playerCountMultIcon
          txt(" = ")
          resultTxt
        ]
      : [resultTxt]
  }
}

let mkArmyBaseExpTooltip = @(squads, exp) mkArmyExpTooltip(
  loc("debriefing/armyExpBaseTooltipHeader"),
  exp,
  squads,
  @(squad) txt({text = squad?.baseExp ?? 0, color = awardPositiveColor})
)

let isSquadPremium = @(squad) (squad?.sign ?? SIGN_NONE) == SIGN_PREMIUM

function resultExpCfg(squad, details, isDeserter, armyId) {
  let { baseExp = 0, premSquadExpBonus = 0, premAccountExpBonus = 0 } = squad
  let { armyExpBoost = 0, battleResultMult = 1, anyTeamMult = 1, playerCountMult = 1,
    lastGameDeserterMult = 1, battleHeroAwardsMult = 1 } = details

  let baseWithBoost = baseExp * (1.0 + armyExpBoost)
  let squadBonusExp = (baseWithBoost * premSquadExpBonus).tointeger()
  let isPremiumSquad = isSquadPremium(squad)
  return squad.__merge({
    baseExp = baseExp + (isPremiumSquad ? 0 : squadBonusExp)
    boostBonus = (baseExp * armyExpBoost).tointeger()
    premAccountBonus = (baseWithBoost * premAccountExpBonus).tointeger()
    premSquadBonus = isPremiumSquad ? squadBonusExp : 0
    resultMult = battleResultMult
    anyTeamMult
    lastGameDeserterMult
    awardsMult = battleHeroAwardsMult
    playerCountMult
    isDeserter
    armyId
  })
}

let mkArmyResultExpTooltip = @(squads, exp, details, isDeserter, armyId) mkArmyExpTooltip(
  loc("debriefing/armyExpResultTooltipHeader"),
  exp,
  squads,
  @(squad) getSquadExpDetailed(
    resultExpCfg(squad, details, isDeserter, armyId))
)

function getSquadPremiumExpDetailed(squad, details, armyId) {
  let isPremiumSquad = isSquadPremium(squad)
  let { baseExp = 0, premSquadExpBonus = 0, premAccountExpBonus = 0 } = squad
  let hasPremiumBonuses = premAccountExpBonus > 0 || (isPremiumSquad && premSquadExpBonus > 0)
  if (!hasPremiumBonuses)
    return null

  let boostMult = 1.0 + (details?.armyExpBoost ?? 0)
  let squadExpBonus = (baseExp * boostMult * premSquadExpBonus).tointeger()
  let premExpCfg = {
    baseExp = isPremiumSquad ? 0 : squadExpBonus
    premSquadBonus = !isPremiumSquad ? 0 : squadExpBonus
    premAccountBonus = (baseExp * boostMult * premAccountExpBonus).tointeger()
    armyId
  }

  return getSquadExpDetailed(premExpCfg)
}

function getPremiumTooltipHeader(hasPremiumAccount, hasPremiumSquad) {
  if (hasPremiumAccount && hasPremiumSquad)
    return loc("debriefing/armyExpPremiumTooltipHeader")
  if (hasPremiumAccount)
    return loc("debriefing/armyExpPremiumAccountTooltipHeader")
  if (hasPremiumSquad)
    return loc("debriefing/armyExpPremiumSquadTooltipHeader")
  return null
}

let mkArmyPremiumExpTooltip = @(squads, exp, details, armyId, hasPremiumAccount, hasPremiumSquad) mkArmyExpTooltip(
  getPremiumTooltipHeader(hasPremiumAccount, hasPremiumSquad)
  exp
  squads
  @(squad) getSquadPremiumExpDetailed(squad, details, armyId)
)

function mkGiftView(giftCfg, size = tooltipIconSize) {
  let itemCurrency = getCurrencyPresentation(giftCfg.basetpl)
  return itemCurrency == null ? null
    : mkCurrencyImage(itemCurrency.icon, [size, size])
}

let mkHeroAwardsSilverTooltip = @(baseSilver, totalSilver, awards, silverPerAward, giftCfg)
  awards.len() == 0 ? null : tooltipCtor({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        valign = ALIGN_CENTER
        children = [
          mkGiftView(giftCfg)
          txt({ text = $"{totalSilver}", color = titleTxtColor})
        ]
      }
      txt({ text = $" = {baseSilver}", color = defTxtColor})
    ].extend( awards.map(@(v) {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        txt({ text = $" + {silverPerAward}", color = defTxtColor})
        mkAward.make({
          size = [tooltipIconSize, tooltipIconSize]
          award = v
          hasAnim = false
        })
      ]
    }))
  })

return {
  mkArmyBaseExpTooltip
  mkArmyPremiumExpTooltip
  mkArmyResultExpTooltip
  mkPremSquadXpImage
  mkHeroAwardsSilverTooltip
  mkGiftView
}