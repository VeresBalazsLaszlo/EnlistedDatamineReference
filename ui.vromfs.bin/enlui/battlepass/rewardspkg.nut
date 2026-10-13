import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import defTxtColor, activeTxtColor, titleTxtColor, smallPadding,
  midPadding, accentColor, mkTimerIcon, transpBgColor, defItemBlur
from "%ui/components/tasksPkg.nut" import taskMinHeight, taskSlotPadding
from "%ui/items/itemsPresentationUtils.nut" import rewardWidthToHeight
from "%ui/soldiers/model/all_items_templates.nut" import findTemplateInArmies
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/meta/profile.nut" import commonArmy
from "%ui/components/defcomps.nut" import txt
from "%ui/ui_library.nut" import *

let defCardSize = const [hdpx(170), hdpx(210)]
let taskRewardSize = taskMinHeight - 2 * taskSlotPadding[0]
const timerSize = hdpxi(13)
let accentTxtStyle = { color = accentColor }.__update(fontSub)
const rewardIconWidth = hdpxi(42)

function prepareRewards(rewards, itemsMappingVal) {
  let list = []
  foreach (key, count in rewards)
    if (count > 0) {
      let reward = itemsMappingVal?[key]
      let { itemCount = 1 } = reward
      if (reward != null)
        list.append({ reward, count = count * itemCount })
    }
  return list
}

function getRewardViewData(rewardInfo, seasonIdx,
    curArmy, armies, templates, schemes, unlock = null) {

  if (rewardInfo?.reward == null)
    return null

  let reward = clone rewardInfo.reward
  let commonArmyId = commonArmy.get()

  let specialWeapon = reward?.specialRewards[seasonIdx][curArmy]
  if (specialWeapon != null) {
    let {
      gametemplate = reward.gametemplate, equipSchemeId = null
    } = templates?[curArmy][specialWeapon]

    return reward.__update({
      isSpecial = true
      gametemplate
      equipScheme = schemes?[equipSchemeId]
    })
  }

  if (reward?.boosterId != null) {
    reward.gametemplate <- "booster_template"

  } else if (reward?.itemTemplate != null && reward?.gametemplate == null) {
    let { itemTemplate = null } = reward

    if (itemTemplate in templates?[commonArmyId]) {
      reward.gametemplate <- templates?[commonArmyId][itemTemplate].gametemplate

    } else {
      let { armyId = "", template = null } = findTemplateInArmies(templates, armies, itemTemplate)
      let { gametemplate = null, equipSchemeId = null } = template

      reward.gametemplate <- gametemplate
      reward.equipScheme <- schemes?[armyId][equipSchemeId]
    }
  }

  let { stage0idx = -1, stageIdx = null } = rewardInfo
  if (stage0idx >= 0) {
    reward.isPremium <- true
  } else {
    let item = unlock?.findvalue(@(v) v.stage == stageIdx)
    reward.isPremium <- item?.isPremium ?? false
  }

  return reward
}


let getOneReward = @(rewards, itemsMappingVal) prepareRewards(rewards, itemsMappingVal)?[0]

function mkRewardIcon(reward, size = hdpx(30), override = {}) {
  let { icon = null } = reward
  if (icon == null)
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    image = Picture("{0}:{1}:{1}".subst(icon, size.tointeger()))
    keepAspect = KEEP_ASPECT_FIT
  }.__update(override)
}

function mkRewardImages(reward, sizeBg = defCardSize, override = {}, hasStageCompleted = false) {
  let { cardImage = null, middleImage = null, cardImageParams = @(_) {},
    bgImage = null, cardImageOpen = null, mkImage = null } = reward
  if (bgImage == null && cardImage == null && mkImage == null)
    return null

  let curImage = hasStageCompleted && cardImageOpen ? cardImageOpen : cardImage
  let mdlImage = hasStageCompleted && cardImageOpen ? null : middleImage
  let mdlImageObj = mdlImage == null ? null
    : mkImage != null ? mkImage?(sizeBg, mdlImage)
    : {
        rendObj = ROBJ_IMAGE
        image = Picture(mdlImage)
      }.__update(cardImageParams?(sizeBg) ?? {})
  return {
    size = sizeBg
    children = [
      bgImage == null ? null : {
        rendObj = ROBJ_IMAGE
        size = sizeBg
        image = Picture(bgImage)
      }
      mdlImageObj
      mkImage != null
        ? mkImage?(sizeBg, curImage)
        : {
            rendObj = ROBJ_IMAGE
            image = Picture(curImage)
          }.__update(cardImageParams?(sizeBg) ?? {})
    ]
  }.__update(override)
}

function mkRewardText(reward, pxSize,  override = {}){
  let { cardText = null} = reward
  if (cardText == null)
    return null
  return {
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    children = {
      rendObj = ROBJ_TEXT
      fontSize = pxSize
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      text = cardText
    }
  }.__update(override)
}

function mkSeasonTime(endTime, expiredCmp = null, override = {}) {
  let hasTimeExpired = Computed(@() endTime <= serverTime.get())
  if (hasTimeExpired.get())
    return expiredCmp
  let timeLeft = Computed(@() secondsToHoursLoc(endTime - serverTime.get()))
  return @() {
    watch = hasTimeExpired
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = transpBgColor
    color = defItemBlur
    padding = taskSlotPadding
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    children = [
      mkTimerIcon(timerSize, { color = accentColor })
      @() {
        watch = timeLeft
        rendObj = ROBJ_TEXT
        text = timeLeft.get()
      }.__update(accentTxtStyle, override)
    ]
  }
}

let mkSeasonTimeWithText = @(timeWatch, compStyle = {}, textStyle = {}, timerStyle = {},
    defaultCmp = null) @() {
  watch = timeWatch
  gap = midPadding
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/timeLeft")
      color = defTxtColor
    }.__update(textStyle)
    mkSeasonTime(timeWatch.get(), defaultCmp, timerStyle)
  ]
}.__update(compStyle)

function mkRewardTooltip(presentation) {
  let children = []
  if ("name" in presentation)
    children.append({
      rendObj = ROBJ_TEXT
      text = presentation.name
      color = activeTxtColor
    }.__update(fontBody))
  if ("description" in presentation)
    children.append({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = hdpx(500)
      text = presentation.description
      color = defTxtColor
    }.__update(fontSub))

  return children.len() == 0 ? null : tooltipCtor({ flow = FLOW_VERTICAL, children })
}

function mkRewardBlock(rewardData, isFinished = false) {
  let { reward = null, count = 1 } = rewardData
  return {
    children = [
      mkRewardIcon(reward, taskRewardSize, isFinished ? { opacity = 0.5 } : {})
      count == 1 ? null
        : txt({
            text = loc("common/amountShort", { count })
            margin = const [0, smallPadding]
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            color = titleTxtColor
            fontFx = FFT_GLOW
            fontFxColor = 0xCC000000
            fontFxFactor = hdpx(32)
          }).__update(fontSub)
    ]
  }
}

return freeze({
  getOneReward
  mkRewardIcon
  mkSeasonTime
  mkSeasonTimeWithText
  mkRewardBlock
  prepareRewards
  getRewardViewData
  mkRewardImages
  mkRewardText
  rewardWidthToHeight
  mkRewardTooltip
  defCardSize
  rewardIconWidth
})
