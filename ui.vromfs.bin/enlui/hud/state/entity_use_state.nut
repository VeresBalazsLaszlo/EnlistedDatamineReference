import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/state/time_state.nut" import curTime
from "%ui/scene_update.nut" import frameUpdateCounter
from "%sqstd/math.nut" import lerp
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

let entityUse = mkEcsComputed({
  comps = [
    ["human_inventory__entityUseStart", ecs.TYPE_FLOAT],
    ["human_inventory__entityUseEnd", ecs.TYPE_FLOAT],
  ]
  comps_rq = ["watchedByPlr"]
})


let entityUseStart = Computed(@() entityUse.get()?.human_inventory__entityUseStart ?? -1.0)
let entityUseEnd = Computed(@() entityUse.get()?.human_inventory__entityUseEnd ?? -1.0)

let itemUseProgress = Watched(0)

let doCalcTime = Watched(false)
function calcitemUseProgress(...){
  local res = 0
  if (curTime.get() <= entityUseEnd.get()) {
    res = lerp(entityUseStart.get(), entityUseEnd.get(), 0.0, 100.0, curTime.get())
    if (!doCalcTime.get())
      doCalcTime.set(true)
  }
  else
    doCalcTime.set(false)

  itemUseProgress.set(res)
}
doCalcTime.subscribe(function(v) {
  if (!v)
    frameUpdateCounter.unsubscribe(calcitemUseProgress)
  else
    frameUpdateCounter.subscribe(calcitemUseProgress)
})

subscribeList(calcitemUseProgress, entityUseEnd, entityUseStart)


return {
  medkitStartTime = entityUseStart
  medkitEndTime = entityUseEnd
}
