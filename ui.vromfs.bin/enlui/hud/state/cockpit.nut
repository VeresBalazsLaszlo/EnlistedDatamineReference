import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *



let cockpit = mkEcsComputed({
  comps = [
    ["cockpit__slitNodes", ecs.TYPE_INT_LIST],
    ["cockpit__isAttached", ecs.TYPE_BOOL],
  ]
})

let canChangeCockpitView = Computed(function() {
  let slitNodes = cockpit.get()?.cockpit__slitNodes
  return (slitNodes?.len() ?? 0) > 1
})


let bomberCockpit = mkEcsComputed({
  comps = [["cockpit__isBomberCockpit", ecs.TYPE_BOOL]]
})
let isBomberCockpitView = Computed(@() bomberCockpit.get() != null)

return {
  canChangeCockpitView = canChangeCockpitView
  isBomberCockpitView = isBomberCockpitView
}