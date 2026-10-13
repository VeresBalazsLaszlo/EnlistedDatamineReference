options no_aot
require ecs
require ecs.common
require DagorMath
require math.base
require math.linear
require AnimV20
require Gun
require GeomNodeTree
require math.ang
require SmokeOccluder
require RendInst
require GridCollision
require Dacoll
require ecs.ecs_template
require DagorDebug3D
require DagorConsole
require gameLibs.pufd_events.pufd_events
require game.utils.team

[ecs_template]
struct spy_debug_draw
  spyDebug : Tag

[console_cmd(name="spy_debug")]
def spy_debug()
  var exists = false
  query() <| $ [es(REQUIRE=spyDebug)] (eid : EntityId)
    destroyEntity(eid)
    exists = true
  if !exists
    createEntity("spy_debug_draw")
  console_print("Spy debug is {exists ? "off" : "on"}")

def private debug_check_watcher_sees_spies(shootPos, shootDir : float3;
                                           watcher_team : int;
                                           is_zooming : bool)
  if shootPos == float3() || shootDir == float3()
    return
  var spyFounded = false
  var detectedSpyFounded = false
  var distApplied = false
  var visibleDist = 0.
  var coneBackOffset = 0.
  var shootPosForAngleCheck = float3()
  var detAngle = 0.

  find_query() <| $ [es(REQUIRE_NOT=deadEntity)] (team : int;
                                                  animchar : AnimcharBaseComponent;
                                                  spy_soldier__detected : bool;
                                                  spy_soldier__targetNodeIdx : int;
                                                  spy_soldier__detectionAngle : float;
                                                  spy_soldier__detectionAngleWithScope : float;
                                                  spy_soldier__detectionConeBackOffset : float;
                                                  spy_soldier__detectionConeBackOffsetWithScope : float;
                                                  spy_soldier__detectionVisibleDist : float;
                                                  spy_soldier__detectionVisibleDistWithScope : float)
    if !distApplied
      distApplied = true
      visibleDist = is_zooming ? spy_soldier__detectionVisibleDistWithScope : spy_soldier__detectionVisibleDist
      coneBackOffset = is_zooming ? spy_soldier__detectionConeBackOffsetWithScope : spy_soldier__detectionConeBackOffset
      detAngle = deg_to_rad(is_zooming ? spy_soldier__detectionAngleWithScope : spy_soldier__detectionAngle)
      shootPosForAngleCheck = shootPos - shootDir * coneBackOffset

    let aimPos = geomtree_getNodeWpos(*animchar.nodeTree, spy_soldier__targetNodeIdx)
    if watcher_team == team || length_sq(aimPos - shootPos) > square(visibleDist)
      return false
    if angle(shootDir, normalize(aimPos - shootPosForAngleCheck)) > detAngle || angle(shootDir, normalize(aimPos - shootPos)) > HALF_PI
      return false
    let targetDir = normalize(aimPos - shootPos)
    let dist = length(aimPos - shootPos)
    var t = dist + 0.5
    var norm : float3
    if traceray_normalized(shootPos, targetDir, t, norm)
      return false
    if rayhit_entities_in_grid(ecs_hash("vehicles"), shootPos, targetDir, t, INVALID_ENTITY_ID)
      return false
    if traceTransparencyRayRIGenNormalized(shootPos, targetDir, dist, 0.01)
      return false
    if rayhit_smoke_occluders(shootPos, aimPos)
      return false
    spyFounded = true
    detectedSpyFounded ||= spy_soldier__detected
    return detectedSpyFounded

  let color = detectedSpyFounded ? E3DCOLOR(0xFFFF0000) : spyFounded ? E3DCOLOR(0xFF0000FF) : E3DCOLOR(0xFF00FF00)
  draw_debug_cone_buffered(shootPosForAngleCheck, shootPosForAngleCheck + shootDir * (visibleDist + coneBackOffset),
                            detAngle, color, 16, 1)


[es(tag=(render, dev), no_order, REQUIRE=spyDebug)]
def spy_detection_draw(info : ParallelUpdateFrameDelayed)
  var spyExist = false
  query() <| $ [es(REQUIRE_NOT=deadEntity)] (transform : float3x4; spy_soldier__detected : bool; spy_soldier__canChangeClothes : bool)
    spyExist = true
    let color = spy_soldier__detected ? E3DCOLOR(0xFFFF0000) : !spy_soldier__canChangeClothes ? E3DCOLOR(0xFF0000FF) : E3DCOLOR(0xFF00FF00)
    draw_debug_sphere_buffered(transform[3] + float3(0., 1.5, 0.), 0.3, color, 12, 1)

  if !(find_query <| $ [es(REQUIRE=spy_soldier__animationEntity)] () => true)
    return

  query() <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (team : int;
                                                            human_anim__vehicleSelected : EntityId;
                                                            human_net_phys__isZooming : bool;
                                                            human_weap__currentGunEid : EntityId)
    if !!human_anim__vehicleSelected
      return
    var shootPos = float3()
    var shootDir = float3()
    query(human_weap__currentGunEid) <| $ [es] (gun : Gun)
      shootPos = gun.gunTm[3]
      shootDir = gun.gunTm[0]
    debug_check_watcher_sees_spies(shootPos, shootDir, team, human_net_phys__isZooming)

  query() <| $ [es(REQUIRE_NOT=deadEntity)] (team : int; turret_control__gunEids : EidList; vehicle_seats__seatEids : EidList)
    if empty(turret_control__gunEids)
      return
    var hasOccupant = false
    for seatEid in vehicle_seats__seatEids
      if !!(get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID)
        hasOccupant = true
        break
    if !hasOccupant
      return
    var shootPos = float3()
    var shootDir = float3()
    query(turret_control__gunEids[0]) <| $ [es(REQUIRE_NOT=controlledByTankAiGunner)] (gun : Gun)
      shootPos = gun.gunTm[3]
      shootDir = gun.gunTm[0]
    debug_check_watcher_sees_spies(shootPos, shootDir, team, false)
