require ecs
require ecs.common
require vehicle
require dm
require DngDm
require AnimV20
require GeomNodeTree
require CollRes
require game.es.vehicle.vehicle_events
require game.es.flying_turret_common
require common_shooter.events_common_shooter

[es(tag=server, on_appear)]
def damage_model_part_alive_update_es_event_handler(evt : Event;
                                                    damage_model : DamageModel;
                                                    var damage_part_alive : BoolList)
  let partsCount = get_damage_part_props_count(damage_model.dmData)
  resize(damage_part_alive, partsCount)
  for i in range(0, partsCount)
    damage_part_alive[i] = false

[es(tag=server, no_order)]
def damage_model_part_alive_update_es(act : ecs::UpdateStageInfoAct;
                                      damage_model : DamageModel;
                                      var damage_part_alive : BoolList)
  let partsCount = get_damage_part_props_count(damage_model.dmData)
  for i in range(0, partsCount)
    damage_part_alive[i] = int(get_damage_part_props(damage_model.dmData, i).relHpFixed) > 0

def show_dmg(show : bool;
             coll_node_id : int;
             collNodeIdToNodeIdMain, collNodeIdToNodeIdDmg : IntList;
             var dmg_animchar : DmgAnimChar&;
             var animchar_render : AnimcharRendComponent&)
  if collNodeIdToNodeIdMain[coll_node_id] >= 0 && collNodeIdToNodeIdDmg[coll_node_id] >= 0
    animchar_render.sceneInstance |> scene_instance_show_node(collNodeIdToNodeIdMain[coll_node_id], !show)
    dmg_animchar.sceneInstance |> scene_instance_show_node(collNodeIdToNodeIdDmg[coll_node_id], show)
    return true
  return false

[es(tag=render, track=damage_part_alive, REQUIRE_NOT=deadEntity, before=visual_damage_immediate_es)]
def visual_barrel_damage_updater(evt : Event;
                                 isExploded, isAlive : bool;
                                 turret_control__gunEids : EidList;
                                 damage_part_alive : BoolList)

  if !isAlive || isExploded
    return
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_dm_part__barrelDm, turret_dm_part__breechDm : int;
                                                        var turret__isVisualBroken : bool&)
      let barrelDm = turret_dm_part__barrelDm
      let breechDm = turret_dm_part__breechDm
      if barrelDm >= 0
        turret__isVisualBroken = !damage_part_alive[barrelDm]
      if breechDm >= 0 && !turret__isVisualBroken
        turret__isVisualBroken = !damage_part_alive[breechDm]

[es(tag=render, on_appear, track=damage_part_alive, before=before_animchar_update_sync, after=visual_damage_remap_init_es)]
def visual_damage_immediate_es(evt : Event;
                               eid : EntityId;
                               visual_dmg_remap__collNodeIdToNodeIdMain, visual_dmg_remap__collNodeIdToNodeIdDmg : IntList;
                               damage_model : DamageModel;
                               damage_part_alive : BoolList;
                               turret_control__gunEids : EidList const?;
                               animchar : AnimcharBaseComponent const?;
                               collres : CollisionResource const?;
                               losable_turret__lostBone : string = "";
                               var animchar_render : AnimcharRendComponent&;
                               var dmg_animchar : DmgAnimChar&;
                               var dmg_animchar__renderable : bool&)
  // Build the set of coll-node ids that belong to the lost turret subtree on the source
  // tank (enlisted-specific tank_loseable_turret flow). After detach, the dmg/main meshes for
  // those parts should stay HIDDEN on the source tank -- the flying turret entity now carries
  // them. Without this, the per-tick re-show loop below flips gun_barrel_dmg back to visible
  // every time damage_part_alive ticks, producing a broken gun barrel floating where the
  // turret used to be. Set is empty for entities that haven't lost a turret
  // (losable_turret__lostBone="") or that don't have the components needed to resolve the subtree.
  // Bitset over collres node ids (O(1) membership check in the damage-parts loop below).
  var isLostTurretCollNode : array<bool>
  if !empty(losable_turret__lostBone) && animchar != null && collres != null
    let rootBoneIdx = *animchar.nodeTree |> geomtree_findNodeIndex(losable_turret__lostBone)
    if rootBoneIdx >= 0
      var subtree : array<int>
      gather_bone_subtree(animchar.nodeTree, rootBoneIdx, subtree)
      let n = collres_get_nodesCount(*collres)
      isLostTurretCollNode |> resize(n)
      for i in range(n)
        let node = collres_get_node(*collres, i)
        if node != null && find_index(subtree, int((*node).geomNodeId)) >= 0
          isLostTurretCollNode[i] = true

  using() <| $(var turretControlGunDmParts : IntList&)
    if turret_control__gunEids != null
      for gun in *turret_control__gunEids
        query(gun) <| $ [es] (turret__isVisualBroken : bool;
                              turret_dm_part__barrelDm : int;
                              turret_dm_part__breechDm : int)
          if turret__isVisualBroken
            return
          if turret_dm_part__barrelDm >= 0
            turretControlGunDmParts |> push(turret_dm_part__barrelDm)
          if turret_dm_part__breechDm >= 0
            turretControlGunDmParts |> push(turret_dm_part__breechDm)

    dmg_animchar__renderable = false
    let damagePartsCount = length(damage_part_alive)
    for i in range(0, damagePartsCount)
      let collNodeId = damage_model.dmData |> get_collision_node_id(i)
      if collNodeId < 0
        continue
      if get_max_hp(damage_model.dmData, i) <= 0.0
        continue  // geometry-only part (no HP); node visibility managed by C++ wreckage system
      // Lost-turret subtree: leave whatever visibility on_lost_turret_bone_render_hide_es
      // set alone (both main and dmg hidden) so the source tank doesn't sprout the broken
      // turret's parts back into view.
      if collNodeId < length(isLostTurretCollNode) && isLostTurretCollNode[collNodeId]
        continue
      var showDamage = !damage_part_alive[i]
      if showDamage && turretControlGunDmParts |> find_index(i) >= 0
        showDamage = false
      show_dmg(showDamage, collNodeId, visual_dmg_remap__collNodeIdToNodeIdMain,
               visual_dmg_remap__collNodeIdToNodeIdDmg, dmg_animchar, animchar_render)
      dmg_animchar__renderable ||= showDamage
    sendEvent(eid, NodesVisibilityWasUpdated())

[es(REQUIRE_NOT=(disableUpdate, damage_part_alive, animchar__actOnDemand))]
def visual_damage_es_event_handler(evt : EventOnCollisionHit;
                                   eid : EntityId;
                                   visual_dmg_remap__collNodeIdToNodeIdMain, visual_dmg_remap__collNodeIdToNodeIdDmg : IntList;
                                   damage_model : DamageModel;
                                   var animchar_render : AnimcharRendComponent&;
                                   var dmg_animchar : DmgAnimChar&;
                                   var dmg_animchar__renderable : bool&)
  let collNodeId = evt.collNodeId
  let partId = get_part_id_by_coll_node_id(damage_model.dmData, int(collNodeId))
  if partId < 0 && show_dmg(true, collNodeId, visual_dmg_remap__collNodeIdToNodeIdMain,
                            visual_dmg_remap__collNodeIdToNodeIdDmg, dmg_animchar, animchar_render)
    dmg_animchar__renderable = true
    sendEvent(eid, NodesVisibilityWasUpdated())

[es(REQUIRE_NOT=(disableUpdate, damage_part_alive, animchar__actOnDemand))]
def visual_damage_part_damaged(evt : EventOnPartDamaged;
                               eid : EntityId;
                               visual_dmg_remap__collNodeIdToNodeIdMain, visual_dmg_remap__collNodeIdToNodeIdDmg : IntList;
                               damage_model : DamageModel;
                               var animchar_render : AnimcharRendComponent&;
                               var dmg_animchar : DmgAnimChar&;
                               var dmg_animchar__renderable : bool&)
  let hpFixed = evt.hpFixed
  let collNodeId = damage_model.dmData |> get_collision_node_id(evt.partId)
  if int(hpFixed) == 0 && show_dmg(true, collNodeId, visual_dmg_remap__collNodeIdToNodeIdMain,
                                   visual_dmg_remap__collNodeIdToNodeIdDmg, dmg_animchar, animchar_render)
    dmg_animchar__renderable = true
    sendEvent(eid, NodesVisibilityWasUpdated())

[es(REQUIRE_NOT=(disableUpdate, damage_part_alive, animchar__actOnDemand))]
def visual_damage_on_volumetric_damage(evt : EventOnVolumetricDamage;
                                       eid : EntityId;
                                       visual_dmg_remap__collNodeIdToNodeIdMain, visual_dmg_remap__collNodeIdToNodeIdDmg : IntList;
                                       damage_model : DamageModel;
                                       var animchar_render : AnimcharRendComponent&;
                                       var dmg_animchar : DmgAnimChar&;
                                       var dmg_animchar__renderable : bool&)
  for partIt in evt.damagedParts
    let part = get_ecs_object(partIt)
    let partId = get_int(part, "partId") ?? -1
    let hpFixed = get_int(part, "hpFixed") ?? 0
    let collNodeId = damage_model.dmData |> get_collision_node_id(partId)
    if hpFixed == 0 && show_dmg(true, collNodeId, visual_dmg_remap__collNodeIdToNodeIdMain,
                                 visual_dmg_remap__collNodeIdToNodeIdDmg, dmg_animchar, animchar_render)
      dmg_animchar__renderable = true
      sendEvent(eid, NodesVisibilityWasUpdated())
