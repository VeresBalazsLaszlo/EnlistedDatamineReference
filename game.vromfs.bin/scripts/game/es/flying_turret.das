require ecs
require ecs.common
require ecs.extra_set
require ecs.safe
require AnimV20
require GeomNodeTree
require DagorMath
require DagorSystem
require DngPhysObj
require PhysObj
require CollRes
require dm
require strings
require vehicle
require turrets
require PhysVars
require AnimatedPhys
require DagorRandom
require math.base
require math.ang
require enlisted.events_enlisted
require DngDm
require game.es.vehicle.vehicle_events
require game.es.flying_turret_common
require common_shooter.es.vehicle.vehicle_explosion_common
require common_shooter.es.vehicle.vehicle_fx_common


def calc_ammo_fraction(tankEid : EntityId) : float
  var totalCurrent = 0
  var totalMax = 0
  query(tankEid) <| $ [es] (ammo_stowage__stowages : EidList)
    for stowageEid in ammo_stowage__stowages
      query(stowageEid) <| $ [es] (ammo_stowage__numAmmo : int; ammo_stowage__clusters : EidList)
        totalCurrent += ammo_stowage__numAmmo
        for clusterEid in ammo_stowage__clusters
          query(clusterEid) <| $ [es(REQUIRE=ammo_cluster__isShell)] (ammo_cluster__slotsMaxAmmo : IntList)
            for slotMax in ammo_cluster__slotsMaxAmmo
              totalMax += slotMax
  if totalMax <= 0
    return 0.0
  return clamp(float(totalCurrent) / float(totalMax), 0.0, 1.0)


[es(tag=server, track=isExploded, after=vehicle_velocity_bump_on_explosion)]
def maybe_detach_turret_on_explode_es(evt : Event;
                                      eid : EntityId;
                                      isExploded : bool;
                                      fire_damage__isFatal : bool;
                                      losable_turret__detachChance : float;
                                      losable_turret__detachBone : string;
                                      losable_turret__ammoDetachThreshold : float;
                                      losable_turret__lostBone : string;
                                      losable_turret__suppressDetach : bool)
  if (!isExploded || fire_damage__isFatal || losable_turret__suppressDetach ||
      !empty(losable_turret__lostBone) || empty(losable_turret__detachBone))
    return
  if gfrnd() >= losable_turret__detachChance
    return
  let ammoFraction = calc_ammo_fraction(eid)
  if ammoFraction < losable_turret__ammoDetachThreshold
    return
  do_detach_turret_server(eid, losable_turret__detachBone, ammoFraction)


[es(track=losable_turret__lostBone, on_appear, after=visual_damage_immediate_es)]
def on_lost_turret_bone_changed_es(evt : Event;
                                   eid : EntityId;
                                   losable_turret__lostBone : string;
                                   animchar : AnimcharBaseComponent;
                                   collres : CollisionResource;
                                   var vehicle_net_phys : VehiclePhysActor&)
  if losable_turret__lostBone == ""
    return
  let rootBoneIdx = *animchar.nodeTree |> geomtree_findNodeIndex(losable_turret__lostBone)
  if rootBoneIdx < 0
    logerr("[lost_turret_bone] bone not found on entity {eid}: '{losable_turret__lostBone}'")
    return
  var subtree : array<int>
  gather_bone_subtree(animchar.nodeTree, rootBoneIdx, subtree)

  // (1) Physics + collres flags - runs on every machine.
  var turretCollNodeIds : array<int>
  let n = collres_get_nodesCount(collres)
  for i in range(n)
    let node = collres_get_node(collres, i)
    if node != null && find_index(subtree, int((*node).geomNodeId)) >= 0
      turretCollNodeIds |> push(i)
      vehicle_net_phys.phys |> vehicle_phys_setCollisionObjectActive(i, false)
  if length(turretCollNodeIds) > 0
    clone_collres(eid)
    using() <| $(var rules : Array)
      push_to_array(rules) <| $(var rule : Object)
        rule |> set("nodeIds", turretCollNodeIds)
        rule |> set("behaviorFlags", 0)
      apply_collres_node_flag_rules(eid, rules)

  // (2) Render-only via nested query (animchar_render / dmg_animchar are render-tagged).
  query(eid) <| $ [es] (var animchar_render : AnimcharRendComponent;
                        var dmg_animchar : DmgAnimChar&;
                        turret_control__gunEids : EidList const?)
    let sceneInstance = animchar_render.sceneInstance
    let dmgSceneInstance = dmg_animchar.sceneInstance
    for boneIdx in subtree
      let boneName = string(*animchar.nodeTree |> geomtree_getNodeName(boneIdx))
      let mainNodeId = *sceneInstance |> scene_instance_getNodeId(boneName)
      if mainNodeId >= 0
        sceneInstance |> scene_instance_show_node(mainNodeId, false)
      let dmgNodeId = *dmgSceneInstance |> scene_instance_getNodeId("{boneName}_dmg")
      if dmgNodeId >= 0
        dmgSceneInstance |> scene_instance_show_node(dmgNodeId, false)
    sendEvent(eid, NodesVisibilityWasUpdated())
    if turret_control__gunEids != null
      for gunEid in *turret_control__gunEids
        query(gunEid) <| $ [es] (var turret__isVisualBroken : bool&)
          turret__isVisualBroken = true


// On appear: phys override + bone pinning + visual setup, in one ES.
//   - `after=update_animchar_on_create_es`: the `animchar__actOnCreate` tag fires an
//     `act(dt=0, calc_anim=true)` on appear that rebuilds bones from origTree; we must run
//     after it so our pinned-bone writes survive.
//   - `before=disable_animchar_nodes_es`: that ES refines our blanket hide using `disableDMParts`.
//   - `animchar__updatable=false` excludes us from the engine's main per-frame animchar update;
//     `flying_turret_static_act_es` below drives the animchar ourselves.
[es(on_appear, after=update_animchar_on_create_es, before=disable_animchar_nodes_es, REQUIRE=flyingTurret)]
def flying_turret_setup_es(evt : Event;
                           eid : EntityId;
                           flying_turret__comOffset : float3;
                           flying_turret__mass : float;
                           flying_turret__pinnedBoneTms : Object;
                           flying_turret__bone : string;
                           flying_turret__aliveBarrelBones : StringList;
                           var phys_obj_net_phys : PhysObjActor&;
                           var animchar : AnimcharBaseComponent;
                           var animchar__updatable : bool&)
  phys_obj_net_phys.phys.centerOfMass = flying_turret__comOffset
  phys_obj_net_phys.phys.mass = flying_turret__mass
  for it in flying_turret__pinnedBoneTms
    let boneName = string(it.key)
    let tm = get_TMatrix(it.value) ?? IDENT_TM
    let boneIdx = *animchar.nodeTree |> geomtree_findNodeIndex(boneName)
    if boneIdx >= 0
      *animchar.nodeTree |> geomtree_setNodeTmScalar(boneIdx, tm)
  animchar__updatable = false
  // Visual setup - nested query matches only on render-capable machines where
  // animchar_render / dmg_animchar / the remap lists exist. Captures `animchar`,
  // `flying_turret__bone`, `flying_turret__aliveBarrelBones`, `eid` from outer scope.
  query(eid) <| $ [es] (var animchar_render : AnimcharRendComponent;
                        var dmg_animchar : DmgAnimChar&;
                        var dmg_animchar__renderable : bool&;
                        var geomNodeIdRemapMain : IntList&;
                        var geomNodeIdRemapDmg : IntList&;
                        var geomNodeIdRemapDstr : IntList&)
    let mainSi = animchar_render.sceneInstance
    let dmgSi = dmg_animchar.sceneInstance
    // Blanket-hide both scenes, then re-show subtree below.
    for nodeIdx in range((*mainSi).nodeCount)
      mainSi |> scene_instance_show_node(nodeIdx, false)
    for nodeIdx in range((*dmgSi).nodeCount)
      dmgSi |> scene_instance_show_node(nodeIdx, false)
    // dmg_animchar bone-id remaps - mirror visualDamageES.cpp.inl's visual_damage_remap_init_es
    // but without `damage_model` (we don't have one). Consumed by dmg_animchar_before_render_es.
    let mainBoneCount = int((*animchar.nodeTree).nodeCount)
    resize(geomNodeIdRemapMain, mainBoneCount)
    resize(geomNodeIdRemapDmg, mainBoneCount)
    resize(geomNodeIdRemapDstr, mainBoneCount)
    let dmgTree = dmg_animchar.base.nodeTree
    for i in range(mainBoneCount)
      let mainBoneName = string(*animchar.nodeTree |> geomtree_getNodeName(i))
      geomNodeIdRemapMain[i] = int(*dmgTree |> geomtree_findNodeIndex(mainBoneName))
      geomNodeIdRemapDmg[i] = int(*dmgTree |> geomtree_findNodeIndex("{mainBoneName}_dmg"))
      geomNodeIdRemapDstr[i] = int(*dmgTree |> geomtree_findNodeIndex("{mainBoneName}_dstr"))
    // Walk turret subtree, selectively re-show. Per-bone rules:
    //   aliveBarrelBones -> main; <bone>_dmg present -> dmg; <bone>_dstr present -> hide all
    //   (chunk flew off as wreckage on source); otherwise -> main.
    let rootBoneIdx = *animchar.nodeTree |> geomtree_findNodeIndex(flying_turret__bone)
    if rootBoneIdx < 0
      logerr("[flying_turret_setup] bone not found: '{flying_turret__bone}'")
      return
    var subtree : array<int>
    gather_bone_subtree(animchar.nodeTree, rootBoneIdx, subtree)
    for boneIdx in subtree
      let boneName = string(*animchar.nodeTree |> geomtree_getNodeName(boneIdx))
      let mainNodeId = *mainSi |> scene_instance_getNodeId(boneName)
      let dmgNodeId = *dmgSi |> scene_instance_getNodeId("{boneName}_dmg")
      let dstrNodeId = *dmgSi |> scene_instance_getNodeId("{boneName}_dstr")
      let isAliveBarrel = find_index(flying_turret__aliveBarrelBones, boneName) >= 0
      if isAliveBarrel
        if mainNodeId >= 0
          mainSi |> scene_instance_show_node(mainNodeId, true)
        if dmgNodeId >= 0
          dmgSi |> scene_instance_show_node(dmgNodeId, false)
        continue
      if dmgNodeId >= 0
        if mainNodeId >= 0
          mainSi |> scene_instance_show_node(mainNodeId, false)
        dmgSi |> scene_instance_show_node(dmgNodeId, true)
        dmg_animchar__renderable = true
      elif dstrNodeId >= 0
        if mainNodeId >= 0
          mainSi |> scene_instance_show_node(mainNodeId, false)
      else
        if mainNodeId >= 0
          mainSi |> scene_instance_show_node(mainNodeId, true)
    sendEvent(eid, NodesVisibilityWasUpdated())


// Per-frame static-pose act. `animchar_act(..., calc_anim=false)` short-circuits the blend
// tree (no bone clobber) and rebuilds WTMs from the pinned pose held in geomtree. WTMs follow
// the PhysObj as it tumbles via the `animchar_set_tm` -> `transform` sync.
[es(after=animchar_es, REQUIRE=flyingTurret)]
def flying_turret_static_act_es(info : ParallelUpdateFrameDelayed;
                                transform : float3x4;
                                var animchar : AnimcharBaseComponent;
                                var animchar_node_wtm : AnimcharNodesMat44;
                                var animchar_render__root_pos : vec4f&)
  animchar_set_tm(animchar, transform, false)
  animchar_act(animchar, info.dt, false)
  animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)
