require ecs
require ecs.safe
require ecs.extra_set
require ecs.common
require ecs.soa_template
require math.base
require strings
require fx
require AnimV20
require GeomNodeTree
require DaWeapons
require DagorSystem
require danetlibs.weaponry_hit_fx.main.physmat_fx_common
require PhysMat
require Dacoll
require RendInst
require DngCamera
require DagorMath
require danetlibs.weaponry_hit_fx.render.ground_wave_common


[soa_template]
struct TurretGunFx
  turret_gun_fx__fxTemplate : string
  turret_gun_fx__nodeId : int


def get_mult_tm(scale : float)
  var multTm = IDENT_TM
  multTm[0] = float3(0.0, scale,  0.0)
  multTm[1] = float3(scale, 0.0,  0.0)
  multTm[2] = float3(0.0, 0.0, -scale)
  return multTm


[es(tag=render, on_appear)]
def turret_ground_wave_fx_init_es(evt : Event;
                                  global_ground_wave_fx__maxImpulses : FloatList;
                                  var global_ground_wave_fx__effectGroups : Array&)
  if length(global_ground_wave_fx__maxImpulses) != length(global_ground_wave_fx__effectGroups)
    logerr("turret_ground_wave_fx_init_es: lengths of global_ground_wave_fx__maxImpulses and global_ground_wave_fx__effectGroups are not equal")

  for elem in global_ground_wave_fx__effectGroups
    var effectGroup = elem as Object
    if effectGroup == null
      logerr("turret_ground_wave_fx_init_es: all elements in global_ground_wave_fx__effectGroups should be 'object'")
      continue
    let infoForMats = effectGroup?.info ?as Object
    if infoForMats == null
      continue

    let defaultFx = effectGroup?.defaultFx ?? ""
    if empty(defaultFx)
      continue

    var fxs : array<string>
    resize(fxs, physMatCount())

    for_each_physmat_data(*infoForMats, /*group_prefix*/"group__") <| $(pmid : int; data : ChildComponent)
      let fxName = data as string
      if fxName == null
        logerr("turret_ground_wave_fx_init_es: all elements in 'info' in global_ground_wave_fx__effectGroups should be 't'")
        return
      elif empty(*fxName)
        fxs[pmid] = "-"
      else
        fxs[pmid] := *fxName

    *effectGroup |> set("fxs", fxs)


[es(tag=render, on_appear, track=turret__resolved)]
def turret_dust_fx_init_es(evt : Event;
                           turret_dust_fx__nodes : StringList;
                           turret__owner : EntityId;
                           turret__resolved : bool;
                           var turret_dust_fx__nodeIds : IntList&)
  if !turret__resolved
    return
  query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
    for node in turret_dust_fx__nodes
      let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, string(node))
      if nodeId >= 0
        turret_dust_fx__nodeIds |> push(nodeId)


def spawn_dust_fx(fx_name : string; animchar : AnimcharBaseComponent; node_ids : IntList)
  let fxTemplate = getTemplateByName(fx_name)
  if fxTemplate == null
    return

  let lowestFxQuality = getTemplateComponent(*fxTemplate, "effect__lowestFxQuality") ?? 0
  if int(get_fx_target()) < (1 << lowestFxQuality)
    return

  for nodeId in node_ids
    var dustTm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, nodeId, dustTm)

    createEntity(fx_name) <| $(var init : ComponentsInitializer)
      set(init, "transform", dustTm)


def is_hero_in_hatch()
  var res = false
  find_query() <| $ [es(REQUIRE=hero)] (human_vehicle__isInHatch : bool)
    res = human_vehicle__isInHatch
    return true
  return res


[soa_es, es(tag=render, on_event=ParallelUpdateFrameDelayed, before=clear_gun_launch_events_es, after=after_guns_update_sync)]
def turret_gun_fx_inserter_es(info : Event;
                              eid : EntityId;
                              animchar : AnimcharBaseComponent;
                              turretGunFx : TurretGunFx_SOA;
                              turret_control__gunEids : EidList;
                              transform : float3x4;
                              @shared_comp turret_gun_flash_fx__flashFxScale : Array;
                              turret_gun_fx__thresholdDistSq : float = 10000.0;
                              heroVehicle : Tag const?)
  let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
  let tooFar = camTm == null ? false : distance_sq(transform[3], (*camTm)[3]) > turret_gun_fx__thresholdDistSq

  for gunEid, gunFx, fxScale in turret_control__gunEids, turretGunFx, turret_gun_flash_fx__flashFxScale
    if gunFx.turret_gun_fx__nodeId < 0 || empty(gunFx.turret_gun_fx__fxTemplate)
      continue

    query(gunEid) <| $ [es] (gun_launch_events : GunLaunchEvents;
                             gun__curShellImpulse : float;
                             turret_dust_fx__minImpulse : float;
                             turret_dust_fx__fxTemplate : string;
                             turret_dust_fx__nodeIds : IntList)
      for _launchEvent in gun_launch_events.launchEvents
        var tm : float3x4
        geomtree_getNodeWtmScalar(*animchar.nodeTree, gunFx.turret_gun_fx__nodeId, tm)
        let forwardDir = tm[0]
        tm = tm * get_mult_tm(fxScale ?? 1.0)

        createEntity(add_sub_template_name(string(gunFx.turret_gun_fx__fxTemplate),
            "autodelete_effect_entity")) <| $(var init : ComponentsInitializer)
          set(init, "transform", tm)
          set(init, "gun_fx__ownerEid", eid)
          set(init, "gun_fx__nodeId", gunFx.turret_gun_fx__nodeId)
        let isHeroVehicle = heroVehicle != null
        if !tooFar && (!isHeroVehicle || is_hero_in_hatch())
          //We use tank's orientation to roughly determine the inclination of the ground under the turret.
          //This ignores any small unevenness of the ground, which is what we want
          //For performance reasons, let's not spawn leaves effects (unless leavesAlwaysSpawn == true)
          spawn_ground_wave_fx(gun__curShellImpulse, transform[1], forwardDir, tm[3], /*spawn_leaves*/false)
          if gun__curShellImpulse > turret_dust_fx__minImpulse
            spawn_dust_fx(turret_dust_fx__fxTemplate, animchar, turret_dust_fx__nodeIds)


[soa_es, es(tag=render, on_appear)]
def turret_gun_flash_fx_created_es(evt : Event;
                                   eid : EntityId;
                                   animchar : AnimcharBaseComponent;
                                   @shared_comp turret_gun_flash_fx__flashFx : Array;
                                   @shared_comp turret_gun_flash_fx__flashNodes : Array;
                                   @shared_comp turret_gun_flash_fx__flashFxScale : Array;
                                   var turretGunFx : TurretGunFx_SOA)
  if length(turret_gun_flash_fx__flashNodes) != length(turret_gun_flash_fx__flashFx) || length(turret_gun_flash_fx__flashFx) != length(turret_gun_flash_fx__flashFxScale)
    logerr("Lengths of turret_gun_flash_fx__flashNodes, turret_gun_flash_fx__flashFx and turret_gun_flash_fx__flashFxScale are not match to each other")
    return

  for flashFx, flashNode in turret_gun_flash_fx__flashFx, turret_gun_flash_fx__flashNodes
    let fx = flashFx ?? ""
    let node = flashNode ?? ""
    if empty(fx) || empty(node)
      push(turretGunFx, TurretGunFx(
        turret_gun_fx__fxTemplate = "",
        turret_gun_fx__nodeId = -1
      ))
      continue

    let fxNodeId = geomtree_findNodeIndex(*animchar.nodeTree, node)
    if fxNodeId < 0
      logerr("turret gun flash fx node <{node}> is not found in animchar <{eid}>")

    push(turretGunFx, TurretGunFx(
      turret_gun_fx__fxTemplate = fx,
      turret_gun_fx__nodeId = fxNodeId
    ))

[soa_def]
def get_tree_inside_radius(pos : float3; radius : float; var vegetationInfo : VegetationInfo_SOA) : int
  let box = BBox3(pos - float3(radius), pos + float3(radius))

  rendinst_foreachTreeInBox(box) <| $(coll_info : CollisionInfo)
    let height = coll_info.localBBox.width.y * coll_info.tm[1].y
    let riDesc = coll_info.desc
    let fxName = getRIGenDestrFxTemplateName(riDesc)
    if !empty(fxName)
      push(vegetationInfo, VegetationInfo(
        vegetation_info__posHeight = float4(coll_info.tm[3], height),
        vegetation_info__fxName = fxName,
        vegetation_info__rendinstPool = riDesc.pool
      ))


  return length(vegetationInfo)

def spawn_effect_aux(pos : float3; fx_name : string; rendinst_pool : int)
  var tm = IDENT_TM
  tm[3] = pos
  createEntity(fx_name) <| $(init)
    init |> set("transform", tm)
    init |> set("effect__riPoolUsedForColoring", rendinst_pool)

[soa_es, es(tag=render, on_appear, REQUIRE=effect__environmentDestruction)]
def spawn_enviroment_fx_from_expl_es(evt : Event;
                                     transform : float3x4;
                                     effect__environmentDestructionRadius : float;
                                     var vegetationInfo : VegetationInfo_SOA)
  if int(get_fx_target()) <= int(FxQuality.FX_QUALITY_LOW)
    return

  let tree_count = get_tree_inside_radius(transform[3], effect__environmentDestructionRadius, vegetationInfo)
  if tree_count == 0
    return
  for info in vegetationInfo
    let pos = info.vegetation_info__posHeight
    let resultPos = float3(pos.x, pos.y, pos.z)
    let rendinstPool = info.vegetation_info__rendinstPool
    let fxName = string(info.vegetation_info__fxName)
    spawn_effect_aux(resultPos, fxName, rendinstPool)
