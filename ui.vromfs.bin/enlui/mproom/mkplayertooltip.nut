import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import smallPadding, midPadding, activeBgColor, defTxtColor
from "%ui/components/decoratorsPresentation.nut" import getPortrait
from "%ui/soldiers/components/armyPackage.nut" import mkArmySimpleIcon
from "%ui/mpRoom/components/memberComps.nut" import memberName, mkStatusImg
from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/ui_library.nut" import *

let roomMemberStatuses = require("%ui/mpRoom/roomMemberStatuses.nut")

const portraitSize = hdpxi(132)

let mkText = @(text, color = defTxtColor) {
  rendObj = ROBJ_TEXT, color, text
}.__update(fontSub)

let mkTextWithIcon = @(icon, text) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      size = const [hdpx(35), SIZE_TO_CONTENT]
      children = icon
    }
    mkText(text)
  ]
}

function mkPortrait(portrait) {
  let { icon } = getPortrait(portrait)
  return {
    padding = smallPadding
    rendObj = ROBJ_BOX
    borderColor = activeBgColor
    borderWidth = hdpx(1)
    children = {
      size = const [portraitSize, portraitSize]
      rendObj = ROBJ_IMAGE
      image = Picture("!{0}:{1}:{1}".subst(icon, portraitSize))
    }
  }
}

let mkStatusRow = @(statusCfg) mkTextWithIcon(
  mkStatusImg(statusCfg.icon, statusCfg?.iconColor)
  loc(statusCfg.locId))

function mkPlayerTooltip(player) {
  let { public, nameText } = player
  let { army = null, status = null, portrait = "", nickFrame = "" } = public
  let statusCfg = roomMemberStatuses?[status]
  if (army == "")
    log($"army is an empty string in mkPlayerTooltip in {player}")
  return tooltipCtor({
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = [
      mkPortrait(portrait)
      @() {
        watch = allArmiesInfo
        flow = FLOW_VERTICAL
        gap = midPadding
        children = [
          memberName(nameText, nickFrame)
          statusCfg == null ? null : mkStatusRow(statusCfg)
          army == null || army == "" ? null
            : mkTextWithIcon(mkArmySimpleIcon(army, hdpx(20), { margin = 0 }),
              loc($"country/{allArmiesInfo.get()[army].country}"))
        ]
      }
    ]
})
}

return mkPlayerTooltip