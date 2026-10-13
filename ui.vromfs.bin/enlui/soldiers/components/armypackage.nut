import "%ui/components/armiesPresentation.nut" as armiesPresentation
from "%ui/style/designConst.nut" import bigGap, armyIconSize
from "%ui/ui_library.nut" import *

let mkIcon = @(sIcon, size, override) sIcon == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture("{0}:{1}:{1}".subst(sIcon, size.tointeger()))
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
  margin = bigGap
}.__update(override)

let mkArmyIcon = @(armyId, size = armyIconSize, override = {})
  mkIcon(armiesPresentation?[armyId].armyColorIcon ?? armyId, size, override)

let mkArmySimpleIcon = @(armyId, size = armyIconSize, override = {})
  mkIcon(armiesPresentation?[armyId].armyIcon ?? armyId, size, override)

return {
  mkArmySimpleIcon
  mkArmyIcon
}
