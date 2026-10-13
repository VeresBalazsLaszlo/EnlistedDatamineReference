require ecs
require ecs.common
require AnimV20
require DngHuman
require DngWeapon
require DagorSystem
require MotionMatching
require enlisted.events_enlisted
require %gameLibs.anim.motionMatching.das.tags_common


def update_mm_tags_from_human_state(human_anim__lowerStateSprint : int;
                                    human_anim__lowerStateRun : int;
                                    human_anim__lowerStateStand : int;
                                    human_anim__lowerStateWalk : int;
                                    human_anim__lowerStateRotateLeft : int;
                                    human_anim__lowerStateRotateRight : int;
                                    prev_anim_state_id : int;
                                    next_anim_state_id : int;
                                    stand_state : HUStandState;
                                    motion_matching__weaponTagIdx : int;
                                    var motion_matching__enabled : bool&;
                                    var motion_matching__controller : MotionMatchingController)
  if motion_matching__weaponTagIdx >= 0
    if prev_anim_state_id == human_anim__lowerStateRun || prev_anim_state_id == human_anim__lowerStateStand
      motion_matching__controller.currentTags |> removeTag(uint(motion_matching__weaponTagIdx))
    if next_anim_state_id == human_anim__lowerStateRun || next_anim_state_id == human_anim__lowerStateStand
      motion_matching__controller.currentTags |> requireTag(uint(motion_matching__weaponTagIdx))

  if prev_anim_state_id < 0
    motion_matching__enabled = false
  elif prev_anim_state_id == human_anim__lowerStateSprint
    remove_tag(motion_matching__controller, "sprint")
    motion_matching__enabled = false
  elif prev_anim_state_id == human_anim__lowerStateRun || prev_anim_state_id == human_anim__lowerStateWalk
    remove_tag(motion_matching__controller, "walk")
    remove_tag(motion_matching__controller, "crouch")
    motion_matching__enabled = false
  elif (prev_anim_state_id == human_anim__lowerStateStand ||
        prev_anim_state_id == human_anim__lowerStateRotateLeft ||
        prev_anim_state_id == human_anim__lowerStateRotateRight)
    remove_tag(motion_matching__controller, "stand")
    remove_tag(motion_matching__controller, "crouch")
    remove_tag(motion_matching__controller, "turn_on_spot")
    motion_matching__enabled = false

  if next_anim_state_id == human_anim__lowerStateSprint
    set_tag(motion_matching__controller, "sprint", true)
    motion_matching__enabled = true
  elif next_anim_state_id == human_anim__lowerStateRun || next_anim_state_id == human_anim__lowerStateWalk
    if stand_state == HUStandState.ESS_STAND
      set_tag(motion_matching__controller, "walk", true)
      motion_matching__enabled = true
    elif stand_state == HUStandState.ESS_CROUCH
      set_tag(motion_matching__controller, "crouch", true)
      motion_matching__enabled = true
  elif (next_anim_state_id == human_anim__lowerStateStand ||
        next_anim_state_id == human_anim__lowerStateRotateLeft ||
        next_anim_state_id == human_anim__lowerStateRotateRight)
    if stand_state == HUStandState.ESS_STAND
      set_tag(motion_matching__controller, "stand", true)
    elif stand_state == HUStandState.ESS_CROUCH
      set_tag(motion_matching__controller, "crouch", true)
    motion_matching__enabled = true

  if !hasAvailableAnimations(*motion_matching__controller.dataBase, motion_matching__controller.currentTags)
    motion_matching__enabled = false

[es(tag=gameClient, after=(human_anim_es, force_anim_state_es), before=(anim_state_es, update_tag_changes_es))]
def update_human_mm_tags_es(evt : ParallelUpdateFrameDelayed;
                            animchar__animState : Object;
                            animchar__animStateDirty : bool;
                            human_anim__lowerStateSprint : int;
                            human_anim__lowerStateRun : int;
                            human_anim__lowerStateStand : int;
                            human_anim__lowerStateWalk : int;
                            human_anim__lowerStateRotateLeft : int;
                            human_anim__lowerStateRotateRight : int;
                            human_net_phys : HumanActor;
                            motion_matching__dataBaseEid : EntityId;
                            motion_matching__weaponTagIdx : int;
                            isInVehicle : bool;
                            var motion_matching__prevLowerAnimState : int&;
                            var motion_matching__prevStandState : int&;
                            var motion_matching__enabled : bool&;
                            var motion_matching__controller : MotionMatchingController)
  assume phys = human_net_phys.phys
  if (motion_matching__dataBaseEid == INVALID_ENTITY_ID || isInVehicle ||
      (!animchar__animStateDirty && motion_matching__prevLowerAnimState >= 0 &&
       int(phys.currentState.standState) == motion_matching__prevStandState))
    return

  for state in animchar__animState
    if state.key == "lower"
      let nextLowerStateId = get_int(state.value) ?? 0
      update_mm_tags_from_human_state(human_anim__lowerStateSprint, human_anim__lowerStateRun,
        human_anim__lowerStateStand, human_anim__lowerStateWalk, human_anim__lowerStateRotateLeft,
        human_anim__lowerStateRotateRight, motion_matching__prevLowerAnimState, nextLowerStateId,
        phys.currentState.standState, motion_matching__weaponTagIdx, motion_matching__enabled,
        motion_matching__controller)
      motion_matching__prevLowerAnimState = nextLowerStateId
      motion_matching__prevStandState = int(phys.currentState.standState)

[es(tag=gameClient, on_event=AnimationDataBaseAssigned, track=isInVehicle)]
def disable_mm_in_vehicle_es(event : Event;
                             isInVehicle : bool;
                             var motion_matching__enabled : bool&)
  if (isInVehicle)
    motion_matching__enabled = false

//todo: try to remove this when transitions between stand,walk,run will be added
[es(tag=gameClient, after=update_human_mm_tags_es)]
def set_mm_turn_on_spot_tag_es(evt : ParallelUpdateFrameDelayed;
                               human_net_phys : HumanActor;
                               var motion_matching__turnOnSpotTimer : float&;
                               var motion_matching__controller : MotionMatchingController)
  if motion_matching__controller.dataBase == null
    return
  assume curState = human_net_phys.phys.currentState
  motion_matching__turnOnSpotTimer += evt.dt
  if curState.standState == HUStandState.ESS_STAND && (curState.moveState == HUMoveState.EMS_ROTATE_LEFT ||
      curState.moveState == HUMoveState.EMS_ROTATE_RIGHT)
    motion_matching__turnOnSpotTimer = 0.f
    set_tag(motion_matching__controller, "turn_on_spot", true)
  elif (motion_matching__turnOnSpotTimer < 0.75f &&
        curState.moveState == HUMoveState.EMS_STAND &&
        curState.standState == HUStandState.ESS_STAND)
    set_tag(motion_matching__controller, "turn_on_spot", true)
  else
    remove_tag(motion_matching__controller, "turn_on_spot")

def get_selected_weapon_var_id(human_weap__currentGunSlot : int;
                               human_weap__gunEids : EidList)
  if human_weap__currentGunSlot < 0
    return -1
  var weaponEnumVarId = -1
  query(human_weap__gunEids[human_weap__currentGunSlot]) <| $ [es(REQUIRE_NOT=grenade_thrower)] (gun__propsId : int)
    gun_to_anim_get_props(gun__propsId) <| $(gunAnimProps : GunToAnimProps)
      weaponEnumVarId = gunAnimProps.enumVarId
  query(human_weap__gunEids[human_weap__currentGunSlot]) <| $ [es(REQUIRE=grenade_thrower)] (grenade_thrower__selectedGrenadeVarId : int)
    weaponEnumVarId = grenade_thrower__selectedGrenadeVarId
  return weaponEnumVarId

[es(tag=gameClient, track=main_database__loaded)]
def init_mm_tags_for_weapons(evt : Event;
                             eid aka database_eid : EntityId;
                             main_database__loaded : bool;
                             dataBase : AnimationDataBase;
                             motion_matching__weaponToTag : Object;
                             var motion_matching__weaponEnumVars : IntList;
                             var motion_matching__weaponTags : IntList)
  clear(motion_matching__weaponEnumVars)
  clear(motion_matching__weaponTags)
  if !main_database__loaded
    return
  for weaponTagPair in motion_matching__weaponToTag
    let enumVarId = animV20_get_enum_value_by_name(weaponTagPair.key)
    let mmTag = get_ecs_string(weaponTagPair.value)
    let mmTagId = mmTag != null ? dataBase |> getTagIdx(string(*mmTag)) : -1
    if enumVarId >= 0 && mmTagId >= 0
      push(motion_matching__weaponEnumVars, enumVarId)
      push(motion_matching__weaponTags, mmTagId)
  query() <| $ [es] (motion_matching__dataBaseEid : EntityId;
                     human_weap__currentGunSlot : int;
                     human_weap__gunEids : EidList;
                     var motion_matching__weaponTagIdx : int&)
    if motion_matching__dataBaseEid != database_eid
      return
    let weaponEnumVarId = get_selected_weapon_var_id(human_weap__currentGunSlot, human_weap__gunEids)
    let weaponIdx = find_index(motion_matching__weaponEnumVars, weaponEnumVarId)
    if weaponIdx >= 0
      motion_matching__weaponTagIdx = motion_matching__weaponTags[weaponIdx]
    else
      motion_matching__weaponTagIdx = dataBase |> getTagIdx("default_weapon")

[es(tag=gameClient, on_appear, track=human_weap__currentGunSlot, after=init_animations_es)]
def detect_mm_tag_from_current_weapon(evt : Event;
                                      human_weap__currentGunSlot : int;
                                      human_weap__gunEids : EidList;
                                      motion_matching__dataBaseEid : EntityId;
                                      var motion_matching__weaponTagIdx : int&;
                                      var motion_matching__controller : MotionMatchingController)
  let weaponEnumVarId = get_selected_weapon_var_id(human_weap__currentGunSlot, human_weap__gunEids)
  let prevWeaponTagIdx = motion_matching__weaponTagIdx
  query(motion_matching__dataBaseEid) <| $ [es] (motion_matching__weaponEnumVars : IntList;
                                                 motion_matching__weaponTags : IntList)
    let weaponIdx = find_index(motion_matching__weaponEnumVars, weaponEnumVarId)
    if weaponIdx >= 0
      motion_matching__weaponTagIdx = motion_matching__weaponTags[weaponIdx]
    else
      motion_matching__weaponTagIdx = *motion_matching__controller.dataBase |> getTagIdx("default_weapon")

  if prevWeaponTagIdx >= 0 && motion_matching__controller.currentTags |> isTagRequired(uint(prevWeaponTagIdx))
    motion_matching__controller.currentTags |> removeTag(uint(prevWeaponTagIdx))
    if motion_matching__weaponTagIdx >= 0
      motion_matching__controller.currentTags |> requireTag(uint(motion_matching__weaponTagIdx))
