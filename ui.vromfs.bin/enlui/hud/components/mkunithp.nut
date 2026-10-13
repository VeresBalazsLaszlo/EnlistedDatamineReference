from "%ui/ui_library.nut" import *


const hpBarHeight = hdpx(8)
let iconSize = [hdpxi(28), hdpxi(28)]
const iconColor = 0xFF999999
const hpColor = 0xFF660000

let mkBar = @(color = 0xFF666666, pwVal = 100) {
  size = [pw(pwVal), FLEX]
  rendObj = ROBJ_SOLID
  color
}

let defIcon = {
  size = iconSize
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#skull.svg:{0}:{1}".subst(iconSize[0], iconSize[1]))
  color = iconColor
}

function mkUnitHp(curVal, maxVal, params = {}, icon = defIcon, addObject = null) {
  let progress = maxVal == 0 ? 0 : 100.0 * curVal / maxVal
  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = hdpx(8)
    valign = ALIGN_CENTER
    children = [
      icon
      {
        size = [FLEX, params?.height ?? hpBarHeight]
        children = [
          mkBar()
          mkBar(params?.color ?? hpColor, progress)
          addObject
        ]
      }
    ]
  }
}


return mkUnitHp
