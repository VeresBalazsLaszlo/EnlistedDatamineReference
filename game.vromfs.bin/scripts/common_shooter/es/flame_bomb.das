require app
require ecs
require math
require math.base
require DagorMath
require DagorSystem
require DagorRandom
require DaWeapons
require DaWeaponProps
require Dacoll
require Gun
require BallisticsProps
require Ballistics
require common_shooter.events_common_shooter
require enlisted.events_enlisted
require game.es.events
require game.es.vehicle.vehicle_events
require NetPropsRegistry
require DngPlane
require GamePhys
require math.interpolation

struct FlameBombConfigServer
  flameProjectile : string
  fireCount : int
  coilCount : float
  fireIdxOffset : int
  spreadSpeed : float
  carryVelCoeff : float
  fireProjectileMaxSpawnHeight : float
  explosionSpawnHeight : float
  normSpawnShift : float
  auxProjectileBlk : string


struct FlameBombConfigRender
  explosionProjectile : string
  trailProjectile : string
  spreadSpeed : float
  carryVelCoeff : float
  normSpawnShift : float
  explosionSpawnHeight : float
  trailCount : int
  trailAngle : float
  auxProjectileBlk : string


def calc_projectile_vel(theta : float; phi : float; ground_norm : float3; spread_speed : float; carry_vel_tan : float3)
  var sinTheta, cosTheta : float
  var sinPhi, cosPhi : float
  sincos(theta, sinTheta, cosTheta)
  sincos(phi, sinPhi, cosPhi)
  let vx = spread_speed * cosTheta * cosPhi
  let vy = spread_speed * sinTheta
  let vz = spread_speed * cosTheta * sinPhi
  var v = float3(vx, vy, vz)
  let rotQuat = quat(quat_from_unit_arc(float3(0, 1, 0), ground_norm))
  v = rotQuat * v
  v += carry_vel_tan
  return v


[es(tag=server, on_appear, REQUIRE=flame_bomb)]
def register_bomb_aux_projectile_props_es(evt : Event; flame_bomb__auxProjectileBlk : string)
  register_net_props(flame_bomb__auxProjectileBlk, "shell")
  register_net_props(flame_bomb__auxProjectileBlk, "damage")
  register_net_props(flame_bomb__auxProjectileBlk, "ballistics")


[es(tag=server, REQUIRE=flame_bomb)]
def flame_bomb_on_hit_scene_server_es(evt : EventProjectileHitScene;
                                      ownerEid : EntityId;
                                      launch_desc : LaunchDesc;
                                      projectile__isUnderwater : bool;
                                      flame_bomb__flameProjectile : string;
                                      flame_bomb__fireCount : int;
                                      flame_bomb__coilCount : float;
                                      flame_bomb__fireIdxOffset : int;
                                      flame_bomb__spreadSpeed : float;
                                      flame_bomb__carryVelCoeff : float;
                                      flame_bomb__normSpawnShift : float;
                                      flame_bomb__fireProjectileMaxSpawnHeight : float;
                                      flame_bomb__auxProjectileBlk : string)
  if evt.shouldStop && !projectile__isUnderwater
    let config = FlameBombConfigServer(flameProjectile = flame_bomb__flameProjectile,
                                         fireCount = flame_bomb__fireCount,
                                         coilCount = flame_bomb__coilCount,
                                         fireIdxOffset = flame_bomb__fireIdxOffset,
                                         spreadSpeed = flame_bomb__spreadSpeed,
                                         carryVelCoeff = flame_bomb__carryVelCoeff,
                                         normSpawnShift = flame_bomb__normSpawnShift,
                                         fireProjectileMaxSpawnHeight = flame_bomb__fireProjectileMaxSpawnHeight,
                                         auxProjectileBlk = flame_bomb__auxProjectileBlk)
    flame_bomb_explosion_server(evt.pos, evt.vel, evt.norm, ownerEid, launch_desc.gunPropsId, config)


[es(tag=server, before=terraform_crater_on_airplane_crash)]
def aircraft_crash_land_scene_server_es(evt : EventCrashExplosionFatal;
                                        transform : float3x4;
                                        plane_net_phys : PlaneActor;
                                        plane_landcrash_fx__flameProjectile : string;
                                        plane_landcrash_fx__coilCount : float;
                                        plane_landcrash_fx__fireIdxOffset : int;
                                        plane_landcrash_fx__carryVelCoeff : float;
                                        plane_landcrash_fx__normSpawnShift : float;
                                        plane_landcrash_fx__fireProjectileMaxSpawnHeight : float;
                                        plane_landcrash_fx__auxProjectileBlk : string;
                                        plane_landcrash_fx__fuelToFireCount : Point2List;
                                        plane_landcrash_fx__fuelToSpreadSpeed : Point2List)
  if evt.crashType == int(CrashType.CRASH_TYPE_WATER)
    return

  assume mass = plane_net_phys.phys.M
  let fuelCurrent = getFuelMassCurrent(mass)
  let fuelMax = getFuelMassMax(mass)
  let fuelRatio = fuelMax > 0.0 ? clamp(fuelCurrent / fuelMax, 0.0, 1.0) : 0.0

  let scaledFireCount = roundi(interpolate_by_point_list(plane_landcrash_fx__fuelToFireCount, fuelRatio))
  let scaledSpreadSpeed = interpolate_by_point_list(plane_landcrash_fx__fuelToSpreadSpeed, fuelRatio)

  let config = FlameBombConfigServer(flameProjectile = plane_landcrash_fx__flameProjectile,
                                        fireCount = scaledFireCount,
                                        coilCount = plane_landcrash_fx__coilCount,
                                        fireIdxOffset = plane_landcrash_fx__fireIdxOffset,
                                        spreadSpeed = scaledSpreadSpeed,
                                        carryVelCoeff = plane_landcrash_fx__carryVelCoeff,
                                        normSpawnShift = plane_landcrash_fx__normSpawnShift,
                                        fireProjectileMaxSpawnHeight = plane_landcrash_fx__fireProjectileMaxSpawnHeight,
                                        auxProjectileBlk = plane_landcrash_fx__auxProjectileBlk)
  let vel = float3(plane_net_phys.phys.currentState.velocity)
  var norm = float3(0, 1, 0)
  let traceLenBase = 15.0
  let traceOffset = 5.0
  let centerOffset = 2.0
  let traceStart = transform[3] + float3(0, traceOffset, 0)
  var t = traceLenBase + traceOffset
  if tracedown_normalized(traceStart, t, norm, ETF_ALL)
    flame_bomb_explosion_server(traceStart + float3(0, centerOffset - t, 0), vel, norm, INVALID_ENTITY_ID, int16(-1), config)


[es(tag=render, after=flame_bomb_on_hit_scene_server_es, REQUIRE=flame_bomb)]
def flame_bomb_on_hit_scene_render_es(evt : EventProjectileHitScene;
                                      ownerEid : EntityId;
                                      launch_desc : LaunchDesc;
                                      projectile__isUnderwater : bool;
                                      flame_bomb__explosionProjectile : string;
                                      flame_bomb__trailProjectile : string;
                                      flame_bomb__spreadSpeed : float;
                                      flame_bomb__carryVelCoeff : float;
                                      flame_bomb__explosionSpawnHeight : float;
                                      flame_bomb__normSpawnShift : float;
                                      flame_bomb__trailCount : int;
                                      flame_bomb__trailAngle : float;
                                      flame_bomb__auxProjectileBlk : string)
  if evt.shouldStop && !projectile__isUnderwater
    let config = FlameBombConfigRender(explosionProjectile = flame_bomb__explosionProjectile,
                                         trailProjectile = flame_bomb__trailProjectile,
                                         spreadSpeed = flame_bomb__spreadSpeed,
                                         carryVelCoeff = flame_bomb__carryVelCoeff,
                                         explosionSpawnHeight = flame_bomb__explosionSpawnHeight,
                                         normSpawnShift = flame_bomb__normSpawnShift,
                                         trailCount = flame_bomb__trailCount,
                                         trailAngle = flame_bomb__trailAngle,
                                         auxProjectileBlk = flame_bomb__auxProjectileBlk)
    flame_bomb_explosion_render(evt.pos, evt.vel, evt.norm, ownerEid, launch_desc.gunPropsId, config)


[es(tag=server, REQUIRE=eid)]
def flame_bomb_on_hit_entity_server_es(evt : EventOnProjectileHit)
  query(evt.projectileEid) <| $ [es(REQUIRE=flame_bomb)] (projectile_ballistics : ProjectileBallistics;
                                                          ownerEid : EntityId;
                                                          launch_desc : LaunchDesc;
                                                          projectile__isUnderwater : bool;
                                                          flame_bomb__flameProjectile : string;
                                                          flame_bomb__fireCount : int;
                                                          flame_bomb__coilCount : float;
                                                          flame_bomb__fireIdxOffset : int;
                                                          flame_bomb__spreadSpeed : float;
                                                          flame_bomb__carryVelCoeff : float;
                                                          flame_bomb__normSpawnShift : float;
                                                          flame_bomb__fireProjectileMaxSpawnHeight : float;
                                                          flame_bomb__auxProjectileBlk : string)
    if !projectile__isUnderwater
      let config = FlameBombConfigServer(flameProjectile = flame_bomb__flameProjectile,
                                           fireCount = flame_bomb__fireCount,
                                           coilCount = flame_bomb__coilCount,
                                           fireIdxOffset = flame_bomb__fireIdxOffset,
                                           spreadSpeed = flame_bomb__spreadSpeed,
                                           carryVelCoeff = flame_bomb__carryVelCoeff,
                                           normSpawnShift = flame_bomb__normSpawnShift,
                                           fireProjectileMaxSpawnHeight = flame_bomb__fireProjectileMaxSpawnHeight,
                                           auxProjectileBlk = flame_bomb__auxProjectileBlk)
      flame_bomb_explosion_server(evt.hitPos, projectile_ballistics.state.vel, evt.norm, ownerEid, launch_desc.gunPropsId, config)


[es(tag=render, after=flame_bomb_on_hit_entity_server_es, REQUIRE=eid)]
def flame_bomb_on_hit_entity_render_es(evt : EventOnProjectileHit)
  query(evt.projectileEid) <| $ [es(REQUIRE=flame_bomb)] (ownerEid : EntityId;
                                                          launch_desc : LaunchDesc;
                                                          projectile_ballistics : ProjectileBallistics;
                                                          projectile__isUnderwater : bool;
                                                          flame_bomb__explosionProjectile : string;
                                                          flame_bomb__trailProjectile : string;
                                                          flame_bomb__spreadSpeed : float;
                                                          flame_bomb__carryVelCoeff : float;
                                                          flame_bomb__explosionSpawnHeight : float;
                                                          flame_bomb__normSpawnShift : float;
                                                          flame_bomb__trailCount : int;
                                                          flame_bomb__trailAngle : float;
                                                          flame_bomb__auxProjectileBlk : string)
    if !projectile__isUnderwater
      let config = FlameBombConfigRender(explosionProjectile = flame_bomb__explosionProjectile,
                                           trailProjectile = flame_bomb__trailProjectile,
                                           spreadSpeed = flame_bomb__spreadSpeed,
                                           carryVelCoeff = flame_bomb__carryVelCoeff,
                                           explosionSpawnHeight = flame_bomb__explosionSpawnHeight,
                                           normSpawnShift = flame_bomb__normSpawnShift,
                                           trailCount = flame_bomb__trailCount,
                                           trailAngle = flame_bomb__trailAngle,
                                           auxProjectileBlk = flame_bomb__auxProjectileBlk)
      flame_bomb_explosion_render(evt.hitPos, projectile_ballistics.state.vel, evt.norm, ownerEid, launch_desc.gunPropsId, config)


[es(tag=server, REQUIRE=flame_projectile)]
def flame_projectile_hit_scene_es(evt : EventProjectileHitScene;
                                  flame_projectile__onHitCreate : string;
                                  ownerEid : EntityId;
                                  launch_desc : LaunchDesc)
  create_fire(evt.pos, flame_projectile__onHitCreate, ownerEid, int(launch_desc.gunPropsId), int(launch_desc.shellId.shellId))


[es(tag=server, REQUIRE=flame_projectile)]
def simple_flame_projectile_hit_scene_es(evt : SimpleProjectileHitScene;
                                         flame_projectile__onHitCreate : string;
                                         ownerEid : EntityId)
  if !evt.hitWater
    create_fire(evt.pos, flame_projectile__onHitCreate, ownerEid, -1, -1)


[es(tag=server, REQUIRE=eid)]
def flame_projectile_hit_entity_es(evt : EventOnProjectileHit)
  query(evt.projectileEid) <| $ [es(REQUIRE=flame_projectile)] (flame_projectile__onHitCreate : string;
                                                                ownerEid : EntityId;
                                                                launch_desc : LaunchDesc;
                                                                projectile__isUnderwater : bool)
    if !projectile__isUnderwater
      create_fire(evt.hitPos, flame_projectile__onHitCreate, ownerEid, int(launch_desc.gunPropsId), int(launch_desc.shellId.shellId))


def flame_bomb_explosion_render(pos : float3; vel : float3; norm : float3; owner_eid : EntityId; gun_props_id : int16; config : FlameBombConfigRender)
  let shellId = int16(register_net_props(config.auxProjectileBlk, "shell"))
  let damageId = int16(register_net_props(config.auxProjectileBlk, "damage"))
  let ballisticsId = int16(register_net_props(config.auxProjectileBlk, "ballistics"))

  let carryVel = config.carryVelCoeff * vel
  let carryVelNorm = dot(norm, carryVel) * norm
  let carryVelTan = carryVel - carryVelNorm
  let explosionVel = calc_projectile_vel(90.0 * DEG_TO_RAD, 0.0, norm, 0.5 * config.spreadSpeed, carryVelTan)
  let explosionDir = normalize(explosionVel)
  let explosionPos = pos + float3(0.0, config.explosionSpawnHeight, 0.0) + config.normSpawnShift * norm

  launch_projectile(owner_eid, INVALID_ENTITY_ID, shellId, damageId, ballisticsId, gun_props_id, config.explosionProjectile, explosionPos, explosionVel)

  for i in range(config.trailCount)
    let rotAngle = float(i - config.trailCount / 2) * config.trailAngle + 0.5 * config.trailAngle
    let trailDir = quat(float3(0, 1, 0), rotAngle) * explosionDir
    let trailVel = trailDir * length(explosionVel)
    launch_projectile(owner_eid, INVALID_ENTITY_ID, shellId, damageId, ballisticsId, gun_props_id, config.trailProjectile, explosionPos, trailVel)


def flame_bomb_explosion_server(pos : float3; vel : float3; norm : float3; owner_eid : EntityId; gun_props_id : int16; config : FlameBombConfigServer)
  let shellId = int16(register_net_props(config.auxProjectileBlk, "shell"))
  let damageId = int16(register_net_props(config.auxProjectileBlk, "damage"))
  let ballisticsId = int16(register_net_props(config.auxProjectileBlk, "ballistics"))

  let flameProjectile = clone_string(config.flameProjectile)

  let carryVel = config.carryVelCoeff * vel
  let carryVelNorm = dot(norm, carryVel) * norm
  let carryVelTan = carryVel - carryVelNorm

  let flameProjectileTmpl = getTemplateByName(flameProjectile)
  if flameProjectileTmpl == null
    return
  let isSimpleProjectile = templateHasComponent(*flameProjectileTmpl, "simple_projectile")

  for i in range(config.fireCount)
    let ratio = float(i + config.fireIdxOffset) / float(config.fireCount + config.fireIdxOffset)
    let theta = ratio * 0.25 * PI //0.25*PI = 45 deg, the angle that achieves the maximum distance of projectile's flight
    let phi = ratio * TWOPI * config.coilCount
    let fireProjectileVel = calc_projectile_vel(theta, phi, norm, config.spreadSpeed, carryVelTan)
    let fireProjectilePos = pos + float3(0.0, config.fireProjectileMaxSpawnHeight * ratio, 0.0) + config.normSpawnShift * norm
    if isSimpleProjectile
      launch_simple_projectile(flameProjectile, fireProjectilePos, fireProjectileVel)
    else
      launch_projectile(owner_eid, INVALID_ENTITY_ID, shellId, damageId, ballisticsId, gun_props_id, flameProjectile, fireProjectilePos, fireProjectileVel)


def create_fire(pos : float3; flame_template : string; owner_eid : EntityId; gun_props_id : int; shell_id : int)
  var tm = IDENT_TM
  tm[3] = pos
  createEntity(flame_template) <| $(var init : ComponentsInitializer)
    set(init, "dmgzone__offender", owner_eid)
    set(init, "dmgzone__gunPropsId", gun_props_id)
    set(init, "dmgzone__shellId", shell_id)
    set(init, "transform", tm)


def launch_projectile(owner_eid : EntityId; gun_eid : EntityId; shell_id_shell_id : int16; shell_id_damage_id : int16; shell_id_ballistics_id : int16; gun_props_id : int16; projectile_template : string; pos : float3; vel : float3)
  let shotTime = get_sync_time()

  using() <| $(var launchDesc : LaunchDesc#)
    launchDesc.shellId.shellId = shell_id_shell_id
    launchDesc.shellId.damageId = shell_id_damage_id
    launchDesc.shellId.ballisticsId = shell_id_ballistics_id
    launchDesc.gunPropsId = gun_props_id
    launchDesc.atTime = shotTime
    launchDesc.initialLifeTime = 0.0
    assume tm = launchDesc.tm
    tm[0] = normalize(vel)
    tm[2] = cross(tm[0], float3(0, 1, 0))
    tm[1] = cross(tm[2], tm[0])
    tm[3] = pos
    launchDesc.vel = vel
    launchDesc.firingMode = 0U
    launchDesc.bombBayHeight = 0.0
    createEntity(projectile_template) <| $(var init : ComponentsInitializer)
      init |> set("ownerEid", owner_eid)
      init |> set("gunEid", gun_eid)
      init |> set("launch_desc", launchDesc)
      init |> set("projectile__traceRayMatId", 0)
      init |> set("projectile__visualPos", launchDesc.tm[3])


def launch_simple_projectile(projectile_template : string; pos : float3; vel : float3)
  var waterLevel = 0.0
  let isUnderWater = traceht_water(pos, waterLevel) && pos.y < waterLevel
  if isUnderWater
    return

  let shotTime = get_sync_time()
  createEntity(projectile_template) <| $(init)
    init |> set("simple_projectile__position", pos)
    init |> set("simple_projectile__velocity", vel)
