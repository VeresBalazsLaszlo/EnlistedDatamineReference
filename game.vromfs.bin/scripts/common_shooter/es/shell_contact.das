require ecs
require math
require math.base
require DagorMath
require DngPhysObj
require game.es.events
require DaWeaponProps
require GridCollision
require common_shooter.events_common_shooter
require Dacoll

def explode_shell(eid : EntityId;
                  curTime : float;
                  phys_obj_net_phys : PhysObjActor;
                  var shell__active : bool&;
                  shell__launchTime : float&;
                  shell__fuseTime : float;
                  shell__cleanupTime : float;
                  contact_point : float3;
                  shell__minPrevPosToContactDistance : float = 0.1;
                  shell__minContactDirDeviationCos : float = 0.999)
  if curTime >= shell__launchTime + shell__fuseTime
    shell__active = false
    var prevPos = float3(phys_obj_net_phys.phys.previousState.location.P)
    // use previous state because current velocity might be already clipped
    let vel = phys_obj_net_phys.phys.previousState.velocity

    // if prevPos and contact point are very close, we may have wrong direction prevPos -> contact
    if distance_sq(contact_point, prevPos) < square(shell__minPrevPosToContactDistance)
      let contactDir = normalize(contact_point - prevPos)
      let shellDir = normalize(vel)
      if dot(contactDir, shellDir) < shell__minContactDirDeviationCos
        prevPos = contact_point - shellDir * shell__minPrevPosToContactDistance
    sendEvent(eid, CmdShellExplode(position = contact_point, prevPos = prevPos, vel = vel))
  else
    sendEvent(eid, CmdBodyCleanup(time = shell__cleanupTime))


[es(REQUIRE=shell__explodeOnContact)]
def explode_shell_on_water_contact(evt : CmdPostPhysUpdate;
                                   eid : EntityId;
                                   phys_obj_net_phys : PhysObjActor;
                                   shell__isUnderwater : bool;
                                   var shell__active : bool&;
                                   var shell__launchTime : float&;
                                   shell__fuseTime : float = 0.0;
                                   shell__cleanupTime : float = 5.0)
  if !shell__active || !shell__isUnderwater
    return
  let curTime = float(evt.tick) * evt.dt
  if shell__launchTime < 0.0
    shell__launchTime = curTime
  let contact = float3(phys_obj_net_phys.phys.currentState.location.P)
  explode_shell(eid, curTime, phys_obj_net_phys, shell__active, shell__launchTime, shell__fuseTime, shell__cleanupTime, contact)


[es(REQUIRE=shell__explodeOnContact)]
def explode_on_contact_shell_contact(evt : CmdPostPhysUpdate;
                                     eid : EntityId;
                                     phys_obj_net_phys : PhysObjActor;
                                     var shell__active : bool&;
                                     var shell__launchTime : float&;
                                     shell__fuseTime : float = 0.0;
                                     shell__cleanupTime : float = 5.0)
  if !shell__active
    return
  let curTime = float(evt.tick) * evt.dt
  if shell__launchTime < 0.0
    shell__launchTime = curTime

  let prevPos = float3(phys_obj_net_phys.phys.previousState.location.P)
  let curPos = phys_obj_net_phys.phys.currentState.hadContact ? phys_obj_net_phys.phys.currentState.contactPoint : float3(phys_obj_net_phys.phys.currentState.location.P)
  let dir = curPos - prevPos
  let dirN = normalize(dir)
  var traceLen = length(dir)

  // contact point calculating by phys collision, by for correct dm calculations we must use trace collision correction for vehicles
  let eps = 0.01 // for more correct shell explode position
  if trace_entities_in_grid(ecs_hash("vehicles"), prevPos, dirN, traceLen, INVALID_ENTITY_ID)
    let contact = prevPos + dirN * (traceLen - eps)
    explode_shell(eid, curTime, phys_obj_net_phys, shell__active, shell__launchTime, shell__fuseTime, shell__cleanupTime, contact)
    return

  if phys_obj_net_phys.phys.currentState.hadContact
    let contact = phys_obj_net_phys.phys.currentState.contactPoint
    explode_shell(eid, curTime, phys_obj_net_phys, shell__active, shell__launchTime, shell__fuseTime, shell__cleanupTime, contact)

[es(REQUIRE=shell__explodeOnSpeedDrop)]
def explode_on_speed_drop_shell_contact(evt : CmdPostPhysUpdate;
                                        eid : EntityId;
                                        phys_obj_net_phys : PhysObjActor;
                                        shell__shell_id__shell_id : int;
                                        shell__activationSpeedDropThreshold : float;
                                        var shell__active : bool&;
                                        var shell__launchTime : float&;
                                        shell__fuseTime : float = 0.0;
                                        shell__cleanupTime : float = 5.0)
  if !shell__active
    return

  let curTime = float(evt.tick) * evt.dt
  if shell__launchTime < 0.f
    shell__launchTime = curTime
  if !phys_obj_net_phys.phys.currentState.hadContact
    return
  if phys_obj_net_phys.phys.hasRiDestroyingCollision
    return

  let vel = phys_obj_net_phys.phys.currentState.velocity
  shell_start_get_props(shell__shell_id__shell_id) <| $(startProps : ShellStartProps)
    if safediv(length(vel), startProps.speed) >= shell__activationSpeedDropThreshold
      return

    let contact = phys_obj_net_phys.phys.currentState.contactPoint
    explode_shell(eid, curTime, phys_obj_net_phys, shell__active, shell__launchTime, shell__fuseTime, shell__cleanupTime, contact)

[es(tag=server, REQUIRE=shell_trigger__requireContact)]
def shell_trigger_require_contact(evt : CmdPostPhysUpdate;
                                  phys_obj_net_phys : PhysObjActor;
                                  var shell_trigger__active : bool&)
  shell_trigger__active = phys_obj_net_phys.phys.currentState.hadContact
