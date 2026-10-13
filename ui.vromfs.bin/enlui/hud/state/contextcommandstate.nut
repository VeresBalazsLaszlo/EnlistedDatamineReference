import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let state = mkEcsComputed({
  comps = [
    ["human_context_command__orderType", ecs.TYPE_INT],
    ["human_context_command__orderUseEntity", ecs.TYPE_EID],
  ]
  comps_rq = ["human_context_command_input"]
  tags = "gameClient"
})

return {
  orderType = Computed(@() state.get()?.human_context_command__orderType ?? 0)
  orderUseEntity = Computed(@() state.get()?.human_context_command__orderUseEntity ?? ecs.INVALID_ENTITY_ID)
}
