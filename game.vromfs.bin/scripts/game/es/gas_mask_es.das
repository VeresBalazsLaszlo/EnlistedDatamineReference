require ecs
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require game.es.vehicle.vehicle_events
require game.events_game
require danetlibs.dm.dm_events
require PhysVars
require HumanPhys
require DngHuman
require DngDm
require DngNet
require DngWeapon
require AnimV20
require DagorSystem
require DagorMath
require math.base


def hide_gas_mask_weapon(maskEid : EntityId)
  query(maskEid) <| $ [es] (var gun__visible : bool&; var animchar_render__enabled : bool&)
    gun__visible = false
    animchar_render__enabled = false


def restore_gun_to_main_slot(gunEid : EntityId)
  query(gunEid) <| $ [es] (gun_attach__mainSlotId : int;
                           var slot_attach__slotId : int&;
                           var slot_attach__rotOffset : float3?;
                           var gun__visible : bool&)
    slot_attach__slotId = gun_attach__mainSlotId
    gun__visible = true
    if slot_attach__rotOffset != null
      *slot_attach__rotOffset = float3()


def move_gun_to_holster_slot(gunEid : EntityId; slotIdx : int)
  query(gunEid) <| $ [es] (gun_attach__holsterSlotsIds : IntList const?;
                           gun_attach__holsterRotOffset : float3 = float3();
                           var slot_attach__slotId : int&;
                           var slot_attach__rotOffset : float3?;
                           var gun__visible : bool&)
    let holsterSlot = gun_attach__holsterSlotsIds != null ? (*gun_attach__holsterSlotsIds)[slotIdx] : -1
    if holsterSlot >= 0
      slot_attach__slotId = holsterSlot
      gun__visible = true
      if slot_attach__rotOffset != null
        *slot_attach__rotOffset = gun_attach__holsterRotOffset
    else
      slot_attach__slotId = -1
      gun__visible = false


def gas_mask_cancel_sequence(eid : EntityId;
                             human_gas_mask__eid : EntityId;
                             var human_gas_mask__putonPhase : int&;
                             var human_gas_mask__takeoffPhase : int&;
                             var human_gas_mask__localProgress : float&;
                             var human_gas_mask__prevGunInSlotEid : EntityId&;
                             var human_gas_mask__prevGunSlot : int&;
                             var human_gas_mask__sequenceMode : int&;
                             var human_weap__equipBlocked : bool&;
                             var human_input__actionBlocked : int&)
  if human_gas_mask__putonPhase == 0 && human_gas_mask__takeoffPhase == 0
    return
  let phase = human_gas_mask__putonPhase != 0 ? human_gas_mask__putonPhase : human_gas_mask__takeoffPhase
  // Always hide the mask weapon on cancel (it may be visible during phase 2+)
  hide_gas_mask_weapon(human_gas_mask__eid)
  // If mask was swapped into weapon slot (phase >= 2), restore gun to main slot
  if phase >= 2 && !!human_gas_mask__prevGunInSlotEid
    sendEventImmediate(human_gas_mask__eid, CmdWeapAttach(toEid = eid, isAttached = false, slotId = human_gas_mask__prevGunSlot))
    restore_gun_to_main_slot(human_gas_mask__prevGunInSlotEid)
  human_gas_mask__prevGunInSlotEid = INVALID_ENTITY_ID
  human_gas_mask__prevGunSlot = -1
  human_gas_mask__putonPhase = 0
  human_gas_mask__takeoffPhase = 0
  human_gas_mask__localProgress = 0.0
  if is_server()
    human_weap__equipBlocked = false
    human_gas_mask__sequenceMode = 0
  human_input__actionBlocked--


// Resolve anim enum value for gas mask weapon type on item appear
[es(on_appear)]
def gas_mask_init_anim_enum(evt : Event;
                            gas_mask__animEnumName : string;
                            var gas_mask__animEnumValue : int&)
  gas_mask__animEnumValue = animV20_add_enum_value(gas_mask__animEnumName)

[es(tag=server, on_appear, track=(item__lastOwner, item__ownerEid), REQUIRE=gasMask)]
def gas_mask_on_appear_init(evt : Event;
                            item__lastOwner : EntityId;
                            item__ownerEid : EntityId;
                            gun__owner : EntityId&)
  if !!gun__owner
    return
  var owner = item__ownerEid
  if !owner
    owner = item__lastOwner
  sendEvent(owner, ReinitGasMask())

[es(tag=server, on_appear, track=itemContainer, on_event=ReinitGasMask)]
def gas_mask_track_inventory(evt : Event; eid : EntityId; itemContainer : EidList;
                             var human_gas_mask__eid : EntityId&;
                             var human_gas_mask__faceEid : EntityId&)
  if !!human_gas_mask__faceEid
    return
  human_gas_mask__eid = INVALID_ENTITY_ID
  var faceTemplate = ""
  for itemEid in itemContainer
    query(itemEid) <| $ [es(REQUIRE=gasMask)] (var gun__owner : EntityId&; gas_mask__faceItemTemplate : string)
      human_gas_mask__eid = itemEid
      gun__owner = eid
      faceTemplate = gas_mask__faceItemTemplate
    if !!human_gas_mask__eid
      break
  // Create the face-attached cosmetic mask (hidden initially)
  if !!human_gas_mask__eid && faceTemplate != ""
    var attachesList = getRW_ecs_EidList(eid, "attaches_list")
    if attachesList != null
      human_gas_mask__faceEid = createEntity(faceTemplate) <| $(var init : ComponentsInitializer)
        set(init, "slot_attach__slotName", "face_equipment")
        set(init, "animchar_attach__attachedTo", eid)
        set(init, "skeleton_attach__attached", true)
        set(init, "slot_attach__visible", false)
      *attachesList |> push(human_gas_mask__faceEid)


// Server-side: handle CmdSwitchGasMask, validate and start sequence
[es(tag=server)]
def gas_mask_on_switch_event(evt : CmdSwitchGasMask;
                             eid : EntityId;
                             human_gas_mask__eid : EntityId;
                             human_gas_mask__active : bool&;
                             human_inventory__entityToUse : EntityId;
                             human_net_phys : HumanActor;
                             var human_gas_mask__putonPhase : int&;
                             var human_gas_mask__takeoffPhase : int&;
                             var human_weap__equipBlocked : bool&;
                             var human_input__actionBlocked : int&;
                             var human_gas_mask__sequenceMode : int&;
                             human_use_object__currentInteractBombSite : EntityId = INVALID_ENTITY_ID;
                             human_weap__radioMode : bool = false;
                             human_weap__throwMode : bool = false)
  if !human_gas_mask__eid
    return
  if human_gas_mask__putonPhase != 0 || human_gas_mask__takeoffPhase != 0
    return
  if human_net_phys.phys.currentState.weapEquipState.curState != HUWeaponEquipState.EES_EQUIPED
    return
  if !!human_inventory__entityToUse || human_weap__radioMode || human_weap__throwMode
    return
  if (get_Eid(human_use_object__currentInteractBombSite, "bomb_site__operator") ?? INVALID_ENTITY_ID) == eid
    return
  human_weap__equipBlocked = true
  human_input__actionBlocked++
  sendEvent(eid, CmdInterruptReloadImmediately())
  if human_gas_mask__active
    human_gas_mask__takeoffPhase = 1
    human_gas_mask__sequenceMode = 2
  else
    human_gas_mask__putonPhase = 1
    human_gas_mask__sequenceMode = 1


// Client-side: start local sequence when sequenceMode replicates from server
[es(tag=netClient, track=human_gas_mask__sequenceMode)]
def gas_mask_start_on_sequence_mode(evt : Event;
                                    human_gas_mask__sequenceMode : int;
                                    var human_gas_mask__putonPhase : int&;
                                    var human_gas_mask__takeoffPhase : int&;
                                    var human_input__actionBlocked : int&)
  if human_gas_mask__sequenceMode == 0 || human_gas_mask__putonPhase != 0 || human_gas_mask__takeoffPhase != 0
    return
  human_input__actionBlocked++
  if human_gas_mask__sequenceMode == 1
    human_gas_mask__putonPhase = 1
  elif human_gas_mask__sequenceMode == 2
    human_gas_mask__takeoffPhase = 1


// Main PUFD ES: drives PhysVars for holster/mask/equip animation on all machines
// Runs after human_anim_es and human_anim_weap_es so we can override their PhysVars
[es(after=(human_anim_es, human_anim_weap_es, human_gun_attach_es, human_gun_phys_vars_es, human_unarmed_melee_anim_es, human_anim_radio_es, human_anim_weap_attachment_es), before=before_animchar_update_sync, REQUIRE_NOT=deadEntity)]
def gas_mask_sequence_update(info : ParallelUpdateFrameDelayed;
                             eid : EntityId;
                             human_gas_mask__eid : EntityId;
                             human_gas_mask__faceEid : EntityId;
                             human_weap__gunEids : EidList;
                             human_gas_mask__maskTime : float;
                             human_anim__changeWeaponVarId : int;
                             human_anim__changeDirVarId : int;
                             human_anim__selectedWeaponVarId : int;
                             human_anim__upperStateChangeWeapon : int;
                             human_anim__comboStateCrawlChangeWeapons : int;
                             human_net_phys : HumanActor;
                             reye_offset__fwd0Id : int = -1;
                             gun_offset__acrossId : int = -1;
                             gun_offset__upId : int = -1;
                             gun_offset__alongId : int = -1;
                             var human_gas_mask__active : bool&;
                             var human_gas_mask__putonPhase : int&;
                             var human_gas_mask__takeoffPhase : int&;
                             var human_gas_mask__localProgress : float&;
                             var human_gas_mask__prevGunInSlotEid : EntityId&;
                             var human_gas_mask__prevGunSlot : int&;
                             var human_gas_mask__sequenceMode : int&;
                             var human_weap__equipBlocked : bool&;
                             var human_input__actionBlocked : int&;
                             var phys_vars : PhysVars&)
  let isPuton = human_gas_mask__putonPhase != 0
  let isTakeoff = human_gas_mask__takeoffPhase != 0
  if !isPuton && !isTakeoff
    return

  assume phys = human_net_phys.phys
  assume moveState = phys.currentState.moveState
  assume standState = phys.currentState.standState

  let overrideAnimations = phys.currentState.height > -0.1 || moveState == HUMoveState.EMS_STAND

  // Override animgraph upper body state to weapon-change
  if overrideAnimations
    if phys.currentState.height < -0.1
      send_change_anim_state_event(eid, "upper", ecs_hash("upper"), human_anim__comboStateCrawlChangeWeapons)
      send_change_anim_state_event(eid, "lower", ecs_hash("lower"), human_anim__comboStateCrawlChangeWeapons)
    else
      send_change_anim_state_event(eid, "upper", ecs_hash("upper"), human_anim__upperStateChangeWeapon)

  let phase = isPuton ? human_gas_mask__putonPhase : human_gas_mask__takeoffPhase
  let curSlot = int(phys.currentState.weapEquipState.curSlot)
  let dt = info.dt

  if phase == 1
    // Phase 1: holstering weapon (progress 0 -> 1)
    let holsterTime = phys.weaponParams[curSlot].holsterTime
    human_gas_mask__localProgress += safediv(dt, holsterTime)
    phys_vars |> setVar(human_anim__changeWeaponVarId, human_gas_mask__localProgress)
    phys_vars |> setVar(human_anim__changeDirVarId, -1.0)
    if human_gas_mask__localProgress >= 1.0
      // Store current gun for later restoration
      human_gas_mask__prevGunSlot = curSlot
      human_gas_mask__prevGunInSlotEid = human_weap__gunEids[curSlot]
      // Move gun to holster slot (or hide if no holster)
      move_gun_to_holster_slot(human_weap__gunEids[curSlot], curSlot)
      sendEventImmediate(human_gas_mask__eid, CmdWeapAttach(toEid = eid, isAttached = true, slotId = curSlot))
      query(human_gas_mask__eid) <| $ [es] (var animchar_render__enabled : bool&)
        animchar_render__enabled = true
      if isPuton
        human_gas_mask__putonPhase = 2
        human_gas_mask__localProgress = 1.0
      else
        human_gas_mask__takeoffPhase = 2
        human_gas_mask__localProgress = 0.0

  elif phase == 2
    // Phase 2: mask animation
    // Puton: equip mask (dir=1, progress 1->0). Takeoff: holster mask (dir=-1, progress 0->1)
    // Force gun in holster and mask visible every frame (weapon systems may reset them)
    move_gun_to_holster_slot(human_gas_mask__prevGunInSlotEid, human_gas_mask__prevGunSlot)
    query(human_gas_mask__eid) <| $ [es] (var animchar_render__enabled : bool&)
      animchar_render__enabled = overrideAnimations
    // Override gun offset PhysVars with FPS/default values from the gun to avoid TPS offset glitch
    if reye_offset__fwd0Id >= 0
      query(human_weap__gunEids[curSlot]) <| $ [es] (gun_anim_var__defReyeOffsetFwd0 : float;
                                                     gun_anim_var__defGunOffsetAlong : float;
                                                     gun_anim_var__defGunOffsetAcross : float;
                                                     gun_anim_var__defGunOffsetUp : float;
                                                     gun_anim_var__fpsReyeOffsetFwd0 : float const?;
                                                     gun_anim_var__fpsGunOffsetAlong : float const?;
                                                     gun_anim_var__fpsGunOffsetAcross : float const?;
                                                     gun_anim_var__fpsGunOffsetUp : float const?)
        phys_vars |> setVar(reye_offset__fwd0Id, gun_anim_var__fpsReyeOffsetFwd0 ?? gun_anim_var__defReyeOffsetFwd0)
        phys_vars |> setVar(gun_offset__alongId, gun_anim_var__fpsGunOffsetAlong ?? gun_anim_var__defGunOffsetAlong)
        phys_vars |> setVar(gun_offset__acrossId, gun_anim_var__fpsGunOffsetAcross ?? gun_anim_var__defGunOffsetAcross)
        phys_vars |> setVar(gun_offset__upId, gun_anim_var__fpsGunOffsetUp ?? gun_anim_var__defGunOffsetUp)
    var enumVal = -1
    query(human_gas_mask__eid) <| $ [es] (gas_mask__animEnumValue : int)
      enumVal = gas_mask__animEnumValue
    if enumVal >= 0 && human_anim__selectedWeaponVarId >= 0
      phys_vars |> setVar(human_anim__selectedWeaponVarId, float(enumVal))
    if isPuton
      human_gas_mask__localProgress -= safediv(dt, human_gas_mask__maskTime)
      phys_vars |> setVar(human_anim__changeWeaponVarId, human_gas_mask__localProgress)
      phys_vars |> setVar(human_anim__changeDirVarId, 1.0)
      if human_gas_mask__localProgress < 0.5
        query(human_gas_mask__faceEid) <| $ [es] (var slot_attach__visible : bool&;
                                                  var animchar : AnimcharBaseComponent;
                                                  var animchar_node_wtm : AnimcharNodesMat44;
                                                  var animchar_render__root_pos : vec4f&)
          if !slot_attach__visible
            slot_attach__visible = true
            animchar_set_tm(animchar, IDENT_TM, true)
            animchar_act(animchar, 0.0, true)
            animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)
    else
      human_gas_mask__localProgress += safediv(dt, human_gas_mask__maskTime)
      phys_vars |> setVar(human_anim__changeWeaponVarId, human_gas_mask__localProgress)
      phys_vars |> setVar(human_anim__changeDirVarId, -1.0)
      if human_gas_mask__localProgress > 0.5
        query(human_gas_mask__faceEid) <| $ [es] (var slot_attach__visible : bool&)
          slot_attach__visible = false
    let phase2Done = isPuton ? human_gas_mask__localProgress <= 0.0 : human_gas_mask__localProgress >= 1.0
    if phase2Done
      human_gas_mask__localProgress = 1.0
      // Hide mask, show gun back
      sendEventImmediate(human_gas_mask__eid, CmdWeapAttach(toEid = eid, isAttached = false, slotId = human_gas_mask__prevGunSlot))
      hide_gas_mask_weapon(human_gas_mask__eid)
      restore_gun_to_main_slot(human_gas_mask__prevGunInSlotEid)
      human_gas_mask__prevGunInSlotEid = INVALID_ENTITY_ID
      human_gas_mask__prevGunSlot = -1
      // Toggle active state on server
      if is_server()
        human_gas_mask__active = isPuton
      if isPuton
        human_gas_mask__putonPhase = 3
      else
        human_gas_mask__takeoffPhase = 3

  elif phase == 3
    // Phase 3: equipping weapon back (progress 1 -> 0)
    let equipTime = phys.weaponParams[curSlot].equipTime
    human_gas_mask__localProgress -= safediv(dt, equipTime)
    phys_vars |> setVar(human_anim__changeWeaponVarId, human_gas_mask__localProgress)
    phys_vars |> setVar(human_anim__changeDirVarId, 1.0)
    if human_gas_mask__localProgress <= 0.0
      human_gas_mask__localProgress = 0.0
      if isTakeoff && is_server()
        human_gas_mask__active = false
      if isPuton
        human_gas_mask__putonPhase = 0
      else
        human_gas_mask__takeoffPhase = 0
      if is_server()
        human_weap__equipBlocked = false
        human_gas_mask__sequenceMode = 0
      human_input__actionBlocked--


// Cancel sequence on vehicle enter
[es(on_event=EventEnterVehicle)]
def gas_mask_cancel_on_vehicle(evt : Event;
                               eid : EntityId;
                               human_gas_mask__eid : EntityId;
                               var human_gas_mask__putonPhase : int&;
                               var human_gas_mask__takeoffPhase : int&;
                               var human_gas_mask__localProgress : float&;
                               var human_gas_mask__prevGunInSlotEid : EntityId&;
                               var human_gas_mask__prevGunSlot : int&;
                               var human_gas_mask__sequenceMode : int&;
                               var human_weap__equipBlocked : bool&;
                               var human_input__actionBlocked : int&)
  gas_mask_cancel_sequence(eid, human_gas_mask__eid,
    human_gas_mask__putonPhase, human_gas_mask__takeoffPhase,
    human_gas_mask__localProgress, human_gas_mask__prevGunInSlotEid, human_gas_mask__prevGunSlot,
    human_gas_mask__sequenceMode, human_weap__equipBlocked, human_input__actionBlocked)


// Cancel sequence on stationary gun attach
[es(on_event=HumanAttachToGunResponse)]
def gas_mask_cancel_on_stationary_gun(evt : Event;
                                      eid : EntityId;
                                      human_gas_mask__eid : EntityId;
                                      var human_gas_mask__putonPhase : int&;
                                      var human_gas_mask__takeoffPhase : int&;
                                      var human_gas_mask__localProgress : float&;
                                      var human_gas_mask__prevGunInSlotEid : EntityId&;
                                      var human_gas_mask__prevGunSlot : int&;
                                      var human_gas_mask__sequenceMode : int&;
                                      var human_weap__equipBlocked : bool&;
                                      var human_input__actionBlocked : int&)
  gas_mask_cancel_sequence(eid, human_gas_mask__eid,
    human_gas_mask__putonPhase, human_gas_mask__takeoffPhase,
    human_gas_mask__localProgress, human_gas_mask__prevGunInSlotEid, human_gas_mask__prevGunSlot,
    human_gas_mask__sequenceMode, human_weap__equipBlocked, human_input__actionBlocked)


// Cancel sequence on death
[es(on_event=(EventBeforeEntityRecreatedOnDeath, EventEntityDied))]
def gas_mask_cancel_on_death(evt : Event;
                             eid : EntityId;
                             human_gas_mask__eid : EntityId;
                             var human_gas_mask__putonPhase : int&;
                             var human_gas_mask__takeoffPhase : int&;
                             var human_gas_mask__localProgress : float&;
                             var human_gas_mask__prevGunInSlotEid : EntityId&;
                             var human_gas_mask__prevGunSlot : int&;
                             var human_gas_mask__sequenceMode : int&;
                             var human_weap__equipBlocked : bool&;
                             var human_input__actionBlocked : int&)
  gas_mask_cancel_sequence(eid, human_gas_mask__eid,
    human_gas_mask__putonPhase, human_gas_mask__takeoffPhase,
    human_gas_mask__localProgress, human_gas_mask__prevGunInSlotEid, human_gas_mask__prevGunSlot,
    human_gas_mask__sequenceMode, human_weap__equipBlocked, human_input__actionBlocked)


[es(tag=server, on_appear, track=animchar_attach__attachedTo, REQUIRE=gasMaskFace)]
def gas_mask_bot_puton_on_appear_es(evt : Event;
                                    animchar_attach__attachedTo : EntityId)
  query(animchar_attach__attachedTo) <| $ [es] (squad_member__playerEid : EntityId;
                                                var human_gas_mask__active : bool&)
    if has(squad_member__playerEid, "playerIsBot")
      human_gas_mask__active = true


// Routes gas damage to the controlling client so a Squirrel UI tip can react on the main thread
// instead of subscribing to CmdApplyDamage (which fires from PUFD workers and would race the SQ VM).
[es(tag=server)]
def gas_mask_show_tip_on_gas_damage(evt : CmdApplyDamage;
                                    eid : EntityId;
                                    possessedByPlr : EntityId;
                                    human_gas_mask__eid : EntityId = INVALID_ENTITY_ID;
                                    human_gas_mask__active : bool = false)
  if evt.damageType != int(DamageType.DM_GAS)
    return
  if !possessedByPlr || human_gas_mask__active || !human_gas_mask__eid
    return
  send_net_event(eid, CmdShowGasDamageMaskTip())


// Cancel sequence on hero change
[es(track=possessedByPlr, REQUIRE_NOT=deadEntity)]
def gas_mask_cancel_on_hero_change(evt : Event;
                                   eid : EntityId;
                                   possessedByPlr : EntityId;
                                   human_gas_mask__eid : EntityId;
                                   var human_gas_mask__putonPhase : int&;
                                   var human_gas_mask__takeoffPhase : int&;
                                   var human_gas_mask__localProgress : float&;
                                   var human_gas_mask__prevGunInSlotEid : EntityId&;
                                   var human_gas_mask__prevGunSlot : int&;
                                   var human_gas_mask__sequenceMode : int&;
                                   var human_weap__equipBlocked : bool&;
                                   var human_input__actionBlocked : int&)
  if !possessedByPlr
    gas_mask_cancel_sequence(eid, human_gas_mask__eid,
      human_gas_mask__putonPhase, human_gas_mask__takeoffPhase,
      human_gas_mask__localProgress, human_gas_mask__prevGunInSlotEid, human_gas_mask__prevGunSlot,
      human_gas_mask__sequenceMode, human_weap__equipBlocked, human_input__actionBlocked)
