import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody
from "%ui/components/soldiersUiComps.nut" import kindIcon
from "%ui/style/designConst.nut" import titleTxtColor, activeTxtColor, midPadding, defTxtColor, commonBtnHeight, accentTitleTxtColor
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/ui_library.nut" import *

const btnSizeSmall = [hdpx(330), commonBtnHeight]
const btnSizeBig = [hdpx(400), commonBtnHeight]
const mainBgColor = Color(98, 98, 80)
const primeColor = Color(146, 10, 1)
const receivedColor = Color(98, 98, 80)
const unavailableColor = Color(96, 96, 96)
const progressBarWidth = hdpxi(787)

let mkText = @(txt, style = {}) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = txt
}.__update(fontBody, style)

function mkSquadName(params) {
  let { nameLocId = "", titleLocId = "", sClass = null, itemType = null, itemSubType = null } = params
  return {
    flow = FLOW_HORIZONTAL
    gap = midPadding
    padding = const [midPadding * 2, midPadding * 4]
    minWidth = hdpx(300)
    valign = ALIGN_CENTER
    children = [
      sClass == null
        ? itemTypeIcon(itemType, itemSubType, { size = hdpxi(55) })
        : kindIcon(sClassesCfg.get()?[sClass].kind ?? sClass, hdpx(55), titleTxtColor)
      {
        flow = FLOW_VERTICAL
        children = [
          mkText(loc(nameLocId), { color = accentTitleTxtColor }).__update(fontBody)
          mkText(loc(titleLocId), { color = titleTxtColor }).__update(fontHeading2)
        ]
      }
    ]
  }
}

let headerBgImage = freeze({
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/gameImage/base_header_bar.svg:{hdpxi(150)}:4:K?Ac")
})

function campaignName(params) {
  let { hasReceived, isPrimeSquad = false } = params
  return {
    vplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    pos = const [-hdpx(23), 0]
    size = FLEX_H
    children = [
      {
        children = [
          headerBgImage.__merge({
            color = isPrimeSquad ? primeColor
              : hasReceived ? receivedColor
              : unavailableColor
          })
          mkSquadName(params)
        ]
      }
      {
        rendObj = ROBJ_VECTOR_CANVAS
        size = hdpx(15)
        lineWidth = 0
        color = 0
        fillColor = isPrimeSquad ? Color(69, 24, 24)
          : Color(54, 54, 45)
        commands = const [
          [VECTOR_POLY, 0,0, 100,0, 100,100]
        ]
      }
    ]}
}

let mkReceivedBanner = @(bgColor) {
  size = hdpx(180)
  hplace = ALIGN_RIGHT
  clipChildren = true
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    size = const [hdpx(300), hdpx(50)]
    pos = const [hdpx(20), -hdpx(20)]
    transform = const { rotate = 45 }
    rendObj = ROBJ_SOLID
    color = bgColor
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = const {
      rendObj = ROBJ_TEXT
      text = loc("squads/received")
    }.__merge(fontBody)
  }
}

const infoBtnSize = hdpxi(20)

let weapInfoBtn =  @(sf) {
  rendObj = ROBJ_IMAGE
  size = const [infoBtnSize, infoBtnSize]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  margin = midPadding
  image =  Picture("{0}:{1}:{1}".subst("ui/skin#info/info_icon.svg", infoBtnSize))
  color = sf & S_ACTIVE ? activeTxtColor
    : sf & S_HOVER ? titleTxtColor
    : activeTxtColor
}

return freeze({
  campaignName
  btnSizeSmall
  btnSizeBig
  receivedCommon = mkReceivedBanner(mainBgColor)
  weapInfoBtn
  progressBarWidth
})