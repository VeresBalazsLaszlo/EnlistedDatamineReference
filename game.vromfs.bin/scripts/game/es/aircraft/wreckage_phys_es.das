require ecs
require DagorMath
require GamePhys
require math
require math.base
require enlisted.events_enlisted

[es(tag=gameClient, on_appear, REQUIRE=plane_wreckage)]
def wreckage_phys_init_es(evt : Event;
                          plane_wreckage__mass : float;
                          plane_wreckage__startImpulse : float3;
                          plane_wreckage__startMoment : float3;
                          plane_wreckage__tm : float3x4;
                          var plane_wreckage__vel : float3&;
                          var plane_wreckage__omega : float3&)
  let invMass = 1.0 / plane_wreckage__mass
  plane_wreckage__vel = plane_wreckage__vel + plane_wreckage__startImpulse * invMass
  plane_wreckage__omega = rotate(plane_wreckage__tm, (plane_wreckage__omega + plane_wreckage__startMoment * invMass))

[es(tag=gameClient, REQUIRE=plane_wreckage, no_order)]
def wreckage_phys_es(info : ParallelUpdateFrameDelayed;
                     eid : ecs::EntityId;
                     var transform : float3x4;
                     var plane_wreckage__t : float&;
                     plane_wreckage__ttl : float;
                     plane_wreckage__mass : float;
                     plane_wreckage__center : float3;
                     plane_wreckage__size : float3;
                     plane_wreckage__offset : float3;
                     var plane_wreckage__pos : float3&;
                     var plane_wreckage__orient : float4&;
                     var plane_wreckage__vel : float3&;
                     var plane_wreckage__omega : float3&)
  let dt = info.dt

  plane_wreckage__t += dt
  if plane_wreckage__t > plane_wreckage__ttl
    destroyEntity(eid)
    return

  let mass = plane_wreckage__mass

  let airFrictionOscillationFactor = 0.5
  let oscillationTimer = plane_wreckage__t * airFrictionOscillationFactor;
  let center = plane_wreckage__center
  let size = plane_wreckage__size
  let rad = sqrt(size.x * size.x + size.y * size.y + size.z * size.z)
  let stability = 0.0
  let airFrictionRotateFactor = 0.001
  let forcePointLoc = float3(
    center.x + sin(oscillationTimer * size.x) * size.x,
    center.y + cos(oscillationTimer * size.y) * size.y,
    center.z + sin(oscillationTimer * size.z + 1.22) * size.z) * lerp(airFrictionRotateFactor, 0.0, stability) * mass;

  let wreckageQuat = quat(plane_wreckage__orient)
  let speed = inverse(wreckageQuat) * plane_wreckage__vel;
  let speedSqr = speed * length(speed);
  let airFriction = 0.2;
  let airFrictionMult = 1.0;
  let effectiveAirFriction = airFriction * airFrictionMult;

  let wtFactor = 1.0

  let force1 = float3(-speedSqr.x, 0.0, 0.0) * size.y * size.z / (size.x + rad * 0.05) * effectiveAirFriction
  let force2 = float3(0.0, -speedSqr.y, 0.0) * size.z * size.x / (size.y + rad * 0.05) * effectiveAirFriction
  let force3 = float3(0.0, 0.0, -speedSqr.z) * size.x * size.y / (size.z + rad * 0.05) * effectiveAirFriction
  let forces = (force1 + force2 + force3) * wtFactor

  let force = wreckageQuat * forces + float3(0.0, -gravity() * mass, 0.0)
  let forcePoint = wreckageQuat * forcePointLoc
  let moment = (cross(forcePoint, wreckageQuat * force1) + cross(forcePoint, wreckageQuat * force2) + cross(forcePoint, wreckageQuat * force3)) * wtFactor

  let invMass = 1.0 / plane_wreckage__mass
  let acc = force * invMass
  plane_wreckage__vel += acc * dt
  let maxSpeed = 1000.0
  if (length_sq(plane_wreckage__vel) > maxSpeed * maxSpeed)
    plane_wreckage__vel = normalize(plane_wreckage__vel) * maxSpeed;

  plane_wreckage__pos += plane_wreckage__vel * dt + acc * dt * dt

  let airRotationViscosity = 8.0;
  plane_wreckage__omega = approach(plane_wreckage__omega, float3(0.0, 0.0, 0.0), dt, airRotationViscosity * mass / rad);
  plane_wreckage__omega.x = clamp(plane_wreckage__omega.x, -9.f, 9.f);
  plane_wreckage__omega.y = clamp(plane_wreckage__omega.y, -9.f, 9.f);
  plane_wreckage__omega.z = clamp(plane_wreckage__omega.z, -9.f, 9.f);
  let mulJ = 0.01;
  let J = float3(1.0 / (mass * (size.y + size.z)),
                  1.0 / (mass * (size.x + size.z)),
                  1.0 / (mass * (size.x + size.y))) * mulJ;
  plane_wreckage__omega += float3(moment.x * J.x, moment.y * J.y, moment.z * J.z) * dt;
  let maxAngularSpeed = 1000.0
  if (length_sq(plane_wreckage__omega) > maxAngularSpeed * maxAngularSpeed)
    plane_wreckage__omega = normalize(plane_wreckage__omega) * maxAngularSpeed;

  let orientInc = plane_wreckage__omega * dt
  let quatInc   = quat(orientInc, length(orientInc))
  plane_wreckage__orient = float4(normalize(wreckageQuat * quatInc))

  var offsetTm = IDENT_TM
  offsetTm[3] = plane_wreckage__offset

  var wreckageTm : float3x4
  make_tm(quat(plane_wreckage__orient), plane_wreckage__pos, wreckageTm)
  transform = wreckageTm * offsetTm
