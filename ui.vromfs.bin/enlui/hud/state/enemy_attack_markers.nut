import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap



let enemy_attack_markers = mkEcsComputedEidMap({
  comps = [["enemy_attack_marker__offset", ecs.TYPE_FLOAT, 0.0]]
  comps_rq = ["enemy_attack_marker"]
})

return enemy_attack_markers
