from "%ui/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed


let curGroupActive = Watched("")


let spawner1 = mkEcsComputed({
  comps = [
    ["wave_bot_spawner__squadsToSpawn", ecs.TYPE_INT],
    ["wave_bot_spawner__nextSpawnTime", ecs.TYPE_FLOAT]
  ]
  comps_filter = [["team", ecs.TYPE_INT]]
  filter = "team == 1"
})

let spawner2 = mkEcsComputed({
  comps = [
    ["wave_bot_spawner__squadsToSpawn", ecs.TYPE_INT],
    ["wave_bot_spawner__nextSpawnTime", ecs.TYPE_FLOAT]
  ]
  comps_filter = [["team", ecs.TYPE_INT]]
  filter = "ne(team, 1)"
})

let botsWaitingCount1 = Computed(@() spawner1.get()?.wave_bot_spawner__squadsToSpawn ?? 0)
let nextWaveSpawnTime1 = Computed(@() spawner1.get()?.wave_bot_spawner__nextSpawnTime ?? 0.0)
let botsWaitingCount2 = Computed(@() spawner2.get()?.wave_bot_spawner__squadsToSpawn ?? 0)
let nextWaveSpawnTime2 = Computed(@() spawner2.get()?.wave_bot_spawner__nextSpawnTime ?? 0.0)

return {
  botsWaitingCount1
  nextWaveSpawnTime1
  botsWaitingCount2
  nextWaveSpawnTime2
  curGroupActive
}
