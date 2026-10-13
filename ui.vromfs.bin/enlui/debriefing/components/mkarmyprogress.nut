import "%ui/debriefing/components/mkAward.nut" as mkAward
import "%ui/components/colorize.nut" as colorize
import "%ui/components/mkCountingText.nut" as mkCounting
from "%enlSqGlob/battleHeroesAwards.nut" import awardPriority
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/cursors.nut" import withTooltip
from "%ui/components/itemsInfo.nut" import itemNameFromTemplate
from "%ui/style/fontsStyle.nut" import fontSub, fontHeading2
from "%ui/growth/growthPkg.nut" import elemBarSize, mkGrowthSlotElems
from "%ui/components/mkXpBooster.nut" import mkXpBooster
from "%ui/components/defComponents.nut" import doubleSideHighlightLine, doubleSideHighlightLineBottom, doubleSideBg
from "%ui/debriefing/components/mkXpImage.nut" import mkWinXpImage, mkBattleHeroAwardXpImage, mkPremiumAccountXpImage, mkBoosterXpImage
from "%ui/debriefing/components/mkArmyExpTooltip.nut" import mkArmyBaseExpTooltip, mkArmyPremiumExpTooltip, mkArmyResultExpTooltip, mkPremSquadXpImage, mkHeroAwardsSilverTooltip, mkGiftView
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding, largePadding, defItemBlur, brightAccentColor, titleTxtColor
  , defTxtColor, totalBlack
from "%ui/shop/armyCurrencyUi.nut" import mkExpIcon
from "%ui/ui_library.nut" import *

const trigger = "content_anim"
const playerCountMultTooltipText = "debriefing/playerCountMultArmyExpTooltip"
const notEnoughPlayersShortText = "debriefing/playerCountMultArmyExpTooltipShort"
const heroAwardsExpTooltipText = "debriefing/heroAwardsExpTooltipText"

const REWARD_ICON_SIZE = hdpxi(30)
const xpIconSize = hdpxi(34)
const rewardBlockHeight = hdpx(50)
const rewardRowWidth = hdpx(100)

const awardPositiveColor = Color(252, 186, 3, 255)
const awardNegativeColor = Color(252, 0, 0, 255)
const growthBgColor = 0xFF58603A

let expIcon = mkExpIcon([REWARD_ICON_SIZE, REWARD_ICON_SIZE])


let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(fontSub, override)


let mkSign = @(text) mkText(text, { padding = hdpx(5) })
let multiplySign = mkSign("\u00D7")
let addingSign = mkSign("+")


let expHeader = mkText(utf8ToUpper(loc("ui/textColon", { text = loc("debriefing/expAdded") })))
let silverHeader = mkText(
  utf8ToUpper(loc("ui/textColon", { text = loc("debriefing/silverAdded") })))


let mkGrowthProgress = @(wasProgress, addProgress, isForceCompleted, animDelay) {
  size = [FLEX, midPadding]
  flow = FLOW_HORIZONTAL
  rendObj = ROBJ_SOLID
  color = totalBlack
  children = [
    {
      size = [pw(wasProgress), FLEX]
      rendObj = ROBJ_SOLID
      color = growthBgColor
    }
    {
      size = isForceCompleted ? FLEX : [pw(addProgress), FLEX]
      rendObj = ROBJ_SOLID
      color = brightAccentColor
      transform = { pivot = [0, 0] }
      animations = [
        { prop = AnimProp.scale, from = [0,1], to = [0,1], duration = animDelay,
          play = true, trigger }
        { prop = AnimProp.scale, from = [0,1], to = [1,1], duration = 1,
          play = true, delay = animDelay, trigger }
      ]
    }
  ]
}


let getGlobalGiftGuid = @(gift, campaignId = null) (campaignId ?? "") != ""
  ? $"progress_gift_{campaignId}_{gift.basetpl}"
  : $"progress_gift_{gift.army}_{gift.basetpl}"

let getNextGlobalGiftRequire = @(gift, cycle)
  cycle > 0 ? gift.loopExp : gift.startExp

let getNextGlobalGiftCount = @(gift, cycle)
  cycle > 0 ? gift.loopCount : gift.startCount


let horFlow = @(children) {
  flow = FLOW_HORIZONTAL
  size = const [SIZE_TO_CONTENT, xpIconSize]
  valign = ALIGN_CENTER
  children
}

function mkSilverReward(giftsConfig, curGifts, campaignId, armyAddExp, awardsAdditionalExp,
  battleHeroAwards, expHeroAwardsLimit, expPerHeroAward
) {
  let giftCfg = giftsConfig?[0]
  if (giftCfg == null)
    return null

  let giftObj = curGifts?[getGlobalGiftGuid(giftCfg, campaignId)]
  let wasExp = giftObj?.exp ?? 0
  local cycle = giftObj?.cycle ?? 0
  local exp = wasExp + armyAddExp
  local nextGiftCount = 0
  while (true) {
    let nextReq = getNextGlobalGiftRequire(giftCfg, cycle)
    if (nextReq > exp)
      break

    nextGiftCount += getNextGlobalGiftCount(giftCfg, cycle)
    exp -= nextReq
    cycle++
  }

  let giftCountRes = nextGiftCount + awardsAdditionalExp
  if (giftCountRes == 0)
    return null

  let heroAwards = battleHeroAwards
    .map(@(a) { id = a.award })
    .sort(@(a,b) awardPriority[b.id] <=> awardPriority[a.id])
    .slice(0, expHeroAwardsLimit)
  let hasHeroAwards = heroAwards.len() > 0
    && expPerHeroAward > 0
    && awardsAdditionalExp > 0
  let resultGift = withTooltip(
    mkText($" = {giftCountRes}", { color = titleTxtColor }.__update(fontSub)),
    @() mkHeroAwardsSilverTooltip(nextGiftCount, giftCountRes, heroAwards, expPerHeroAward, giftCfg)
  )

  return {
    size = const [FLEX, rewardBlockHeight]
    children = [
      doubleSideHighlightLine
      doubleSideBg({
        size = FLEX
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        padding = [midPadding, bigPadding]
        children = [
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            children = !hasHeroAwards ? silverHeader : withTooltip(
              horFlow([
                silverHeader
                mkText(nextGiftCount)
              ].extend(heroAwards.map(@(v) {
                flow = FLOW_HORIZONTAL
                valign = ALIGN_CENTER
                children = [
                  mkText($" + {expPerHeroAward}")
                  mkAward.make({
                    size = const [xpIconSize, xpIconSize]
                    award = v
                    hasAnim = false
                  })
                ]
              }))
              .append({
                vplace = ALIGN_CENTER
                children = resultGift
              })), @() loc(heroAwardsExpTooltipText))
          }
          {
            size = const [rewardRowWidth, SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            vplace = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = [
              mkGiftView(giftCfg, REWARD_ICON_SIZE)
              mkCounting(0, giftCountRes, 1, 0.5, { color = titleTxtColor }.__update(fontSub))
            ]
          }
        ]
      })
      doubleSideHighlightLineBottom
    ]
  }
}


let premiumAccAndSquadIcon = @(size) {
  size = [size * 1.5, size]
  children = [
    mkPremSquadXpImage(size, { pos = [size * 0.5, 0] })
    mkPremiumAccountXpImage(size)
  ]
}

let premiumIcon = @(size, isPremiumAccount, isPremiumSquad)
  isPremiumAccount && isPremiumSquad ? premiumAccAndSquadIcon(size)
    : isPremiumAccount ? mkPremiumAccountXpImage(size)
    : isPremiumSquad ? mkPremSquadXpImage(size)
    : null

let mkValueWithIcon = @(value, txtStyle, icon) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    mkText(value, txtStyle)
    icon
  ]
}

let mkValueWithIconArmyExp = @(value, icon, textLocId = null)
  mkValueWithIcon(textLocId == null ? value : $"{value} {loc(textLocId)}",
    { color = value >= 1.0 ? awardPositiveColor : awardNegativeColor },
    icon)


const tokenIconSize = hdpxi(30)
let tokenIcon = {
  rendObj = ROBJ_IMAGE
  size = const [tokenIconSize, tokenIconSize]
  image = Picture("!ui/uiskin/currency/halloween_token.svg:{0}:{0}:K".subst(tokenIconSize))
}

function mkTokensReward(tokens, objectiveTokens, tokenMultiplier) {
  if (tokens == null && objectiveTokens == null)
    return null

  local totalTokens = (tokens ?? 0) + (objectiveTokens ?? 0)
  let headerTxt = tokenMultiplier > 1
    ? loc("zombieMod/tokensWithPass", { count = tokenMultiplier })
    : loc("zombieMod/tokens")
  return {
    size = const [FLEX, rewardBlockHeight]
    children = [
      doubleSideHighlightLine
      doubleSideBg({
        size = FLEX
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        valign = ALIGN_CENTER
        padding = [midPadding, bigPadding]
        children = [
          mkText(headerTxt, {
            size = FLEX_H
            color = brightAccentColor
          })
          {
            size = [rewardRowWidth, SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            valign = ALIGN_CENTER
            children = [
              tokenIcon
              mkCounting(0, totalTokens * tokenMultiplier, 1, 1.2,
                { color = titleTxtColor }.__update(fontSub))
            ]
          }
        ]
      })
      doubleSideHighlightLineBottom
    ]
  }
}


function mkPointsReward(result, details, armyAddExp, squads, armyId) {
  if (armyAddExp <= 0)
    return null

  let isSuccess = (result?.success ?? false)
  let isDeserter = (result?.deserter ?? false)
  let {
    baseArmyExp = 0, boostedExp = 0, premiumExp = 0, noviceBonus = 0,
    battleResultMult = 1.0, anyTeamMult = 1.0, lastGameDeserterMult = 1.0,
    battleHeroAwardsMult = 1.0, playerCountMult = 1.0, armyExpBoost = 0,
    isBattleResultMultDisabled = false, isArmyBoostDisabled = false,
    isBattleHeroMultDisabled = false
  } = details

  let battleResultLocId = isSuccess ? "debriefing/battleResultWinMult"
    : isDeserter ? "debriefing/battleResultDeserterMult"
    : "debriefing/battleResultMult"

  let battleResultText = isDeserter ? "debriefing/battleResultDeserterMultShort" : null
  let battleResultImage = isSuccess ? mkWinXpImage(xpIconSize) : null
  const anyTeamMultText = "debriefing/anyTeamMultShort"
  let anyTeamMultImage = null
  const anyTeamMultLocId = "debriefing/anyTeamMultTooltip"
  const lastGameDeserterMultText = "debriefing/lastGameDeserterMultShort"
  let lastGameDeserterMultImage = null
  const lastGameDeserterMultLocId = "debriefing/lastGameDeserterMultTooltip"

  let hasBoostBonus = boostedExp > 0
  let hasPremiumAccount = (details?.premiumExpMul ?? 1.0) > 1.0
  let hasPremiumSquad = squads.findvalue(@(squad)
    (squad?.sign ?? SIGN_NONE) == SIGN_PREMIUM && (squad?.premSquadExpBonus ?? 0) > 0) != null
  let hasSquadOrPremBonus = premiumExp > 0
  let hasPremBonus = hasSquadOrPremBonus && (hasPremiumAccount || hasPremiumSquad)
  let hasBattleResultMult = battleResultMult != 1.0
  let hasAnyTeamMult = anyTeamMult != 1.0
  let hasLastGameDeserterMult = lastGameDeserterMult != 1.0
  let hasBattleHeroMult = battleHeroAwardsMult != 1.0
  let hasPlayerCountMultIcon = playerCountMult != 1.0
  let needsParentheses = (hasBoostBonus || hasSquadOrPremBonus)
    && (hasBattleResultMult || hasAnyTeamMult || hasLastGameDeserterMult || hasBattleHeroMult)
  let showNotEnoughPlayersNotice = hasPlayerCountMultIcon || isBattleResultMultDisabled
    || isArmyBoostDisabled || isBattleHeroMultDisabled
  let showDetailed = hasBattleHeroMult || hasBattleResultMult || hasAnyTeamMult
    || hasLastGameDeserterMult || showNotEnoughPlayersNotice || hasSquadOrPremBonus
    || hasBoostBonus || noviceBonus > 0

  let baseExp = showDetailed
    ? withTooltip(mkText(baseArmyExp), @() mkArmyBaseExpTooltip(squads, baseArmyExp))
    : null
  let boostExp = !hasBoostBonus ? null
    : horFlow([
        addingSign
        withTooltip(mkValueWithIconArmyExp(boostedExp, mkBoosterXpImage(xpIconSize)),
          @() loc("debriefing/boosterBonusExp", {
            percent = colorize(awardPositiveColor, 100 * armyExpBoost)
          }))
      ])
  let premExp = !hasPremBonus ? null
    : horFlow([
        addingSign
        withTooltip(
          mkValueWithIconArmyExp(premiumExp, premiumIcon(xpIconSize, hasPremiumAccount, hasPremiumSquad))
          @() mkArmyPremiumExpTooltip(squads, premiumExp, details, armyId, hasPremiumAccount, hasPremiumSquad))
      ])

  let squadBonusExp = !hasPremBonus && premiumExp > 0 ? premiumExp : 0 
  let squadBonus = squadBonusExp > 0
    ? horFlow([ addingSign, withTooltip(mkText(squadBonusExp), @() loc("debriefing/squadBonusExp")) ])
    : null

  let battleResultMultIcon = !hasBattleResultMult ? null
    : horFlow([
        multiplySign
        withTooltip(
          mkValueWithIconArmyExp(battleResultMult, battleResultImage, battleResultText)
          @() loc(battleResultLocId))
      ])
  let lastGameDeserterMultIcon = !hasLastGameDeserterMult ? null
    : horFlow([
        multiplySign
        withTooltip(
          mkValueWithIconArmyExp(lastGameDeserterMult, lastGameDeserterMultImage, lastGameDeserterMultText)
          @() loc(lastGameDeserterMultLocId))
      ])
  let anyTeamMultIcon = !hasAnyTeamMult ? null
    : horFlow([
        multiplySign
        withTooltip(
          mkValueWithIconArmyExp(anyTeamMult, anyTeamMultImage, anyTeamMultText)
          @() loc(anyTeamMultLocId))
      ])
  let battleHeroMultIcon = !hasBattleHeroMult ? null
    : horFlow([
        multiplySign
        withTooltip(
          mkValueWithIconArmyExp(battleHeroAwardsMult, mkBattleHeroAwardXpImage(xpIconSize))
          @() loc("debriefing/battleHeroAwardsMult"))
      ])
  let playerCountMultIcon = !showNotEnoughPlayersNotice ? null
    : horFlow([
        hasPlayerCountMultIcon ? multiplySign : null
        withTooltip(hasPlayerCountMultIcon
            ? mkValueWithIconArmyExp(playerCountMult, null, notEnoughPlayersShortText)
            : mkText(loc(notEnoughPlayersShortText), { color = awardNegativeColor }),
          @() loc(playerCountMultTooltipText))
      ])
  let noviceBonusExp = noviceBonus <= 0 ? null
    : horFlow([ addingSign, withTooltip(mkText(noviceBonus), @() loc("debriefing/noviceExpBonus")) ])
  let resultExp = withTooltip({
      size = const [rewardRowWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = [
        expIcon
        mkCounting(0, armyAddExp, 1, 1.2, { color = titleTxtColor }.__update(fontSub))
      ]
    },
    @() mkArmyResultExpTooltip(squads, armyAddExp, details, isDeserter, armyId)
  )

  return {
    size = const [FLEX, rewardBlockHeight]
    children = [
      doubleSideHighlightLine
      doubleSideBg({
        size = FLEX
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        valign = ALIGN_CENTER
        padding = [midPadding, bigPadding]
        children = [
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            valign = ALIGN_CENTER
            children = !showDetailed
              ? expHeader
              : horFlow([
                  expHeader
                  needsParentheses ? mkText("(") : null
                  baseExp
                  boostExp
                  squadBonus
                  premExp
                  needsParentheses ? mkText(")") : null
                  battleResultMultIcon
                  lastGameDeserterMultIcon
                  anyTeamMultIcon
                  battleHeroMultIcon
                  playerCountMultIcon
                  noviceBonusExp
                ])
          }
          resultExp
        ]
      })
      doubleSideHighlightLineBottom
    ]
  }
}


let mkExpBoosterWithTooltip = @(value) withTooltip({
  flow = FLOW_VERTICAL
  gap = smallPadding
  halign = ALIGN_CENTER
  margin = [largePadding, 0, 0, largePadding]
  children = [
    mkXpBooster({ size = const [hdpx(70), hdpx(86)] })
    {
      rendObj = ROBJ_TEXT
      text = loc("expBoost", { boost = (100.0 * value + 0.5).tointeger() })
    }
  ]
}, @() loc("boostTotal/global", { percent = colorize(awardPositiveColor, 100 * value) }))

let battleResultHeader = {
  rendObj = ROBJ_TEXT
  color = brightAccentColor
  text = utf8ToUpper(loc("lb/battleResults"))
}.__update(fontHeading2)

function mkArmyProgress(
  armyId, armyAddExp, growthProgress, result, onFinish, isForceCompleted,
  giftsConfig = null, curGifts = null, campaignId = "",
  armyExpDetailed = {}, boosts = null, squads = {}, battleHeroAwards = [],
  expHeroAwardsLimit = 0, expPerHeroAward = 0, awardsAdditionalExp = 0,
  tokenMultiplier = 1
) {
  let { exp = 0, status = 0, growthCfg = null, item = null } = growthProgress
  let { expRequired = 0, reward = null } = growthCfg
  let { squadId = null } = reward

  let resultObject = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      mkSilverReward(giftsConfig, curGifts, campaignId, armyAddExp, awardsAdditionalExp,
        battleHeroAwards, expHeroAwardsLimit, expPerHeroAward)
      mkPointsReward(result, armyExpDetailed, armyAddExp, squads, armyId)
      mkTokensReward(result?.tokens, result?.objectiveTokens, tokenMultiplier)
    ]
    animations = [
      { prop = AnimProp.scale, from = [1,1], to = [1,1], duration = 2,
        play = true, trigger, onFinish }
    ]
  }

  let wasProgress = expRequired == 0 ? 0 : 100 * exp / expRequired
  let addProgress = expRequired == 0 ? 0 : min(100 - wasProgress, 100 * armyAddExp / expRequired)
  let growthObject = growthCfg == null || item == null || addProgress == 0
    ? null
    : {
        flow = FLOW_VERTICAL
        size = [elemBarSize[0], SIZE_TO_CONTENT]
        gap = midPadding
        children = [
          {
            flow = FLOW_VERTICAL
            children = [
              {
                rendObj = ROBJ_TEXT
                behavior = [Behaviors.Marquee]
                size = [elemBarSize[0], SIZE_TO_CONTENT]
                text = itemNameFromTemplate(item)
                color = titleTxtColor
              }
              {
                size = elemBarSize
                rendObj = ROBJ_WORLD_BLUR_PANEL
                fillColor = 0XFF1E272E
                color = defItemBlur
                children = mkGrowthSlotElems(0xFFB3BDC1, status, item, squadId)
              }
            ]
          }
          mkGrowthProgress(wasProgress, addProgress, isForceCompleted, 0.8)
          mkText(loc("debriefing/growthHeader"), {
            size = FLEX_H
            behavior = Behaviors.Marquee
            color = brightAccentColor
          })
        ]
      }

  let { positive = 0 } = boosts
  let boostsObject = positive <= 0 ? null : mkExpBoosterWithTooltip(positive)

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      battleResultHeader
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = largePadding
        valign = ALIGN_TOP
        children = [
          resultObject
          growthObject
          boostsObject
        ]
      }
    ]
  }
}

return kwarg(mkArmyProgress)
