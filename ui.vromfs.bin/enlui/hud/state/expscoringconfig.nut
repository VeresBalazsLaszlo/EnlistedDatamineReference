import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *



let expScoreConfig = mkEcsComputed({
  comps = [["expScoreConfig", ecs.TYPE_OBJECT, {}]]
  comps_rq = ["gameModeConf"]
  defVal = {}
})
let isDesertionPenaltyEnabled = Computed(@() expScoreConfig.get()?.DESERTER_ENABLE ?? false)

return {
  isDesertionPenaltyEnabled
}
