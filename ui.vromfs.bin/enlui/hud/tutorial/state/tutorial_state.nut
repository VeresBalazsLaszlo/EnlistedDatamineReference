import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *



let tutorialMission = mkEcsComputed({
  comps = [["tutorial__profile", ecs.TYPE_STRING, ""]]
  comps_rq = ["isTutorial"]
})
let isTutorial = Computed(@() tutorialMission.get() != null)

return {
  isTutorial
}
