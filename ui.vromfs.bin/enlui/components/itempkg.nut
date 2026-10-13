import "%ui/components/faComp.nut" as faComp
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/style/designConst.nut" import msgHighlightedTxtColor, smallPadding, hoverTxtColor, vehicleListCardSize, listCtors, defTxtColor
from "%ui/style/statusIcon.nut" import statusIconChosen, statusIconDisabled, statusIconLocked
from "%ui/components/itemTier.nut" import mkItemTier
from "%ui/components/itemsInfo.nut" import itemNameFromItem, itemNameFromGametemplate, getItemDesc
from "%ui/components/battleRatingPkg.nut" import mkBattleRating
from "%ui/ui_library.nut" import *

let { txtColor } = listCtors

const iconSize = hdpx(15)
const badgeSize = hdpx(40)

let mkStatusIcon = @(icon, color) faComp(icon, {
  margin = smallPadding
  fontSize = iconSize
  color
})

let iconChosen = mkStatusIcon("check", statusIconChosen)
let iconBlocked = mkStatusIcon("ban", statusIconDisabled)

let mkBackBlock = @(children) {
  rendObj = ROBJ_BOX
  size = array(2, hdpx(19))
  borderWidth = 0
  borderRadius = hdpx(5)
  fillColor = statusIconLocked
  clipChildren = true
  margin = smallPadding
  valign = ALIGN_CENTER
  children = children
}

let iconLocked = faComp("lock", {
  size = array(2, hdpx(19))
  fontSize = iconSize
  color = statusIconLocked
})

let mkIconWarning = @(size) faComp("warning", {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  fontSize = size
  color = statusIconLocked
  animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1.0, play = true, loop = true, easing = CosineFull }]
})

let mkLevelBlock = @(level) mkBackBlock({
  rendObj = ROBJ_TEXT
  size = FLEX_H
  halign = ALIGN_CENTER
  text = level
  color = hoverTxtColor
}.__update(fontSub))

let statusIconCtor = @(demands) demands == null ? null
  : demands?.canObtainInShop ? null
  : iconLocked

let mkHintText = @(text, params = fontSub) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  text = text
  color = msgHighlightedTxtColor
}.__update(params)

let mkStatusHint = @(demands) demands == null ? null
  : demands?.canObtainInShop ? mkHintText(loc("itemObtainInShop"))
  : mkHintText(loc("itemOutOfStock"))

function mkVehicleHint(vehicle) {
  let desc = getItemDesc(vehicle)
  let { growthTier = 0 } = vehicle
  return tooltipCtor({
    flow = FLOW_VERTICAL
    minWidth = hdpx(350)
    maxWidth = hdpx(500)
    gap = smallPadding
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        children = [
          mkHintText(itemNameFromItem(vehicle), { color = defTxtColor }.__update(fontBody))
          mkItemTier(vehicle)
        ]
      }
      desc == "" ? null : mkHintText(desc, { color = defTxtColor })
      mkBattleRating(growthTier)
    ]
  })
}

function mkItemHintFromTemplate(template) {
  let desc = getItemDesc(template)
  let { growthTier = 0, gametemplate = "" } = template
  return tooltipCtor({
    flow = FLOW_VERTICAL
    minWidth = hdpx(350)
    maxWidth = hdpx(500)
    gap = smallPadding
    children = [
      mkHintText(itemNameFromGametemplate(gametemplate), { color = defTxtColor }.__update(fontBody))
      desc == "" ? null : mkHintText(desc, { color = defTxtColor })
      mkBattleRating(growthTier)
    ]
  })
}

let statusBadgeWarning = mkIconWarning(badgeSize)

let mkNoVehicle = @(sf, color = null) {
  size = [FLEX, vehicleListCardSize[1] - smallPadding * 2]
  children = [
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_CENTER
      text = loc("menu/vehicle/none")
      color = color ?? txtColor(sf)
    }.__update(fontSub)
    statusBadgeWarning
  ]
}

return freeze({
  statusIconLocked = iconLocked
  statusIconChosen = iconChosen
  statusIconBlocked = iconBlocked
  statusIconCtor = statusIconCtor
  statusIconWarning = mkIconWarning(iconSize)
  statusBadgeWarning
  statusLevel = mkLevelBlock
  statusTier = mkItemTier 
  hintText = mkHintText
  statusHintText = mkStatusHint
  mkVehicleHint
  mkNoVehicle
  mkItemHintFromTemplate
})
