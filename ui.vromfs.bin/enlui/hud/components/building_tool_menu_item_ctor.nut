from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/hud/state/building_tool_menu_state.nut" import radius
from "%ui/hud/state/building_tool_state.nut" import availableBuildings, buildingLimits, requirePrice, availableStock, buildingAllowRecreates
from "%ui/ui_library.nut" import *

const white = Color(255,255,255)
const dark = Color(200,200,200)
const disableColor = Color(60,60,60)
const disabledTextColor = Color(50, 50, 50, 50)
const curTextColor = Color(250,250,200,200)
const defTextColor = Color(150,150,150,50)

return @(buildingIndex, image, imageSize) @(curIdx, idx) watchElemState(function(sf) {
  let count = availableBuildings.get()?[buildingIndex] ?? 0
  let limit = buildingLimits.get()?[buildingIndex] ?? 0
  let allowRecreate = buildingAllowRecreates.get()?[buildingIndex] ?? false
  let available = (allowRecreate || count > 0) && ((requirePrice.get()?[buildingIndex] ?? 0) <= availableStock.get())
  let isCurrent = (sf & S_HOVER) || curIdx == idx
  let icon = image ? {
    image = Picture(image)
    rendObj = ROBJ_IMAGE
    size = imageSize
    color = !available ? disableColor : isCurrent ? white : dark
  } : null
  let text = {
    rendObj = ROBJ_TEXT
    color = !available ? disabledTextColor
              : isCurrent ? curTextColor
              : defTextColor
    text = "{count}/{limit}".subst({count=count limit=limit})
  }.__update(fontBody)

  return {
    watch = [availableBuildings]
    children = [
      icon
      text
    ]
    size = array(2, (0.4 * radius.get()).tointeger())
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
  }
})