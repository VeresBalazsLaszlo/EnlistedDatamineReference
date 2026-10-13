import "%dngscripts/ecs.nut" as ecs
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let zombieSpawner = mkEcsComputed({
  comps = [
    ["entity_spawner__nextWaveAtTime", ecs.TYPE_FLOAT],
    ["entity_spawner__curWaveId", ecs.TYPE_INT],
  ]
  
  comps_rq = [
    ["entity_spawner__aliveZombiesCount", ecs.TYPE_INT],
    ["entity_spawner__counstSpawnInWave", ecs.TYPE_INT],
    ["entity_spawner__alreadySpawnInWave", ecs.TYPE_INT],
  ]
})


let isZombieMode = Computed(@() zombieSpawner.get() != null)
let zombieModeCurWave = Computed(@() zombieSpawner.get()?.entity_spawner__curWaveId ?? 0)
let zombiesNextWaveAtTime = Computed(@() zombieSpawner.get()?.entity_spawner__nextWaveAtTime ?? -1)

let zombieModeHeroPoints = mkEcsComputed({
  comps = [["paid_loot__points", ecs.TYPE_INT]]
  comps_rq = ["watchedByPlr"]
  defVal = 0
})

let zombiesNextWaveTime = mkCountdownTimerPerSec(zombiesNextWaveAtTime)


return {
  isZombieMode
  zombieModeCurWave
  zombieModeHeroPoints
  zombiesNextWaveTime
}
