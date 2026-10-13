from "%ui/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed

let spyCanChangeClothes = Watched(true)
let spyDetected = Watched(false)
let spyDisguised = Watched(false)

ecs.register_es("spy_detected_state", {
  onChange = function(_, comp){
    spyCanChangeClothes.set(comp.spy_soldier__canChangeClothes)
    spyDetected.set(comp.spy_soldier__detected)
    spyDisguised.set(!comp.spy_soldier__detected)
  }
  onInit = function(_, comp){
    spyCanChangeClothes.set(comp.spy_soldier__canChangeClothes)
    spyDetected.set(false)
    spyDisguised.set(false)
  }
  onDestroy = function(_, __) {
    spyCanChangeClothes.set(true)
    spyDetected.set(false)
    spyDisguised.set(false)
  }
},
{
  comps_track = [
    ["spy_soldier__detected", ecs.TYPE_BOOL],
    ["spy_soldier__canChangeClothes", ecs.TYPE_BOOL]
  ]
  comps_rq = ["hero"]
})

let spyClothesChange = mkEcsComputed({
  comps = [
    ["spy_soldier__clothesChangeEndTime", ecs.TYPE_FLOAT],
    ["spy_soldier__clothesChangeTotalTime", ecs.TYPE_FLOAT],
  ]
  comps_rq = ["hero"]
})

let spyClothesChangeEndTime = Computed(@() spyClothesChange.get()?.spy_soldier__clothesChangeEndTime ?? 0)
let spyClotheTotalChangeTime = Computed(@() spyClothesChange.get()?.spy_soldier__clothesChangeTotalTime ?? 3)

return {
  spyClotheTotalChangeTime
  spyClothesChangeEndTime
  spyCanChangeClothes
  spyDetected
  spyDisguised
}
