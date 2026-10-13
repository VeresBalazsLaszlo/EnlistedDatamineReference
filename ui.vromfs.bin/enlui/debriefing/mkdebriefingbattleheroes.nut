import "%ui/components/battleHeroAwardIcon.nut" as mkBattleHeroAwardIcon
import "%ui/hud/components/mkAwardsTooltip.nut" as mkAwardsTooltip
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/battleHeroesAwards.nut" import BattleHeroesAward, combineMultispecialistAward, awardPriority, isSoldierKindAward
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub
from "%ui/style/designConst.nut" import smallPadding, activeBgColor
from "%ui/components/defcomps.nut" import txt
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/components/decoratorsPresentation.nut" import frameNick, getPortrait
from "%ui/style/cursors.nut" import withTooltip
from "%ui/components/itemsInfo.nut" import soldierNameSlicer
from "%sqstd/underscore.nut" import partition
from "%ui/helpers/animation_utils.nut" import getIdleAnimState
from "%ui/components/soldierPhoto.nut" import mkSoldierPhotoName, mkSoldierPhoto
from "%ui/components/rankPresentation.nut" import mkRankIcon
from "%ui/profile/decoratorPkg.nut" import mkPortraitIcon
from "%ui/ui_library.nut" import *

const awardMultTxtColor = Color(252, 186, 3, 255)
const battleHeroNameColor = Color(120,120,120, 50)
const localBattleHeroNameColor = Color(252, 186, 3, 255)

const PORTRAIT_SIZE = hdpxi(140)
const maxNameBlockWidth = hdpx(184)
let awardIconSize = [hdpxi(70), hdpxi(70)]
let photoSize = [hdpxi(92), hdpxi(136)]

let mkBattleHeroPlayerNameText = @(playerName, isLocalPlayer) {
  rendObj = ROBJ_TEXT
  maxWidth = maxNameBlockWidth
  behavior = Behaviors.Marquee
  clipChildren = true
  color = isLocalPlayer ? localBattleHeroNameColor : battleHeroNameColor
  text = playerName
}.__update(fontHeading2)

function mkBattleHeroAwards(awards) {
  local sortedAwards = [].extend(awards).sort(@(a,b) awardPriority[b] <=> awardPriority[a])
  let combinedAwards = combineMultispecialistAward(sortedAwards).reverse()

  let [kindAwards, otherAwards] = partition(sortedAwards, isSoldierKindAward)
  if (kindAwards.len() > 1)
    sortedAwards = otherAwards
      .append({icon=BattleHeroesAward.MULTISPECIALIST, text="debriefing/tooltipScoreTableMultispecialist"})
      .extend(kindAwards)

  const offset = hdpx(25)
  let firstOffset = (max(0, combinedAwards.len() - 1)) * offset * 0.5
  return {
    children = combinedAwards.map(@(award, index) withTooltip(
      mkBattleHeroAwardIcon(award, awardIconSize, true).__merge({ pos = [firstOffset - index * offset, 0] }),
      @() mkAwardsTooltip(sortedAwards, awardIconSize)))
  }
}

let mkBattleHeroPortrait = @(portrait, playerRank) {
  rendObj = ROBJ_BOX
  borderColor = activeBgColor
  borderWidth = hdpx(1)
  children = [
    mkPortraitIcon(getPortrait(portrait), PORTRAIT_SIZE).__update({ padding = hdpx(1) })
    mkRankIcon(playerRank)
  ]
}

function mkBattleHeroPhoto(soldier, playerRank) {
  let db = ecs.g_entity_mgr.getTemplateDB()
  let { guid, equipment = null, weapTemplates = null, gametemplate = null } = soldier
  if (gametemplate == null)
    return mkSoldierPhoto(null, photoSize, mkRankIcon(playerRank))

  let equipmentInfo = []
  let itemTemplates = []
  if (equipment != null) {
    foreach (slot, equip in equipment) {
      equipmentInfo.append({
        slot = slot,
        tpl = equip.gametemplate
      })
      let itemTemplate = db.getTemplateByName(equip.gametemplate)
      if (itemTemplate != null)
        itemTemplates.append(itemTemplate)
    }
  }
  let soldierTemplate = db.getTemplateByName(gametemplate)
  let overridedIdleAnims = soldierTemplate?.getCompValNullable("animation__overridedIdleAnims")
  let overridedSlotsOrder = soldierTemplate?.getCompValNullable("animation__overridedSlotsOrder").getAll()
  let animation = getIdleAnimState({
    weapTemplates
    itemTemplates
    overridedIdleAnims
    overridedSlotsOrder
    seed = guid.hash()
  })
  let photo = mkSoldierPhotoName(gametemplate, equipmentInfo, animation, true)
  return mkSoldierPhoto(photo, photoSize, mkRankIcon(playerRank))
}

let mkSoldierName = @(soldier, isLocalPlayer) isLocalPlayer && (soldier?.callname ?? "") != ""
  ? {
      rendObj = ROBJ_TEXT
      text = soldier.callname
      maxWidth = SIZE_TO_CONTENT
      size = const [PORTRAIT_SIZE, SIZE_TO_CONTENT]
      behavior = Behaviors.Marquee
    }.__update(fontSub)
  : {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = soldierNameSlicer(soldier, isLocalPlayer)
    }.__update(fontSub)

let mkBattleHeroArmyMult = @(mult) txt({
  text = loc("common/amountShort", { count = mult })
  color = awardMultTxtColor
})

function mkHeroes(heroes, isExpReceived, localPlayerGroupMembers) {
  let children = []
  foreach (hero in heroes) {
    let {
      isFinished = true, awards = [], playerName = "", nickFrame = "", playerEid = null,
      portrait = "", isLocalPlayer = false, soldier = null, expMult = 1.0, playerRank = 0
    } = hero
    if (!isFinished)
      continue

    let name = remap_nick(playerName,
      !isLocalPlayer && (playerEid ?? 0).tostring() not in localPlayerGroupMembers)
    children.append({
      flow = FLOW_VERTICAL
      vplace = ALIGN_TOP
      halign = ALIGN_CENTER
      gap = smallPadding
      children = [
        mkBattleHeroPlayerNameText(frameNick(name, nickFrame), isLocalPlayer)
        portrait == ""
          ? mkBattleHeroPhoto(soldier, playerRank)
          : mkBattleHeroPortrait(portrait, playerRank)
        mkSoldierName(soldier, isLocalPlayer)
        mkBattleHeroAwards(awards)
        isExpReceived ? mkBattleHeroArmyMult(expMult) : null
      ]
    })
  }
  return {
    flow = FLOW_HORIZONTAL
    size = SIZE_TO_CONTENT
    gap = hdpx(18)
    children
  }
}

return mkHeroes
