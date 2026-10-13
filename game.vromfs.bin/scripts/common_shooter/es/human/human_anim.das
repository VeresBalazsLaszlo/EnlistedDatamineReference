require ecs
require ecs.safe
require app
require AnimV20
require math.base
require DngHuman
require DngActor
require PhysVars
require PhysDecl
require HumanPhys
require DagorMath
require DngWeapon
require game.es.events
require enlisted.events_enlisted
require DagorRandom
require DagorSystem


enum HumanStatePos
  E_STAND = 0
  E_CROUCH
  E_CRAWL
  E_SWIM
  E_SWIM_UNDERWATER
  E_DOWNED
  E_BIPOD

enum HumanStateMove
  E_STILL = 0
  E_MOVE
  E_RUN
  E_SPRINT
  E_ROTATE_LEFT
  E_ROTATE_RIGHT

enum HumanStateUpperBody
  E_READY = 0
  E_AIM
  E_RELOAD
  E_CHANGE
  E_DOWN
  E_DEFLECT
  E_FAST_THROW
  E_THROW
  E_HEAL
  E_PUT_OUT_FIRE
  E_USE_RADIO
  E_USE_MORTAR
  E_USE_DEFIBRILLATOR_START
  E_USE_DEFIBRILLATOR_FINISH

enum StateJump
  E_NOT_JUMP = 0
  E_FROM_STAND
  E_FROM_RUN

enum HumanAnimStateFlags
  None = 0
  Dead = (1 << 0)
  Attacked = (1 << 1)
  Climbing = (1 << 4)
  Ladder = (1 << 5)
  Gunner = (1 << 6)
  RidingStand = (1 << 8)
  RidingWalk = (1 << 9)
  RidingSprint = (1 << 10)
  ClimbingOverObstacle = (1 << 11)
  FastClimbing = (1 << 12)

def operator &(a : uint; b : HumanAnimStateFlags)
  return (a & uint(b)) != uint(HumanAnimStateFlags.None)

struct StateResult
  upper : int
  lower : int

[es(on_appear)]
def init_human_anim_vars(evt : Event;
                         var phys_vars : PhysVars;
                         var human_anim__gunPitchVarId : int&;
                         var human_anim__persCourseVarId : int&;
                         var human_anim__changeWeaponVarId : int&;
                         var human_anim__changeDirVarId : int&;
                         var human_anim__reloadVarId : int&;
                         var human_anim__walkDirVarId : int&;
                         var human_anim__bodyDirVarId : int&;
                         var human_anim__headRollVarId : int&;
                         var human_anim__headPitchVarId : int&;
                         var human_anim__headYawVarId : int&;
                         var human_anim__leanVarId : int&;
                         var human_anim__standHeightVarId : int&;
                         var human_anim__climbProgressVarId : int&;
                         var human_anim__ladderProgressVarId : int&;
                         var human_anim__vehicleSelectedVarId : int&;
                         var human_anim__seatTypeVarId : int&;
                         var human_anim__healItemSelectedVarId : int&;
                         var human_anim__hitPartsSelectedVarId : int&;
                         var human_anim__weaponYawVarId : int&;
                         var human_anim__weaponPitchVarId : int&;
                         var human_anim__weaponRollVarId : int&;
                         var human_anim__weaponOffsFwdVarId : int&;
                         var human_anim__weaponOffsUpVarId : int&;
                         var human_anim__weaponOffsLeftVarId : int&;
                         var human_anim__vertSpeedVarId : int&;
                         var human_anim__sprintLocalDirVarId : int&;
                         var human_anim__distanceFromCameraVarId : int&)
  human_anim__gunPitchVarId = phys_vars |> registerVar("aim_pitch", 0.f)
  human_anim__persCourseVarId = phys_vars |> registerVar("pers_course", 0.f)
  human_anim__changeWeaponVarId = phys_vars |> registerVar("changeweapon_progress", 0.f)
  human_anim__changeDirVarId = phys_vars |> registerVar("changeweapon_dir", 1.f)
  human_anim__reloadVarId = phys_vars |> registerVar("reload_progress", 0.f)
  human_anim__walkDirVarId = phys_vars |> registerVar("walk_dir", 0.f)
  human_anim__bodyDirVarId = phys_vars |> registerVar("body_dir", 0.f)
  human_anim__headRollVarId = phys_vars |> registerVar("head_roll", 0.f)
  human_anim__headPitchVarId = phys_vars |> registerVar("head_pitch", 0.f)
  human_anim__headYawVarId = phys_vars |> registerVar("head_yaw", 0.f)
  human_anim__leanVarId = phys_vars |> registerVar("torso_lean", 0.f)
  human_anim__standHeightVarId = phys_vars |> registerVar("stand_height", 1.f)
  human_anim__climbProgressVarId = phys_vars |> registerVar("climb_progress", 0.f)
  human_anim__ladderProgressVarId = phys_vars |> registerVar("ladder_progress", 0.f)
  human_anim__vehicleSelectedVarId = phys_vars |> registerVar("vehicle_selected", 0.f)
  human_anim__seatTypeVarId = phys_vars |> registerVar("seat_type", 0.f)
  human_anim__healItemSelectedVarId = phys_vars |> registerVar("heal_item_selected", 0.f)
  human_anim__hitPartsSelectedVarId = phys_vars |> registerVar("hit_parts_selected", 0.f)
  human_anim__weaponYawVarId = phys_vars |> registerVar("recoil_yaw", 0.f)
  human_anim__weaponPitchVarId = phys_vars |> registerVar("recoil_pitch", 0.f)
  human_anim__weaponRollVarId = phys_vars |> registerVar("recoil_roll", 0.f)
  human_anim__weaponOffsFwdVarId = phys_vars |> registerVar("recoil_offset_along", 0.f)
  human_anim__weaponOffsUpVarId = phys_vars |> registerVar("recoil_offset_up", 0.f)
  human_anim__weaponOffsLeftVarId = phys_vars |> registerVar("recoil_offset_across", 0.f)
  human_anim__vertSpeedVarId = phys_vars |> registerVar("vert_speed", 0.f)
  human_anim__sprintLocalDirVarId = phys_vars |> registerVar("sprint_local_dir", 0.f)
  human_anim__distanceFromCameraVarId = phys_vars |> registerVar("distance_from_camera", 0.f)


[es(on_appear)]
def init_human_anim_states(evt : Event;
                           animchar : AnimcharBaseComponent;
                           var human_anim__lowerStateStand : int&;
                           var human_anim__lowerStateStandStill : int&;
                           var human_anim__lowerStateRun : int&;
                           var human_anim__lowerStateWalk : int&;
                           var human_anim__lowerStateCrawlMove : int&;
                           var human_anim__lowerStateCrawlStill : int&;
                           var human_anim__lowerStateRotateLeft : int&;
                           var human_anim__lowerStateRotateRight : int&;
                           var human_anim__lowerStateCrouchRotateLeft : int&;
                           var human_anim__lowerStateCrouchRotateRight : int&;
                           var human_anim__lowerStateJumpStand : int&;
                           var human_anim__lowerStateJumpRun : int&;
                           var human_anim__lowerStateRidingWalk : int&;
                           var human_anim__lowerStateRidingSprint : int&;
                           var human_anim__lowerStateRidingStand : int&;
                           var human_anim__lowerStateSprint : int&;
                           var human_anim__upperStateAim : int&;
                           var human_anim__upperStateFireReady : int&;
                           var human_anim__upperStateChangeWeapon : int&;
                           var human_anim__upperStateReload : int&;
                           var human_anim__upperStateGunDown : int&;
                           var human_anim__upperStateThrowGrenade : int&;
                           var human_anim__upperStateFastThrow : int&;
                           var human_anim__upperStateDeflect : int&;
                           var human_anim__upperStateAimCrouch : int&;
                           var human_anim__upperStateFireReadyCrouch : int&;
                           var human_anim__upperStateChangeWeaponCrouch : int&;
                           var human_anim__upperStateReloadCrouch : int&;
                           var human_anim__upperStateHeal : int&;
                           var human_anim__upperStateHealCrawl : int&;
                           var human_anim__upperStateSwimEatStill : int&;
                           var human_anim__upperStateUpperSprint : int&;
                           var human_anim__comboStateCrawlReload : int&;
                           var human_anim__comboStateCrawlMove : int&;
                           var human_anim__comboStateCrawlRotateLeft : int&;
                           var human_anim__comboStateCrawlRotateRight : int&;
                           var human_anim__comboStateHealInjured : int&;
                           var human_anim__comboStateInjuredCrawlStill : int&;
                           var human_anim__comboStateInjuredCrawlMove : int&;
                           var human_anim__comboStateCrawlAim : int&;
                           var human_anim__comboStateCrawlFireReady : int&;
                           var human_anim__comboStateCrawlChangeWeapons : int&;
                           var human_anim__comboStateAttackedState : int&;
                           var human_anim__comboStateSwimStill : int&;
                           var human_anim__comboStateSwimStillUnderwater : int&;
                           var human_anim__comboStateSwimOnWater : int&;
                           var human_anim__comboStateSwimUnderWater : int&;
                           var human_anim__comboStateClimbHigh : int&;
                           var human_anim__comboStateClimbLadder : int&;
                           var human_anim__comboStateUseMortar : int&;
                           var human_anim__comboStateUseDefibrillatorStart : int&;
                           var human_anim__comboStateUseDefibrillatorFinish : int&;
                           var human_anim__comboStateClimbOverObstacle : int&;
                           var human_anim__comboStateFastClimb : int&;
                           var human_anim__comboStateDead : int&)
  assume animGraph = *animchar.animGraph
  human_anim__lowerStateStand = animGraph |> anim_graph_getStateIdx("lower_stand")
  human_anim__lowerStateStandStill = animGraph |> anim_graph_getStateIdx("lower_stand_still")
  human_anim__lowerStateRun = animGraph |> anim_graph_getStateIdx("lower_run")
  human_anim__lowerStateWalk = animGraph |> anim_graph_getStateIdx("lower_walk")
  human_anim__lowerStateCrawlMove = animGraph |> anim_graph_getStateIdx("lower_crawlmove")
  human_anim__lowerStateCrawlStill = animGraph |> anim_graph_getStateIdx("lower_crawlstill")
  human_anim__lowerStateRotateLeft = animGraph |> anim_graph_getStateIdx("lower_rotate_left")
  human_anim__lowerStateRotateRight = animGraph |> anim_graph_getStateIdx("lower_rotate_right")
  human_anim__lowerStateCrouchRotateLeft = animGraph |> anim_graph_getStateIdx("lower_crouch_rotate_left")
  human_anim__lowerStateCrouchRotateRight = animGraph |> anim_graph_getStateIdx("lower_crouch_rotate_right")
  human_anim__lowerStateJumpStand = animGraph |> anim_graph_getStateIdx("lower_jump_stand")
  human_anim__lowerStateJumpRun = animGraph |> anim_graph_getStateIdx("lower_jump_run")
  human_anim__lowerStateRidingWalk = animGraph |> anim_graph_getStateIdx("lower_beast_rider")
  human_anim__lowerStateRidingSprint = animGraph |> anim_graph_getStateIdx("lower_beast_rider_sprint")
  human_anim__lowerStateRidingStand = animGraph |> anim_graph_getStateIdx("lower_beast_rider_static")
  human_anim__lowerStateSprint = animGraph |> anim_graph_getStateIdx("lower_sprint")

  human_anim__upperStateAim = animGraph |> anim_graph_getStateIdx("upper_aim")
  human_anim__upperStateFireReady = animGraph |> anim_graph_getStateIdx("upper_fireready")
  human_anim__upperStateChangeWeapon = animGraph |> anim_graph_getStateIdx("upper_changeweapon")
  human_anim__upperStateReload = animGraph |> anim_graph_getStateIdx("weapon_reload")
  human_anim__upperStateGunDown = animGraph |> anim_graph_getStateIdx("upper_down")
  human_anim__upperStateThrowGrenade = animGraph |> anim_graph_getStateIdx("point_hand_throw")
  human_anim__upperStateFastThrow = animGraph |> anim_graph_getStateIdx("upper_fast_throw")
  human_anim__upperStateDeflect = animGraph |> anim_graph_getStateIdx("upper_deflect")
  human_anim__upperStateAimCrouch = animGraph |> anim_graph_getStateIdx("upper_aim_crouch")
  human_anim__upperStateFireReadyCrouch = animGraph |> anim_graph_getStateIdx("upper_fireready_crouch")
  human_anim__upperStateChangeWeaponCrouch = animGraph |> anim_graph_getStateIdx("upper_changeweapon_crouch")
  human_anim__upperStateReloadCrouch = animGraph |> anim_graph_getStateIdx("weapon_reload_crouch")
  human_anim__upperStateHeal = animGraph |> anim_graph_getStateIdx("upper_heal")
  human_anim__upperStateHealCrawl = animGraph |> anim_graph_getStateIdx("upper_heal_crawl")
  human_anim__upperStateSwimEatStill = animGraph |> anim_graph_getStateIdx("swim_eat_still")
  human_anim__upperStateUpperSprint = animGraph |> anim_graph_getStateIdx("upper_sprint")

  human_anim__comboStateCrawlReload = animGraph |> anim_graph_getStateIdx("crawl_reload")
  human_anim__comboStateCrawlMove = animGraph |> anim_graph_getStateIdx("crawl_move")
  human_anim__comboStateCrawlRotateLeft = animGraph |> anim_graph_getStateIdx("crawl_rotate_left")
  human_anim__comboStateCrawlRotateRight = animGraph |> anim_graph_getStateIdx("crawl_rotate_right")
  human_anim__comboStateHealInjured = animGraph |> anim_graph_getStateIdx("heal_injured")
  human_anim__comboStateInjuredCrawlStill = animGraph |> anim_graph_getStateIdx("injured_crawl_still")
  human_anim__comboStateInjuredCrawlMove = animGraph |> anim_graph_getStateIdx("injured_crawl_move")
  human_anim__comboStateCrawlAim = animGraph |> anim_graph_getStateIdx("crawl_aim")
  human_anim__comboStateCrawlFireReady = animGraph |> anim_graph_getStateIdx("crawl_fireready")
  human_anim__comboStateCrawlChangeWeapons = animGraph |> anim_graph_getStateIdx("crawlChangeWeapons")
  human_anim__comboStateAttackedState = animGraph |> anim_graph_getStateIdx("sm_bitten")
  human_anim__comboStateSwimStill = animGraph |> anim_graph_getStateIdx("swim_still")
  human_anim__comboStateSwimStillUnderwater = animGraph |> anim_graph_getStateIdx("swim_still_underwater")
  human_anim__comboStateSwimOnWater = animGraph |> anim_graph_getStateIdx("swim_onwater")
  human_anim__comboStateSwimUnderWater = animGraph |> anim_graph_getStateIdx("swim_underwater")
  human_anim__comboStateClimbHigh = animGraph |> anim_graph_getStateIdx("climb_high")
  human_anim__comboStateClimbLadder = animGraph |> anim_graph_getStateIdx("climb_ladder")
  human_anim__comboStateUseMortar = animGraph |> anim_graph_getStateIdx("use_device_state")
  human_anim__comboStateUseDefibrillatorStart = animGraph |> anim_graph_getStateIdx("defibrillator_crawl")
  human_anim__comboStateUseDefibrillatorFinish = animGraph |> anim_graph_getStateIdx("defibrillator_jump")
  human_anim__comboStateClimbOverObstacle = animGraph |> anim_graph_getStateIdx("hurdle_jump_state_01")
  human_anim__comboStateFastClimb = animGraph |> anim_graph_getStateIdx("hurdle_jump_state_02")
  human_anim__comboStateDead = animGraph |> anim_graph_getStateIdx("dead")


def updateState(eid : EntityId;
                state_pos : HumanStatePos;
                state_move : HumanStateMove;
                state_jump : StateJump;
                state_upper_body : HumanStateUpperBody;
                state_flags : uint)
  var res : StateResult

  query(eid) <| $ [es] (human_anim__lowerStateStand : int;
                        human_anim__lowerStateStandStill : int;
                        human_anim__lowerStateRun : int;
                        human_anim__lowerStateWalk : int;
                        human_anim__lowerStateCrawlMove : int;
                        human_anim__lowerStateCrawlStill : int;
                        human_anim__lowerStateRotateLeft : int;
                        human_anim__lowerStateRotateRight : int;
                        human_anim__lowerStateCrouchRotateLeft : int;
                        human_anim__lowerStateCrouchRotateRight : int;
                        human_anim__lowerStateJumpStand : int;
                        human_anim__lowerStateJumpRun : int;
                        human_anim__lowerStateRidingWalk : int;
                        human_anim__lowerStateRidingSprint : int;
                        human_anim__lowerStateRidingStand : int;
                        human_anim__lowerStateSprint : int;
                        human_anim__upperStateAim : int;
                        human_anim__upperStateFireReady : int;
                        human_anim__upperStateChangeWeapon : int;
                        human_anim__upperStateReload : int;
                        human_anim__upperStateGunDown : int;
                        human_anim__upperStateThrowGrenade : int;
                        human_anim__upperStateFastThrow : int;
                        human_anim__upperStateDeflect : int;
                        human_anim__upperStateAimCrouch : int;
                        human_anim__upperStateFireReadyCrouch : int;
                        human_anim__upperStateChangeWeaponCrouch : int;
                        human_anim__upperStateReloadCrouch : int;
                        human_anim__upperStateHeal : int;
                        human_anim__upperStateHealCrawl : int;
                        human_anim__upperStateSwimEatStill : int;
                        human_anim__upperStateUpperSprint : int;
                        human_anim__comboStateCrawlReload : int;
                        human_anim__comboStateCrawlMove : int;
                        human_anim__comboStateCrawlRotateLeft : int;
                        human_anim__comboStateCrawlRotateRight : int;
                        human_anim__comboStateHealInjured : int;
                        human_anim__comboStateInjuredCrawlStill : int;
                        human_anim__comboStateInjuredCrawlMove : int;
                        human_anim__comboStateCrawlAim : int;
                        human_anim__comboStateCrawlFireReady : int;
                        human_anim__comboStateCrawlChangeWeapons : int;
                        human_anim__comboStateAttackedState : int;
                        human_anim__comboStateSwimStill : int;
                        human_anim__comboStateSwimStillUnderwater : int;
                        human_anim__comboStateSwimOnWater : int;
                        human_anim__comboStateSwimUnderWater : int;
                        human_anim__comboStateClimbHigh : int;
                        human_anim__comboStateClimbLadder : int;
                        human_anim__comboStateUseMortar : int;
                        human_anim__comboStateUseDefibrillatorStart : int;
                        human_anim__comboStateUseDefibrillatorFinish : int;
                        human_anim__comboStateClimbOverObstacle : int;
                        human_anim__comboStateFastClimb : int;
                        human_anim__comboStateDead : int)
    if state_flags & HumanAnimStateFlags.Dead
      res.upper = human_anim__comboStateDead
      res.lower = human_anim__comboStateDead
      return
    if state_flags & HumanAnimStateFlags.Attacked
      res.upper = human_anim__comboStateAttackedState
      res.lower = human_anim__comboStateAttackedState
      return
    if state_flags & HumanAnimStateFlags.ClimbingOverObstacle
      res.upper = human_anim__comboStateClimbOverObstacle
      res.lower = human_anim__comboStateClimbOverObstacle
      return
    if state_flags & HumanAnimStateFlags.FastClimbing
      res.upper = human_anim__comboStateFastClimb
      res.lower = human_anim__comboStateFastClimb
      return
    if state_flags & HumanAnimStateFlags.Climbing
      res.upper = human_anim__comboStateClimbHigh
      res.lower = human_anim__comboStateClimbHigh
      return
    if state_flags & HumanAnimStateFlags.Ladder
      res.upper = human_anim__comboStateClimbLadder
      res.lower = human_anim__comboStateClimbLadder
      return

    var upperStateIdx = -1
    var lowerStateIdx = -1
    var comboStateIdx = -1

    if state_pos == HumanStatePos.E_STAND
      if state_move == HumanStateMove.E_STILL
        lowerStateIdx = human_anim__lowerStateStand
      elif state_move == HumanStateMove.E_MOVE
        lowerStateIdx = human_anim__lowerStateWalk
      elif state_move == HumanStateMove.E_RUN
        lowerStateIdx = human_anim__lowerStateRun
      elif state_move == HumanStateMove.E_ROTATE_LEFT
        lowerStateIdx = human_anim__lowerStateRotateLeft
      elif state_move == HumanStateMove.E_ROTATE_RIGHT
        lowerStateIdx = human_anim__lowerStateRotateRight

    elif state_pos == HumanStatePos.E_CROUCH
      if state_move == HumanStateMove.E_STILL
        lowerStateIdx = human_anim__lowerStateStand
      elif state_move == HumanStateMove.E_RUN || state_move == HumanStateMove.E_MOVE
        lowerStateIdx = human_anim__lowerStateWalk
      elif state_move == HumanStateMove.E_ROTATE_LEFT
        lowerStateIdx = human_anim__lowerStateCrouchRotateLeft
      elif state_move == HumanStateMove.E_ROTATE_RIGHT
        lowerStateIdx = human_anim__lowerStateCrouchRotateRight

    elif state_pos == HumanStatePos.E_CRAWL
      if state_move == HumanStateMove.E_STILL
        lowerStateIdx = human_anim__lowerStateCrawlStill
      elif state_move == HumanStateMove.E_RUN || state_move == HumanStateMove.E_MOVE
        lowerStateIdx = human_anim__lowerStateCrawlMove

    elif state_pos == HumanStatePos.E_DOWNED
      if state_move == HumanStateMove.E_SPRINT || state_move == HumanStateMove.E_MOVE || state_move == HumanStateMove.E_RUN || state_move == HumanStateMove.E_ROTATE_LEFT || state_move == HumanStateMove.E_ROTATE_RIGHT
        comboStateIdx = human_anim__comboStateInjuredCrawlMove
      else
        comboStateIdx = human_anim__comboStateInjuredCrawlStill

    if state_upper_body == HumanStateUpperBody.E_READY
      upperStateIdx = state_pos == HumanStatePos.E_CROUCH && human_anim__upperStateFireReadyCrouch >= 0 ? human_anim__upperStateFireReadyCrouch : human_anim__upperStateFireReady
    elif state_upper_body == HumanStateUpperBody.E_AIM
      upperStateIdx = state_pos == HumanStatePos.E_CROUCH && human_anim__upperStateAimCrouch >= 0 ? human_anim__upperStateAimCrouch : human_anim__upperStateAim
    elif state_upper_body == HumanStateUpperBody.E_CHANGE
      upperStateIdx = state_pos == HumanStatePos.E_CROUCH && human_anim__upperStateChangeWeaponCrouch >= 0 ? human_anim__upperStateChangeWeaponCrouch : human_anim__upperStateChangeWeapon
    elif state_upper_body == HumanStateUpperBody.E_RELOAD
      upperStateIdx = state_pos == HumanStatePos.E_CROUCH && human_anim__upperStateReloadCrouch >= 0 ? human_anim__upperStateReloadCrouch : human_anim__upperStateReload
    elif state_upper_body == HumanStateUpperBody.E_DOWN
      upperStateIdx = state_pos != HumanStatePos.E_CRAWL ? human_anim__upperStateGunDown : human_anim__upperStateFireReady
    elif state_upper_body == HumanStateUpperBody.E_FAST_THROW
      upperStateIdx = human_anim__upperStateFastThrow
    elif state_upper_body == HumanStateUpperBody.E_THROW
      upperStateIdx = human_anim__upperStateThrowGrenade
    elif state_upper_body == HumanStateUpperBody.E_DEFLECT
      upperStateIdx = human_anim__upperStateDeflect
    elif state_upper_body == HumanStateUpperBody.E_HEAL
      if state_pos == HumanStatePos.E_CRAWL
        upperStateIdx = human_anim__upperStateHealCrawl
      elif state_pos == HumanStatePos.E_DOWNED
        comboStateIdx = human_anim__comboStateHealInjured
      else
        upperStateIdx = human_anim__upperStateHeal
    elif state_upper_body == HumanStateUpperBody.E_PUT_OUT_FIRE
      if state_pos == HumanStatePos.E_CRAWL
        upperStateIdx = human_anim__upperStateHealCrawl
      else
        upperStateIdx = human_anim__upperStateHeal
    elif state_upper_body == HumanStateUpperBody.E_USE_RADIO
      upperStateIdx = human_anim__upperStateFireReady
      lowerStateIdx = human_anim__lowerStateStand
    elif state_upper_body == HumanStateUpperBody.E_USE_MORTAR
      comboStateIdx = human_anim__comboStateUseMortar
    elif state_upper_body == HumanStateUpperBody.E_USE_DEFIBRILLATOR_START
      comboStateIdx = human_anim__comboStateUseDefibrillatorStart
    elif state_upper_body == HumanStateUpperBody.E_USE_DEFIBRILLATOR_FINISH
      comboStateIdx = human_anim__comboStateUseDefibrillatorFinish

    if state_pos == HumanStatePos.E_CRAWL
      if state_upper_body == HumanStateUpperBody.E_RELOAD
        comboStateIdx = human_anim__comboStateCrawlReload
      elif state_upper_body == HumanStateUpperBody.E_AIM
        comboStateIdx = human_anim__comboStateCrawlAim
      elif state_upper_body == HumanStateUpperBody.E_READY
        comboStateIdx = human_anim__comboStateCrawlFireReady
      elif state_upper_body == HumanStateUpperBody.E_CHANGE
        comboStateIdx = human_anim__comboStateCrawlChangeWeapons

      if state_move == HumanStateMove.E_ROTATE_LEFT
        comboStateIdx = human_anim__comboStateCrawlRotateLeft
      elif state_move == HumanStateMove.E_ROTATE_RIGHT
        comboStateIdx = human_anim__comboStateCrawlRotateRight
      elif state_move == HumanStateMove.E_RUN || state_move == HumanStateMove.E_MOVE
        comboStateIdx = human_anim__comboStateCrawlMove

    if state_move == HumanStateMove.E_SPRINT
      lowerStateIdx = human_anim__lowerStateSprint
      if state_upper_body == HumanStateUpperBody.E_CHANGE
        upperStateIdx = human_anim__upperStateChangeWeapon
      elif state_upper_body == HumanStateUpperBody.E_RELOAD
        upperStateIdx = human_anim__upperStateReload
      else
        upperStateIdx = human_anim__upperStateUpperSprint

    if state_pos == HumanStatePos.E_SWIM
      if state_move == HumanStateMove.E_STILL
        if state_upper_body == HumanStateUpperBody.E_HEAL
          upperStateIdx = human_anim__upperStateSwimEatStill
          lowerStateIdx = human_anim__comboStateSwimStill
        else
          comboStateIdx = human_anim__comboStateSwimStill
      else
        comboStateIdx = human_anim__comboStateSwimOnWater
    elif state_pos == HumanStatePos.E_SWIM_UNDERWATER
      if state_move == HumanStateMove.E_STILL
        comboStateIdx = human_anim__comboStateSwimStillUnderwater
      else
        comboStateIdx = human_anim__comboStateSwimUnderWater

    if state_jump == StateJump.E_FROM_STAND
      lowerStateIdx = human_anim__lowerStateJumpStand
    if state_jump == StateJump.E_FROM_RUN
      lowerStateIdx = human_anim__lowerStateJumpRun

    if state_flags & HumanAnimStateFlags.RidingSprint
      res.upper = upperStateIdx
      res.lower = human_anim__lowerStateRidingSprint
      return
    if state_flags & HumanAnimStateFlags.RidingWalk
      res.upper = upperStateIdx
      res.lower = human_anim__lowerStateRidingWalk
      return
    if state_flags & HumanAnimStateFlags.RidingStand
      res.upper = upperStateIdx
      res.lower = human_anim__lowerStateRidingStand
      return

    let isCrawlState = lowerStateIdx >= 0 && (lowerStateIdx == human_anim__lowerStateCrawlMove || lowerStateIdx == human_anim__lowerStateCrawlStill)
    if (state_pos == HumanStatePos.E_BIPOD && !isCrawlState)
      lowerStateIdx = human_anim__lowerStateStandStill

    if (comboStateIdx >= 0)
      res.upper = comboStateIdx
      res.lower = comboStateIdx
      return
    res.upper = upperStateIdx
    res.lower = lowerStateIdx
    return

  return res

def private calc_head_pitch_yaw(state : HumanPhysState, ignoreGunDir : bool)
  let localGunDir = inverse(state.location.O.quat) * (ignoreGunDir ? state.headDir : state.gunDir)
  let localHeadDir = inverse(state.location.O.quat) * state.headDir
  let yawPitch = float2(-atan2(localGunDir.z, localGunDir.x), atan2(localGunDir.y, length(localGunDir.xz)))
  return float2(-atan2(localHeadDir.z, localHeadDir.x) - yawPitch.x,
                 atan2(localHeadDir.y, length(localHeadDir.xz)) - yawPitch.y)

// just for easier reading
struct Angles
  roll : float
  pitch : float
  yaw : float

def calc_head_roll_pitch_yaw(phys : HumanPhys;
                             interpK : float;
                             rotation : float3;
                             ignoreGunDir : bool)
  let prevHead = calc_head_pitch_yaw(phys.previousState, ignoreGunDir)
  let curHead = calc_head_pitch_yaw(phys.currentState, ignoreGunDir)

  let roll = clamp(deg_to_rad(rotation.x), deg_to_rad(-30.0), deg_to_rad(30.0))
  let pitch = clamp(lerp(prevHead.y, curHead.y, interpK) + deg_to_rad(rotation.y), deg_to_rad(-70.0), deg_to_rad(60.0))
  let yaw = clamp(lerp(prevHead.x, curHead.x, interpK) + deg_to_rad(rotation.z), deg_to_rad(-45.0), deg_to_rad(45.0))
  return Angles(roll = roll, pitch = pitch, yaw = yaw)

def calc_shoot_pitch(actor : HumanActor;
                     eid : EntityId;
                     at_time : float;
                     tm : float3x4;
                     var pitch : float&)
  assume phys = actor.phys
  let interpK = get_phys_interpk_clamped(phys, at_time)
  let prevGun = dir_to_quat(phys.previousState.gunDir)
  let curGun = dir_to_quat(phys.currentState.gunDir)
  var interpGun = slerp(prevGun, curGun, interpK)
  let gun = get_human_gun(eid)
  var shootTm : float3x4
  make_tm(interpGun, shootTm)
  let requiredNetRole = uint(NetRole.URF_LOCAL_CONTROL)
  if gun != null && (uint(actor.role) & requiredNetRole) != 0u
    human_gun_get_shoot_tm(*gun, phys, at_time, shootTm)
    interpGun = DagorMath::quat(shootTm)

  let y = dot(tm[1], shootTm[0])
  let x = dot(tm[0], shootTm[0])
  //we need to clamp x to be positive, because we can't have pitch +-PI
  pitch = atan2(y, x < 0f ? 0f : x)

def get_gun_head_rotation(is_crawl : bool; gun_eid : EntityId; attached_gun_eid : EntityId)
  var rot = float3(0.0)
  let usedGunEid = gun_eid != INVALID_ENTITY_ID ? gun_eid : attached_gun_eid
  query(usedGunEid) <| $ [es] (gun__addHeadRotation : float3;
                               gun__addHeadRotationCrawl : float3)
    rot = is_crawl ? gun__addHeadRotationCrawl : gun__addHeadRotation

  return rot

[es(tag=gameClient, REQUIRE_NOT=animchar__actOnDemand, no_order)]
def human_head_anim_es(info : ParallelUpdateFrameDelayed;
                       animchar__updatable : bool;
                       animchar__visible : bool = true;
                       human_net_phys : HumanActor;
                       human_vehicle__isHoldingGunPassenger : bool = false;
                       human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID;
                       human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                       human_head_dir__interpolationSpeed : float;
                       prevLocoQuat : float4 = float4(0.0, 0.0, 0.0, 1.0);
                       human_anim__headYawRotVisc : float = 0.2;
                       human_anim__headYawVarId : int;
                       human_anim__headRollVarId : int;
                       human_anim__headPitchVarId : int;
                       isInVehicle : bool = false;
                       human_vehicle__isShootingPassenger : bool = false;
                       var phys_vars : PhysVars;
                       var human_head_dir__addHeadRotation : float3&)
  if !animchar__updatable || !animchar__visible
    return

  assume phys = human_net_phys.phys

  var targetAddHeadRotation = float3(0.0)
  if !isInVehicle || human_vehicle__isShootingPassenger
    targetAddHeadRotation = get_gun_head_rotation(phys.currentState.isCrawl,
                                                  human_weap__currentGunEid,
                                                  human_attached_gun__attachedGunEid)
  human_head_dir__addHeadRotation = lerp(human_head_dir__addHeadRotation,
                                         targetAddHeadRotation,
                                         float3(human_head_dir__interpolationSpeed))

  let interpK = get_phys_interpk_clamped(phys, get_sync_time())
  var headAngles = calc_head_roll_pitch_yaw(phys, interpK, human_head_dir__addHeadRotation, isInVehicle && !human_vehicle__isHoldingGunPassenger)

  if phys.currentState.isAiming
    let breathOffset = lerp(phys.previousState.breathOffset, phys.currentState.breathOffset, float2(interpK))
    headAngles.yaw += breathOffset.x * 0.9
    headAngles.pitch += breathOffset.y * 0.9
    var hd : float
    var att : float
    var bank : float
    let q = quat(prevLocoQuat)
    quat_to_euler(q, hd, att, bank)
    headAngles.pitch += att
    headAngles.pitch = max(0.0, headAngles.pitch)

  let prevHeadYawVar = phys_vars |> getVar(human_anim__headYawVarId)
  let newHeadYawVar = approach(prevHeadYawVar, rad_to_deg(headAngles.yaw),
                               info.dt, human_anim__headYawRotVisc)

  phys_vars |> setVar(human_anim__headRollVarId, rad_to_deg(headAngles.roll))
  phys_vars |> setVar(human_anim__headPitchVarId, rad_to_deg(headAngles.pitch))
  phys_vars |> setVar(human_anim__headYawVarId, newHeadYawVar)

[es(on_appear)]
def init_to_crawl_transition_anim_id(evt : Event;
                                     animchar : AnimcharBaseComponent;
                                     human_anim__toCrawlTransitionAnim : string;
                                     human_anim__toCrawlTransitionVar : string;
                                     var phys_vars : PhysVars;
                                     var human_anim__toCrawlTransitionAnimId : int&;
                                     var human_anim__toCrawlTransitionVarId : int&)
  if animchar.animGraph != null
    human_anim__toCrawlTransitionAnimId = *animchar.animGraph |> anim_graph_getStateIdx(human_anim__toCrawlTransitionAnim)
    human_anim__toCrawlTransitionVarId = phys_vars |> registerVar(human_anim__toCrawlTransitionVar, 0.)

[es(on_appear)]
def init_bipod_anim_id(evt : Event;
                       human_anim__bipodVar : string;
                       var phys_vars : PhysVars;
                       var human_anim__bipodVarId : int&)
  human_anim__bipodVarId = phys_vars |> registerVar(human_anim__bipodVar, 0.)

[es(on_appear)]
def init_from_crawl_transition_anim_id(evt : Event;
                                       animchar : AnimcharBaseComponent;
                                       human_anim__fromCrawlTransitionAnim : string;
                                       human_anim__fromCrawlTransitionVar : string;
                                       var phys_vars : PhysVars;
                                       var human_anim__fromCrawlTransitionAnimId : int&;
                                       var human_anim__fromCrawlTransitionVarId : int&)
  if animchar.animGraph != null
    human_anim__fromCrawlTransitionAnimId = *animchar.animGraph |> anim_graph_getStateIdx(human_anim__fromCrawlTransitionAnim)
    human_anim__fromCrawlTransitionVarId = phys_vars |> registerVar(human_anim__fromCrawlTransitionVar, 0.)

[es(on_appear)]
def human_init_stationary_gun_animation(evt : Event;
                                        animchar : AnimcharBaseComponent;
                                        var human_anim__stationaryGunAnimId : int&)
  let animGraph = animchar.animGraph
  if animGraph != null
    human_anim__stationaryGunAnimId = anim_graph_getStateIdx(*animGraph, "stationary_machine_gun_hold")

[es(tag=server, on_appear)]
def human_init_sprint_anim_variation_in_squad(evt : Event;
                                              human_anim__sprintVariationCount : int;
                                              squad_member__squad : EntityId = INVALID_ENTITY_ID;
                                              var human_anim__sprintVariation : int&)
  if human_anim__sprintVariationCount <= 0
    return
  let squadFound = query(squad_member__squad) <| $ [es] (var squad__sprintAnims : IntList&)
    if length(squad__sprintAnims) == 0
      for i in range(human_anim__sprintVariationCount)
        squad__sprintAnims |> push(i)
    let index = rnd_int(0, length(squad__sprintAnims) - 1)
    human_anim__sprintVariation = squad__sprintAnims[index]
    squad__sprintAnims |> erase(index)
  if !squadFound
    human_anim__sprintVariation = rnd_int(0, human_anim__sprintVariationCount - 1)

[es(on_appear)]
def human_init_sprint_animation_variation(evt : Event;
                                          human_anim__sprintVariation : int;
                                          var human_anim__sprintVariationVarId : int&;
                                          var phys_vars : PhysVars&)
  human_anim__sprintVariationVarId = phys_vars |> registerVar("anim_variation", float(human_anim__sprintVariation))

[es(track=human_anim__sprintVariation, after=human_init_sprint_animation_variation)]
def human_track_sprint_animation_variation(evt : Event;
                                           human_anim__sprintVariation : int;
                                           human_anim__sprintVariationVarId : int;
                                           var phys_vars : PhysVars&)
  phys_vars |> setVar(human_anim__sprintVariationVarId, float(human_anim__sprintVariation))

[es(on_appear)]
def init_human_idle_upper_anim_state(evt : Event;
                                     eid : EntityId;
                                     animchar : AnimcharBaseComponent;
                                     human_anim__idleUpperState : string;
                                     var human_anim__idleUpperStateId : int&)
  if empty(human_anim__idleUpperState)
    return
  human_anim__idleUpperStateId = anim_graph_getStateIdx(*animchar.animGraph, human_anim__idleUpperState)
  if human_anim__idleUpperStateId < 0
    logerr("anim state /*{human_anim__idleUpperState}*/ not found for /*{getEntityTemplateName(eid)}*/")

[es(tag=server, on_appear, track=agent_dangers__hasTraceableDangers)]
def human_anim_idling_state(evt : Event; agent_dangers__hasTraceableDangers : bool; var human_anim__isIdling : bool&)
  human_anim__isIdling = !agent_dangers__hasTraceableDangers

[es(REQUIRE_NOT=animchar__actOnDemand, parallel_for=1)]
def human_anim_es(info : ParallelUpdateFrameDelayed;
                  ragdoll : PhysRagdoll const?;
                  human_anim__climbHeights : Array;
                  dm_parts__hitPartsAnimationId : Array const?;
                  human_net_phys__climbToPos : float3 = float3();
                  transform aka human_transform : float3x4;
                  human_net_phys : HumanActor;
                  human_phys__jumpEndTime : float;
                  eid : EntityId;
                  isAlive : bool;
                  stunTimer : float;
                  human_anim__gunPitchVarId : int;
                  human_anim__leanVarId : int;
                  human_anim__standHeightVarId : int;
                  human_anim__hitPartsSelectedVarId : int;
                  human_anim__persCourseVarId : int;
                  human_anim__changeDirVarId : int;
                  human_anim__reloadVarId : int;
                  human_anim__changeWeaponVarId : int;
                  human_anim__healItemSelectedVarId : int;
                  human_anim__climbProgressVarId : int;
                  human_anim__vehicleSelectedVarId : int;
                  human_anim__seatTypeVarId : int;
                  human_anim__vertSpeedVarId : int;
                  human_anim__walkDirVarId : int;
                  human_anim__bodyDirVarId : int;
                  human_anim__sprintLocalDirVarId : int;
                  human_anim__distanceFromCameraVarId : int;
                  hitpoints__lastHitNodeId : int = -1;
                  human_inventory__entityToUse : EntityId = INVALID_ENTITY_ID;
                  human_inventory__targetToUse : EntityId = INVALID_ENTITY_ID;
                  human_inventory__entityUseEnd : float = -1.0;
                  human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                  human_net_phys__isClimbing : bool = false;
                  human_weap__reloadAtTime : float = -1.0;
                  human_weap__reloadStartTime : float = -1.0;
                  human_weap__isReloading : bool = false;
                  human_weap__weapModActivateStartTime : float = -1.0;
                  human_weap__weapModActivateFinishTime : float = -1.0;
                  human_vehicle__isHoldingGunPassenger : bool = false;
                  isGunner : bool = false;
                  isInVehicle : bool = false;
                  human_weap__throwMode : bool = false;
                  human_weap__radioMode : bool = false;
                  human_weap__mortarMode : bool = false;
                  human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                  human_anim__stationaryGunAnimId : int = -1;
                  animchar__scale : float = 1.0;
                  human_anim__airSpeedMult : float = 0.05;
                  human_anim__jumpTransitionTime : float = 2.0;
                  human_anim__jumpVertSpeedTransitionOffset : float = -10.0;
                  human_anim__vertVelVisc : float = 0.2;
                  human_anim__considerFwdStopped : float = 0.1;
                  human_anim__considerFallingCoef : float = 2.0;
                  human_anim__jumpUpperStateId : int = -1;
                  burning__isPuttingOut : bool = false;
                  burning__animPutOutEnum : int = -1;
                  bipod__enabled : bool = false;
                  human_vehicle_anim__upperId : int = -1;
                  human_vehicle_anim__lowerId : int = -1;
                  human_vehicle_anim__fireReadyUpperId : int = -1;
                  human_vehicle_anim__fireReadyLowerId : int = -1;
                  human_vehicle_anim__healUpperId : int = -1;
                  human_vehicle_anim__healLowerId : int = -1;
                  human_vehicle_anim__maxStandHeight : float = 1.;
                  human_anim__crawlThreshold : float = -0.1;
                  human_anim__toCrawlTransitionAnimId : int;
                  human_anim__toCrawlTransitionVarId : int;
                  human_anim__bipodVarId : int;
                  human_anim__fromCrawlTransitionAnimId : int;
                  human_anim__fromCrawlTransitionVarId : int;
                  human_anim__upperStateFastThrow : int;
                  human_anim__upperStateThrowGrenade : int;
                  human_anim__upperStateChangeWeapon : int;
                  human_anim__idleUpperStateId : int = -1;
                  human_melee_charge__isActive : bool = false;
                  human_melee_charge__animUpperStateId : int = -1;
                  human_melee_charge__animProgressVarId : int = -1;
                  human_melee_charge__animProgress : float = 0.0;
                  human_melee_charge__isActiveVarId : int = -1;
                  animchar__updatable : bool;
                  animchar__visible : bool = true;
                  animchar__accumDt = -1.f;
                  animchar__dtThreshold = 0.f;
                  human_anim__jumpStartStateRange : float2;
                  human_anim__jumpEndStateRange : float2;
                  human_phys__jumpStartTime : float;
                  human_phys__beforeJumpDelay : float;
                  human_phys__beforeJumpCrouchHeight : float;
                  human_phys__afterJumpCrouchHeight : float;
                  human_anim__heightViscosity : float = 0.1;
                  human_anim__bipodHeightViscosity : float = 0.01;
                  huamn_anim__sprintLocalDirViscosity : float = 0.1;
                  human_anim__isIdling : bool = false;
                  beh_tree__enabled : bool = false;
                  var human_anim__previousHeight : float&;
                  var phys_vars : PhysVars;
                  var animchar__animSpeed : float&;
                  var human_anim__jumpTimer : float&)
  if !animchar__updatable || (!animchar__visible && ((animchar__accumDt + info.dt) < animchar__dtThreshold))
    return

  var distanceFromCamera = FLT_MAX;
  find_query() <| $ [es] (camera__active : bool;
                          transform aka camera_transform : float3x4)
    if camera__active
      distanceFromCamera = length(human_transform[3] - camera_transform[3])
      return true
    return false
  phys_vars |> setVar(human_anim__distanceFromCameraVarId, distanceFromCamera)

  var pitch : float
  calc_shoot_pitch(human_net_phys, eid, info.curTime, transform, pitch)

  let dt = info.dt
  let curTime = get_sync_time()

  var animHitPartId = 0
  if dm_parts__hitPartsAnimationId != null && hitpoints__lastHitNodeId > -1
    animHitPartId = (hitpoints__lastHitNodeId < length(*dm_parts__hitPartsAnimationId) ?
      get_int((*dm_parts__hitPartsAnimationId)[hitpoints__lastHitNodeId]) ?? 0 : 0)

  let unitTm = transform
  assume phys = human_net_phys.phys

  let interpK = get_phys_interpk_clamped(phys, curTime)
  let walkDir = lerp(phys.previousState.walkDir, phys.currentState.walkDir, float2(interpK))
  let bodyDir = lerp(phys.previousState.bodyOrientDir, phys.currentState.bodyOrientDir, float2(interpK))
  let bodyDir2d = float3(bodyDir.x, 0.0, bodyDir.y)
  assume up = unitTm[1]
  let bodyDir3d = normalize(bodyDir2d - dot(bodyDir2d, up) * up)
  let walkYaw = rad_to_deg(atan2(walkDir.y, walkDir.x))
  let bodyYaw = rad_to_deg(atan2(bodyDir3d.z, bodyDir3d.x))
  let velDelta = lerp(phys.previousState.velocity - phys.previousState.standingVelocity,
                      phys.currentState.velocity - phys.currentState.standingVelocity, float3(interpK))
  var spd = length(velDelta.xz)
  var isClimbing = human_net_phys__isClimbing
  var animHeight = lerp(phys.previousState.height, phys.currentState.height, interpK)

  if human_phys__beforeJumpDelay > 0.f && phys.currentState.jumpStartTime >= 0. && curTime > phys.currentState.jumpStartTime
    animHeight = curTime < phys.currentState.jumpStartTime + human_phys__beforeJumpDelay ? human_phys__beforeJumpCrouchHeight : 1.
  if curTime < phys.currentState.afterJumpDampingEndTime
    animHeight = min(animHeight, human_phys__afterJumpCrouchHeight)

  animHeight = approach(human_anim__previousHeight, animHeight, dt, bipod__enabled ? human_anim__bipodHeightViscosity : human_anim__heightViscosity)

  phys_vars |> setVar(human_anim__gunPitchVarId, rad_to_deg(pitch))
  phys_vars |> setVar(human_anim__walkDirVarId, walkYaw + 90.0)
  phys_vars |> setVar(human_anim__bodyDirVarId, bodyYaw + 90.0)

  let standState = phys.currentState.standState

  phys_vars |> setVar(human_anim__bipodVarId, (bipod__enabled || standState == HUStandState.ESS_CRAWL) ? 1. : 0.)

  phys_vars |> setVar(human_anim__leanVarId, lerp(phys.previousState.leanPosition, phys.currentState.leanPosition, interpK))
  phys_vars |> setVar(human_anim__standHeightVarId, clamp(animHeight, 0., 1.))
  phys_vars |> setVar(human_anim__hitPartsSelectedVarId, float(animHitPartId))

  var sprintLocalDir = 0f
  if phys.currentState.moveState == HUMoveState.EMS_SPRINT
    let sprintYawClamp = PI * 0.125f
    sprintLocalDir = rad_to_deg(clamp(atan2(phys.appliedCT.walkDir.y, phys.appliedCT.walkDir.x), -sprintYawClamp, sprintYawClamp))
  let prevSprintLocalDir = phys_vars |> getVar(human_anim__sprintLocalDirVarId)
  sprintLocalDir = approach(prevSprintLocalDir, sprintLocalDir, dt, huamn_anim__sprintLocalDirViscosity)
  phys_vars |> setVar(human_anim__sprintLocalDirVarId, sprintLocalDir)

  assume fwd = unitTm[0]
  let dir = normalize(fwd - dot(fwd, up) * up)
  let persCourse = rad_to_deg(atan2(dir.z, dir.x))
  phys_vars |> setVar(human_anim__persCourseVarId, persCourse + 90.0)
  let reduceToWalk = abs(norm_s_ang_deg(persCourse - walkYaw)) > 60.0

  let isSwimming = human_phys_state_get_is_swimming(human_net_phys.phys.currentState)
  if (int(human_net_phys.phys.currentState.isInAirHistory) & 1) != 0 && !isSwimming && !isClimbing
    human_anim__jumpTimer += info.dt
    spd *= cvt(human_anim__jumpTimer, 0.0, human_anim__jumpTransitionTime * 0.5, 1.0, human_anim__airSpeedMult)
  else
    human_anim__jumpTimer = 0.0

  let statePos = (bipod__enabled &&
                 standState != HUStandState.ESS_CRAWL ? HumanStatePos.E_BIPOD :
                 standState == HUStandState.ESS_STAND ? HumanStatePos.E_STAND :
                 standState == HUStandState.ESS_DOWNED ? HumanStatePos.E_DOWNED :
                 standState == HUStandState.ESS_CROUCH ? HumanStatePos.E_CROUCH :
                 standState == HUStandState.ESS_CRAWL ? HumanStatePos.E_CRAWL :
                 standState == HUStandState.ESS_SWIM ? HumanStatePos.E_SWIM :
                 standState == HUStandState.ESS_SWIM_UNDERWATER ? HumanStatePos.E_SWIM_UNDERWATER :  HumanStatePos.E_STAND)

  var stateMove = (phys.currentState.moveState == HUMoveState.EMS_SPRINT ? HumanStateMove.E_SPRINT :
                   phys.currentState.moveState == HUMoveState.EMS_WALK ? HumanStateMove.E_MOVE :
                   phys.currentState.moveState == HUMoveState.EMS_RUN ? !reduceToWalk ? HumanStateMove.E_RUN : HumanStateMove.E_MOVE :
                   phys.currentState.moveState == HUMoveState.EMS_ROTATE_LEFT ? HumanStateMove.E_ROTATE_LEFT :
                   phys.currentState.moveState == HUMoveState.EMS_ROTATE_RIGHT ? HumanStateMove.E_ROTATE_RIGHT :
                   HumanStateMove.E_STILL)

  var stateUpperBody = HumanStateUpperBody.E_READY
  let effectiveCurSlot = phys.currentState.weapEquipState.effectiveCurSlot
  let isChangingWeapon = (phys.currentState.weapEquipState.curState == HUWeaponEquipState.EES_HOLSTERING ||
                          phys.currentState.weapEquipState.curState == HUWeaponEquipState.EES_EQUIPING ||
                          phys.previousState.weapEquipState.curState == HUWeaponEquipState.EES_HOLSTERING ||
                          phys.previousState.weapEquipState.curState == HUWeaponEquipState.EES_EQUIPING)
  if human_weap__throwMode
    stateUpperBody = (effectiveCurSlot == HUWeaponSlots.EWS_GRENADE ? HumanStateUpperBody.E_THROW
                                                                    : HumanStateUpperBody.E_FAST_THROW)
  elif phys.currentState.weapEquipState.curState == HUWeaponEquipState.EES_EQUIPED && !isChangingWeapon
    let reload = (curTime >= human_weap__reloadStartTime &&
                  curTime <= human_weap__reloadAtTime) || human_weap__isReloading
    let weapModActivate = (curTime >= human_weap__weapModActivateStartTime &&
                           curTime <= human_weap__weapModActivateFinishTime)
    stateUpperBody = ((reload || weapModActivate) ? HumanStateUpperBody.E_RELOAD :
                      human_phys_isAiming(phys) ? HumanStateUpperBody.E_AIM : HumanStateUpperBody.E_READY)
    phys_vars |> setVar(human_anim__changeWeaponVarId, 0f)
  elif isChangingWeapon
    stateUpperBody = HumanStateUpperBody.E_CHANGE

    assume prevState = phys.previousState.weapEquipState
    assume curState = phys.currentState.weapEquipState
    let progress = lerp(prevState.progress, curState.progress, interpK)
    phys_vars |> setVar(human_anim__changeWeaponVarId, progress)
    phys_vars |> setVar(human_anim__changeDirVarId, prevState.curState == HUWeaponEquipState.EES_EQUIPING ? 1.0 : -1.0)

  elif phys.currentState.weapEquipState.curState == HUWeaponEquipState.EES_DOWN
    let reload = phys_vars |> getVar(human_anim__reloadVarId)
    stateUpperBody = reload > 0.0 ? HumanStateUpperBody.E_READY : HumanStateUpperBody.E_DOWN

  if human_inventory__entityToUse != INVALID_ENTITY_ID && info.curTime < human_inventory__entityUseEnd
    query(human_inventory__entityToUse) <| $ [es] (item__healAnimEnumValue : int;
                                                   item__healTargetAnimEnumValue : int)
      stateUpperBody = HumanStateUpperBody.E_HEAL
      let isTarget = human_inventory__targetToUse != INVALID_ENTITY_ID && human_inventory__targetToUse != eid
      let healEnum = (isTarget && item__healTargetAnimEnumValue > -1
                      ? item__healTargetAnimEnumValue : item__healAnimEnumValue)
      phys_vars |> setVar(human_anim__healItemSelectedVarId, float(healEnum))

  if burning__isPuttingOut
    stateUpperBody = HumanStateUpperBody.E_PUT_OUT_FIRE
    phys_vars |> setVar(human_anim__healItemSelectedVarId, float(burning__animPutOutEnum))

  if human_weap__radioMode
    stateUpperBody = HumanStateUpperBody.E_USE_RADIO

  if human_weap__mortarMode
    stateUpperBody = HumanStateUpperBody.E_USE_MORTAR

  if isClimbing
    let posHt = human_net_phys__climbToPos.y - unitTm[3].y
    var startPt = float2(0.0, 1.0)
    var endPt = float2(0.0, 1.0)
    for attr in human_anim__climbHeights
      let ht = get_Point2(attr) ?? float2()
      if posHt > ht.x
        startPt = ht
        endPt = ht
      else
        endPt = ht
        break
    let climbProgress = cvt(posHt, startPt.x, endPt.x, startPt.y, endPt.y)
    if climbProgress == 1.0
      isClimbing = false
      stateMove = HumanStateMove.E_MOVE
    phys_vars |> setVar(human_anim__climbProgressVarId, climbProgress)

  query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList;
                                                vehicle_seats__enumVarId : int = -1)
    if vehicle_seats__enumVarId >= 0
      phys_vars |> setVar(human_anim__vehicleSelectedVarId, float(vehicle_seats__enumVarId))
    for seatEid in vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__ownerEid : EntityId;
                                seat__enumVarId : int)
        if eid == seat__ownerEid && seat__enumVarId >= 0
          phys_vars |> setVar(human_anim__seatTypeVarId, float(seat__enumVarId))

  var state_flags = uint(HumanAnimStateFlags.None)
  if ragdoll == null && !isAlive
    state_flags |= uint(HumanAnimStateFlags.Dead)
  if stunTimer >= 0.0
    state_flags |= uint(HumanAnimStateFlags.Attacked)
  if isGunner
    state_flags |= uint(HumanAnimStateFlags.Gunner)
  if isClimbing
    state_flags |= uint(HumanAnimStateFlags.Climbing)

  // Jumping and falling animation
  let moveVThres = 0.01
  var moveV = float3(phys.currentState.location.P - phys.previousState.location.P)
  let moveVlen = length(moveV)
  moveV = moveVlen > moveVThres ? moveV * safeinv(moveVlen) : float3()
  let fwdV = phys.currentState.location.fwd
  let fwdStopped = dot(moveV, fwdV) < human_anim__considerFwdStopped
  let isOnGround = (uint(phys.currentState.states) & uint(StateFlag.ST_ON_GROUND)) != 0u
  let isClimbingCurrentState = human_phys_state_get_isClimbing(phys.currentState)
  let inJumping = (!isOnGround && !isClimbingCurrentState &&
                  (statePos != HumanStatePos.E_SWIM && statePos != HumanStatePos.E_SWIM_UNDERWATER))
  let inLongJump = human_anim__jumpTimer > human_anim__jumpTransitionTime
  let walkSpeed = phys |> human_phys_getWalkSpeed(HUStandState.ESS_STAND, HUMoveState.EMS_WALK)
  let isFalling = phys.currentState.velocity.y < -walkSpeed * human_anim__considerFallingCoef
  let jumpFromStand = inJumping && fwdStopped && !isFalling
  let vertSpeed = phys.currentState.velocity.y + (jumpFromStand ? 0.0 :
                                                  cvt(human_anim__jumpTimer,
                                                      human_anim__jumpTransitionTime,
                                                      human_anim__jumpTransitionTime * 2.0,
                                                      human_anim__jumpVertSpeedTransitionOffset,
                                                      0.0))
  let prevVertSpeedVar = phys_vars |> getVar(human_anim__vertSpeedVarId)
  let newVertSpeedVar = approach(prevVertSpeedVar, vertSpeed, dt, human_anim__vertVelVisc)
  phys_vars |> setVar(human_anim__vertSpeedVarId, newVertSpeedVar)
  let stateJump = (jumpFromStand || inLongJump) ? StateJump.E_FROM_STAND : StateJump.E_NOT_JUMP

  var state = StateResult(upper = -1, lower = -1)
  if isInVehicle
    let isHealing = stateUpperBody == HumanStateUpperBody.E_HEAL
    let throwModeUpperState = effectiveCurSlot == HUWeaponSlots.EWS_GRENADE ? human_anim__upperStateThrowGrenade : human_anim__upperStateFastThrow
    let upperVehicleState = ((isHealing && human_vehicle_anim__healUpperId >= 0) ? human_vehicle_anim__healUpperId
      : human_vehicle__isHoldingGunPassenger && human_weap__throwMode ? throwModeUpperState
      : human_vehicle__isHoldingGunPassenger && isChangingWeapon ? human_anim__upperStateChangeWeapon
      : human_vehicle__isHoldingGunPassenger ? human_vehicle_anim__fireReadyUpperId
      : human_vehicle_anim__upperId)
    let lowerVehicleState = ((isHealing && human_vehicle_anim__healLowerId >= 0) ? human_vehicle_anim__healLowerId
      : human_vehicle__isHoldingGunPassenger ? human_vehicle_anim__fireReadyLowerId
      : human_vehicle_anim__lowerId)
    state = StateResult(upper = upperVehicleState, lower = lowerVehicleState)
    if phys.currentState.height > human_vehicle_anim__maxStandHeight
      phys_vars |> setVar(human_anim__standHeightVarId, human_vehicle_anim__maxStandHeight)
  else
    state = updateState(eid, statePos, stateMove, stateJump, stateUpperBody, state_flags)
    if (human_anim__idleUpperStateId >= 0 && beh_tree__enabled && human_anim__isIdling
        && stateUpperBody == HumanStateUpperBody.E_READY
        && stateMove == HumanStateMove.E_STILL
        && (statePos == HumanStatePos.E_STAND || statePos == HumanStatePos.E_CROUCH))
      state.upper = human_anim__idleUpperStateId

    if human_anim__jumpUpperStateId > 0 && ((curTime > human_phys__jumpStartTime + human_anim__jumpStartStateRange.x && curTime < human_phys__jumpStartTime + human_anim__jumpStartStateRange.y) ||
                                            (curTime > human_phys__jumpEndTime + human_anim__jumpEndStateRange.x && curTime < human_phys__jumpEndTime + human_anim__jumpEndStateRange.y))
      state.upper = human_anim__jumpUpperStateId

    let isToCrawlTransition = animHeight < human_anim__previousHeight && phys.currentState.height < human_anim__crawlThreshold && phys.currentState.height > -1.
    let isFromCrawlTransition = animHeight > human_anim__previousHeight && phys.currentState.height < human_anim__crawlThreshold
    if human_anim__toCrawlTransitionAnimId >= 0 && isToCrawlTransition
      state.upper = human_anim__toCrawlTransitionAnimId
      state.lower = human_anim__toCrawlTransitionAnimId
      if human_anim__toCrawlTransitionVarId >= 0
        setVar(phys_vars, human_anim__toCrawlTransitionVarId, cvt(animHeight, 0., -1., 0., 1.))
    if human_anim__fromCrawlTransitionAnimId >= 0 && isFromCrawlTransition
      state.upper = human_anim__fromCrawlTransitionAnimId
      state.lower = human_anim__fromCrawlTransitionAnimId
      if human_anim__fromCrawlTransitionVarId >= 0
        setVar(phys_vars, human_anim__fromCrawlTransitionVarId, cvt(animHeight, 0., -1., 1., 0.))
    if human_melee_charge__isActive && human_melee_charge__animUpperStateId >= 0
      state.upper = human_melee_charge__animUpperStateId
      if human_melee_charge__animProgressVarId >= 0
        setVar(phys_vars, human_melee_charge__animProgressVarId, human_melee_charge__animProgress)
    if human_melee_charge__isActiveVarId >= 0
      setVar(phys_vars, human_melee_charge__isActiveVarId, human_melee_charge__isActive ? 1f : 0f)
  send_change_anim_state_event(eid, "lower", ecs_hash("lower"), state.lower)
  send_change_anim_state_event(eid, "upper", ecs_hash("upper"), state.upper)

  if !!human_attached_gun__attachedGunEid && human_anim__stationaryGunAnimId >= 0
    send_change_anim_state_event(eid, "lower", ecs_hash("lower"), human_anim__stationaryGunAnimId)
    send_change_anim_state_event(eid, "upper", ecs_hash("upper"), human_anim__stationaryGunAnimId)
  animchar__animSpeed = spd * safeinv(animchar__scale)
  human_anim__previousHeight = animHeight

[es(REQUIRE_NOT=(animchar__actOnDemand, human_net_phys, deadEntity), on_appear)]
def simple_human_vehicle_anim_es(evt : Event;
                                 eid : EntityId;
                                 human_vehicle_anim__upperId : int;
                                 human_vehicle_anim__lowerId : int)
  send_change_anim_state_event(eid, "upper", ecs_hash("upper"), human_vehicle_anim__upperId)
  send_change_anim_state_event(eid, "lower", ecs_hash("lower"), human_vehicle_anim__lowerId)

[es(tag=(server, net), REQUIRE=human_net_phys, REQUIRE_NOT=ragdoll, track=isAlive)]
def human_anim_disable_anim_updates_for_deadmen_server_es(evt : Event;
                                                          isAlive : bool;
                                                          var animchar__updatable : bool&)
  animchar__updatable = isAlive

[es(on_appear, before=anim_phys_init_es)]
def human_anim_set_animchar_params_es(event : Event;
                                      animcharParams : Object;
                                      var phys_vars : PhysVars)
  var params : array<int>
  var values : array<float>
  for item in animcharParams
    let k = phys_vars |> registerVar(item.key, 0.0)
    params |> push(k)
    let v = get_float(item.value) ?? 0.0
    values |> push(v)
  for i in iter_range(animcharParams)
    phys_vars |> setVar(params[i], values[i])

