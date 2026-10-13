require ecs
require DngHuman
require HumanPhys
require math.base

[es(no_order)]
def human_camera_zoom(info : UpdateStageInfoAct; bindedCamera : EntityId; human_net_phys : HumanActor; human_weap__blockAiming : bool)
  query(bindedCamera) <| $ [es] (var zoom : float&)
    let wishZoomValue = !human_weap__blockAiming && is_control_bit_set(human_net_phys.phys.producedCT, (HumanPhysControlType.HCT_AIM)) ? 1.0 : 0.0
    zoom = move_to_scalar(zoom, wishZoomValue, info.dt, human_net_phys.phys.aimSpeed)

[es(no_order)]
def human_switch_to_alternative_settings(info : UpdateStageInfoAct; bindedCamera : EntityId; isAlive, isDowned : bool)
  query(bindedCamera) <| $ [es] (var shooter_cam__alternative_settings : bool&)
    shooter_cam__alternative_settings = !isAlive || isDowned
