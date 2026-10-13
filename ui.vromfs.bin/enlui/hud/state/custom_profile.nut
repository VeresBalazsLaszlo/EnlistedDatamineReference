import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let customProfileState = mkEcsComputed({
  comps = [["customProfile", ecs.TYPE_STRING], ["joinProfile", ecs.TYPE_BOOL]]
})

let customProfile = Computed(function() {
  let state = customProfileState.get()
  return state == null ? null : {
    path = state.customProfile
    isJoined = state.joinProfile
  }
})

return {
  customProfile
}