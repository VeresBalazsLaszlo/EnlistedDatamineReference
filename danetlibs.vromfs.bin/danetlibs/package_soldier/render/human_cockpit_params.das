require ecs
require DagorMath
require Dacoll
require DagorShaders
require DngHuman
require math.base
require DngCamera
require player
require gameLibs.render_events.render_events
require gameLibs.pufd_events.pufd_events
require AnimV20
require CollRes


[cpp_event(unicast)]
struct QueryHeroWtmAndBoxForRender
  resWtm : float3x4
  resWofs : float3
  resLboxMin, resLboxMax : float3
  resReady : bool
  resFlags : uint8
  onlyWeapons : bool

[es(tag=render)]
def reset_hero_cockpit_params(event : ParallelUpdateFrameDelayed;
                              var hero_cockpit_vec_value : float4&;
                              var hero_cockpit_camera_to_point_value : float4&;
                              var hero_cockpit_bbox_min_value : float4&;
                              var hero_cockpit_bbox_max_value : float4&;
                              var hero_cockpit_camera_enabled_value : int&;
                              var hero_cockpit_camera_fade_value : int&)
  hero_cockpit_vec_value = float4(0, 0, 0, 0)
  hero_cockpit_camera_to_point_value = float4(0, 0, 0, 0) // For completeness.
  hero_cockpit_bbox_min_value = float4(0, 0, 0, 0)
  hero_cockpit_bbox_max_value = float4(0, 0, 0, 0)
  hero_cockpit_camera_enabled_value = 0
  hero_cockpit_camera_fade_value = 0

[es(tag=render, after=reset_hero_cockpit_params)]
def update_and_provide_human_cockpit(event : ParallelUpdateFrameDelayed;
                                     human_cockpit__gunMaxLength, human_cockpit__traceMaxBias,
                                     human_cockpit__startFadeBeforeIntersection, human_cockpit__fadeInterval,
                                     human_cockpit__sampleOffsetAboveCamera, human_cockpit__sampleBias : float)
  let heroEid = get_Eid(get_local_player_eid(), "possessed") ?? INVALID_ENTITY_ID
  if !heroEid || getEntityTemplateId(heroEid) == INVALID_TEMPLATE_INDEX
    return

  var heroCockpitEnabled = false
  find_query() <| $ [es] (isHeroCockpitCam : bool; camera__active : bool)
    if !camera__active
      return false
    heroCockpitEnabled = isHeroCockpitCam
    return true

  if !heroCockpitEnabled
    return

  var shootTm : float3x4

  var gun_data : QueryHeroWtmAndBoxForRender
  gun_data.resReady = false
  gun_data.onlyWeapons = true
  sendEventImmediate(heroEid, gun_data)
  if !gun_data.resReady
    return

  var humanTraceHandle : TraceMeshFaces?
  var isAiming, inVehicle : bool
  var gunEid = INVALID_ENTITY_ID
  var heroBbox = BBox3()
  query(heroEid) <| $ [es] (var human_net_phys : HumanActor;
                            human_net_phys__isAiming : bool;
                            human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                            human_weap__currentGunEid : EntityId = INVALID_ENTITY_ID;
                            isInVehicle : bool;
                            transform : float3x4;
                            animchar : AnimcharBaseComponent const?;
                            collres : CollisionResource)
    humanTraceHandle = human_net_phys.phys |> human_phys_getTraceHandle()
    isAiming = human_net_phys__isAiming
    inVehicle = isInVehicle
    gunEid = !!human_attached_gun__attachedGunEid ? human_attached_gun__attachedGunEid : human_weap__currentGunEid
    if inVehicle
      return

    let nodesCount = collres |> collres_get_nodesCount()
    let nodeTree = animchar != null ? animchar.nodeTree : null
    for i in range(nodesCount)
      let node = collres |> collres_get_node(i)
      var nodeTm : float3x4
      collres |> collres_get_collision_node_tm(int(node.nodeIndex), transform, nodeTree, nodeTm)
      heroBbox |> bbox3_add(nodeTm * collres_get_node_bbox(collres, i))

  if inVehicle
    return

  shootTm[0] = -gun_data.resWtm[2]
  shootTm[1] = gun_data.resWtm[1]
  shootTm[2] = gun_data.resWtm[0]
  shootTm[3] = gun_data.resWtm[3] + gun_data.resWofs

  let weaponDir = cross(-shootTm[0], shootTm[2])
  let cameraTm = get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM
  let startBias = clamp(dot(shootTm[3] - cameraTm[3], weaponDir),
                        -human_cockpit__traceMaxBias, human_cockpit__traceMaxBias)
  let tracePos = shootTm[3] - startBias * weaponDir
  var t : float = startBias + human_cockpit__gunMaxLength
  var norm = float3()
  var pmid : int
  var riDesc = RendInstDesc()

  var startFadeDistance = 1000.0
  var applyFade = false
  let traceDir = normalize(weaponDir)
  if traceray_normalized(tracePos, traceDir, t, pmid, norm, ETF_DEFAULT | ETF_RI_TREES, riDesc, -1, humanTraceHandle)
    applyFade = true
    startFadeDistance = t - human_cockpit__startFadeBeforeIntersection
    let gunBbox = shootTm * BBox3(gun_data.resLboxMin, gun_data.resLboxMax)
    heroBbox |> bbox3_add(gunBbox)

  if isAiming
    query(gunEid) <| $ [es] (gun__distanceToDisableAOinAiming : float)
      if gun__distanceToDisableAOinAiming > 0.0
        applyFade = true
        startFadeDistance = min(startFadeDistance, gun__distanceToDisableAOinAiming + startBias)

  query() <| $ [es] (var hero_cockpit_vec_value : float4&;
                     var hero_cockpit_camera_to_point_value : float4&;
                     var hero_cockpit_bbox_min_value : float4&;
                     var hero_cockpit_bbox_max_value : float4&;
                     var hero_cockpit_camera_enabled_value : int&;
                     var hero_cockpit_camera_fade_value : int&)
    hero_cockpit_bbox_min_value = float4(heroBbox.boxMin, 0.0)
    hero_cockpit_bbox_max_value = float4(heroBbox.boxMax, 0.0)
    hero_cockpit_camera_enabled_value = 1

    if applyFade
      hero_cockpit_camera_fade_value = 1

      let startFadePos = tracePos + startFadeDistance * weaponDir
      let normalizedDir = weaponDir / human_cockpit__fadeInterval
      hero_cockpit_vec_value = float4(normalizedDir, -dot(normalizedDir, startFadePos) + 1.0)

      let back = shootTm * float3(0, 0, -1)
      let front = shootTm * float3(0, 0, 1)
      let sampleDir = -normalize(front - back).zx * human_cockpit__sampleBias
      let cameraTracePos = float4(sampleDir.x, human_cockpit__sampleOffsetAboveCamera, sampleDir.y, 0.0)
      hero_cockpit_camera_to_point_value = cameraTracePos
