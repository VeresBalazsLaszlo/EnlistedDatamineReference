require ecs
require ecs.safe
require common_shooter.events_common_shooter
require DagorMath
require GeomNodeTree
require math.base
require Dacoll
require danetlibs.weaponry_hit_fx.main.physmat_fx_common
require DagorSystem
require PhysMat
require AnimV20
require HumanPhys
require DngHuman

[es(on_appear, tag=render)]
def gun_init_environment_effect_node_es(evt : Event;
                                        animchar : AnimcharBaseComponent;
                                        gun__environmentEffectNode : string;
                                        var gun__environmentEffectNodeId : int&)
  gun__environmentEffectNodeId = geomtree_findNodeIndex(*animchar.nodeTree, gun__environmentEffectNode)

[es(on_appear, tag=render)]
def gun_init_environment_effect_mat_es(evt : Event;
                                       gun__environmentEffectMat : string;
                                       var gun__environmentEffectMatId : int&)
  gun__environmentEffectMatId = get_material_id(gun__environmentEffectMat)

[es(on_appear, tag=render)]
def gun_fx_init_mat_ids(evt : Event;
                        gun_environment_fx__materials : Object;
                        var gun_environment_fx__matTemplates : StringList&)
  resize(gun_environment_fx__matTemplates, physMatCount())
  for_each_physmat_data(gun_environment_fx__materials, /*group_prefix*/"group__") <| $(pmid : int; data : ChildComponent)
    let fxName = data as string
    if fxName == null
      logerr("all elements in gun_enviroment_fx__materials should be 't'")
      return
    gun_environment_fx__matTemplates[pmid] := *fxName

[es(REQUIRE=watchedByPlr, no_order, tag=render)]
def draw_effect_trace(evt : CmdLaunchProjectile; human__aimTm : float3x4; var human_net_phys : HumanActor&)
  assume phys = human_net_phys.phys
  let gunEid = evt.gunEid
  query(gunEid) <| $ [es] (gun__environmentEffectRadius : float;
                           gun__environmentEffectLimit : int;
                           gun__environmentEffectMatId : int;
                           gun__environmentEffectNodeId : int;
                           animchar : AnimcharBaseComponent)
    assume radius = gun__environmentEffectRadius
    assume limit = gun__environmentEffectLimit

    let fPos = gun__environmentEffectNodeId >= 0 ? geomtree_getNodeWpos(*animchar.nodeTree, gun__environmentEffectNodeId) : human__aimTm[3]
    let dpos = DPoint3(fPos)
    let mask = int(PhysLayer.EPL_ALL) & ~int(PhysLayer.EPL_CHARACTER)
    test_sphere_collision_world(dpos, radius, gun__environmentEffectMatId, PhysLayer.EPL_DEFAULT, mask) <| $(contacts : array<CollisionContactData>#)
      find_query() <| $ [es] (gun_environment_fx__matTemplates : StringList&; gun_environment__defaultFxTemplate : string)
        for contact, _alreadyCreated in contacts, range(limit)
          var tm = IDENT_TM
          let eps = 0.0001
          let subVec = length_sq(contact.wnormB - tm[1]) > eps ? float3(0., 1., 0.) : float3(0., 0., 1.)
          tm[1]  = contact.wnormB
          tm[2] = normalize(cross(tm[1], subVec))
          tm[0] = normalize(cross(tm[2], tm[1]))
          tm[3] = contact.wposB

          let dir = contact.wposB - fPos
          let ndir = normalize(dir)
          var dist = length(dir) + eps
          var norm : float3
          var riDesc = RendInstDesc()
          var pmid = -1
          let rayMatId = -1
          let traceHandle = human_phys_getTraceHandle(phys)
          traceray_normalized(fPos, ndir, dist, pmid, norm, ETF_DEFAULT, riDesc, rayMatId, traceHandle)

          var matFxName = pmid >= 0 ? string(gun_environment_fx__matTemplates[pmid]) : gun_environment__defaultFxTemplate
          if matFxName == ""
            matFxName = gun_environment__defaultFxTemplate
          let needPaintFromBiome = getTemplateComponent(*getTemplateByName(matFxName), "paint_from_biome") ?? false

          if (needPaintFromBiome)
            createEntity("biome_fx_readback_info") <| $(init)
              init |> set("transform", tm)
              init |> set("fx_name_to_spawn", matFxName)
          else
            createEntity(matFxName) <| $(init)
              init |> set("transform", tm)
        return true
