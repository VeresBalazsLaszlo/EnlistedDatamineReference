require ecs
require game.es.events
require game.es.input.input_events
require enlisted.events_enlisted
require DagorInput
require DngHuman
require HumanPhys
require DagorMathUtils
require app
require game.es.input.input_common


def init(var human_input__artilleryStrike : int&)
  human_input__artilleryStrike = int(get_action_handle("Human.ArtilleryStrike", TYPEGRP_DIGITAL))


def reset(var human_input__artilleryStrike : int&)
  human_input__artilleryStrike = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def artillery_input_appear(evt : Event; var human_input__artilleryStrike : int&)
  init(human_input__artilleryStrike)

[es(tag=input)]
def artillery_input(evt : EventDaInputInit; var human_input__artilleryStrike : int&)
  if evt.init
    init(human_input__artilleryStrike)
  else
    reset(human_input__artilleryStrike)

def artyllery_action(eid : EntityId; possessedByPlr : EntityId)
  query(possessedByPlr) <| $ [es] (artillery_menu__active : bool; artillery__availableAtTime : float)
    if artillery_menu__active
      if get_sync_time() < artillery__availableAtTime
        sendEvent(possessedByPlr, CmdShowArtilleryCooldownHint())
      else
        sendEvent(possessedByPlr, CmdArtilleryMenu())
    else
      sendEvent(eid, RequestOpenArtilleryMap())

[es(tag=input)]
def artillery_menu_input_on_terminated(evt : EventDaInputActionTerminated;
                                       input__enabled : bool;
                                       possessedByPlr : EntityId;
                                       human_input__artilleryStrike : int)
  if input__enabled && is_gamepad_input() && int(evt.action) == human_input__artilleryStrike && (get_bool(possessedByPlr, "artillery_menu__active") ?? false)
    sendEvent(possessedByPlr, CmdArtilleryMenu())

[es(tag=input)]
def artillery_request_event_es(evt : RequestArtillery; eid : EntityId; possessedByPlr : EntityId)
  artyllery_action(eid, possessedByPlr)

[es(tag=input)]
def artillery_input_action_triggered(evt : EventDaInputActionTriggered;
                                     eid : EntityId;
                                     human_input__artilleryStrike : int;
                                     possessedByPlr : EntityId;
                                     input__enabled : bool;
                                     human_input__actionBlocked : int = 0)
  if input__enabled && human_input__actionBlocked <= 0 && int(evt.action) == human_input__artilleryStrike && (get_bool(possessedByPlr, "artillery__available") ?? false)
    artyllery_action(eid, possessedByPlr)

[es(tag=input, after=human_input_es)]
def artillery_radio_lock_input_es(evt : UpdateStageUpdateInput;
                                  human_weap__radioMode : bool;
                                  var human_net_phys : HumanActor&)
  if human_weap__radioMode
    human_net_phys.phys.producedCT |> human_control_state_set_neutral_ctrl()
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType.HCT_CROUCH, true)

[es(track=human_weap__radioMode)]
def artillery_radio_orient(evt : Event;
                           var human_input__aimAngle : float2&;
                           var human_net_phys : HumanActor&;
                           var radioMode__prevAimAngle : float2&;
                           radioMode__vertThreshold : float;
                           human_weap__radioMode : bool)
  if human_weap__radioMode
    radioMode__prevAimAngle = human_input__aimAngle
    human_net_phys.phys.currentState.velocity = float3()
    human_input__aimAngle.y = radioMode__vertThreshold
  else
    human_input__aimAngle = radioMode__prevAimAngle

  let bodyNewDir = float2(human_input__aimAngle.x, 0.)
  let dir = angles_to_dir(bodyNewDir)

  human_net_phys.phys.currentState.bodyOrientDir = dir.xz

  human_net_phys.phys.producedCT |> human_control_state_set_wish_look_dir(dir)
  human_net_phys.phys.producedCT |> human_control_state_set_wish_shoot_dir(dir)