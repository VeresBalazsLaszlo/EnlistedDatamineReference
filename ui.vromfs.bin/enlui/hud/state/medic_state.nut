import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/human_actions.nut" import ACTION_REVIVE_TEAMMATE
from "%ui/ui_library.nut" import *

let heroMedicState = mkEcsComputed({
  comps = [
    ["medic__canHealSelectedSoldier", ecs.TYPE_BOOL],
    ["useActionAvailable", ecs.TYPE_INT]
  ]
  comps_rq = ["hero"]
  comps_no = ["deadEntity"]
})

let canHealSelectedSoldier = Computed(function() {
  let state = heroMedicState.get()
  return state != null && state.medic__canHealSelectedSoldier
    && state.useActionAvailable != ACTION_REVIVE_TEAMMATE
})

let heroMedicMedpacks = mkEcsComputed({
  comps = [["total_kits__targetOnlyHeal", ecs.TYPE_INT]]
  comps_rq = ["hero"]
  defVal = 0
})

return {
  canHealSelectedSoldier
  heroMedicMedpacks
}