import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/controls_online_storage.nut" import isAimAssistEnabled
from "%ui/ui_library.nut" import *

let comps = {
  comps_rq = ["human_input"],
  comps_rw = [["aim_assist__enabled", ecs.TYPE_BOOL]]
}
let findHumanToAimAssist = ecs.SqQuery("findHumanToAimAssist", comps)

function setAssistValToEntity(val, comp){
  comp["aim_assist__enabled"] = val
}

isAimAssistEnabled.subscribe(function(val) {
  findHumanToAimAssist.perform(function(_eid, comp) {setAssistValToEntity(val, comp)})
})

ecs.register_es("assists_ui_es", {
  onInit = @(_eid,comp) setAssistValToEntity(isAimAssistEnabled.get(), comp),
}, comps)
