import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed

let isMortarMode = mkEcsComputed({
  comps = [["human_weap__mortarMode", ecs.TYPE_BOOL]]
  comps_rq = ["hero", "watchedByPlr"]
  defVal = false
})

return {
  isMortarMode
}