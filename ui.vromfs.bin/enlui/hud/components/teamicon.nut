import "%ui/components/armiesPresentation.nut" as armiesPresentation
from "%ui/ui_library.nut" import *
from "types" import String

const logo_size = fsh(6)
const ARMY_ICON_UNKNOWN = "ui/skin#unknown.svg"

let getArmyIcon = @(armyId) armiesPresentation?[armyId].armyColorIcon ?? ARMY_ICON_UNKNOWN

function image_from_attr(image_name, size) {
  assert(image_name instanceof String || image_name==null, "image_name should be string")
  if (image_name==null)
    return null

  if (image_name.endswith("svg"))
    return Picture("{0}:{1}:{1}".subst(image_name,size.tointeger()))

  return Picture("{0}".subst(image_name))
}

let mkTeamIcon = @(state, size = logo_size) @() {
  rendObj = ROBJ_IMAGE
  watch = state
  size = [size, size]
  image = image_from_attr(state.get(), size)
}

return {
  mkTeamIcon
  getArmyIcon
}
