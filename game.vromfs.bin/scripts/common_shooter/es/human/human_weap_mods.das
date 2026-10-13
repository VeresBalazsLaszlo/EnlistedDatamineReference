require ecs
require ecs.common
require app
require DngNet
require game.es.events
require DngHuman
require DngWeapon
require DagorMath
require DagorSystem
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common

def human_weap_mod_activate(eid : EntityId;
                            isDowned : bool;
                            human_weap__gunEids : EidList;
                            human_weap__gunMods : Array;
                            human_weap__reloadFinishTime : float;
                            slot_id : int;
                            activate : bool;
                            var human_weap__weapModActivateStartTime : float&;
                            var human_weap__weapModActivateFinishTime : float&)
  verify(is_server())

  if slot_id < 0 || slot_id >= length(human_weap__gunMods) || isDowned
    return

  let curTime = get_sync_time()
  let inProgress = curTime <= human_weap__weapModActivateFinishTime
  if inProgress
    return

  if !human_weap_can_reload(eid, human_weap__gunEids[slot_id]) || (human_weap__reloadFinishTime > curTime)
    return

  let gunModEids = get_ecs_EidList(human_weap__gunMods[slot_id])
  for gunMod in *gunModEids
    query(gunMod) <| $ [es] (weapon_mod__active : bool;
                             weapon_mod__activateTime : float;
                             weapon_mod__deactivateTime : float;
                             gun__ammo : int;
                             gun__totalAmmo : int;
                             ramrodGun : Tag const?)
      if weapon_mod__active == activate || (
        ramrodGun != null && gun__ammo == 0 && gun__totalAmmo == 0)
        return

      human_weap__weapModActivateStartTime = curTime
      human_weap__weapModActivateFinishTime = curTime + (activate ? weapon_mod__activateTime : weapon_mod__deactivateTime)


[es]
def human_weap_mod_toggle_es(evt : CmdWeapModToggle; eid : EntityId; human_weap__gunMods : Array)
  if evt.slotId < 0 || evt.slotId >= length(human_weap__gunMods)
    return

  let gunModEids = get_ecs_EidList(human_weap__gunMods[evt.slotId])
  for gunMod in *gunModEids
    ecs::query(gunMod) <| $ [es] (weapon_mod__active : bool)
      sendEvent(eid, CmdWeapModActivate(slotId = evt.slotId, activate = !weapon_mod__active))


[es(tag=server, REQUIRE=human_weap__currentGunEid, track=human_weap__currentGunEid)]
def human_weap_mod_toggle_cancel_es(evt : Event;
                                    var human_weap__weapModActivateStartTime : float&;
                                    var human_weap__weapModActivateFinishTime : float&)
  human_weap__weapModActivateStartTime = -1.0
  human_weap__weapModActivateFinishTime = -1.0


[es(tag=server, before=net_phys_update_es)]
def human_weap_mod_active_update_es(info : ParallelUpdateFrameDelayed;
                                    human_weap__gunMods : Array;
                                    human_weap__currentGunSlot : int;
                                    var human_weap__weapModActivateStartTime : float&;
                                    var human_weap__weapModActivateFinishTime : float&)
  if (human_weap__weapModActivateStartTime < 0.0) || (human_weap__currentGunSlot < 0)
    return

  let inProgress = info.curTime <= human_weap__weapModActivateFinishTime
  if inProgress
    return

  let gunModEids = get_ecs_EidList(human_weap__gunMods[human_weap__currentGunSlot])
  for gunMod in *gunModEids
    ecs::query(gunMod) <| $ [es] (var weapon_mod__active : bool&)
      weapon_mod__active = !weapon_mod__active
      human_weap__weapModActivateStartTime = -1.0
      human_weap__weapModActivateFinishTime = -1.0


[es(tag=server)]
def human_weap_mod_activate_server_es(evt : CmdWeapModActivate;
                                      eid : EntityId;
                                      isDowned : bool;
                                      human_weap__gunEids : EidList;
                                      human_weap__gunMods : Array;
                                      human_weap__reloadFinishTime : float;
                                      var human_weap__weapModActivateStartTime : float&;
                                      var human_weap__weapModActivateFinishTime : float&)
  human_weap_mod_activate(eid, isDowned, human_weap__gunEids, human_weap__gunMods,
                          human_weap__reloadFinishTime,
                          evt.slotId, evt.activate,
                          human_weap__weapModActivateStartTime,
                          human_weap__weapModActivateFinishTime)


[es(tag=netClient)]
def human_weap_mod_activate_client_es(evt : CmdWeapModActivate; eid : EntityId)
  send_net_event(eid, HumanRequestModActivate(slotId = evt.slotId, activate = evt.activate))


[es(tag=server)]
def human_weap_mod_activate_req_es(evt : HumanRequestModActivate;
                                   eid : EntityId;
                                   isDowned : bool;
                                   human_weap__gunEids : EidList;
                                   human_weap__gunMods : Array;
                                   human_weap__reloadFinishTime : float;
                                   var human_weap__weapModActivateStartTime : float&;
                                   var human_weap__weapModActivateFinishTime : float&)
  human_weap_mod_activate(eid, isDowned, human_weap__gunEids, human_weap__gunMods,
                          human_weap__reloadFinishTime,
                          evt.slotId, evt.activate,
                          human_weap__weapModActivateStartTime,
                          human_weap__weapModActivateFinishTime)


[es(REQUIRE=watchedByPlr, after=after_net_phys_sync, REQUIRE_NOT=deadEntity)]
def human_optics_camera_es(info : ParallelUpdateFrameDelayed;
                           human_net_phys : HumanActor;
                           human_weap__currentGunEid : EntityId;
                           human_weap__currentGunModEids : EidList;
                           var camera__magnification : float&;
                           var human_weap__opticsAttached : bool&)
  var gunScopeEid = find_scope_eid(human_weap__currentGunModEids)
  let isIntegratedScope = get_bool(human_weap__currentGunEid, "gun__integratedScope") ?? false

  if isIntegratedScope && !gunScopeEid
    gunScopeEid = human_weap__currentGunEid

  if !human_weap__currentGunEid
    camera__magnification = 1.0
    return

  let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)
  let aimPosition = lerp(human_net_phys.phys.previousState.aimPosition, human_net_phys.phys.currentState.aimPosition, interpK)

  let zoomFactor = get_float(gunScopeEid, "gunmod__zoomFactor") ?? 0.0
  let zoomPosition = lerp(human_net_phys.phys.previousState.zoomPosition,
                          human_net_phys.phys.currentState.zoomPosition, interpK)

  human_weap__opticsAttached = zoomFactor > 0.0

  // TODO: remove this sideeffect and make ECS_TAG
  setOptional(human_weap__currentGunEid, "gun__opticsAttached", human_weap__opticsAttached)

  if !human_weap__opticsAttached
    let gunMagnification = get_float(human_weap__currentGunEid, "gun__magnification") ?? 1.5
    camera__magnification = lerp(1.0, gunMagnification, zoomPosition)
    return

  camera__magnification = lerp(1.0, zoomFactor, lerp(0.0, zoomPosition, aimPosition))

[es(tag=gameClient, on_appear, REQUIRE=(deadEntity, watchedByPlr), after=camera_set_sync, before=before_camera_sync)]
def human_reset_optics_on_die_es(evt : Event; var camera__magnification : float&)
  camera__magnification = 1.0

[es(tag=gameClient, on_appear)]
def human_optics_init_cam_node(evt : Event;
                               eid : EntityId;
                               animchar : AnimcharBaseComponent;
                               gunmod__camNode : string;
                               var gunmod__camNodeId : int&)
  gunmod__camNodeId = geomtree_findNodeIndex(*animchar.nodeTree, gunmod__camNode)
  if gunmod__camNodeId < 0
    logerr("node /*{gunmod__camNode}*/ not found in animchar of gun /*{getEntityTemplateName(eid)}*/")