import "%dngscripts/ecs.nut" as ecs
from "%ui/state/autoleanState.nut" import autoleanSettingState
from "%ui/ui_library.nut" import *

let setAutoleanSettingQuery = ecs.SqQuery("setAutoleanSettingQuery", {
  comps_rw = [["autolean_settings__autolean", ecs.TYPE_BOOL]]
})

let setAutoleanSettingComponent = @(autoleanValue) setAutoleanSettingQuery(@(_eid, comp) comp.autolean_settings__autolean = autoleanValue)

autoleanSettingState.subscribe(@(autoleanValue) setAutoleanSettingComponent(autoleanValue))

ecs.register_es("autolean_settings",
  { onInit = @(_evt, _eid, comp) comp.autolean_settings__autolean = autoleanSettingState.get() },
  { comps_rw = [["autolean_settings__autolean", ecs.TYPE_BOOL]] },
  { tags="gameClient" }
)
