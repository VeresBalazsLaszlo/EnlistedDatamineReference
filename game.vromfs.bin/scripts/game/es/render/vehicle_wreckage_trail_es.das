require ecs
require ecs.common
require DagorMath
require DagorRandom
require math
require math.base
require GamePhys
require strings
require fx
require vehicle


// ──────────────────────────────────────────────────────────────────────────────
// Physics simulation for vehicle explosion trail emitters.
// Self-contained, tag-gated with `vehicle_explosion_trail`.
// ──────────────────────────────────────────────────────────────────────────────

[es(tag=gameClient, REQUIRE=vehicle_explosion_trail, no_order)]
def vehicle_wreckage_phys_es(info : UpdateStageInfoAct;
                             eid : EntityId;
                             var transform : float3x4;
                             var vehicle_wreckage__t : float&;
                             vehicle_wreckage__ttl : float;
                             vehicle_wreckage__mass : float;
                             vehicle_wreckage__size : float3;
                             var vehicle_wreckage__pos : float3&;
                             var vehicle_wreckage__orient : float4&;
                             var vehicle_wreckage__vel : float3&;
                             var vehicle_wreckage__omega : float3&)
  let dt = info.dt
  vehicle_wreckage__t += dt
  if vehicle_wreckage__t > vehicle_wreckage__ttl
    destroyEntity(eid)
    return

  let mass = vehicle_wreckage__mass
  let size = vehicle_wreckage__size
  let rad = sqrt(size.x * size.x + size.y * size.y + size.z * size.z)

  // Aerodynamic drag in body frame.
  let wreckQuat = quat(vehicle_wreckage__orient)
  let speedLocal = inverse(wreckQuat) * vehicle_wreckage__vel
  let speedLocalSqr = speedLocal * length(speedLocal)
  let airFriction = 0.2
  let force1 = float3(-speedLocalSqr.x, 0.0, 0.0) * size.y * size.z / (size.x + rad * 0.05) * airFriction
  let force2 = float3(0.0, -speedLocalSqr.y, 0.0) * size.z * size.x / (size.y + rad * 0.05) * airFriction
  let force3 = float3(0.0, 0.0, -speedLocalSqr.z) * size.x * size.y / (size.z + rad * 0.05) * airFriction
  let combinedForce = force1 + force2 + force3
  let force = wreckQuat * combinedForce + float3(0.0, -gravity() * mass, 0.0)

  let invMass = 1.0 / mass
  let acc = force * invMass
  vehicle_wreckage__vel += acc * dt
  let maxSpeed = 300.0
  if length_sq(vehicle_wreckage__vel) > maxSpeed * maxSpeed
    vehicle_wreckage__vel = normalize(vehicle_wreckage__vel) * maxSpeed

  vehicle_wreckage__pos += vehicle_wreckage__vel * dt

  // Rotation with viscous damping.
  let airRotationViscosity = 8.0
  vehicle_wreckage__omega = approach(vehicle_wreckage__omega, float3(0.0, 0.0, 0.0), dt,
                                     airRotationViscosity * mass / rad)
  vehicle_wreckage__omega.x = clamp(vehicle_wreckage__omega.x, -9.0, 9.0)
  vehicle_wreckage__omega.y = clamp(vehicle_wreckage__omega.y, -9.0, 9.0)
  vehicle_wreckage__omega.z = clamp(vehicle_wreckage__omega.z, -9.0, 9.0)

  let orientInc = vehicle_wreckage__omega * dt
  let quatInc = quat(orientInc, length(orientInc))
  vehicle_wreckage__orient = float4(normalize(wreckQuat * quatInc))

  make_tm(quat(vehicle_wreckage__orient), vehicle_wreckage__pos, transform)


// ──────────────────────────────────────────────────────────────────────────────
// Trail FX: spawn one effect on first render frame, then follow physics each
// frame.  On entity destruction the FX entity is torn down explicitly.
// ──────────────────────────────────────────────────────────────────────────────

[es(tag=render, on_disappear, REQUIRE=vehicle_explosion_trail)]
def vehicle_wreckage_trail_disappear_es(evt : Event;
                                        vehicle_wreckage__fxEid : EntityId)
  destroyEntity(vehicle_wreckage__fxEid)


[es(tag=render, after=vehicle_wreckage_phys_es, REQUIRE=vehicle_explosion_trail)]
def vehicle_wreckage_trail_update_es(info : UpdateStageInfoAct;
                                     transform : float3x4;
                                     vehicle_wreckage__vel : float3;
                                     vehicle_wreckage__effects : StringList;
                                     var vehicle_wreckage__fxEid : EntityId&;
                                     var vehicle_wreckage__isEffectsStarted : bool&)
  if !vehicle_wreckage__isEffectsStarted
    let n = length(vehicle_wreckage__effects)
    if n > 0
      let effectIndex = clamp(rnd_int(0, n), 0, n - 1)
      vehicle_wreckage__fxEid = createEntity(string(vehicle_wreckage__effects[effectIndex])) <| $(var init)
        set(init, "transform", transform)
    vehicle_wreckage__isEffectsStarted = true
  query(vehicle_wreckage__fxEid) <| $ [es] (var effect : TheEffect&)
    effect_set_emitter_tm(effect, transform)
    effect_set_velocity(effect, vehicle_wreckage__vel)


// ──────────────────────────────────────────────────────────────────────────────
// Spawn helper: create `count` trail emitters scattered in a cone around +Y.
// ──────────────────────────────────────────────────────────────────────────────

def spawn_vehicle_wreckage_trails(pos : float3; unit_vel : float3)
  if rnd_float(0.0, 1.0) >= 0.6
    return
  let count = 10
  let speedMin = 10.0
  let speedMax = 30.0
  let maxAngle = 50.0 * PI / 180.0
  let mass = 1.0
  let size = float3(0.3, 0.3, 0.3)
  let ttl = 5.0

  for _ in range(count)
    let speed = rnd_float(speedMin, speedMax)
    let phi   = rnd_float(0.0, 2.0 * PI)
    let theta = rnd_float(0.0, maxAngle)
    let st    = sin(theta)
    let ct    = cos(theta)
    // Direction: upward-biased cone in world space.
    let addVel = float3(st * cos(phi), ct, st * sin(phi)) * speed
    let vel    = unit_vel + addVel
    let omega  = float3(rnd_float(-3.0, 3.0),
                        rnd_float(-3.0, 3.0),
                        rnd_float(-3.0, 3.0))
    var spawnTm = IDENT_TM
    spawnTm[3] = pos
    createEntity("vehicle_explosion_trail") <| $(var init)
      set(init, "transform", spawnTm)
      set(init, "vehicle_wreckage__pos", pos)
      set(init, "vehicle_wreckage__vel", vel)
      set(init, "vehicle_wreckage__omega", omega)
      set(init, "vehicle_wreckage__mass", mass)
      set(init, "vehicle_wreckage__size", size)
      set(init, "vehicle_wreckage__ttl", ttl)


// ──────────────────────────────────────────────────────────────────────────────
// Scenario 1: vehicle was set on fire (fire_damage__isFatal) and then exploded.
// fire_damage__isFatal is replicated and set before isExploded, so by the time
// track=isExploded fires on the client it is already true.
// ──────────────────────────────────────────────────────────────────────────────

[es(tag=gameClient, track=isExploded, REQUIRE=vehicle_net_phys, REQUIRE_NOT=airplane)]
def vehicle_fatal_fire_wreckage_es(evt : Event;
                                   isExploded : bool;
                                   fire_damage__isFatal : bool;
                                   transform : float3x4;
                                   vehicle_net_phys : VehiclePhysActor)
  if !isExploded || !fire_damage__isFatal
    return
  let unitVel = float3(vehicle_net_phys.phys.currentState.velocity)
  spawn_vehicle_wreckage_trails(transform[3], unitVel)


// ──────────────────────────────────────────────────────────────────────────────
// Scenario 2: losable turret bone was detached.
// ──────────────────────────────────────────────────────────────────────────────

[es(tag=gameClient, track=losable_turret__lostBone, REQUIRE=vehicle_net_phys, REQUIRE_NOT=airplane)]
def vehicle_lost_turret_wreckage_es(evt : Event;
                                    losable_turret__lostBone : string;
                                    transform : float3x4;
                                    vehicle_net_phys : VehiclePhysActor)
  if empty(losable_turret__lostBone)
    return
  let unitVel = float3(vehicle_net_phys.phys.currentState.velocity)
  spawn_vehicle_wreckage_trails(transform[3], unitVel)
