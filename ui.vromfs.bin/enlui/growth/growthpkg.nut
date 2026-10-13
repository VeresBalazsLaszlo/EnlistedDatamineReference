import "%ui/vehicles/allowedVehicles.nut" as allowedVehicles
import "%ui/soldiers/components/viewItemScene.nut" as viewItemScene
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import titleTxtColor, smallPadding, bigPadding, defTxtColor, defSlotBgColor, midPadding
from "%ui/components/soldiersUiComps.nut" import kindIcon
from "%ui/soldiers/mkSquadPromo.nut" import newSquadBlock, starterPerkBlock, primePerkBlock
from "%ui/soldiers/components/itemDetailsComp.nut" import mkViewDetailsBrief, mkViewDetailsCard
from "%ui/soldiers/model/items_list_lib.nut" import mkShopItem
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/components/itemsInfo.nut" import itemNameFromTemplate, iconByGameTemplate
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/components/textButton.nut" import Regular
from "%ui/soldiers/unlockSquadScene.nut" import openUnlockSquadScene
from "%ui/growth/growthState.nut" import GrowthStatus, curGrowthId
from "%ui/components/itemTier.nut" import DEFAULT_PREMIUM_LEVEL, mkTierStars
from "%ui/soldiers/components/perksPackage.nut" import getSoldierClassPerksPoints, getStatDescFull
from "%ui/battleData/testDrive.nut" import mkItemTestDriveButtonUi
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/vehicles/vehiclesListState.nut" import goToSquad
from "%ui/soldiers/model/state.nut" import curArmy, curUnlockedSquads
from "%ui/ui_library.nut" import *

let detailsDescStyle = freeze({ color = defTxtColor }.__update(fontSub))
let headerTitleStyle = freeze({ color = titleTxtColor }.__update(fontSub))

const bigIconSize = hdpxi(32)
let itemImgStyle = const { width = hdpxi(300), height = hdpxi(150) }
let relationIconSize = const [hdpxi(24), hdpxi(24)]
let squadIconSize = const [hdpxi(30), hdpxi(18)]
let elemBarSize = const [hdpxi(218), hdpxi(80)]


let templateSize = {
  width = elemBarSize[0] - midPadding * 2
  height = elemBarSize[1] - midPadding * 2
}


let mkText = @(text, style = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = FLEX_H
  color = titleTxtColor
  text
}.__update(fontSub, style)


function mkVehicleSquadBtn(cb = @() null) {
  return function() {
    let watch = [curGrowthId, curArmy, allowedVehicles]
    let basetpl = curGrowthId.get()

    let squadsWithVehicle = (allowedVehicles.get()?[curArmy.get()] ?? {})
      .reduce(function(result, squadsV, squadId) {
        if (basetpl in squadsV)
          result.append(squadId)
        return result
      }, [])
    if (squadsWithVehicle.len() == 0)
      return { watch }

    local availableSquad = null
    foreach(item in squadsWithVehicle) {
      availableSquad = curUnlockedSquads.get().findvalue(@(squad) squad.squadId == item)?.squadId
      if (availableSquad)
        break
    }

    if (availableSquad == null)
      return { watch }

    function btnAction() {
      goToSquad(availableSquad)
      cb()
    }

    return {
      watch
      size = FLEX_H
      children = Regular(loc("GoToSquad"), btnAction, { size = FLEX_H })
    }
  }
}

function mkSquadDescBlock(squad, armyId) {
  let { newClass, newPerk = null, isPrimeSquad = false } = squad
  let { shortLocId, perksId } = getClassCfg(newClass)
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    vplace = ALIGN_CENTER
    gap = bigPadding
    children = [
      newSquadBlock(armyId, newClass)
      mkText(getSoldierClassPerksPoints(perksId))
      starterPerkBlock(newPerk)
      isPrimeSquad
        ? primePerkBlock(getStatDescFull(perksId, armyId))
        : {
            rendObj = ROBJ_TEXTAREA
            textOverflowY = TOVERFLOW_CLIP
            behavior = [Behaviors.TextArea, Behaviors.WheelScroll]
            size = FLEX
            color = titleTxtColor
            text = loc(shortLocId)
          }.__update(fontSub)
    ]
  }
}


function mkSquadDetails(data, classesCfg, squadsById, cb = @() null) {
  let { squad, armyId } = data
  let {
    nameLocId, titleLocId, image, id, newClass = null,
    itemType = null, itemSubType = null
  } = squad
  let squadCfg = squadsById?[armyId][id]
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      {
        size = const [FLEX, hdpxi(270)]
        valign = ALIGN_BOTTOM
        children = [
          {
            size = FLEX
            rendObj = ROBJ_IMAGE
            image = Picture(image)
            keepAspect = KEEP_ASPECT_FILL
            imageValign = ALIGN_TOP
          }
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            padding = smallPadding
            valign = ALIGN_CENTER
            children = [
              newClass == null
                ? itemTypeIcon(itemType, itemSubType, {
                    size = const [hdpxi(bigIconSize), hdpxi(bigIconSize)]
                  })
                : kindIcon(classesCfg?[newClass].kind ?? newClass, hdpxi(bigIconSize), defTxtColor)
              {
                size = FLEX_H
                flow = FLOW_VERTICAL
                children = [
                  mkText(loc(titleLocId), headerTitleStyle)
                  mkText(loc(nameLocId), detailsDescStyle)
                ]
              }
            ]
          }
        ]
      }
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          Regular(loc("btn/view"), function() {
            openUnlockSquadScene(armyId, squadCfg, { hasTestDrive = true })
            cb()
          })
          mkVehicleSquadBtn()
        ]
      }
      mkSquadDescBlock(squad, armyId)
    ]
  }
}

function mkItemDetails(data, cb = @() null) {
  let { item, itemTemplate, armyId } = data
  let { gametemplate } = item
  let itemDetails = mkShopItem(itemTemplate, item, armyId)

  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      {
        size = FLEX_H
        rendObj = ROBJ_SOLID
        color = defSlotBgColor
        children = iconByGameTemplate(gametemplate, itemImgStyle)
      }
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            children = [
              Regular(loc("btn/view"), function() {
                viewItemScene(itemDetails)
                cb()
              })
              mkVehicleSquadBtn(cb)
            ]
          }
          mkItemTestDriveButtonUi(itemDetails, { size = FLEX_H }, cb)
        ]
      }
      makeVertScroll({
        size = FLEX_H
        children = mkViewDetailsBrief(itemDetails)
      }, {
        size = FLEX
        styling = thinStyle
        rootBase = {
          behavior = Behaviors.Pannable
        }
      })
    ]
  }
}

function mkGrowthItemCard(data) {
  let { item, itemTemplate, armyId } = data
  let { gametemplate } = item
  let itemDetails = mkShopItem(itemTemplate, item, armyId)

  return {
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      {
        size = FLEX_H
        rendObj = ROBJ_SOLID
        color = defSlotBgColor
        children = iconByGameTemplate(gametemplate, itemImgStyle)
      }
      mkViewDetailsCard(itemDetails)
    ]
  }
}

function mkGrowthRewardsText(reward, templates, squads) {
  let { itemTemplate = null, squadId = null } = reward
  if (itemTemplate == null && squadId == null)
    return []

  let item = templates?[itemTemplate]
  let squad = squads?[squadId]
  let res = []
  if (item != null)
    res.append(itemNameFromTemplate(item))
  if (squad != null)
    res.append(loc(squad.titleLocId))

  return res
}



let relationsIcon = @(status, color) {
  rendObj = ROBJ_IMAGE
  size = relationIconSize
  hplace = ALIGN_RIGHT
  keepAspect = KEEP_ASPECT_FIT
  margin = smallPadding
  image = Picture("ui/skin#icons/angle_icon.svg:{0}:{1}"
    .subst(relationIconSize[0], relationIconSize[1]))
  color
  opacity = status == GrowthStatus.UNAVAILABLE ? 0.7 : 1
}


let squadIcon = @(color) {
  rendObj = ROBJ_IMAGE
  size = squadIconSize
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  keepAspect = KEEP_ASPECT_FIT
  margin = [0, 0, smallPadding, 0]
  image = Picture("ui/skin#icons/squad_icon.svg:{0}:{1}".subst(squadIconSize[0], squadIconSize[1]))
  color
}


function mkGrowthInfo(item, squad, status, elemsColor, curRelations) {
  let { upgradeIdx = 0, gametemplate = "", sign = 0, upgradesId = "" } = item
  let stars = sign != 0 && upgradesId == "" ? DEFAULT_PREMIUM_LEVEL : upgradeIdx
  let imgStyle = status != GrowthStatus.UNAVAILABLE ? {} : { picSaturate = 0, opacity = 0.7 }
  let itemIcon = iconByGameTemplate(gametemplate, imgStyle.__update(templateSize))
  return {
    size = FLEX
    padding = smallPadding
    children = [
      itemIcon
      mkTierStars(stars, { fontSize = hdpxi(12) }
        .__update({
          color = elemsColor
          hplace = ALIGN_CENTER
          margin = curRelations == null ? 0 : [0,relationIconSize[0],0,0]
        }))
      squad == null ? null : squadIcon(elemsColor)
    ]
  }
}


let mkGrowthSlotElems = @(elemsColor, status, item, squad, curRelations = null) {
  size = FLEX
  children = [
    curRelations == null ? null : relationsIcon(status, elemsColor)
    mkGrowthInfo(item, squad, status, elemsColor, curRelations)
  ]
}


const tierColor = 0xFF292F38
const tierProgressColor = 0xFFFBB01C

let mkTierObject = @(progress, leftObj = null, rightObj = null) {
  size = FLEX
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = tierColor
      children = [
        {
          size = [pw(min(progress * 100, 100)), FLEX]
          rendObj = ROBJ_SOLID
          color = tierProgressColor
        }
        {
          size = FLEX
          padding = [0, midPadding]
          valign = ALIGN_CENTER
          children = [
            leftObj
            rightObj
          ]
        }
      ]
    }
    {
      size = const [ph(50), FLEX]
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/uiskin/progress_bar_tail.svg:{30}:{60}:K")
      color = progress < 1 ? tierColor : tierProgressColor
    }
  ]
}


return freeze({
  mkSquadDetails
  mkItemDetails
  mkGrowthItemCard
  mkGrowthRewardsText
  mkGrowthSlotElems
  mkTierObject
  elemBarSize
})
