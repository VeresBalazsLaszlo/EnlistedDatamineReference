import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/warnings.nut" import warningUpdate, addWarnings
from "%ui/ui_library.nut" import *

let { WARNING_PRIORITIES } = require("%ui/hud/state/warnings.nut")
const nearEnemyRespawnWarning = "nearEnemyRespawn"
const nearEnemyRespawnWarningDamage = "nearEnemyRespawnDamage"

let displayNearEnemyRespawnWarningDamage = Watched(false)
let displayNearEnemyRespawnWarning = Watched(false)

const WARNING_VISIBLE_TIME = 5.0
let warningTimer = @() displayNearEnemyRespawnWarning.set(false)
let warningDamageTimer = @() displayNearEnemyRespawnWarningDamage.set(false)

addWarnings({
  [nearEnemyRespawnWarning]         = { priority = WARNING_PRIORITIES.HIGH },
  [nearEnemyRespawnWarningDamage]   = { priority = WARNING_PRIORITIES.HIGH }
})

function trackComponents(_eid, comp) {
  let showNearEnemySpawnWarningDamage = comp.isAlive && comp.isNearEnemyRespawnWarningDamage
  warningUpdate(nearEnemyRespawnWarningDamage, showNearEnemySpawnWarningDamage)
  gui_scene.clearTimer(warningDamageTimer)
  if (showNearEnemySpawnWarningDamage)
    gui_scene.resetTimeout(WARNING_VISIBLE_TIME, warningDamageTimer)
  displayNearEnemyRespawnWarningDamage.set(showNearEnemySpawnWarningDamage)

  let showNearEnemySpawnWarning = !showNearEnemySpawnWarningDamage && comp.isAlive && comp.isNearEnemyRespawnWarning
  warningUpdate(nearEnemyRespawnWarning, showNearEnemySpawnWarning)
  gui_scene.clearTimer(warningTimer)
  if (showNearEnemySpawnWarning)
    gui_scene.resetTimeout(WARNING_VISIBLE_TIME, warningTimer)
  displayNearEnemyRespawnWarning.set(showNearEnemySpawnWarning)
}

ecs.register_es("near_enemy_respawn_ui_es",
  {
    [["onInit", "onChange"]] = trackComponents,
  },
  {
    comps_rq = ["hero"],
    comps_track = [
      ["isAlive", ecs.TYPE_BOOL],
      ["isNearEnemyRespawnWarning", ecs.TYPE_BOOL],
      ["isNearEnemyRespawnWarningDamage", ecs.TYPE_BOOL],
    ]
  }
)

return {
  displayNearEnemyRespawnWarning
  displayNearEnemyRespawnWarningDamage
}