require ecs
require CollRes
require DagorMath
require AnimV20
require GeomNodeTree
require danetlibs.animchar_attach.render.skeleton_attach_common
require enlisted.events_enlisted

def try_get_visual_bbox_center(animchar_render : AnimcharRendComponent; var center : float3&) : bool
  let sceneInst = animchar_render.sceneInstance
  if sceneInst == null
    return false // model is not loaded yet
  var box = BBox3()
  scene_instance_get_local_bounding_box(sceneInst, box)
  if box.isempty
    return false
  center = box.center
  return true


// menu item animchar is rendered with animchar__turnDir, so the model space center
// has to be brought into the same basis as transform
def to_menu_item_center(model_center : float3) : float3
  return float3(-model_center.z, model_center.y, model_center.x)


def collres_menu_item_center(collres : CollisionResource) : float3
  var box = BBox3()
  bbox3f_to_scalar_bbox3(box, collres.vFullBBox)
  return to_menu_item_center(box.center)


// item collres is a gameplay volume, not a fit of the mesh: cloth spans the whole figure,
// a medkit box is twice the model height. Center on visible geometry and keep collres for
// the frames where the animchar res is not loaded yet. Runs before the only reader
[es(tag=gameClient, before=menu_rotate_target_cam_es)]
def menu_item_bbox_center_es(info : UpdateStageInfoAct;
                             animchar_render : AnimcharRendComponent;
                             collres : CollisionResource const?;
                             var menu_item__boundingBoxCenter : float3&)
  var center : float3
  if try_get_visual_bbox_center(animchar_render, center)
    menu_item__boundingBoxCenter = to_menu_item_center(center)
  elif collres != null
    menu_item__boundingBoxCenter = collres_menu_item_center(*collres)


// standalone preview items skip the skeleton-attach path that settles fastphys,
// so straps hang in the unsettled pose and clip; settle them once like attachments do
[es(on_appear, REQUIRE=(menuItemObject, animchar_fast_phys))]
def menu_item_settle_fast_phys_es(evt : Event;
                                  var animchar : AnimcharBaseComponent&)
  assume nodeTree = *animchar.nodeTree
  animchar |> animchar_resetFastPhysWtmOfs(geomtree_getWtmOfs(nodeTree))
  // simulate fastphys for some frames to let fastphys items settle
  let fastPhysSimTimeOnReset = 1.5
  animchar |> animchar_updateFastPhys(fastPhysSimTimeOnReset)


// menu animchar updates it's position and camera fov for zoom effect on input
// because of this we need to update menu animchar and it's attachments
// on update and not in parallel, before rendering. Otherwise we get one frame
// of new camera fov and old animchar position which looks jittery
// this also fixes item in BP being rendered in a wrong pos for one frame
[es(tag=server, tag=gameClient, after=menu_rotate_target_cam_es, REQUIRE=menuItemObject)]
def menu_item_animchar_act(info : UpdateStageInfoAct;
                           transform : float3x4;
                           var animchar : AnimcharBaseComponent;
                           var animchar_node_wtm : AnimcharNodesMat44;
                           var animchar_render__root_pos : vec4f&;
                           animchar__turnDir = false)
  var resultTm = transform
  if animchar__turnDir
    resultTm[0] = transform[2]
    resultTm[2] = -transform[0]

  animchar_set_tm(animchar, resultTm, true)
  animchar |> animchar_recalc_wtm()
  animchar |> animchar_updateFastPhys(info.dt)

  animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)

// wear items are skeleton attaches, not slot attaches: nothing refreshes them here, so they are
// left to the tracked-transform ES that runs on the next frame's tick and trail by a frame
[es(tag=gameClient, after=menu_item_animchar_act, REQUIRE=menuItemObject)]
def menu_item_skeleton_attaches_act(info : UpdateStageInfoAct;
                                    eid : EntityId;
                                    animchar : AnimcharBaseComponent&;
                                    animchar__visible : bool;
                                    animchar_bbox : bbox3f;
                                    attaches_list : EidList;
                                    animchar_render : AnimcharRendComponent;
                                    animchar_node_wtm : AnimcharNodesMat44;
                                    var animchar_bsph_precalculated : vec4f&;
                                    var animchar_bbox_precalculated : BBox3&;
                                    var animchar_shadow_cull_bbox_precalculated : BBox3&;
                                    var animchar_attaches_bbox_precalculated : bbox3f?;
                                    var animchar__usePrecalculatedData : bool&)
  animchar__usePrecalculatedData = true

  animchar_bsph_precalculated = animchar_render_prepareSphere(animchar_render, animchar_node_wtm)
  animchar_bbox_precalculated = animchar_render_calcWorldBox(animchar_render, animchar_node_wtm, true)
  animchar_shadow_cull_bbox_precalculated = animchar_render_calcWorldBox(animchar_render, animchar_node_wtm, false)
  skeleton_attached_to(eid, animchar, animchar__visible, attaches_list, info.dt, animchar_bbox,
                       animchar_bsph_precalculated, animchar_attaches_bbox_precalculated)


// separate system so slot attach update is called only once
// and only if there is a menuItemObject in the scene
[es(tag=server, tag=gameClient, after=menu_item_animchar_act)]
def menu_item_animchar_slot_attaches_act(info : UpdateStageInfoAct)
  find_query() <| $ [es(REQUIRE=menuItemObject)] ()
    broadcastEventImmediate(SlotAttachUpdateEvent(dt = info.dt))
    return true
