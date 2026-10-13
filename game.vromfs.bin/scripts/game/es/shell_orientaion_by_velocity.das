require ecs
require GamePhys
require DngPhysObj
require game.es.events
require DagorMath

[es(tag=server, REQUIRE=shell__orientationByVelocity)]
def shell_orientation_by_velocity(evt : CmdPostPhysUpdate; var phys_obj_net_phys : PhysObjActor)
  assume vel = phys_obj_net_phys.phys.currentState.velocity
  let dir = float3(vel.x, vel.y, vel.z)
  var tm : float3x4
  tm[3] = float3(phys_obj_net_phys.phys.currentState.location.P)
  tm[2] = normalize(dir)
  tm[1] = normalize(cross(float3(0f, 1f, 0f), tm[2]))
  tm[0] = normalize(cross(tm[2], tm[1]))
  let orient = DagorMath::quat(tm)
  phys_obj_net_phys.phys.currentState.location.O |> orient_setQuat(orient)