import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/control/gui_buttons.nut" as JB
import "%ui/debriefing/components/mkAward.nut" as mkAward
import "%ui/components/faComp.nut" as faComp
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/debriefing/components/mkArmyProgress.nut" as mkArmyProgress
import "%ui/debriefing/components/mkSquadProgress.nut" as mkSquadProgress
import "%ui/debriefing/components/mkTasksProgress.nut" as mkTasksProgress
import "%ui/debriefing/mkDebriefingSoldierCard.nut" as mkSoldierCard
import "%ui/debriefing/mkDebriefingBattleHeroes.nut" as mkBattleHeroesBlock
import "%ui/hud/components/mkScoresStatistics.nut" as mkScoresStatistics
import "%ui/components/checkbox.nut" as checkbox
import "%ui/gameModes/getMissionInfo.nut" as getMissionInfo
import "%ui/hud/huds/tips/mkTipComposite.nut" as mkTipComposite
from "%enlSqGlob/missionType.nut" import MissionType
from "%enlSqGlob/appInfo.nut" import isProductionCircuit
from "%enlSqGlob/battleHeroesAwards.nut" import BattleHeroesAward, awardPriority, isSoldierAward, isTopSquadAward
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "dagor.system" import get_log_directory, DBGLEVEL
from "%dngscripts/platform.nut" import is_pc
from "%ui/style/cursors.nut" import normal, setTooltip
from "%ui/style/designConst.nut" import midPadding, commonBtnHeight, strokeStyle, smallPadding, largePadding, awardIconSpacing, awardIconSize
  , debriefingDarkColor, panelBgColor
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/helpers/time.nut" import secondsToTimeSimpleString
from "%ui/components/text.nut" import dtext as dtxt
from "%dngscripts/sound_system.nut" import sound_play
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/debriefing/components/mkExpTooltipText.nut" import mkSoldierExpTooltipText
from "%ui/mainMenu/sectionsState.nut" import setCurSection, Section, jumpToArmyGrowth
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/soldiers/model/state.nut" import selectArmy
from "%ui/soldiers/model/collectSoldierData.nut" import collectSoldierPhoto
from "%ui/currency/premiumComp.nut" import premiumImage
from "%sqstd/math.nut" import round_by_value
from "dagor.debug" import logerr
from "%ui/debriefing/debriefingDbgState.nut" import saveDebriefingToLog, saveDebriefingToFile, dbgShowAnim
from "matching.errors" import INVALID_SQUAD_ID, INVALID_SESSION_ID
from "settings" import get_setting_by_blk_path
from "%ui/state/client_user_rights.nut" import hasClientPermission
from "%sqstd/timers.nut" import debounce
from "%ui/components/rankPresentation.nut" import mkRank, getRankConfig
from "%ui/components/mkPromoWidget.nut" import promoWidget
from "%ui/profile/anoProfileState.nut" import showAnoProfile
from "%ui/featureFlags.nut" import showUserProfile, hasMissionLikes
from "%ui/meta/perks/perkTree.nut" import openPerkTree
from "%ui/debriefing/debriefingState.nut" import debriefingShowAnim, setDebriefingShowAnim
from "%ui/meta/profile.nut" import curCampSoldiers
from "%ui/matchingQueues.nut" import matchingQueues
from "%ui/gameModes/missionsRatingState.nut" import isMissionsRatingOpened, lastPlayedMissionData
from "%ui/components/textButton.style.nut" import TextHover, TextNormal
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/gamepadImgByKey.nut" import mkImageCompByDargKey
from "%ui/ui_library.nut" import *

let { INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, CANCEL_INVITE, APPROVE_INVITE, REJECT_INVITE, REMOVE_FROM_FRIENDS, ADD_TO_BLACKLIST, REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_XBOX, REMOVE_FROM_BLACKLIST_PSN, SHOW_USER_LIVE_PROFILE } = require("%ui/contacts/contactActions.nut")
let userActions = [
  INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, CANCEL_INVITE, APPROVE_INVITE, REJECT_INVITE,
  REMOVE_FROM_FRIENDS, ADD_TO_BLACKLIST, REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_XBOX,
  REMOVE_FROM_BLACKLIST_PSN, SHOW_USER_LIVE_PROFILE
]


const ANIM_TRIGGER = "new_items_wnd_anim"
const NEW_BLOCK_TRIGGER = "new_debr_block_appear"
const OVERLAY_TRIGGER = "content_anim"
const OVERLAY_TRIGGER_SKIP = "content_anim_skip"
const SKIP_ANIM_POSTFIX = "_skip"
const MOD_EXP_MODE = "mods"
const FILL_BLOCK_DELAY = 0.3
const AWARD_DELAY = 0.2

const MISSION_NAME_TEXT_DELAY = 1.6
const SESSION_TIME_TEXT_DELAY = 1.8
const SESSION_TIME_VALUE_DELAY = 2.0
const HEADER_TEXT_DELAY = 1.0
const HEADER_ICON_DELAY = 1.3

const DELAY = 0.1 

const BLOCKS_GAP = hdpx(18)
const BLOCK_PADDING = hdpx(10)
const BODY_W = fsh(132)

const debriefingWidth = sw(80)
const leftBlockWidth = debriefingWidth * 0.55
const maxAwardsRows = 3
let awardsInRow = (leftBlockWidth / (awardIconSize + awardIconSpacing)).tointeger()

local hasAnim = true
local skippedAnims = {}
let isShowAnimation = Computed(@() dbgShowAnim.get() ?? debriefingShowAnim.get())
local showAnim = isShowAnimation.get()
let newLevelSoldier = Watched(null)
let canQuitByEsc = Watched(false)
let usedSkipAnim = Watched(false)
let isWaitAnim = Watched(false)

let setupQuitByEsc = @() canQuitByEsc.set(true)
isWaitAnim.subscribe(function(v) {
  if (!v)
    gui_scene.resetTimeout(usedSkipAnim.get() ? 2 : 0.1, setupQuitByEsc)
})

let windowBlocks = []
let windowBlocksVer = Watched(0)
local windowContentQueue = []
let scrollHandler = ScrollHandler()
let gainRewardContent = Watched(null)

local hasAnimFinished = false

let soldierStatsCfg = [
  { stat = "time", locId = "debriefing/battleTime", toString = secondsToTimeSimpleString, isVisible = @(_) true },
  { stat = "spawns", locId = "debriefing/awards/spawns", isVisible = @(_) true },
  { stat = "kills", locId = "debriefing/awards/kill", isVisible = @(_) true },
  { stat = "attackKills", locId = "debriefing/awards/attackKills", isVisible = @(_) true },
  { stat = "defenseKills", locId = "debriefing/awards/defenseKills", isVisible = @(_) true },
  { stat = "longRangeKills", locId = "debriefing/awards/long_range_kill" },
  { stat = "tankKills", locId = "debriefing/awards/tankKill", isVisible = @(_) true },
  { stat = "bikeKills", locId = "debriefing/awards/bikeKill", isVisible = @(_) true },
  { stat = "apcKills", locId = "debriefing/awards/apcKill", isVisible = @(_) true},
  { stats = ["planeKills", "aiPlaneKills"], locId = "debriefing/awards/planeKill", isVisible = @(_) true },
  { stat = "assists", locId = "debriefing/awards/assists", isVisible = @(_) true },
  { stat = "tankKillAssists", locId = "debriefing/awards/tankKillAssists" },
  { stat = "bikeKillAssists", locId = "debriefing/awards/bikeKillAssists" },
  { stat = "apcKillAssists", locId = "debriefing/awards/apcKillAssists" },
  { stat = "apcSpot", locId = "debriefing/awards/apcSpot" },
  { stat = "apcSpotSpy", locId = "debriefing/awards/apcSpotSpy" },
  { stat = "buildingSpot", locId = "debriefing/awards/buildingSpot" },
  { stat = "buildingSpotSpy", locId = "debriefing/awards/buildingSpotSpy" },
  { stat = "tankSpot", locId = "debriefing/awards/tankSpot" },
  { stat = "tankSpotSpy", locId = "debriefing/awards/tankSpotSpy" },
  { stats = ["planeKillAssists", "aiPlaneKillAssists"], locId = "debriefing/awards/planeKillAssists" },
  { stat = "crewKillAssists", locId = "debriefing/awards/crewKillAssists", toString = @(v) round_by_value(v, 0.01), },
  { stat = "crewTankKillAssists", locId = "debriefing/awards/crewTankKillAssists", toString = @(v) round_by_value(v, 0.01),},
  { stat = "crewBikeKillAssists", locId = "debriefing/awards/crewBikeKillAssists", toString = @(v) round_by_value(v, 0.01),},
  { stat = "crewApcKillAssists", locId = "debriefing/awards/crewApcKillAssists", toString = @(v) round_by_value(v, 0.01),},
  { stats = ["crewPlaneKillAssists", "crewAiPlaneKillAssists"], locId = "debriefing/awards/crewPlaneKillAssists", toString = @(v) round_by_value(v, 0.01), },
  { stat = "tankKillAssistsAsCrew", locId = "debriefing/awards/tankKillAssistsAsCrew", toString = @(v) round_by_value(v, 0.01), },
  { stat = "bikeKillAssistsAsCrew", locId = "debriefing/awards/bikeKillAssistsAsCrew", toString = @(v) round_by_value(v, 0.01), },
  { stat = "apcKillAssistsAsCrew", locId = "debriefing/awards/apcKillAssistsAsCrew", toString = @(v) round_by_value(v, 0.01), },
  { stats = ["planeKillAssistsAsCrew", "aiPlaneKillAssistsAsCrew"], locId = "debriefing/awards/planeKillAssistsAsCrew", toString = @(v) round_by_value(v, 0.01), },
  { stat = "builtStructures", locId = "debriefing/awards/builtStructures" },
  { stat = "builtGunKills", locId = "debriefing/awards/builtGunKills" },
  { stat = "builtGunKillAssists", locId = "debriefing/awards/builtGunKillAssists" },
  { stat = "builtGunTankKills", locId = "debriefing/awards/builtGunTankKills" },
  { stat = "builtGunTankKillAssists", locId = "debriefing/awards/builtGunTankKillAssists" },
  { stat = "builtGunBikeKills", locId = "debriefing/awards/builtGunBikeKills" },
  { stat = "builtGunBikeKillAssists", locId = "debriefing/awards/builtGunBikeKillAssists" },
  { stat = "builtGunApcKills", locId = "debriefing/awards/builtGunApcKills" },
  { stat = "builtGunApcKillAssists", locId = "debriefing/awards/builtGunApcKillAssists" },
  { stats = ["builtGunPlaneKills", "builtGunAiPlaneKills"], locId = "debriefing/awards/builtGunPlaneKills" },
  { stats = ["builtGunPlaneKillAssists", "builtGunAiPlaneKillAssists"], locId = "debriefing/awards/builtGunPlaneKillAssists" },
  { stat = "builtBarbwireActivations", locId = "debriefing/awards/builtBarbwireActivations" },
  { stat = "builtCapzoneFortificationActivations", locId = "debriefing/awards/builtCapzoneFortificationActivations" },
  { stat = "builtAmmoBoxRefills", locId = "debriefing/awards/builtAmmoBoxRefills" },
  { stat = "builtMedBoxRefills", locId = "debriefing/awards/builtMedBoxRefills" },
  { stat = "builtRallyPointUses", locId = "debriefing/awards/builtRallyPointUses" },
  { stat = "ownedMobileSpawnUses", locId = "debriefing/awards/ownedMobileSpawnUses" },
  { stat = "killByThrowable", locId = "debriefing/awards/killByThrowable" },
  { stat = "hostedOnSoldierSpawns", locId = "debriefing/awards/hostedOnSoldierSpawns" },
  { stat = "vehicleRepairs", locId = "debriefing/awards/vehicleRepairs" },
  { stat = "vehicleExtinguishes", locId = "debriefing/awards/vehicleExtinguishes" },
  { stat = "landings", locId = "debriefing/awards/landings" },
  { stat = "barrageBalloonDestructions", locId = "debriefing/awards/barrageBalloonDestructions" },
  { stat = "enemyBuiltFortificationDestructions", locId = "debriefing/awards/enemyBuiltFortificationDestructions" },
  { stat = "enemyBuiltGunDestructions", locId = "debriefing/awards/enemyBuiltGunDestructions" },
  { stat = "enemyBuiltUtilityDestructions", locId = "debriefing/awards/enemyBuiltUtilityDestructions" },
  { stat = "reviveAssists", locId = "debriefing/awards/reviveAssists" },
  { stat = "healAssists", locId = "debriefing/awards/healAssists" },
  { stat = "captures", locId = "debriefing/awards/capture", toString = @(v) round_by_value(v, 0.1), isVisible = @(_) true },
  { stat = "plantBomb", locId = "debriefing/awards/plantBomb", toString = @(v) round_by_value(v, 0.1), isVisible = @(_) true },
  { stat = "defuseBomb", locId = "debriefing/awards/defuseBomb", toString = @(v) round_by_value(v, 0.1), isVisible = @(_) true },
  { stat = "friendlyHits", locId = "debriefing/awards/friendlyHits" },
  { stat = "friendlyKills", locId = "debriefing/awards/friendlyKills" },
  { stat = "friendlyTankHits", locId = "debriefing/awards/friendlyTankHits" },
  { stat = "friendlyTankKills", locId = "debriefing/awards/friendlyTankKills" },
  { stat = "friendlyBikeHits", locId = "debriefing/awards/friendlyBikeHits" },
  { stat = "friendlyBikeKills", locId = "debriefing/awards/friendlyBikeKills" },
  { stat = "friendlyApcHits", locId = "debriefing/awards/friendlyApcHits" },
  { stat = "friendlyApcKills", locId = "debriefing/awards/friendlyApcKills" },
  { stat = "friendlyPlaneHits", locId = "debriefing/awards/friendlyPlaneHits" },
  { stat = "friendlyPlaneKills", locId = "debriefing/awards/friendlyPlaneKills" },
  { stat = "zombieKills", locId = "debriefing/awards/zombieKills" },
  { stat = "zombieDoorsScore", locId = "debriefing/awards/zombieDoorsScore" },
  { stat = "zombieWaves", locId = "debriefing/awards/zombieWaves" },
  { stat = "zombieTotalScore", locId = "debriefing/awards/zombieTotalScore" },
  { stat = "awardScore", locId = "debriefing/score", isVisible = @(_) true },
  { stat = "noviceBonus", locId = "debriefing/noviceExpBonus" }
].map(@(s) { toString = @(v) v.tostring(), isVisible = @(v) v != 0 }.__update(s))


windowBlocksVer.subscribe(@(_) windowBlocks.len() == 0 ? null : anim_start(NEW_BLOCK_TRIGGER))
let scrollToBlock = @(key) scrollHandler.scrollToChildren(@(desc) desc?.key == key, 3, false, true)

let mkAppearAnimations = @(delay, onVisibleCb = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true,
    easing = InOutCubic, trigger = $"{ANIM_TRIGGER}{SKIP_ANIM_POSTFIX}" }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4, play = true,
    easing = InOutCubic, delay = delay, trigger = ANIM_TRIGGER, onFinish = onVisibleCb }
  { prop = AnimProp.scale, from = [2,2], to = [1,1], duration = 0.8, play = true,
    easing = InOutCubic, delay = delay, trigger = ANIM_TRIGGER}
  { prop = AnimProp.translate, from = [0, -sh(30)], to = [0,0], duration = 0.8, play = true,
    easing = OutQuart, delay = delay, trigger = ANIM_TRIGGER}
]

let blockAnimations = mkAppearAnimations(0).append(
  { prop = AnimProp.translate, from = [0, sh(30)], to = [0,0], duration = 0.3, easing = OutQuart,
    trigger = NEW_BLOCK_TRIGGER })

let mkAnim = @(children, onVisibleCb = null, animDelay = DELAY) children == null ? null : {
  size = SIZE_TO_CONTENT
  transform = true
  animations = showAnim ? mkAppearAnimations(animDelay, onVisibleCb) : null
  children = children
}

let grayText = @(override) {
  rendObj = ROBJ_TEXT
  color = Color(184, 182, 181)
}.__merge(fontBody, override)

const headerMarginTop = hdpx(30)

function overGainRewardBlock() {
  let res = { watch = gainRewardContent }
  let content = gainRewardContent.get()
  if (content == null)
    return res
  return res.__update({
    size = FLEX
    children = {
      key = $"{content.key}_nest"
      rendObj = ROBJ_SOLID
      size = FLEX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      color = debriefingDarkColor
      behavior = Behaviors.Button
      children = content
      opacity = 0
      transform = true
      animations = [
        { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.2, play = true,
          trigger = OVERLAY_TRIGGER }
        { prop = AnimProp.opacity, from = 1, to = 1, duration = 1.6, play = true, delay = 0.2,
          trigger = OVERLAY_TRIGGER }
        { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, play = true, delay = 1.8,
          trigger = OVERLAY_TRIGGER_SKIP, onFinish = @() gainRewardContent.set(null) }
      ]
    }
  })
}

let missionTitle = @(debriefing) debriefing?.missionName == null ? null : mkAnim({
  rendObj = ROBJ_TEXT
  text = debriefing.missionName
}.__update(fontHeading2, strokeStyle), null, MISSION_NAME_TEXT_DELAY)

let sessionTimeCounter = @(debriefing) {
  margin = const [headerMarginTop, 0, 0, 0]
  flow = FLOW_VERTICAL
  hplace = ALIGN_LEFT
  halign = ALIGN_LEFT
  children = [
    mkAnim(grayText({
      text = utf8ToUpper(loc("debriefing/session_time"))
    }), null, SESSION_TIME_TEXT_DELAY)
    mkAnim(grayText({
      text = secondsToTimeSimpleString((debriefing?.result.time ?? 0).tointeger())
    }.__update(fontHeading2)), null, SESSION_TIME_VALUE_DELAY)
  ]
}

let bonusText = @(val) "+{0}%".subst((100 * val).tointeger())
let colon = loc("ui/colon")

function mkSquadsBonusTooltipText(premiumExpMul) {
  let premiumText = "".concat(loc("premium/title"), colon, "+", premiumExpMul*100, "%")
  return "\n\n".join([premiumText], true)
}

function battleExpBonus(debriefing) {
  let { premiumExpMul = null } = debriefing
  if (premiumExpMul == null)
    return {
      hplace = ALIGN_RIGHT
      margin = const [headerMarginTop, 0, 0, 0]
      children = promoWidget("debriefing_sections", "debriefing_sections")
    }

  return {
    margin = const [headerMarginTop, 0, 0, 0]
    flow = FLOW_VERTICAL
    hplace = ALIGN_RIGHT
    halign = ALIGN_RIGHT

    behavior = Behaviors.Button
    onHover = @(on) setTooltip(
      on ? mkSquadsBonusTooltipText(premiumExpMul - 1) : null)
    children = [
      mkAnim(grayText({ text = utf8ToUpper(loc("battle_exp_bonus")) }))
      mkAnim(
        {
          flow = FLOW_HORIZONTAL
          children = [
            grayText({ text = bonusText(premiumExpMul - 1) }.__update(fontHeading2))
            premiumImage(hdpx(35))
          ]
        }
      )
    ]
  }
}

let blockHeader = @(locId) {
  size = FLEX_H
  rendObj = ROBJ_SOLID
  color = Color(0, 0, 0, 60)
  halign = ALIGN_CENTER
  padding = hdpx(5)
  children = grayText({ text = utf8ToUpper(loc(locId)) }.__update(fontSub))
}

function continueAnimImpl(debriefing) {
  local blockIdx = -1
  local block = null
  foreach (idx, ctor in windowContentQueue) {
    block = ctor(debriefing)
    if (block != null) {
      blockIdx = idx
      break
    }
  }

  if (blockIdx < 0) {
    isWaitAnim.set(false)
    return
  }

  windowContentQueue = windowContentQueue.slice(blockIdx + 1)
  windowBlocks.append(block)
  windowBlocksVer.modify(@(v) v + 1)

  if (windowContentQueue.len() == 0)
    hasAnimFinished = true
}

let continueAnim = debounce(continueAnimImpl, 0.01)

function skipAnim(debriefing) {
  anim_skip(NEW_BLOCK_TRIGGER)
  anim_skip($"{ANIM_TRIGGER}{SKIP_ANIM_POSTFIX}")
  anim_skip(ANIM_TRIGGER)
  anim_skip(OVERLAY_TRIGGER)
  anim_skip_delay(OVERLAY_TRIGGER_SKIP)
  anim_skip("content_anim")

  skippedAnims = skippedAnims.map(@(_) true)

  let prevContent = gainRewardContent.get()
  if (prevContent != null)
    gui_scene.setTimeout(0.5, function() { 
      if (prevContent != gainRewardContent.get())
        return
      gainRewardContent.set(null)
      logerr($"Debriefing reward window not removed after skip: key = /*{prevContent?.key}*/")
      log("Not removed content: ", prevContent)
    })

  continueAnim(debriefing)
}

let blockStyle = {
  color = panelBgColor
}

local blockIdx = 0
function blockCtr(locId, blockContent, override = blockStyle) {
  if (!blockContent)
    return null

  let key = $"debr_block_{blockIdx++}"
  return {
    size = FLEX_H
    rendObj = ROBJ_SOLID
    flow = FLOW_VERTICAL
    children = [
      locId != null ? blockHeader(locId) : null
      {
        size = FLEX_H
        padding = locId != null ? [BLOCK_PADDING, 0, BLOCK_PADDING, 0] : 0
        halign = ALIGN_CENTER
        children = blockContent
      }
    ]

    key
    onAttach = @() scrollToBlock(key)

    transform = true
    animations = blockAnimations
  }.__update(override ?? {})
}

function isFinishGrowth(debriefing) {
  let { armyExp = 0, growthProgress = null, isFirstBattleExp = false } = debriefing
  if (isFirstBattleExp && armyExp > 0)
    return true
  let { exp = 0, growthCfg = null } = growthProgress
  let { id = null, expRequired = 0 } = growthCfg
  return id != null && expRequired > 0 && armyExp > 0 && exp + armyExp >= expRequired
}


function armyProgressBlock(debriefing) {
  let {
    armyId, armyExp = 0, growthProgress = null,
    globalData = null, expMode = "", result = null, squads = {}, campaignId = "",
    armyExpDetailed = null, boosts = null, battleHeroAwards = [],
    expHeroAwardsLimit = 0, expPerHeroAward = 0, isFirstBattleExp = false,
    tokenMultiplier = 1, awardsAdditionalExp = 0
  } = debriefing

  if (expMode == MOD_EXP_MODE)
    return null

  skippedAnims.army <- false
  return {
    size = const [BODY_W, SIZE_TO_CONTENT]
    padding = midPadding
    children = mkArmyProgress({
      armyId
      armyAddExp = armyExp
      isForceCompleted = isFirstBattleExp && armyExp > 0
      growthProgress
      campaignId
      result
      squads
      armyExpDetailed
      boosts
      giftsConfig = globalData?.globalGiftsCfg ?? []
      curGifts = globalData?.globalGifts
      battleHeroAwards
      tokenMultiplier
      expHeroAwardsLimit
      expPerHeroAward
      awardsAdditionalExp
      onFinish = function() {
        if (!(skippedAnims?.army ?? false))
          continueAnim(debriefing)
      }
    })
    transform = true
    animations = mkAppearAnimations(FILL_BLOCK_DELAY)
  }
}

function rankBlock(debriefing) {
  let { wasPlayerRank = 0, playerRank = 0 } = debriefing
  if (playerRank == 0 || wasPlayerRank >= playerRank)
    return null

  let { locId } = getRankConfig(playerRank)
  return {
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc(locId)
      }.__update(fontHeading2)
      mkRank(playerRank)
    ]
    sound = { attach = "ui/debriefing/battle_result" }
  }
}

function debriefingHeader(debriefing) {
  let { result = null, armyId = null, expMode = "" } = debriefing
  let armyIcon = mkArmyIcon(armyId, hdpx(44))
  let armyProgress = armyProgressBlock(debriefing)
  return {
    size = FLEX_H
    halign = ALIGN_CENTER
    margin = const [headerMarginTop, 0, 0, 0]
    flow = FLOW_VERTICAL
    children = [
      {
        size = const [sw(75), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        hplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          missionTitle(debriefing)
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            gap = hdpx(30)
            children = [
              mkAnim(armyIcon, null, HEADER_ICON_DELAY)
              mkAnim({
                  size = SIZE_TO_CONTENT
                  rendObj = ROBJ_TEXT
                  text = utf8ToUpper(result?.title ?? "")
                }.__update(fontHeading2, { fontSize = hdpx(46) }),
                function() {
                  sound_play("ui/debriefing/{0}".subst(result?.success
                    ? "text_victory"
                    : "text_defeat"))
                  if (expMode == MOD_EXP_MODE)
                    continueAnim(debriefing)
                },
                HEADER_TEXT_DELAY)
              mkAnim(armyIcon, null, HEADER_ICON_DELAY)
            ]
          }
        ]
      }
      result?.finishedEarly ? dtxt(loc("debriefing/finished_early/desc")) : null
      blockCtr(null, armyProgress, {
        key = "headerArmyProgress"
        size = const [BODY_W, SIZE_TO_CONTENT]
        color = panelBgColor
        onAttach = @() null
        animations = []
      })
    ]
  }
}

function switchContext(debriefing) {
  let campaign = gameProfile.get()?.campaignByArmyId[debriefing.armyId]
  if (campaign == null) 
    return
  selectArmy(debriefing.armyId)
}


function openNewLevelSoldier() {
  setCurSection(Section.MAIN)
  openPerkTree(newLevelSoldier.get())
}

function skipAnimOrClose(doClose, debriefing) {
  if (isWaitAnim.get()) {
    usedSkipAnim.set(true)
    skipAnim(debriefing)
    return
  }
  doClose()
  hasAnimFinished = false
  switchContext(debriefing)
  if (isFinishGrowth(debriefing)) {
    jumpToArmyGrowth()
  } else if (newLevelSoldier.get() != null) {
    openNewLevelSoldier()
  }
}


function getMissionData(queues, missionId) {
  if (missionId == null)
    return null

  foreach (queue in queues) {
    let { isEventQueue = false, newbies = false } = queue?.extraParams
    if (!isEventQueue && !newbies)
      foreach (scene in queue.scenes) {
        let { fileName, tags } = scene
        if (tags.len() == 0)
          continue

        let sceneInfo = getMissionInfo(fileName)
        let { id, campaign } = sceneInfo
        if (id == missionId)
          return {
            campaign
            tagsCode = ",".join(tags)
            missionType = sceneInfo.type
          }
      }
  }

  return null
}


let mkRateMissionBtn = @(doClose, debriefing) function() {
  let watch = [hasMissionLikes, isWaitAnim, matchingQueues, isGamepad]
  if (!hasMissionLikes.get() || isWaitAnim.get())
    return { watch }

  let missionData = getMissionData(matchingQueues.get(), debriefing?.missionId)
  if (missionData == null)
    return { watch }

  return {
    watch
    children = Regular(@(_txt, _params, _handler, _group, sf)
      {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        margin = [0, midPadding]
        valign = ALIGN_CENTER
        children = [
          isGamepad.get() ? mkImageCompByDargKey("J:X", { margin = [0, largePadding, 0, 0] })
            : null
          faComp("thumbs-up", {
            fontSize = hdpx(24)
            color = sf & S_HOVER ? TextHover : TextNormal
          })
          {
            rendObj = ROBJ_TEXT
            text = loc("debriefing/rateBtn")
            color = sf & S_HOVER ? TextHover : TextNormal
          }.__merge(fontBody)
        ]
      },
      function() {
        skipAnimOrClose(doClose, debriefing)
        lastPlayedMissionData.set(missionData)
        isMissionsRatingOpened.set(true)
      }, { hotkeys = [["^J:X"]] }
    )
  }
}

let mkCloseBtn = @(doClose, debriefing) closeBtnBase({
  onClick = @() skipAnimOrClose(doClose, debriefing)
  hotkeys = null
}).__update({ margin = [midPadding, 0] })

let mkButtons = @(doClose, debriefing) function() {
  let doStopAndClose = @() skipAnimOrClose(doClose, debriefing)
  let rateMissionBtn = mkRateMissionBtn(doClose, debriefing)

  let hotkeysStr = canQuitByEsc.get()
    ? $"^{JB.B} | Space | Enter | Esc"
    : "^J:Y | Space | Enter"

  let children = []
  if (isWaitAnim.get())
    children.append(Regular(loc("Skip"), doStopAndClose, {
      key = "btnSkip"
      size = [SIZE_TO_CONTENT, commonBtnHeight]
      hotkeys = [[$"^{JB.B} | Esc | Space", {description = loc("Skip")}]]
    }))
  else if (isFinishGrowth(debriefing))
    children.append(Primary(loc("finishGrowth"), doStopAndClose, {
      key = $"btnFinish{canQuitByEsc.get()}"
      hotkeys = [[hotkeysStr, {description = loc("finishGrowth")}]],
      size = [SIZE_TO_CONTENT, commonBtnHeight]
    }), rateMissionBtn)
  else if (newLevelSoldier.get() != null)
    children.append(Primary(loc("soldiers/levelUp"), doStopAndClose, {
      key = $"btnLevel{canQuitByEsc.get()}"
      hotkeys = [[hotkeysStr, {description = loc("soldiers/levelUp")}]],
      size = [SIZE_TO_CONTENT, commonBtnHeight]
    }), rateMissionBtn)
  else
    children.append(Regular(loc("Ok"), doStopAndClose, {
      key = $"btnOk{canQuitByEsc.get()}"
      hotkeys = [[hotkeysStr, {description = loc("Ok")}]],
      size = [commonBtnHeight * 10, commonBtnHeight]
    }), rateMissionBtn)

  return {
    watch = [isWaitAnim, canQuitByEsc, newLevelSoldier]
    size = const [BODY_W, SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    halign = isWaitAnim.get() ? ALIGN_RIGHT : ALIGN_CENTER
    children
    animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 2.0,
          play = true, easing = InOutCubic }]
  }
}

let showAnimCheckBox = @() {
  watch = isWaitAnim
  size = const [BODY_W, SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  children = isWaitAnim.get() ? null : checkbox(debriefingShowAnim, {
    text = loc("debriefing/show_anim")
  }.__update(fontBody), { setValue = setDebriefingShowAnim })
}

let mkAnimatedAward = @(award, idx, delay, nextAnimCb = null) {
  children = mkAward.make({
    size = [awardIconSize, awardIconSize]
    award = award
    hasAnim = hasAnim
    pauseTooltip = isWaitAnim
    countDelay = delay + idx * AWARD_DELAY
  })
  transform = true
  animations = mkAppearAnimations(delay + idx * AWARD_DELAY,
    function() {
      sound_play("ui/debriefing/battle_result")
      nextAnimCb?()
    })
}

let awardsWrapParams = {
  width = BODY_W * 0.75
  hGap = midPadding * 4
  vGap = midPadding * 2
  halign = ALIGN_CENTER
}

function mkAwardsContent(topAwards, awards, nextAnimCb, delay = 0) {
  let nextDelay = delay + topAwards.len() * AWARD_DELAY
  return {
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      wrap(topAwards.map(@(award, idx)
        mkAnimatedAward(award, idx, delay)), awardsWrapParams)
      wrap(awards.map(@(award, idx)
        mkAnimatedAward(award, idx, nextDelay, idx == awards.len() - 1 ? nextAnimCb : null)),
          awardsWrapParams)
    ]
  }
}

function tasksBlock(debriefing) {
  let { dailyTasksProgress = [] } = debriefing
  if (dailyTasksProgress.len() == 0)
    return null

  skippedAnims.tasks <- false
  return blockCtr("debriefing/tasks_results",
    mkTasksProgress(dailyTasksProgress,
      mkAppearAnimations,
      function() {
        if (!(skippedAnims?.tasks ?? false))
          continueAnim(debriefing)
      }))
}

function heroesBlock(debriefing) {
  let { heroes = [], armyExp = 0, localPlayerGroupMembers = {} } = debriefing
  if (heroes.len() == 0)
    return null

  skippedAnims.heroes <- false
  let content = mkBattleHeroesBlock(heroes, armyExp > 0, localPlayerGroupMembers).__update({
    animations = mkAppearAnimations(FILL_BLOCK_DELAY, function() {
      sound_play("ui/debriefing/battle_result")
      gui_scene.setTimeout(0.5, @() continueAnim(debriefing))
    })
  })
  return blockCtr("debriefing/heroes", content)
}

function awardsBlock(debriefing) {
  local { awards = [], battleHeroAwards = [] } = debriefing
  awards = awards.filter(@(w) w.value > 0 && mkAward.awardsCfg?[w.id])

  let topAwards = battleHeroAwards
    .map(@(a) {id=a.award})
    .sort(@(a,b) awardPriority[b.id] <=> awardPriority[a.id])

  if (topAwards.len() == 0 && awards.len() == 0)
    return null

  skippedAnims.awards <- false

  let maxRows = topAwards.len() == 0 ? maxAwardsRows : maxAwardsRows - 1
  let awardsContent = mkAwardsContent(topAwards,
    awards.slice(0, maxRows * awardsInRow),
    function() {
      if (!(skippedAnims?.awards ?? false))
        continueAnim(debriefing)
    },
    AWARD_DELAY)

  let content = {
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      rankBlock(debriefing)
      awardsContent
    ]
  }

  return blockCtr("debriefing/personal_results", content)
}

function mkSoldierTooltipText(stats, result) {
  let textList = soldierStatsCfg.map(function(s) {
    local value = s?.defaultValue ?? 0
    foreach (stat in s?.stats ?? [s.stat])
      value += stats?[stat] ?? s?.defaultValue ?? 0

    return (s?.isVisible(value) ?? true)
      ? "".concat(loc(s.locId), colon, s.toString(value))
      : ""
  })
  let expText = mkSoldierExpTooltipText(stats, result)
  if (expText != null)
    textList.append(expText)
  return "\n".join(textList, true)
}

let collectSoldierAwards = @(guid, awards)
  awards.filter(@(award) isSoldierAward(award.award) && award.soldier.guid == guid).map(@(a) a.award)

let collectSquadAwards = @(squadId, awards)
  awards.filter(@(award) (isSoldierAward(award.award) || isTopSquadAward(award.award)) && award.soldier.squadId == squadId)

function checkNewLevelSoldier(soldierStat, soldierData) {
  if (soldierStat == null || soldierData == null)
    return

  let { guid, maxLevel = 1 } = soldierData
  let wasLevel = min(soldierStat?.wasExp.level ?? 0, maxLevel)
  let newLevel = min(soldierStat?.newExp.level ?? 0, maxLevel)
  let soldierInfo = curCampSoldiers.get()?[guid]
  if (newLevel > wasLevel && soldierInfo)
    newLevelSoldier.set(guid)
}

let playSquadProgress = @() sound_play("ui/debriefing/squad_progression_appear")

function squadsAndSoldiersExpBlock(debriefing) {
  let {
    squads = {}, isBattleHero = false, battleHeroSoldier = null,
    armyId = null, result = null
  } = debriefing
  if (squads.len() == 0)
    return null

  local soldiers = debriefing?.soldiers.stats ?? {}
  if (soldiers.len() == 0)
    return null

  soldiers = soldiers.map(@(s, id) s.__merge({ soldierId = id }))
    .values()
    .sort(@(a, b) (b?.exp ?? 0) <=> (a?.exp ?? 0) || (b?.kills ?? 0) <=> (a?.kills ?? 0))

  skippedAnims.squads <- false
  local animDelay = 0
  local idx = 0
  let squadAndSoldierRow = []
  foreach (squadId, squad in squads) {
    let children = []
    let squadSoldiersAwards = collectSquadAwards(squadId, debriefing?.battleHeroAwards ?? [])
    local squadAwards = squadSoldiersAwards.map(@(a) a.award)
    if (isBattleHero)
      squadAwards = [BattleHeroesAward.PLAYER_BATTLE_HERO].extend(squadAwards)

    let squadCard = mkSquadProgress({
      squadId
      squad
      awards = squadAwards
      animDelay
      armyId
      result
      mkAppearAnimations
      onFinishCb = idx < squads.len() - 1 ? null : function() {
          if (!(skippedAnims?.squads ?? false))
            continueAnim(debriefing)
        }
    })
    children.append(squadCard.content)

    local soldierAnimDelay = 0
    newLevelSoldier.set(null)
    foreach (soldierStat in soldiers) {
      let soldierData = debriefing?.soldiers.items[soldierStat.soldierId]
      if (!soldierData)
        continue
      if (squads?[soldierData.squadId] != squad)
        continue

      if (newLevelSoldier.get() == null)
        checkNewLevelSoldier(soldierStat, soldierData)

      let soldierAwards = collectSoldierAwards(soldierData.guid, squadSoldiersAwards)
      if (battleHeroSoldier != null && battleHeroSoldier == soldierData.guid)
        soldierAwards.append(BattleHeroesAward.BATTLE_HEROES_CARD)

      let soldierCard = mkSoldierCard({
        stat = soldierStat
        awards = soldierAwards
        info = collectSoldierPhoto(soldierData, null)
        animDelay = animDelay + soldierAnimDelay
        mkAppearAnimations = mkAppearAnimations
      })
      if (!soldierCard)
        continue
      soldierAnimDelay += 0.1
      let stats = soldierStat
      children.append(soldierCard.content.__update({
        behavior = Behaviors.Button
        onHover = @(on) setTooltip(on
          ? mkSoldierTooltipText(stats, debriefing?.result ?? {})
          : null)
      }))
    }
    animDelay += squadCard.duration
    idx++
    squadAndSoldierRow.append(children)
  }

  let content = [
    {
      flow = FLOW_VERTICAL
      size = SIZE_TO_CONTENT
      onAttach = @() gui_scene.resetTimeout(0.1, playSquadProgress)
      children = squadAndSoldierRow.map(@(v) {
        children = v
        width = BODY_W * 0.95
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        margin = hdpx(10)
        padding = hdpx(10)
        size = SIZE_TO_CONTENT
      })
    }
  ]

  return blockCtr("debriefing/squads_soldiers_progression", content)
}

function specialBlock(debriefing) {
  let { missionType = null } = debriefing
  if (missionType == MissionType.ZOMBIE_MODE) {
    let { localPlayerEid = null, players = {} } = debriefing
    let count = players?[localPlayerEid].scoring_player__zombieDoorsScore ?? 0
    if (count <= 0)
      return null

    skippedAnims.special <- false
    gui_scene.setTimeout(0.5, function() {
      if (!(skippedAnims?.special ?? false))
        continueAnim(debriefing)
    })

    let content = {
      flow = FLOW_HORIZONTAL
      children = mkTipComposite(loc("missionTypeHint/zombieModeSoulsScore", { count }),
        { color = TextNormal })
    }
    return blockCtr("missionType/zombie_mode", content)
  }
  return null
}

function statisticBlock(debriefing) {
  if ((debriefing?.players.len() ?? 0) == 0)
    return null

  skippedAnims.statistic <- false
  gui_scene.setTimeout(0.5, function() {
    if (!(skippedAnims?.statistic ?? false))
      continueAnim(debriefing)
  })
  let {
    myTeam,
    teams,
    localPlayerEid,
    localPlayerGroupId = INVALID_SQUAD_ID,
    localPlayerGroupMembers = {},
    missionType = null,
    result
  } = debriefing

  let { isTeamsUnitedInStatistics = false, isAllEnemiesInStatistics = false } = debriefing
  let params = {
    teams
    myTeam
    localPlayerEid
    localPlayerGroupMembers
    localPlayerGroupId
    width = BODY_W
    sessionId = debriefing?.sessionId ?? INVALID_SESSION_ID
    isInteractive = true
    showProfileCb = showUserProfile.get() ? showAnoProfile : null
    missionType
    result
    mkContextMenuButton = @(_) userActions
    scorePrices = debriefing?.scorePrices ?? {}
    canHideDeserters = true
    isTeamsUnited = isTeamsUnitedInStatistics
    isAllEnemies = isAllEnemiesInStatistics
    friends = debriefing?.friends ?? {}
  }

  return blockCtr(null, mkScoresStatistics(debriefing.players, params), { color = 0 })
}

let windowContent = mkAnim({
  size = const [BODY_W, FLEX]
  hplace = ALIGN_CENTER

  children = scrollbar.makeVertScroll(@() {
    watch = windowBlocksVer
    size = FLEX_H
    minHeight = ph(100)
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = BLOCKS_GAP
    children = windowBlocks
  },
  {
    scrollHandler = scrollHandler
    size = FLEX
    needReservePlace = false
  })
}).__merge({ size = FLEX })

let mkSessionIdText = @(debriefing) (debriefing?.sessionId ?? INVALID_SESSION_ID) == INVALID_SESSION_ID ? null : {
  text = debriefing.sessionId
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_LEFT
  rendObj = ROBJ_TEXT
  color = Color(120,120,120, 50)
}.__update(fontSub)

let debriefingAutosavePath = "".concat(get_log_directory() ?? "", "debriefing_enlisted.json")
let canDebugDebriefing = hasClientPermission("debug_debriefing")

function autosaveDebriefing(debriefing){
  if (!(get_setting_by_blk_path("debug/enableDebriefingDump") ?? true))
    return

  else if (is_pc && !isProductionCircuit.get())
    saveDebriefingToFile(debriefing, debriefingAutosavePath)

  else if ((!is_pc && DBGLEVEL > 0) || (is_pc && isProductionCircuit.get() && canDebugDebriefing.get()))
    saveDebriefingToLog(debriefing)
}

local curDebriefingSessionId = null
function initDebriefingAnim(debriefing) {
  let { sessionId = -1 } = debriefing
  if (sessionId == curDebriefingSessionId)
    return

  curDebriefingSessionId = sessionId
  skippedAnims = {}
  hasAnim = true
  windowBlocks.clear() 
  windowContentQueue = [
    heroesBlock
    awardsBlock
    tasksBlock
    squadsAndSoldiersExpBlock
    specialBlock
    statisticBlock
  ]
}

function debriefingRoot(debriefing, doClose) {
  if ((debriefing?.len() ?? 0) == 0) {
    doClose()
    return null
  }

  function autosaveAndClose() {
    autosaveDebriefing(debriefing)
    doClose()
  }

  showAnim = isShowAnimation.get()
  canQuitByEsc.set(false)

  initDebriefingAnim(debriefing)

  hasAnimFinished = !showAnim
  if (hasAnimFinished) {
    foreach (ctor in windowContentQueue) {
      let block = ctor(debriefing)
      if (block != null)
        windowBlocks.append(block)
    }
    windowContentQueue = []
    gui_scene.resetTimeout(0.05, @() skipAnim(debriefing))
  }

  return @() {
    key = debriefing?.sessionId
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    cursor = normal
    stopMouse = true
    behavior = DngBhv.ActivateActionSet
    actionSet = "StopInput"
    watch = safeAreaBorders
    stopHotkeys = true
    children = [
      {
        size = FLEX
        flow = FLOW_VERTICAL
        padding = safeAreaBorders.get()
        children = [
          {
            size = FLEX
            flow = FLOW_VERTICAL
            gap = BLOCKS_GAP
            children = [
              {
                size = FLEX_H
                children = [
                  debriefingHeader(debriefing)
                  sessionTimeCounter(debriefing)
                  battleExpBonus(debriefing)
                  mkCloseBtn(autosaveAndClose, debriefing)
                ]
              }
              windowContent
              {
                size = FLEX_H
                children = [
                  showAnimCheckBox
                  mkButtons(autosaveAndClose, debriefing)
                ]
              }
            ]
          }
          mkSessionIdText(debriefing)
        ]
      }
      overGainRewardBlock
    ]

    onAttach = @() isWaitAnim.set(showAnim ? true : false)
    onDetach = @() curDebriefingSessionId = null

    transform = {pivot = [0.5, 0.25]}
    animations = [
      { prop=AnimProp.opacity, from=0, to=1 duration=0.8, play=true, easing=InOutCubic}
      { prop=AnimProp.scale, from=[2,2], to=[1,1], duration=0.5, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0 duration=0.8, playFadeOut=true, easing=InOutCubic}
      { prop=AnimProp.scale, from=[1,1], to=[2,2], duration=0.5, playFadeOut=true, easing=InOutCubic}
    ]

    sound = {
      attach = "ui/menu_highlight"
      detach = "ui/menu_highlight"
    }
  }
}

return debriefingRoot
