require ecs
require enlisted.events_enlisted
require dm
require AnimV20
require GeomNodeTree
require CollRes
require DngDm
require DagorMath
require common_shooter.es.repair_common

[es(tag=gameClient, on_appear, REQUIRE_NOT=deadEntity)]
def init_special_view_dm_parts_es(evt : Event;
                                  damage_model : DamageModel&;
                                  @shared_comp dm_parts__specialViewPartNames : StringList;
                                  var dm_parts__specialViewParts : BoolList)
  resize(dm_parts__specialViewParts, get_damage_part_props_count(damage_model.dmData))
  for partName in dm_parts__specialViewPartNames
    let partId = find_part_id_by_name(damage_model, string(partName))
    if partId >= 0
      dm_parts__specialViewParts[partId] = true

[es(tag=server, on_appear, REQUIRE_NOT=deadEntity)]
def create_attached_ammo_box(evt : Event;
                             team : int;
                             var attached_ammo_box__eid : EntityId&;
                             attached_ammo_box__template : string)
  if !!attached_ammo_box__eid
    return
  attached_ammo_box__eid = createEntity(attached_ammo_box__template) <| $(var init)
    set(init, "team", team)

[es(tag=gameClient, on_appear, REQUIRE_NOT=deadEntity)]
def create_attached_ammo_box_markers(evt : Event;
                                     damage_model : DamageModel&;
                                     @shared_comp dm_parts__specialViewPartNames : StringList;
                                     attached_ammo_box__markerIcon : string;
                                     var attached_ammo_box__markerHolders : EidList)
  if length(attached_ammo_box__markerHolders) > 0 && !!attached_ammo_box__markerHolders[0]
    return
  resize(attached_ammo_box__markerHolders, length(dm_parts__specialViewPartNames))
  var partNo = 0
  for partName in dm_parts__specialViewPartNames
    let nodeIdx = find_part_id_by_name(damage_model, string(partName))
    if nodeIdx < 0
      continue
    attached_ammo_box__markerHolders[partNo] = createEntity("marker_holder") <| $(var init)
      set(init, "marker_holder__nodeId", nodeIdx)
      set(init, "hud_icon__maxDistance", partNo == 0 ? 10. : 2.)
      set(init, "hud_icon__image", attached_ammo_box__markerIcon)
      set(init, "hud_icon__isActive", false)
    partNo++

[es(tag=server, on_appear, REQUIRE=deadEntity)]
def destroy_attached_ammo_box(evt : Event; attached_ammo_box__eid : EntityId)
  destroyEntity(attached_ammo_box__eid)

[es(tag=gameClient, on_appear, REQUIRE=deadEntity)]
def destroy_attached_ammo_box_markers(evt : Event; attached_ammo_box__markerHolders : EidList)
  for boxEid in attached_ammo_box__markerHolders
    destroyEntity(boxEid)

[es(tag=gameClient, track=useful_box__useCount, REQUIRE=attachedAmmoBoxTag)]
def attached_ammo_box_use_count_track(evt : Event; eid : EntityId; useful_box__useCount : int)
  find_query() <| $ [es] (attached_ammo_box__eid : EntityId; var attached_ammo_box__hasAmmo : bool&)
    if attached_ammo_box__eid == eid
      attached_ammo_box__hasAmmo = useful_box__useCount > 0
      return true
    return false

[es(tag=gameClient, REQUIRE_NOT=deadEntity)]
def attached_ammo_box_markers_update(info : ParallelUpdateFrameDelayed;
                                     transform aka vehicle_transform : float3x4;
                                     damage_model : DamageModel&;
                                     collres : CollisionResource;
                                     eid : EntityId;
                                     animchar : AnimcharBaseComponent;
                                     attached_ammo_box__markerHolders : EidList;
                                     attached_ammo_box__eid : EntityId)
  let boxTeamRef = get_int(attached_ammo_box__eid, "team")
  if boxTeamRef == null
    return
  let boxTeam = *boxTeamRef
  let boxAnyTeam = has(attached_ammo_box__eid, "useful_box__anyTeam")
  query() <| $ [es(REQUIRE=hero)] (transform aka hero_transform : float3x4;
                                   human_anim__vehicleSelected : EntityId;
                                   team aka hero_team : int)
    let hostileBox = !is_maintenance_allowed(hero_team, boxTeam)
    if (hostileBox && !boxAnyTeam) || distance_sq(vehicle_transform[3], hero_transform[3]) > 100.
      for partEid in attached_ammo_box__markerHolders
        setOptional(partEid, "hud_icon__isActive", false)
      return
    for partEid in attached_ammo_box__markerHolders
      query(partEid) <| $ [es] (marker_holder__nodeId : int; var transform aka part_transform : float3x4; var hud_icon__isActive : bool&)
        if get_damage_part_props_count(damage_model.dmData) <= marker_holder__nodeId
          return
        if human_anim__vehicleSelected == eid
          hud_icon__isActive = false
          return
        hud_icon__isActive = true
        let collisionNodeId = get_collision_node_id(damage_model.dmData, marker_holder__nodeId)
        let node = collres_get_node(collres, collisionNodeId)
        if node != null
          var tm : float3x4
          collres_get_collision_node_tm(collres, collisionNodeId, vehicle_transform, animchar.nodeTree, tm)
          let partModelBBox = collres_get_node_bbox(collres, collisionNodeId)
          part_transform[3] = tm * partModelBBox.center

[es]
def attached_ammo_box_pos_update(info : ParallelUpdateFrameDelayed;
                                 attached_ammo_box__eid : EntityId;
                                 transform aka vehicle_transform : float3x4)
  query(attached_ammo_box__eid) <| $ [es] (var transform aka box_transform : float3x4&)
    box_transform[3] = vehicle_transform[3]
