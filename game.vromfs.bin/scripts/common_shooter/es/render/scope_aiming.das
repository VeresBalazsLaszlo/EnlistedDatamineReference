require ecs
require DngCamera
require enlisted.events_enlisted
require GeomNodeTree
require AnimV20

[es(tag=render, no_order, REQUIRE=cockpitEntity)]
def reset_current_entity_with_scope_eid_es(info : ParallelUpdateFrameDelayed;
                                           var attached_gun_scope__currentEid : EntityId&)
  attached_gun_scope__currentEid = INVALID_ENTITY_ID


def check_lens_node(eid)
  if get_bool(eid, "gunmod__lensActive") ?? false
    var isOk = false
    query(eid) <| $ [es] (animchar : AnimcharBaseComponent; gunmod__lensNode : string)
      isOk = *animchar.nodeTree |> geomtree_findNodeIndex(gunmod__lensNode) != -1
    return isOk
  else
    return false


[es(tag=render, after=reset_current_entity_with_scope_eid_es,
  before=update_camera_common_aim_parameters_es, REQUIRE=cockpitEntity)]
def update_human_entity_with_scope_eid_es(info : ParallelUpdateFrameDelayed;
                                          human_weap__currentGunModEids : EidList;
                                          human_weap__currentGunEid : EntityId;
                                          human_binocular__mode : bool;
                                          human_binocular__eid : EntityId;
                                          var attached_gun_scope__currentEid : EntityId&)
  let camEid = get_cur_cam_entity()
  if get_bool(camEid, "isPlaneCockpitCam") ?? false
    return

  if human_binocular__mode
    if check_lens_node(human_binocular__eid)
      attached_gun_scope__currentEid = human_binocular__eid
    return
  if check_lens_node(human_weap__currentGunEid)
    attached_gun_scope__currentEid = human_weap__currentGunEid
  else
    for eid in human_weap__currentGunModEids
      if check_lens_node(eid)
        attached_gun_scope__currentEid = eid
        break


[es(tag=render, after=reset_current_entity_with_scope_eid_es,
  before=update_camera_common_aim_parameters_es, REQUIRE=(cockpitEntity, planeCockpit))]
def update_plane_entity_with_scope_eid_es(info : ParallelUpdateFrameDelayed;
                                          eid : EntityId;
                                          var attached_gun_scope__currentEid : EntityId&)
  attached_gun_scope__currentEid = eid
