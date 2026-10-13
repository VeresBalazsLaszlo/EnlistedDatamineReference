import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/menus/artillery_radio_map_shell_type.nut" import currentShellType
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR, HUD_TIPS_FAIL_TEXT_COLOR
from "%ui/hud/state/artillery.nut" import activeAircraftRequestTimeLeft
from "%ui/hud/menus/mapComps.nut" import hintTextFunc
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/ui_library.nut" import *

let isAircraftRequest = Computed(function() {
  if (!currentShellType.get())
    return false

  let artilleryTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(currentShellType.get().name)

  return artilleryTemplate?.getCompValNullable("aircraft_request") != null
})

let artRequestTips = @() {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    watch = [activeAircraftRequestTimeLeft]
    children = [
      hintTextFunc(loc("artillery/bombers_cooldown"), DEFAULT_TEXT_COLOR)
      hintTextFunc(secondsToStringLoc(activeAircraftRequestTimeLeft.get()), HUD_TIPS_FAIL_TEXT_COLOR)
    ]
  }

return {
  isAircraftRequest
  artRequestTips
}
