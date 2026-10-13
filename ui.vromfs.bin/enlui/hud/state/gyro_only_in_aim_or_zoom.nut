import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/controls_online_storage.nut" import isGyroOnlyInAimOrZoomEnabled
from "%ui/ui_library.nut" import *

let comps = {
  comps_rq = ["human_input"],
  comps_rw = [["human_input__isGyroOnlyInAimOrZoom", ecs.TYPE_BOOL]]
}
let findHumanInput = ecs.SqQuery("findHumanInput", comps)


isGyroOnlyInAimOrZoomEnabled.subscribe(@(enabled) findHumanInput(
  @(_eid, comp) comp.human_input__isGyroOnlyInAimOrZoom = enabled
))


ecs.register_es("gyro_only_in_aim_or_zoom_ui_es", {
  onInit = @(_eid, comp) comp.human_input__isGyroOnlyInAimOrZoom = isGyroOnlyInAimOrZoomEnabled.get(),
  onDestroy = @(_eid, comp) comp.human_input__isGyroOnlyInAimOrZoom = false
}, comps)
