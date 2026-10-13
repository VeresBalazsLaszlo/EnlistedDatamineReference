import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/dasenums.nut" import CanTerraformCheckResult
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/hero_weapons.nut" import curWeaponWeapType
from "dasevents" import EventOnDig
from "%ui/ui_library.nut" import *

let lastDigResult = Watched(CanTerraformCheckResult.Successful)
let hideTip = @() lastDigResult.set(CanTerraformCheckResult.Successful)

const TIP_SHOW_TIME = 5

ecs.register_es("on_event_dig_es",
  {
    [EventOnDig] = function(evt, _eid, _comp) {
      if (evt.canTerraformCheckResult != CanTerraformCheckResult.Successful) {
        gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
      }
      lastDigResult.set(evt.canTerraformCheckResult)
    }
  },
  { comps_rq=["watchedByPlr"] }
)

let cannotDigAtPosTip = @(last_dig_result) tipCmp({
  text = loc(last_dig_result == CanTerraformCheckResult.NearByObjects ? "hint/cannotDigAtPosNearByObjects" :
             last_dig_result == CanTerraformCheckResult.NearByBuildingPreview ? "hint/cannotDigAtPosNearByBuildingPreview"
             : "hint/cannotDigAtPos")
})

return @() {
  watch = [curWeaponWeapType, lastDigResult]
  children = curWeaponWeapType.get() == "melee" && lastDigResult.get() != CanTerraformCheckResult.Successful
           ? cannotDigAtPosTip(lastDigResult.get())
           : null
}