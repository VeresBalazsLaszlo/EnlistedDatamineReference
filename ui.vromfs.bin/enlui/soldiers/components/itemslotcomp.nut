from "%ui/style/designConst.nut" import defItemBlur, darkTxtColor, defTxtColor
from "%ui/ui_library.nut" import *

const lockColor = 0xFFFFFFFF
const lockIconSize = hdpxi(20)
const lockObjSize = hdpx(32)

let mkLockedBlock = @(color) {
  rendObj = ROBJ_WORLD_BLUR
  size = FLEX
  fillColor = color
  color = defItemBlur
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      size = FLEX
      rendObj = ROBJ_VECTOR_CANVAS
      lineWidth = hdpx(2)
      color = lockColor
      opacity = 0.05
      commands = [[ VECTOR_LINE, 0, 0, 100, 100 ], [ VECTOR_LINE, 0, 100, 100, 0 ]]
    }
    {
      size = const [lockObjSize, lockObjSize]
      rendObj = ROBJ_VECTOR_CANVAS
      commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
      fillColor = color
      color
    }
    {
      rendObj = ROBJ_IMAGE
      size = array(2, lockIconSize)
      image = Picture($"ui/skin#locked_icon.svg:{lockIconSize}:{lockIconSize}")
      color = lockColor
      opacity = 0.05
    }
  ]
}


function mkEmptyItemSlotImg(img, imgSize, group, isSelected) {
  if (img == null)
    return null
  let image = Picture($"ui/skin#{img}:{imgSize}:{imgSize}")
  return watchElemState(@(sf) {
    watch = isSelected
    size = array(2, imgSize)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    group
    color = (sf & S_HOVER) || isSelected.get() ? darkTxtColor : defTxtColor
    image
    opacity = (sf & S_HOVER) || isSelected.get() ? 1 : 0.2
  })
}


return {
  mkLockedBlock
  mkEmptyItemSlotImg
}
