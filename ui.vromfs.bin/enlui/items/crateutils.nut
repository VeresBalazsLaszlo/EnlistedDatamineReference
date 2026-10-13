from  "%ui/components/squadsPresentation.nut" import getSquadArmy, getSquadPresentation
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/defcomps.nut" import txt
from "%ui/profile/decoratorPkg.nut" import mkViewDecoratorById
from "%ui/soldiers/model/cratesContent.nut" import DropKind
from "%ui/components/itemsInfo.nut" import iconByItem, itemNameFromTemplate
from "%ui/vehicles/customizePkg.nut" import getDecorConfig, mkCamouflageImage
from "%ui/unlocks/dailyRewardsPkg.nut" import mkRewardCardByPresentation, mkRewardCardByTemplate
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/components/soldiersUiComps.nut" import kindIcon, classIcon
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/ui_library.nut" import *
from "%ui/style/designConst.nut" import smallPadding, midPadding, defBgColor, activeTxtColor,
  defTxtColor, titleTxtColor, darkBgColor
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/shop/numberUtils.nut" import abbreviateAmount
from "%ui/items/itemsPresentation.nut" import rewardsPresentation

const decorIconSize = hdpxi(140)
const squadIconSize = hdpxi(100)
const rewardSize = [hdpxi(220), hdpxi(220)]
const smallRewardSize = [hdpxi(170), hdpxi(170)]
const infoIconSize = hdpxi(24)

const DEFAULT_CRATE_IMAGE = "ui/skin#rewards/crate_medium_1"

let itemIconSize = @(size) {
  width = size[0]
  height = (size[1] * 0.6).tointeger()
}

let itemTypeName = @(text) {
  rendObj = ROBJ_TEXT
  text
  vplace = ALIGN_TOP
  color = defTxtColor
}.__update(fontSub)

let itemNameTextarea = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  text
}.__update(fontSub)

let nameWithNote = @(main, second = null) main == null && second == null ? null : {
  flow = FLOW_VERTICAL
  vplace = ALIGN_BOTTOM
  size = FLEX_H
  children = [
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = main
      halign = ALIGN_CENTER
      color = titleTxtColor
    }.__update(fontSub)
    second == null ? null : {
      size = FLEX_H
      rendObj = ROBJ_TEXT
      behavior = [Behaviors.Marquee, Behaviors.Button]
      speed = 50
      delay = 0.3
      scrollOnHover = true
      text = second
      color = defTxtColor
      halign = ALIGN_CENTER
    }.__update(fontSub)
  ]
}

let mkImage = @(image, size) {
  size = size ?? FLEX
  rendObj = ROBJ_IMAGE
  image
  keepAspect = KEEP_ASPECT_FILL
}

let mkCount = @(count) count > 1 ? {
    size = FLEX_H
    margin = smallPadding
    vplace = ALIGN_BOTTOM
    halign = ALIGN_RIGHT
    rendObj = ROBJ_TEXT
    padding = [0, smallPadding]
    text = loc("common/amountShort", { count = abbreviateAmount(count) })
    color = activeTxtColor
  }.__update(fontBody) : null


let mkRewardCard = @(children, size) {
  size
  rendObj = ROBJ_SOLID
  color = defBgColor
  padding = [midPadding, smallPadding]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children
}

let mkPresentation = @(presentation, addObj, size, count = 0)
  mkRewardCardByPresentation(presentation, count, addObj, size)

let emptyCard = @(size, count = 1) mkRewardCard([mkCount(count)], size)

let mkArmy = @(armyId) mkArmyIcon(armyId, infoIconSize,
  const { hplace = ALIGN_LEFT, vplace = ALIGN_TOP })

let mkItemCard = @(template, armyId, count, size) template == null
  ? emptyCard(size, count)
  : mkRewardCard([
      iconByItem(template, itemIconSize(size), armyId, true)
      mkCount(count)
      mkArmy(armyId)
      itemNameTextarea(itemNameFromTemplate(template))
    ], size)

function soldierDesc(data) {
  let { id, armyId = "", heroName = null } = data
  let { kind, sClass, locId } = getClassCfg(id)
  return {
    size = FLEX
    children = [
      {
        vplace = ALIGN_TOP
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = [
          mkArmyIcon(armyId, infoIconSize)
          { size = FLEX }
          {
            rendObj = ROBJ_SOLID
            color = darkBgColor
            padding = smallPadding
            flow = FLOW_HORIZONTAL
            children = [
              kindIcon(kind, infoIconSize)
              classIcon(armyId, sClass, infoIconSize)
            ]
          }
        ]
      }
      {
        rendObj = ROBJ_SOLID
        color = darkBgColor
        valign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        children = txt(heroName ?? loc(locId))
      }
    ]
  }
}

let rewardView = {
  [DropKind.ITEM] = function(data, params) {
    let { id, count } = data
    let { mapping = {}, templates = {}, commonArmyId = "", size = rewardSize } = params
    let armyId = templates?.findindex(@(v) id in v)
    let template = templates?[armyId][id]
    return commonArmyId == armyId
      ? mkPresentation(mapping?[id] ?? {}, mkCount(count), size)
      : mkItemCard(template, armyId, count, size)
  },

  [DropKind.VEHICLE] = function(data, params) {
    let { id, count } = data
    let { templates = {}, size = rewardSize } = params
    let armyId = templates?.findindex(@(v) id in v)
    let template = templates?[armyId][id]
    return mkItemCard(template, armyId, count, size)
  },

  [DropKind.DECORATOR] = function(data, params) {
    let { id, count } = data
    let { size = rewardSize } = params
    return mkRewardCard([
      mkViewDecoratorById(id)
      mkCount(count)
    ], size)
  },

  [DropKind.VEHDECORATOR] = function(data, params) {
    let { id, count } = data
    let { size = rewardSize } = params
    let { iconCtor = null } = getDecorConfig(params?.vCustCfg.findindex(@(v) id in v))
    return iconCtor == null
      ? emptyCard(size, count)
      : mkRewardCard([
          iconCtor({ id }, {
            iconSize = decorIconSize
            size = const [decorIconSize, decorIconSize]
          })
          mkCount(count)
        ], size)
  },

  [DropKind.CAMOUFLAGE] = function(data, params) {
    let { id } = data
    let { camoCfg = {}, camoVehicles = {}, templates = {}, size = rewardSize } = params

    foreach (basetpl, skins in camoVehicles) {
      if (id not in skins)
        continue

      let cfg = camoCfg?[basetpl][id]
      if (cfg == null)
        break

      let armyId = templates.findindex(@(v) basetpl in v)
      let template = templates?[armyId][basetpl]
      let vehName = template == null ? null : loc(itemNameFromTemplate(template))
      return mkRewardCard([
        itemTypeName(loc("vehCamouflageHeader"))
        mkCamouflageImage(cfg, { iconSize = decorIconSize })
        nameWithNote(loc($"skin/{id}"), vehName)
        mkArmy(armyId)
      ], size)
    }
    return emptyCard(size)
  },

  [DropKind.SQUAD] = function(data, params) {
    let { id } = data
    let { size = rewardSize } = params
    let armyId = getSquadArmy(id)
    let cfg = getSquadPresentation(id, armyId)
    return cfg == null ? emptyCard(size) : mkRewardCard([
      mkImage(Picture(cfg.icon), [squadIconSize, squadIconSize])
      itemNameTextarea(loc(cfg.titleLocId))
      mkArmy(armyId)
    ], size)
  },

  [DropKind.SOLDIER] = function(data, params) {
    let { count } = data
    let { size = rewardSize } = params
    return mkPresentation(params?.mapping["any_soldier"] ?? {}, soldierDesc(data), size, count)
  },

  [DropKind.HERO] = function(data, params) {
    let { count } = data
    let { size = rewardSize } = params
    return mkPresentation(params?.mapping["any_soldier"] ?? {}, soldierDesc(data), size, count)
  },

  [DropKind.BOOSTER] = function(data, params) {
    let { id, count } = data
    let { size = rewardSize } = params
    return mkRewardCard([
      mkRewardCardByTemplate(id)
      mkCount(count)
    ], size)
  },

  [DropKind.CURRENCY] = function(data, params) {
    let { id, count } = data
    let { mapping = {}, size = rewardSize } = params
    return mkPresentation(mapping?[id] ?? {}, mkCount(count), size)
  },

  [DropKind.OUTFIT] = function(data, params) {
    let { id, count } = data
    let { templates = {}, size = rewardSize } = params
    let armyId = templates?.findindex(@(v) id in v)
    let template = templates?[armyId][id]
    return mkRewardCard([
      iconByItem(template, itemIconSize(size), armyId)
      mkCount(count)
      mkArmy(armyId)
    ], size)
  },

  [DropKind.CRATE] = function(data, params) {
    let { id } = data
    let { size = rewardSize } = params
    let { name = null, desc = null, cardImage = DEFAULT_CRATE_IMAGE } = rewardsPresentation?[id]
    return mkRewardCard([
      mkImage(Picture(cardImage), rewardSize)
      nameWithNote(name, desc)
    ], size)
  }
}

function mkCrateItemView(item, params) {
  let { kind } = item
  return rewardView?[kind](item, params)
}

function getMainVehicles(camoCfg, templates, drops) {
  let skins = {}
  foreach (item in drops) {
    let { kind, id } = item
    if (kind != DropKind.CAMOUFLAGE)
      continue

    skins[id] <- ""
  }

  let res = {}
  foreach (vehBasetpl, skinTbl in camoCfg)
    foreach (id, tpl in skins) {
      if (id not in skinTbl || tpl != "")
        continue

      let armyId = templates?.findindex(@(v) vehBasetpl in v)
      let { sign = 0 } = templates?[armyId][vehBasetpl]
      if (sign > 0)
        continue

      skins[id] <- vehBasetpl

      let vehToSkin = res?[vehBasetpl]
      if (vehToSkin)
        vehToSkin[id] <- true
      else
        res[vehBasetpl] <- { [id] = true }
    }

  return res
}


return {
  mkCrateItemView
  rewardSize
  smallRewardSize

  getMainVehicles
}
