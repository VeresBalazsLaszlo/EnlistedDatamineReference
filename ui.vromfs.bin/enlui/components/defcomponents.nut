from "%ui/style/designConst.nut" import darkPanelBgColor, accentColor
from "%ui/helpers/gradients.nut" import mkTwoSidesGradientX
from "%ui/ui_library.nut" import *

let emptyProgress = @(val, color) {
  key = val
  rendObj = ROBJ_SOLID
  size = FLEX
  color = color ?? darkPanelBgColor
  transform = {
    pivot = [1, 0]
    scale = [val / 100.0, 1]
  }
}

let receivedProgress = @(val, color){
  rendObj = ROBJ_SOLID
  size = [pw(val), FLEX]
  color = color ?? accentColor
}

function progressBar(value, override = {}) {
  let curProgress = clamp(100.0 * value, 0, 100)
  let bgColor = override?.bgColor
  let progressColor = override?.progressColor
  return {
    size = const [FLEX, hdpxi(10)]
    children = [
      receivedProgress(curProgress, progressColor)
      emptyProgress(100 - curProgress, bgColor)
    ]
  }.__update(override)
}


let receivedGradProgress = @(image) {
  rendObj = ROBJ_IMAGE
  size = FLEX
  image
}


function gradientProgressBar(value, override = {}) {
  let curProgress = clamp(100.0 * value, 0, 100)
  let bgImage = override.bgImage
  let emptyColor = override?.emptyColor ?? darkPanelBgColor
  return {
    size = const [FLEX, hdpxi(10)]
    children = [
      receivedGradProgress(bgImage)
      emptyProgress(100 - curProgress, emptyColor)
    ]
  }.__update(override)
}


let gradient = mkTwoSidesGradientX({sideColor = 0x00FFFFFF, centerColor=0x1AFFFFFF, isAlphaPremultiplied=false})

let doubleSideHighlightLine = freeze({
  rendObj = ROBJ_IMAGE
  size = const [FLEX, hdpx(4)]
  image = gradient
})

let doubleSideHighlightLineBottom = freeze({
  rendObj = ROBJ_IMAGE
  size = const [FLEX, hdpx(4)]
  image = gradient
  vplace = ALIGN_BOTTOM
})
let mainTitleImg = mkTwoSidesGradientX({sideColor=0x002B2D44, centerColor=0xE642516C, isAlphaPremultiplied=false})
let doubleSideBg = @(content) {
  rendObj = ROBJ_IMAGE
  size = FLEX
  image = mainTitleImg
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = content
}


return freeze({
  progressBar
  gradientProgressBar
  doubleSideHighlightLine
  doubleSideBg
  doubleSideHighlightLineBottom
})