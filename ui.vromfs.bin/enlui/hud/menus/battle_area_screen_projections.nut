import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let projections = mkEcsComputed({
  comps = [["battle_area__activeBattleAreasScreenProjections", ecs.TYPE_FLOAT_LIST]]
})


let battleAreasProjections = Computed(@() (projections.get()?.len() ?? 0) > 0 ? projections.get() : null)


let projectionOn = Watched(false)

ecs.register_es("battle_areas_projections_state", {
  [["onInit", "onChange"]] = @(_eid, comps) projectionOn.set(comps.battle_area__projectionOn)
}, {
  comps_track = [
    ["battle_area__projectionOn", ecs.TYPE_BOOL]
  ]
})

function battleAreaScreenProjection() {
  if (battleAreasProjections.get() == null)
    return { watch = [battleAreasProjections] }
  let commands = [[VECTOR_INVERSE_POLY].extend(battleAreasProjections.get())]
  return {
    watch = [ battleAreasProjections ]
    color = Color(0, 0, 0, 150)
    fillColor = Color(0, 0, 0, 150)
    rendObj = ROBJ_VECTOR_CANVAS
    commands
    lineWidth = hdpx(1)
    size = const [sw(100), sh(100)]
  }
}

return {
  battleAreaScreenProjection
  projectionOn
}
