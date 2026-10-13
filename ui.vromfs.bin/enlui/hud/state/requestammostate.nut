import "%dngscripts/ecs.nut" as ecs
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *



let requestAmmoAllowTime = mkEcsComputed({
  comps = [["requestAmmoAllowTime", ecs.TYPE_FLOAT]]
  comps_rq = ["hero"]
  defVal = 0.0
})
let requestAmmoTimeout = mkCountdownTimerPerSec(requestAmmoAllowTime)

return {
  requestAmmoTimeout = requestAmmoTimeout
}