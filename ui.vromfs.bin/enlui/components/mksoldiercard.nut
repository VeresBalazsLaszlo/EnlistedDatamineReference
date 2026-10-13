from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/itemPkg.nut" import statusIconWarning
from "%ui/components/defcomps.nut" import autoscrollText
from "%ui/style/cursors.nut" import withTooltip
from "%ui/components/soldiersUiComps.nut" import kindIcon, classIcon, levelBlock, classTooltip, calcExperienceData, experienceTooltip, mkSoldierMedalIcon
from "%ui/components/itemsInfo.nut" import itemNameFromItem, itemNameFromGametemplate, getObjectName
from "%ui/components/soldierPhoto.nut" import mkSoldierPhoto
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/hud/state/respawnState.nut" import freeTankSeatsCount, freeTankSpawnInfoShow
from "%ui/style/designConst.nut" import panelBgColor, squadSlotBgIdleColor, squadSlotBgHoverColor, miniPadding, squadSlotBgActiveColor, squadSlotBgAlertColor, squadSlotBgMultiSelColor
  , gap, midPadding, slotBaseSize, disabledTxtColor, blockedTxtColor, deadTxtColor, defTxtColor
  , listCtors, selectedTxtColor
from "%ui/soldiers/armySquadTier.nut" import getSoldierBR
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/ui_library.nut" import *

let DISABLED_ITEM = { tint = Color(40, 40, 40, 120), picSaturate = 0.0 }
const borderThickness = hdpxi(3)
let iconDead = Picture("ui/skin#lb_deaths.avif")
const panelBgBlockedColor = Color(40,10,10,180)

let listSquadColor = @(flags, selected, massSelected, hasAlertStyle, isBlocked)
  isBlocked ? panelBgBlockedColor
    : flags & S_HOVER ? squadSlotBgHoverColor
    : selected ? squadSlotBgActiveColor
    : massSelected ? squadSlotBgMultiSelColor
    : hasAlertStyle ? squadSlotBgAlertColor
    : squadSlotBgIdleColor


const iconSize = hdpxi(26)
const deadIconSize = hdpxi(48)
let deadIcon = {
  rendObj = ROBJ_IMAGE
  size = const [deadIconSize, deadIconSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  image = iconDead
  opacity = 0.3
}

let mkPhotoSize = @(h) [h * 2 / 3, h]

function mkClassBlock(soldier, isClassRestricted, isPremium, displayedKind) {
  let { sKind = null, sClass = null, armyId = null, locPerkPoints = null } = soldier
  let color = isClassRestricted ? blockedTxtColor : defTxtColor
  return {
    size = const [hdpxi(36), FLEX]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = panelBgColor
    children = withTooltip({
      flow = FLOW_VERTICAL
      gap
      children = [
        kindIcon(displayedKind ?? sKind, iconSize).__update({ color, vplace = ALIGN_CENTER })
        isPremium ? null : classIcon(armyId, sClass, iconSize)
      ]
    }, @() classTooltip(armyId, sClass, sKind, null, locPerkPoints))
  }
}


let mkDropSoldierInfoBlock = @(soldierInfo, squadInfo, nameColor, textColor, group) { 
  size = FLEX
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  children = [
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      children = {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(squadInfo.titleLocId)
        color = textColor
      }.__update(fontSub)
    }
    autoscrollText({
      text = getObjectName(soldierInfo)
      color = nameColor
      group = group
    })
  ]
}

function getWeaponName(soldierInfo) {
  let { primaryWeapon = null, weapons = [] } = soldierInfo
  if (primaryWeapon != null)
    return itemNameFromItem(primaryWeapon)

  let name = weapons.findvalue(@(v, idx) idx < 3 && (v?.templateName ?? "") != "")?.templateName
  if (name != null)
    return itemNameFromGametemplate(name)

  return loc("delivery/withoutWeapon")
}

let mkWeaponRow = @(soldierInfo, weaponColor, group, override = {}) autoscrollText({
  text = getWeaponName(soldierInfo)
  color = weaponColor
  vplace = ALIGN_BOTTOM
  group = group
}.__update(override))

let mkWeaponRowWithWarning = @(soldierInfo, weaponColor, group, override = {}) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = hdpx(2)
  children = [
    statusIconWarning
    mkWeaponRow(soldierInfo, weaponColor, group, override)
  ]
}

function soldierName(soldierInfo, nameColor, group) {
  let { guid = "", callname = "" } = soldierInfo
  return guid == "" ? null : {
    size = const [FLEX, ph(31)]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = gap
    children = [
      mkSoldierMedalIcon(soldierInfo, hdpx(16))
      autoscrollText({
        group = group
        text = callname != "" ? callname : getObjectName(soldierInfo)
        color = nameColor
      })
      {
        padding = [miniPadding, 0, 0, 0]
        children = mkBattleRatingShort(getSoldierBR(guid))
      }
    ]
  }
}

function mkSoldierInfoBlock(soldierInfo, nameColor, weaponRow, group, expToLevel) {
  let { maxLevel = 1, level = 1 } = soldierInfo
  return {
    size = FLEX
    children = [
      {
        size = FLEX
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        children = [
          soldierName(soldierInfo, nameColor, group)
          {
            size = const [FLEX, ph(31)]
            valign = ALIGN_CENTER
            children = weaponRow
          }
          withTooltip(@()
            levelBlock(level, maxLevel, hdpx(14)).__update({ margin = [0, 0, gap, 0] }),
            @() experienceTooltip(calcExperienceData(soldierInfo, expToLevel)))
        ]
      }
    ]
  }
}

function soldierCard(soldierInfo, group = null, sf = 0, isSelected = false,
  isFaded = false, isDead = false, size = slotBaseSize, isClassRestricted = false,
  hasAlertStyle = false, hasWeaponWarning = false, addChild = null, squadInfo = null,
  isDisarmed = false, expToLevel = [], displayedKind = null, isGroupSelected = false
) {
  let {
    guid, photo = null, sClass = null, armyId = null, canSpawn = true, idx = -1
  } = soldierInfo

  let isBlocked = isDead || !canSpawn || (freeTankSpawnInfoShow.get() && idx >= freeTankSeatsCount.get() && idx != -1 && freeTankSeatsCount.get() != -1)
  let isPremium = getClassCfg(sClass)?.isPremium ?? false
  let photoStyle = isFaded || isBlocked ? DISABLED_ITEM : {}
  let noWeaponTxt = loc("delivery/withoutWeapon")

  let textColor = isGroupSelected ?  @(...) selectedTxtColor
    : isBlocked ? @(...) deadTxtColor
    : isFaded ? listCtors.txtDisabledColor
    : listCtors.weaponColor

  let nameColor = isGroupSelected ?  @(...) selectedTxtColor
    : isBlocked ? @(...) deadTxtColor
    : isFaded ? listCtors.weaponColor
    : listCtors.nameColor

  let noWeaponTxtColor = isDisarmed && isGroupSelected ? selectedTxtColor : disabledTxtColor
  let weaponRow = isDisarmed ? mkWeaponRow(soldierInfo, noWeaponTxtColor,
        group, { text = noWeaponTxt })
    : hasWeaponWarning ? mkWeaponRowWithWarning(soldierInfo, textColor(sf), group)
    : mkWeaponRow(soldierInfo, textColor(sf), group)

  return {
    key = guid
    size
    children = [
      {
        size = FLEX
        flow = FLOW_HORIZONTAL
        clipChildren = true
        children = [
          {
            size = FLEX
            flow = FLOW_HORIZONTAL
            gap = midPadding
            rendObj = ROBJ_WORLD_BLUR_PANEL
            fillColor = listSquadColor(sf, isSelected, isGroupSelected, hasAlertStyle, isBlocked)
            children = [
              isDead ? deadIcon : mkSoldierPhoto(photo, mkPhotoSize(size[1]), null, photoStyle)
              {
                size = FLEX
                children = [
                  squadInfo == null
                    ? mkSoldierInfoBlock(
                        soldierInfo,
                        nameColor(sf),
                        weaponRow,
                        group,
                        expToLevel
                      )
                    : mkDropSoldierInfoBlock(
                        soldierInfo,
                        squadInfo,
                        nameColor(sf),
                        textColor(sf),
                        group
                      )
                  addChild == null ? null : {
                    flow = FLOW_HORIZONTAL
                    vplace = ALIGN_BOTTOM
                    hplace = ALIGN_RIGHT
                    margin = hdpx(2)
                    children = addChild(soldierInfo, sf, isSelected)
                  }
                ]
              }
            ]
          }
          mkClassBlock(soldierInfo, isClassRestricted, isPremium, displayedKind)
        ]
      }
      isPremium ? classIcon(armyId, sClass, iconSize) : null
      {
        size = FLEX
        borderWidth = isSelected ? [0,0,borderThickness,0] : 0
        rendObj = ROBJ_BOX
        fillColor = 0
      }
    ]
  }
}

return kwarg(soldierCard)
