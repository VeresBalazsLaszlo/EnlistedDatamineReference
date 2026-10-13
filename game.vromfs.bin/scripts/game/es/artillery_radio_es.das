require ecs
require ecs.safe
require app
require DngNet
require game.es.events
require enlisted.events_enlisted
require HumanPhys
require DngHuman
require enlisted.game.es.artillery_radio_common
require game.utils.hero
require DngWalkerai
require DagorSystem
require game.utils.team
require game.es.squad_order_common
require game.events_game
require game.es.human.human_use_object_common
require gameLibs.pufd_events.pufd_events


[es(tag=server, on_appear, on_event=EventPlayerProfileChanged)]
def artillery_init_squads_have_radio(evt : Event; armies : Object; army : string; var artillery__hasRadioInArmySquads : bool&)
  artillery__hasRadioInArmySquads = false
  assume armyData = armies[army] ?as Object
  assume squads = armyData?.squads ?as Array
  if squads == null
    return
  for it in *squads
    assume squad = it as Object
    assume soldiers = squad?.squad ?as Array
    if soldiers == null
      continue
    for it2 in *soldiers
      assume soldier = it2 as Object
      assume equipment = soldier?.equipment ?as Object
      if equipment == null
        continue
      assume radio = (*equipment)["radio"] ?as Object
      if radio != null
        artillery__hasRadioInArmySquads = true

def update_radio_eid_for_owner(human_equipment__slots : Object; var human_weap__radioEid : EntityId&)
  for it in human_equipment__slots
    let slot = get_ecs_object(it.value)
    if slot != null
      let itemEid = get_Eid(*slot, "item") ?? INVALID_ENTITY_ID
      if has(itemEid, "radio_use")
        human_weap__radioEid = itemEid
        return

[es(tag=server, on_appear, track=human_equipment__slots)]
def artillery_radio_track_equipment(evt : Event; human_equipment__slots : Object; var human_weap__radioEid : EntityId&)
  update_radio_eid_for_owner(human_equipment__slots, human_weap__radioEid)

[es(tag=server, on_appear, REQUIRE=radio_use)]
def artillery_radio_create_equipment(evt : Event;
                                     animchar_attach__attachedTo : EntityId)
  query(animchar_attach__attachedTo) <| $ [es] (human_equipment__slots : Object;
                                                var human_weap__radioEid : EntityId&)
    update_radio_eid_for_owner(human_equipment__slots, human_weap__radioEid)

[es(tag=gameClient, track=(radioMode__startTime, radioMode__endTime))]
def radio_mode_animation(evt : Event; human_weap__radioEid : EntityId; radioMode__startTime : float; radioMode__endTime : float)
  if radioMode__endTime > 0.0
    query(human_weap__radioEid) <| $ [es] (device_animation__postTime : float; var device_animation__endAt : float&)
      device_animation__endAt = radioMode__endTime - device_animation__postTime
  elif radioMode__startTime > 0.0
    query(human_weap__radioEid) <| $ [es] (var device_animation__startAt : float&)
      device_animation__startAt = radioMode__startTime


def force_stop_radio_mode(human_eid : EntityId; var human_weap__radioMode : bool&; var radioMode__startTime : float&; var radioMode__endTime : float&)
  human_weap__radioMode = false
  radioMode__startTime = -1.0
  radioMode__endTime = -1.0
  send_net_event(human_eid, EventActivateRadioMode(isActive = false))

def start_radio_mode(human_eid : EntityId; var human_weap__radioMode : bool&; var radioMode__startTime : float&; var radioMode__endTime : float&)
  human_weap__radioMode = true
  radioMode__startTime = get_sync_time()
  radioMode__endTime = -1.0
  send_net_event(human_eid, EventActivateRadioMode(isActive = true))

def stop_radio_mode(radio_eid : EntityId; var radioMode__endTime : float&)
  var radioPostTime = 0.0
  query(radio_eid) <| $ [es] (device_animation__postTime : float)
    radioPostTime = device_animation__postTime
  radioMode__endTime = get_sync_time() + radioPostTime

[es(tag=(server), no_order)]
def artillery_radio_mode_server(info : UpdateStageInfoAct;
                                eid : EntityId;
                                isAlive : bool;
                                isDowned : bool;
                                human_weap__radioEid : EntityId;
                                human_unarmed__hiddenWeapon : bool;
                                human_net_phys__isClimbing : bool = false;
                                human_net_phys__isSwimming : bool = false;
                                var radioMode__startTime : float&;
                                var radioMode__endTime : float&;
                                var human_weap__radioMode : bool&;
                                var human_net_phys : HumanActor)
  let isInputSet = human_net_phys.phys.appliedCT.isDeviceStateSet
  let isAllowed = isAlive && !isDowned && !human_net_phys__isSwimming && !human_net_phys__isClimbing && !human_unarmed__hiddenWeapon
  if !isAllowed
    if isInputSet
      human_net_phys.phys.producedCT |> human_control_state_set_device_state(false)
    if human_weap__radioMode
      force_stop_radio_mode(eid, human_weap__radioMode, radioMode__startTime, radioMode__endTime)
    return

  if isAllowed && isInputSet && !human_weap__radioMode
    start_radio_mode(eid, human_weap__radioMode, radioMode__startTime, radioMode__endTime)

  if !isInputSet && human_weap__radioMode && radioMode__endTime < 0.0
    stop_radio_mode(human_weap__radioEid, radioMode__endTime)
  if radioMode__endTime > 0.0 && radioMode__endTime < info.curTime
    force_stop_radio_mode(eid, human_weap__radioMode, radioMode__startTime, radioMode__endTime)

[es(tag=gameClient, track=human_weap__radioMode, REQUIRE=hero)]
def radio_mode_change_pose_on_client(evt : Event;
                                     var radioMode__prevPose : int&;
                                     var human_input__standState : int&;
                                     human_weap__radioMode : bool const)
  if human_weap__radioMode
    radioMode__prevPose = human_input__standState
    human_input__standState = int(HumanPhysControlType.HCT_CROUCH)
  elif radioMode__prevPose >= 0
    human_input__standState = radioMode__prevPose

[es(tag=server)]
def request_artillery_strike(evt : RequestArtilleryStrikeAtPos;
                             team : int;
                             human_use_object__artilleryBox : EntityId;
                             human_weap__radioMode : bool;
                             squad_member__squad : EntityId const)
  let playerEid = get_Eid(evt.owner, "possessedByPlr") ?? INVALID_ENTITY_ID
  if !!human_use_object__artilleryBox
    if is_aircraft_request_from_box(human_use_object__artilleryBox, team, evt.typeIndex) && is_aircraft_request_on_cooldown(team, true)
      return
    sendEvent(playerEid, CmdStartArtilleryStrikeAtPos(owner = evt.owner, pos = evt.pos, typeIndex = evt.typeIndex, posEnd = evt.posEnd))
    return
  if !test_artillery_in_battle_area(evt.pos, evt.posEnd, team)
    print("Ignore artillery strike request for invalid pos/segment {evt.pos} {evt.posEnd}")
    return
  if is_aircraft_request(playerEid, evt.typeIndex) && is_aircraft_request_on_cooldown(team)
    debug("Artillery aircraft request for player {get_string(playerEid, "name", "")} on cooldown")
    return
  if is_artillery_on_cooldown(playerEid)
    debug("Artillery request for player {get_string(playerEid, "name", "")} on cooldown")
    return
  if human_weap__radioMode
    sendEvent(playerEid, CmdStartArtilleryStrikeAtPos(owner = evt.owner, pos = evt.pos, typeIndex = evt.typeIndex, posEnd = evt.posEnd))
  else
    sendEventImmediate(squad_member__squad, CmdStartArtilleryOverOrder(targetPos = evt.pos, typeIndex = evt.typeIndex, posEnd = evt.posEnd))

[es(tag=gameClient)]
def artillery_map_pos_selected(evt : EventArtilleryMapPosSelected;
                               team : int;
                               eid : EntityId;
                               possessedByPlr : EntityId;
                               human_use_object__artilleryBox : EntityId;
                               var human_net_phys : HumanActor)
  if test_artillery_in_battle_area(evt.pos, evt.posEnd, team)
    if !!human_use_object__artilleryBox
      if is_aircraft_request_from_box(human_use_object__artilleryBox, team, evt.typeIndex) && is_aircraft_request_on_cooldown(team, true)
        return
      send_net_event(eid, RequestArtilleryStrikeAtPos(owner = eid, pos = evt.pos, typeIndex = evt.typeIndex, posEnd = evt.posEnd))
    elif is_artillery_on_cooldown(possessedByPlr)
      sendEvent(possessedByPlr, CmdShowArtilleryCooldownHint())
    elif is_artillery_max_limit_reached(team)
      send_net_event(possessedByPlr, CmdHeroLogEvent(event = "artillery", text = "artillery/team_limit_reached"))
    elif is_aircraft_request(possessedByPlr, evt.typeIndex) && is_aircraft_request_on_cooldown(team)
      return
    else
      send_net_event(eid, RequestArtilleryStrikeAtPos(owner = eid, pos = evt.pos, typeIndex = evt.typeIndex, posEnd = evt.posEnd))

    sendEvent(eid, CmdCloseArtilleryMap())
    human_net_phys.phys.producedCT |> human_control_state_set_device_state(false)
  else
    print("Ignore artillery strike request for invalid pos/segment {evt.pos} {evt.posEnd}")

[es(tag=gameClient, on_event=CmdCloseArtilleryMap)]
def artillery_map_close_request(evt : Event;
                                squad_member__squad : EntityId const;
                                var human_net_phys : HumanActor)
  human_net_phys.phys.producedCT |> human_control_state_set_device_state(false)
  send_net_event(squad_member__squad, RequestStopArtilleryOverOrder())

[es(tag=server)]
def free_artillery_box_on_map_closing(evt : RequestStopArtilleryOverOrder;
                                      squad__allMembers : EidList)
  for eid in squad__allMembers
    query(eid) <| $ [es] (human_use_object__artilleryBox : EntityId)
      if !!human_use_object__artilleryBox
        query(human_use_object__artilleryBox) <| $ [es] (artillery_box__user : EntityId; var artillery_box__clearTime : float&)
          if artillery_box__user == eid
            artillery_box__clearTime = get_sync_time() + 2.

def artillery_box_use_try(soldier_eid, box_eid)
  query(soldier_eid) <| $ [es] (var human_use_object__artilleryBox : EntityId&;
                                hero : Tag const?)
    query(box_eid) <| $ [es] (var artillery_box__user : EntityId&; artillery_box__availableTime : float; var artillery_box__clearTime : float&)
      var canUse = false
      if artillery_box__availableTime > get_sync_time()
        using() <| $(var data : Object)
          set(data, "timeLeft", int(artillery_box__availableTime - get_sync_time()))
          send_net_event(soldier_eid, CmdHeroLogExEvent(event = "artillery", key = "artillery/cooldown", data = ecs_addr(data)))
      elif !!artillery_box__user && artillery_box__user != soldier_eid
        send_net_event(soldier_eid, CmdHeroLogEvent(event = "artillery", text = "artillery/already_active"))
      elif check_use_dist(soldier_eid, box_eid)
        canUse = true
        if hero != null
          sendEvent(soldier_eid, CmdOpenArtilleryMap())
        if !is_server()
          sendEvent(soldier_eid, HumanUseObjectRequest(objectEid = box_eid))
        else
          human_use_object__artilleryBox = box_eid
          artillery_box__user = soldier_eid
          artillery_box__clearTime = -1.

      if !canUse
        send_net_event(soldier_eid, EventResetDeviceState())

[es(tag=server, no_order)]
def check_forgotten_artillery_box_user(info : ParallelUpdateFrameDelayed;
                                       eid : EntityId;
                                       var artillery_box__clearTime : float&;
                                       var artillery_box__user : EntityId&;
                                       artillery_box__availableTime : float)
  if !!artillery_box__user && (has(artillery_box__user, "deadEntity") || artillery_box__availableTime > info.curTime || !check_use_dist(artillery_box__user, eid) || (artillery_box__clearTime > 0. && artillery_box__clearTime < info.curTime))
    let because = artillery_box__availableTime > info.curTime ? "cooldown" : !check_use_dist(artillery_box__user, eid) ? "usable distance" : "owner clear time"
    debug("Artillery box {eid} cleared from owner {artillery_box__user}, because {because}")
    artillery_box__clearTime = -1.
    setOptional(artillery_box__user, "human_use_object__artilleryBox", INVALID_ENTITY_ID)
    artillery_box__user = INVALID_ENTITY_ID


[es(tag=server, REQUIRE=artillery_box__user)]
def artillery_box_use_try_server(evt : CmdUse; eid : EntityId)
  artillery_box_use_try(evt.requesterEid, eid)

[es(tag=gameClient)]
def artillery_box_use_try_client(evt : HumanUseObjectRequestClient; eid : EntityId)
  artillery_box_use_try(eid, evt.objectEid)

[es(tag=gameClient, on_event=RequestOpenArtilleryMap)]
def artilery_request(evt : Event;
                     team : int;
                     isDowned : bool = false;
                     human_unarmed__hiddenWeapon : bool;
                     var human_net_phys : HumanActor;
                     squad_member__squad : EntityId = INVALID_ENTITY_ID;
                     human_weap__radioEid : EntityId = INVALID_ENTITY_ID;
                     possessedByPlr : EntityId = INVALID_ENTITY_ID)
  if isDowned || human_unarmed__hiddenWeapon
    return

  var isArtilleryAvailable = false
  var isArtilleryReady = false
  query(possessedByPlr) <| $ [es] (artillery__available : bool; artillery__availableAtTime : float)
    isArtilleryAvailable = artillery__available
    isArtilleryReady = get_sync_time() > artillery__availableAtTime

  if !isArtilleryAvailable
    return

  if !isArtilleryReady
    sendEvent(possessedByPlr, CmdShowArtilleryCooldownHint())
  elif is_artillery_max_limit_reached(team)
    send_net_event(possessedByPlr, CmdHeroLogEvent(event = "artillery", text = "artillery/team_limit_reached"))
  else
    if !!human_weap__radioEid
      human_net_phys.phys.producedCT |> human_control_state_set_device_state(true)
    else
      send_net_event(squad_member__squad, RequestSquadMateOrder(orderType = SquadMateOrder.ESMO_ARTILLERY, orderPosition = float3(), orderUseEntity = INVALID_ENTITY_ID))

[es(track=human_weap__radioMode)]
def radio_animation_start_end_control(evt : Event; human_weap__radioMode : bool; human_weap__radioEid : EntityId)
  query(human_weap__radioEid) <| $ [es] (radio__unequippedSlotId : int;
                                         radio__equippedSlotId : int;
                                         var slot_attach__slotId : int&)
    if human_weap__radioMode
      slot_attach__slotId = radio__equippedSlotId
    else
      slot_attach__slotId = radio__unequippedSlotId

[es(tag=gameClient, REQUIRE=hero)]
def radio_mode_exit_close_map(evt : EventActivateRadioMode; eid : EntityId)
  if evt.isActive
    sendEvent(eid, CmdOpenArtilleryMap())
  else
    sendEvent(eid, CmdCloseArtilleryMap())

[es(track=possessedByPlr, REQUIRE=possessedByPlr)]
def unset_radio_mode_when_hero_changed(evt : Event; var human_net_phys : HumanActor)
  human_net_phys.phys.producedCT |> human_control_state_set_device_state(false)

[es(tag=gameClient)]
def close_map_when_hero_changed(evt : EventHeroChanged)
  if evt.eid != INVALID_ENTITY_ID
    sendEvent(evt.eid, CmdCloseArtilleryMap())

[es(tag=server, on_event=EventEntityDestroyed, REQUIRE=artillery__targetPos, REQUIRE_NOT=artilleryFromBox)]
def artillery_strike_finish_es(evt : Event; artillery__calledByTeam : int; artillery__group : int = 0)
  artillery_change_limit(artillery__calledByTeam, -1, artillery__group)

[es(tag=server, on_appear)]
def init_artillery_limit_es(evt : Event; artillery_limit__max : IntList; var artillery_limit__current : IntList&)
  artillery_limit__current |> resize(length(artillery_limit__max))