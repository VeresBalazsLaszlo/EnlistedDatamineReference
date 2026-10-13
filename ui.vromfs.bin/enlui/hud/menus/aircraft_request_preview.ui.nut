import "%dngscripts/ecs.nut" as ecs
from "team" import TEAM_UNASSIGNED
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/hud/menus/artillery_radio_map_shell_type.nut" import currentShellType
from "dagor.math" import Point2, Point3
from "dagor.debug" import logerr
from "%ui/ui_library.nut" import *

let aircraftRespbasesQuery = ecs.SqQuery("aircraftRespbasesQuery", {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["team", ecs.TYPE_INT]
  ],
  comps_rq = ["aircraftRespbase"]
})

function calcAircraftRequestTargetBiases(aircraftRequestSpawnBiases) {
  local countFriendlyTeam = 0
  local spawnFriendlyTeam = Point2()

  local countEnemyTeam = 0
  local spawnEnemyTeam = Point2()

  aircraftRespbasesQuery.perform(function(_eid, comps){
    if (comps.team == TEAM_UNASSIGNED)
      return

    if ((localPlayerTeam.get() ?? TEAM_UNASSIGNED) == comps.team) {
      countFriendlyTeam = countFriendlyTeam + 1
      spawnFriendlyTeam = Point2(comps.transform.getcol(3).x, comps.transform.getcol(3).z)
    }
    else {
      countEnemyTeam = countEnemyTeam + 1
      spawnEnemyTeam = Point2(comps.transform.getcol(3).x, comps.transform.getcol(3).z)
    }
  })

  local dir = Point2(1., 0.)

  if (countEnemyTeam == 0 || countFriendlyTeam == 0)
    logerr("Need at least one friendly / enemy aircraft spawn point")
  else {
    dir = spawnEnemyTeam * (1. / countEnemyTeam) - spawnFriendlyTeam * (1. / countFriendlyTeam)
    dir.normalize()
  }

  let xAxis = Point3(dir.y, 0., -dir.x)
  let yAxis = Point3(0., 1., 0.)
  let zAxis = xAxis % yAxis

  local res = []

  foreach (spawnBias in aircraftRequestSpawnBiases)
    res.append(xAxis * spawnBias.x + yAxis * spawnBias.y + zAxis * spawnBias.z)

  return res
}

let aircraftRequestTargetBiases = Computed(function() {
  if (!currentShellType.get())
    return []

  let artilleryTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(currentShellType.get().name)

  if (!artilleryTemplate)
    return []

  let isAircraftRequest = artilleryTemplate.getCompValNullable("aircraft_request")

  if (!isAircraftRequest)
    return []

  let aircraftRequestBiases = artilleryTemplate.getCompValNullable("aircraft_request__aircraftBiases")

  return calcAircraftRequestTargetBiases(aircraftRequestBiases)
})

function mkAircraftRequestPreviewEllipse(minimapVisibleRadius, radius) {
  let canvasRadius  = radius / minimapVisibleRadius * 50.0

  return [VECTOR_ELLIPSE, 50, 50, canvasRadius, canvasRadius]
}

function mkAircraftRequestPreview(worldPos, radius, minimapVisibleRadius, fillColor = Color(84, 24, 24, 5)) {
  return {
    transform = {
      pivot = [0.5, 0.5]
    }

    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(0)
    color = Color(0, 0, 0, 0)

    fillColor = fillColor
    size = FLEX

    data = {
      worldPos = worldPos
      clampToBorder = false
    }

    commands = [
      [VECTOR_FILL_COLOR, fillColor],
      [VECTOR_WIDTH, 0],
      mkAircraftRequestPreviewEllipse(minimapVisibleRadius, radius)
    ]
  }
}

return {
  aircraftRequestTargetBiases
  mkAircraftRequestPreview
}
