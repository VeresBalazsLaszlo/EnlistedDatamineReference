import "%ui/components/armiesPresentation.nut" as armiesPresentation
import "%ui/components/faComp.nut" as faComp
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import miniPadding, smallPadding, midPadding, darkTxtColor,
  defTxtColor, squadSlotBgIdleColor, squadSlotBgHoverColor, squadSlotBgActiveColor,
  squadSlotBgAlertColor, levelNestGradient, spawnNotReadyColor, multySquadPanelSize,
  brightAccentColor, panelBgColor, negativeTxtColor
from "%ui/components/defcomps.nut" import txt
from "%ui/components/soldierClasses.nut" import soldierKinds
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/soldiers/model/state.nut" import soldiersBySquad
from "%ui/components/soldiersUiComps.nut" import mkSoldierMedalIcon
from "%ui/ui_library.nut" import *

let txtColor = @(flags, _selected=false)
  flags & S_HOVER ? darkTxtColor : defTxtColor

const ICON_SCALE = 0.65
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"
const timerIcon = "ui/skin#battlepass/boost_time.svg"

let squadTypeIconSize = hdpxi(24)
let premIconSize = hdpxi(26)

let isSquadPremium = @(squad) squad?.premIcon != null
  || (squad?.sign ?? SIGN_NONE) == SIGN_PREMIUM

let squadTypeSvg = soldierKinds.map(@(c) c.icon)
  .__update({
      tank = "tank_icon.svg"
      aircraft = "aircraft_icon.svg"
      assault_aircraft = "assault_aircraft_icon.svg"
      bike = "bike_icon.svg"
      mech = "mech_icon.svg"
      truck = "truck_icon.svg"
      jeep = "jeep_icon.svg"
    })
  .map(@(key) $"ui/skin#{key}")

let getSquadTypeIcon = @(squadType) squadTypeSvg?[squadType] ?? squadTypeSvg.unknown

let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
  color = defTxtColor
}.__update(fontSub, override)

let mkTextArea = @(text) mkText(text).__update({
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = SIZE_TO_CONTENT
  maxWidth = pw(80)
})


function mkSquadSpawnDesc(canSpawnSquad, readiness, canSpawnSoldier, isAffordable, price, score) {
  if (canSpawnSquad == null || readiness == null)
    return mkTextArea(loc("respawn/squadNotChosen"))

  let descKeyId = !canSpawnSquad && readiness == 100 && price <= 0 ? "respawn/squadNotParticipate"
    : price > 0 && !isAffordable ? "respawn/notAffordableSubtext"
    : !canSpawnSquad ? "respawn/squadNotReady"
    : !canSpawnSoldier ? "respawn/soldierNotReady"
    : readiness < 100 ? "respawn/squadPartiallyReady"
    : price > 0 ? "respawn/squadReadyWithCost"
    : null
  return descKeyId == null ? null : mkTextArea(loc(descKeyId, { number = readiness, price, score }))
}

let mkSquadSpawnIcon = @(size = hdpxi(20))
  {
    rendObj = ROBJ_IMAGE
    margin = smallPadding
    hplace = ALIGN_RIGHT
    size = [size, size]
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"ui/skin#ban_icon.svg:{size}:{size}")
    color = spawnNotReadyColor
  }

function mkSquadIcon(img, override = {}) {
  if ((img ?? "") == "")
    return {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = FLEX
    }
  local size = FLEX
  if (img.endswith(".svg") && "size" in override) {
    size = override.size
    if (typeof size != "array")
      size = [size, size]
    img = $"{img}:{size[0].tointeger()}:{size[1].tointeger()}"
  }
  return {
    rendObj = ROBJ_IMAGE
    size
    keepAspect = KEEP_ASPECT_FIT
    image = Picture(img)
  }.__update(override)
}

let squadBgColor = @(sf, selected, hasAlertStyle = false)
  sf & S_HOVER ? squadSlotBgHoverColor
    : selected ? squadSlotBgActiveColor
    : hasAlertStyle ? squadSlotBgAlertColor
    : squadSlotBgIdleColor


let mkCardText = @(text, sf) {
  rendObj = ROBJ_TEXT
  behavior = Behaviors.Marquee
  scrollOnHover = true
  text
  color = txtColor(sf)
}

let squadTypeIcon = @(squadType, iconSize = squadTypeIconSize, override = {}) {
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  image = Picture("{0}:{1}:{1}".subst(getSquadTypeIcon(squadType), iconSize))
  keepAspect = KEEP_ASPECT_FIT
}.__update(override)

let mkSquadTypeIcon = @(squadType, sf, _selected, iconSize = squadTypeIconSize) {
  padding = [0, smallPadding]
  children = squadTypeIcon(squadType, iconSize, { color = txtColor(sf) })
}


const typeCircleSize = hdpx(34)
let mkSquadType = @(squadType) {
  size = const [typeCircleSize, typeCircleSize]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
  fillColor = 0xFF000000
  color = 0xFF000000
  children = mkSquadTypeIcon(squadType, 0, false)
}


let mkSquadUnits = @(amount, sf) (amount ?? 0) == 0 ? null : {
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  gap = miniPadding
  margin = miniPadding
  valign = ALIGN_CENTER
  children = [
    txt({ text = amount, color = txtColor(sf) })
    faComp("user", { fontSize = hdpx(12), color = txtColor(sf) })
  ]
}


let rentTimerSize = hdpxi(32)
let timerSize = hdpxi(20)

let mkRentClockIcon = @(iSize) {
  rendObj = ROBJ_IMAGE
  size = [iSize, iSize]
  image = Picture($"{timerIcon}:{iSize}:{iSize}")
  color = brightAccentColor
}

let rentClockIcon = mkRentClockIcon(rentTimerSize)

let squadTimer = {
  size = FLEX_V
  valign = ALIGN_BOTTOM
  margin = [0, smallPadding]
  children = [
    {
      padding = smallPadding
      rendObj = ROBJ_BOX
      fillColor = panelBgColor
      borderRadius = hdpx(10)
      children = mkRentClockIcon(timerSize)
    }
  ]
}

let borderThickness = hdpxi(3)
let mkSquadLevel = @(battleRating, levelText, expireTime, sf, addChild) {
  size = FLEX_H
  valign = ALIGN_CENTER
  margin = [0,0,borderThickness,0]
  children = [
    {
      padding = [miniPadding, midPadding]
      children = addChild
    }
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = miniPadding
      padding = [miniPadding, midPadding]
      vplace = ALIGN_BOTTOM
      valign = ALIGN_CENTER
      halign = ALIGN_RIGHT
      rendObj = ROBJ_IMAGE
      image = levelNestGradient
      children = [
        expireTime == 0 ? null : squadTimer
        battleRating != null ? mkBattleRatingShort(battleRating) : mkCardText(levelText, sf)
      ]
    }
  ]
}


function mkSquadPremIcon(premIcon, override = null) {
  if (premIcon == null)
    return null

  let [ iconW = premIconSize, iconH = premIconSize ] = override?.size
  return (override ?? {}).__merge({
    rendObj = ROBJ_IMAGE
    size = [iconW, iconH]
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{premIcon}:{iconW}:{iconH}")
  })
}

function mkSquadSpecIconFields(armyId, squadId, isPremium = false, override = null) {
  if (!isPremium)
    return null

  let { premIcon = armiesPresentation?[armyId].premIcon } = getSquadPresentation(squadId, armyId)
  return premIcon == null ? null : mkSquadPremIcon(premIcon, override)
}

function mkSquadSpecIcon(squad, override = null) {
  let armyId = getLinkedArmyName(squad)
  let { squadId } = squad
  let isPremium = isSquadPremium(squad)
  return mkSquadSpecIconFields(armyId, squadId, isPremium, override)
}

const sound = {
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
}

let borderWidth = freeze([0,0,borderThickness,0])
let margin2 = freeze([smallPadding, midPadding])
let margin1 = [0, 0, 0, midPadding]

function getSquadMedal(soldiers) {
  foreach (soldier in soldiers ?? []) {
    if (soldier?.isHero) {
      return mkSoldierMedalIcon(soldier, hdpx(20))
    }
  }

  return null
}

function mkSquadCard(squadData) {
  let { idx, isSelected, addChild = null, squadType = null, squadSize = null, level = null,
    isFaded = false, premIcon = null, onClick = null, addedRightObj = null, mkChild = null,
    expireTime = 0, onDoubleClick = null, onHover = null, squadCardSize = null,
    battleRating = null, guid = null } = squadData
  local { icon = "" } = squadData

  let stateFlags = Watched(0)
  if (icon == null || icon == "")
    icon = defaultSquadIcon
  let size = squadCardSize ?? multySquadPanelSize
  let isSelectedObservable = isObservable(isSelected)
  let watch = [stateFlags, soldiersBySquad]
  if (isSelectedObservable)
    watch.append(isSelected)
  let iconSize = array(2, size[1] * ICON_SCALE)
  let xmbNode = XmbNode()
  let squadIcon = mkSquadIcon(icon, {
    size = iconSize
    margin = margin1
    vplace = ALIGN_CENTER
  })
  let onElemState = @(nsf) stateFlags.set(nsf)
  let premIconC = premIcon == null ? null : mkSquadPremIcon(premIcon)
  let behavior = onClick == null ? null : Behaviors.Button

  return function() {
    let sf = stateFlags.get()
    let selected = isSelectedObservable ? isSelected.get() : isSelected
    let medal = getSquadMedal(soldiersBySquad.get()?[guid])

    return {
      watch
      key = idx
      size
      borderWidth = selected ? borderWidth : 0
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = squadBgColor(sf, selected)
      behavior
      sound
      xmbNode
      opacity = isFaded ? 0.7 : 1.0
      onElemState
      onHover
      onClick
      onDoubleClick
      children = [
        {
          size = FLEX
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = smallPadding
          children = [
            squadIcon
            {
              minWidth = sw(1)
              minHeight = typeCircleSize
              vplace = ALIGN_TOP
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              padding = [midPadding, 0, 0, 0]
              children = medal
            }
          ]
        }
        {
          size = FLEX_H
          vplace = ALIGN_BOTTOM
          children = mkSquadLevel(battleRating,
            premIcon == null && level != null
              ? loc("level/short", { level = level + 1 })
              : loc("squad/allResearchesCompleted"),
            expireTime, sf, addChild)
        }
        premIconC
        {
          flow = FLOW_VERTICAL
          gap = smallPadding
          margin = margin2
          hplace = ALIGN_RIGHT
          halign = ALIGN_RIGHT
          children = [
            mkSquadType(squadType)
            addedRightObj
              ?? mkChild?(sf)
              ?? mkSquadUnits(squadSize, sf)
          ]
        }
      ]
    }
  }
}


let mkRentInfo = @(rentTime, rentText = loc("rentHeader"), override = {}) {
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      size = FLEX
      rendObj = ROBJ_BOX
      fillColor = panelBgColor
      borderRadius = hdpx(10)
    }
    {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      padding = [smallPadding, midPadding]
      valign = ALIGN_CENTER
      children = [
        rentClockIcon
        {
          flow = FLOW_VERTICAL
          children = [
            mkText(rentText, { color = defTxtColor })
            rentTime > 0
              ? mkText(secondsToHoursLoc(rentTime), { color = brightAccentColor })
              : mkText("expired", { color = negativeTxtColor })
          ]
        }
      ]
    }
  ]
}.__update(override)


return {
  txtColor
  isSquadPremium
  mkSquadCard
  mkSquadIcon
  squadTypeIcon
  mkSquadTypeIcon
  mkSquadPremIcon
  mkSquadSpecIconFields
  mkSquadSpecIcon
  squadBgColor
  mkCardText
  mkSquadSpawnIcon
  mkSquadSpawnDesc
  mkRentInfo
}
