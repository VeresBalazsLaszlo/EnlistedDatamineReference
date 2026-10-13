require ecs
require ecs.common
require math.base
require DagorMath
require DagorRandom
require game.es.events
require dm
require DngDm
require AnimV20
require CollRes
require DngPlane
require Plane
require strings
require DagorSystem
require GeomNodeTree
require DagorDataBlock
require daslib/enum_trait
require game.es.aircraft.plane_cutting_common


let WRECKAGE_NODE_NAMES = fixed_array(
  "wing_l",
  "wing_r",
  "tail",
  "tail",
  "tail",
  "tail"
)

let WRECKAGE_TYPE_NAMES = fixed_array(
  "wing_l",
  "wing_r",
  "tail",
  "stab_l",
  "stab_r",
  "fin"
)

struct WreckageTypeProperties {
  mass0 : float;
  massMin : float;
  volumeDensity : float;
  areaDensity : float;
  massCenter : float3;
  attachPoint : float3;
  armAxis : int;
  armAxisMinVal : float;
  impulseCoeffsFrom : float3;
  impulseCoeffsTo : float3;
};

let WRECKAGE_TYPE_PROPERTIES = fixed_array(
  WreckageTypeProperties(
    mass0 = 50.0,
    massMin = 0.0,
    volumeDensity = 0.0,
    areaDensity = 1.0 / 2.0,
    massCenter  = float3(0.5, 0.5, 0.625),
    attachPoint = float3(0.25, 0.0, 0.0),
    armAxis  = 2,
    armAxisMinVal = 0.0,
    impulseCoeffsFrom = float3(-0.02, 0.05, 0.0),
    impulseCoeffsTo = float3(-0.1, 0.25, 0.05)
  ),
  WreckageTypeProperties(
    mass0  = 50.0,
    massMin = 0.0,
    volumeDensity = 0.0,
    areaDensity = 1.0 / 2.0,
    massCenter  = float3(0.5, 0.5, 0.375),
    attachPoint = float3(0.25, 0.0, 1.0),
    armAxis  = 2,
    armAxisMinVal = 0.0,
    impulseCoeffsFrom = float3(-0.02, 0.05, 0.0),
    impulseCoeffsTo = float3(-0.1, 0.25, -0.05)
  ),
  WreckageTypeProperties(
    mass0  = 200.0,
    massMin = 0.0,
    volumeDensity = 0.0,
    areaDensity = 2.0 / 2.0,
    massCenter  = float3(0.25, 0.5, 0.5),
    attachPoint = float3(1.00, 0.5, 0.5),
    armAxis  = 0,
    armAxisMinVal = 0.0,
    impulseCoeffsFrom = float3(-0.03, -0.05, -0.05),
    impulseCoeffsTo = float3(-0.15, 0.05, 0.05)
  ),
  WreckageTypeProperties(
    mass0  = 20.0,
    massMin = 0.0,
    volumeDensity = 0.0,
    areaDensity = 1.0 / 2.0,
    massCenter  = float3(0.5, 0.5, 0.75),
    attachPoint = float3(0.5, 0.0, 1.0),
    armAxis  = 2,
    armAxisMinVal = 1.5,
    impulseCoeffsFrom = float3(-0.01, -0.015, 0.0),
    impulseCoeffsTo = float3(-0.045, 0.015, 0.01)
  ),
  WreckageTypeProperties(
    mass0  = 20.0,
    massMin = 0.0,
    volumeDensity = 0.0,
    areaDensity = 1.0 / 2.0,
    massCenter  = float3(0.5, 0.5, 0.25),
    attachPoint = float3(0.5, 0.0, 1.0),
    armAxis  = 2,
    armAxisMinVal = -1.5,
    impulseCoeffsFrom = float3(-0.01, -0.015, 0.0),
    impulseCoeffsTo = float3(-0.045, 0.015, -0.01)
  ),
  WreckageTypeProperties(
    mass0  = 20.0,
    massMin = 0.0,
    volumeDensity = 0.0,
    areaDensity = 1.0 / 2.0,
    massCenter  = float3(0.5, 0.4, 0.5),
    attachPoint = float3(0.35, 0.0, 0.0),
    armAxis  = 1,
    armAxisMinVal = 1.5,
    impulseCoeffsFrom = float3(-0.015, -0.008, -0.015),
    impulseCoeffsTo = float3(-0.05, 0.008, 0.015)
  )
)

let smallWreckageProperties = WreckageTypeProperties(
  mass0 = 0.0,
  massMin = 10.0,
  volumeDensity  = 16.0,
  areaDensity = 8.0,
  massCenter  = float3(0.5, 0.5, 0.5),
  attachPoint = float3(0.25, 0.0, 0.0),
  armAxis  = -1,
  impulseCoeffsFrom = float3(0.0045, 0.0025, 0.00012),
  impulseCoeffsTo = float3(-0.024, -0.012, -0.006)
)

let WRECKAGE_CUT_PART_NAMES = fixed_array(
  "wing_l_dm",
  "wing1_l_dm",
  "wing2_l_dm",

  "wing_r_dm",
  "wing1_r_dm",
  "wing2_r_dm",

  "tail_dm",
  "fin_dm",
  "stab_dm",
  "stab1_dm",
  "stab2_dm"
)

[es(tag=server)]
def plane_cutting_on_repair(evt : EventOnRepaired;
                            var plane_cutting__leftWingCutState : int&;
                            var plane_cutting__rightWingCutState : int&;
                            var plane_cutting__largePartsCut : BoolList&;
                            var plane_cutting__largePartsCutPartId : IntList&;
                            var plane_cutting__smallPartsCut : BoolList&)
  plane_cutting__leftWingCutState = int(FlightModelCutState.FMCS_NONE)
  plane_cutting__rightWingCutState = int(FlightModelCutState.FMCS_NONE)
  for val in plane_cutting__largePartsCut
    val = false
  for val in plane_cutting__largePartsCutPartId
    val = -1
  for val in plane_cutting__smallPartsCut
    val = false

[es(tag=server, on_appear)]
def plane_cutting_init(evt : Event;
                       damage_model : DamageModel;
                       plane_cutting__cuttingPlanes : Point4List;
                       var plane_cutting__largePartsCut : BoolList&;
                       var plane_cutting__largePartsCutPartId : IntList&;
                       var plane_cutting__cuttingPlanesW : FloatList&;
                       var plane_cutting__smallPartsCut : BoolList&)
  plane_cutting__largePartsCut |> clear()
  plane_cutting__largePartsCutPartId |> clear()
  for _i in each_enum(WreckageType.WRECKAGE_WING_L)
    plane_cutting__largePartsCut |> push(false)
    plane_cutting__largePartsCutPartId |> push(-1)

  plane_cutting__cuttingPlanesW |> resize(length(plane_cutting__cuttingPlanes))
  for w, plane in plane_cutting__cuttingPlanesW, plane_cutting__cuttingPlanes
    w = plane.w

  plane_cutting__smallPartsCut |> resize(get_damage_part_props_count(damage_model.dmData))
  for val in plane_cutting__smallPartsCut
    val = false

[es(tag=server)]
def plane_damage_cutting(evt : EventCutPart;
                         plane_cutting__cutPartsId : IntList;
                         plane_cutting__stabLeftCuttingPos : float2;
                         plane_cutting__stabRightCuttingPos : float2;
                         plane_cutting__finCuttingPos : float2;
                         plane_cutting__tailCuttingPos : float2;
                         plane_cutting__wingLeftCuttingPos : Point2List;
                         plane_cutting__wingRightCuttingPos : Point2List;
                         var plane_cutting__cuttingPlanes : Point4List&;
                         var plane_cutting__leftWingCutState : int&;
                         var plane_cutting__rightWingCutState : int&;
                         var plane_cutting__cutting : bool&;
                         var plane_cutting__largePartsCut : BoolList&;
                         var plane_cutting__largePartsCutPartId : IntList&;
                         var plane_cutting__cuttingPlanesW : FloatList&;
                         var plane_cutting__smallPartsCut : BoolList&)
  let partId = evt.partNo
  let cutPartId = find_index(plane_cutting__cutPartsId, partId)

  var wreckageNo = -1
  if cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING_L) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING1_L) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING2_L)
    let cutState = int(FlightModelCutState.FMCS_ALL_CUT) - cutPartId + int(WreckageCutPartId.WRECK_PART_PART_WING_L)
    if cutState < plane_cutting__leftWingCutState
      return

    wreckageNo = int(WreckageType.WRECKAGE_WING_L)

    plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_WING_L)] = true
    plane_cutting__largePartsCutPartId[int(WreckageType.WRECKAGE_WING_L)] = partId
    plane_cutting__leftWingCutState = cutState

    var cutId = plane_cutting__leftWingCutState - 1
    for i in range(int(FlightModelCutState.FMCS_NONE), cutState)
      assume cuttingPos = plane_cutting__wingLeftCuttingPos[i]
      if (cuttingPos.x > 0.0 && cuttingPos.y > 0.0)
        cutId = i

    assume leftWingCuttingPos = plane_cutting__wingLeftCuttingPos[cutId]
    plane_cutting__cuttingPlanes[wreckageNo].w = lerp(leftWingCuttingPos.x, leftWingCuttingPos.y, 0.5)
  elif cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING_R) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING1_R) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_WING2_R)
    let cutState = int(FlightModelCutState.FMCS_ALL_CUT) - cutPartId + int(WreckageCutPartId.WRECK_PART_PART_WING_R)
    if cutState < plane_cutting__rightWingCutState
      return

    wreckageNo = int(WreckageType.WRECKAGE_WING_R)

    plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_WING_R)] = true
    plane_cutting__largePartsCutPartId[int(WreckageType.WRECKAGE_WING_R)] = partId
    plane_cutting__rightWingCutState = cutState

    var cutId = plane_cutting__rightWingCutState - 1
    for i in range(int(FlightModelCutState.FMCS_NONE), cutState)
      assume cuttingPos = plane_cutting__wingRightCuttingPos[i]
      if (cuttingPos.x > 0.0 && cuttingPos.y > 0.0)
        cutId = i

    assume rightWingCuttingPos = plane_cutting__wingRightCuttingPos[cutId]
    plane_cutting__cuttingPlanes[wreckageNo].w = lerp(rightWingCuttingPos.x, rightWingCuttingPos.y, 0.5)
  elif cutPartId == int(WreckageCutPartId.WRECK_PART_PART_TAIL)
    wreckageNo = int(WreckageType.WRECKAGE_TAIL)

    plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_TAIL)] = true
    plane_cutting__largePartsCutPartId[int(WreckageType.WRECKAGE_TAIL)] = partId
    plane_cutting__cuttingPlanes[wreckageNo].w = lerp(plane_cutting__tailCuttingPos.x, plane_cutting__tailCuttingPos.y, 0.5)
  elif cutPartId == int(WreckageCutPartId.WRECK_PART_PART_FIN)
    if plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_TAIL)]
      return

    wreckageNo = int(WreckageType.WRECKAGE_FIN)

    plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_FIN)] = true
    plane_cutting__largePartsCutPartId[int(WreckageType.WRECKAGE_FIN)] = partId
    plane_cutting__cuttingPlanes[wreckageNo].w = lerp(plane_cutting__finCuttingPos.x, plane_cutting__finCuttingPos.y, 0.5)
  elif cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB_1) || cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB_2)
    if plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_TAIL)]
      return

    wreckageNo = int(WreckageType.WRECKAGE_STAB_L)

    if cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB)
      plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_STAB_L)] = true
      plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_STAB_R)] = true
      plane_cutting__largePartsCutPartId[int(WreckageType.WRECKAGE_STAB_L)] = partId
      plane_cutting__largePartsCutPartId[int(WreckageType.WRECKAGE_STAB_R)] = partId
      plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_STAB_L)].w = lerp(plane_cutting__stabLeftCuttingPos.x, plane_cutting__stabLeftCuttingPos.y, 0.5)
      plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_STAB_R)].w = lerp(plane_cutting__stabRightCuttingPos.x, plane_cutting__stabRightCuttingPos.y, 0.5)
    elif cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB_1)
      plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_STAB_L)] = true
      plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_STAB_L)].w = lerp(plane_cutting__stabLeftCuttingPos.x, plane_cutting__stabLeftCuttingPos.y, 0.5)
      plane_cutting__largePartsCutPartId[int(WreckageType.WRECKAGE_STAB_L)] = partId
    elif cutPartId == int(WreckageCutPartId.WRECK_PART_PART_STAB_2)
      plane_cutting__largePartsCut[int(WreckageType.WRECKAGE_STAB_R)] = true
      plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_STAB_R)].w = lerp(plane_cutting__stabRightCuttingPos.x, plane_cutting__stabRightCuttingPos.y, 0.5)
      plane_cutting__largePartsCutPartId[int(WreckageType.WRECKAGE_STAB_R)] = partId
  else
    plane_cutting__smallPartsCut[partId] = true


  if wreckageNo >= 0
    plane_cutting__cutting = true

    plane_cutting__cuttingPlanesW |> resize(length(plane_cutting__cuttingPlanes))
    for w, plane in plane_cutting__cuttingPlanesW, plane_cutting__cuttingPlanes
      w = plane.w

[es(tag=gameClient, no_order)]
def plane_damage_update_cutting_plane_offset(info : UpdateStageInfoAct;
                                             plane_cutting__cuttingPlanesW : FloatList;
                                             var plane_cutting__cuttingPlanes : Point4List&)
  for plane, w in plane_cutting__cuttingPlanes, plane_cutting__cuttingPlanesW
    plane.w = w

def cut_bbox(var model_b_box : BBox3&; cut_plane : float4)
  let absFactors = abs(cut_plane)
  let bBoxCenter = model_b_box.center;
  var maxCoord : int;
  if (absFactors.x > absFactors.y && absFactors.x > absFactors.z)
    maxCoord = 0
  elif (absFactors.y > absFactors.x && absFactors.y > absFactors.z)
    maxCoord = 1
  else
    maxCoord = 2

  if (abs(cut_plane[maxCoord]) < 1.0e-7)
    return ;

  // (A, B, C, D) * (x, y, z, 1) = 0
  // x = - (A, B, C, D) * (0, y, z, 1) / A
  let border = dot(-cut_plane, float4(
    maxCoord != 0 ? bBoxCenter.x : 0.0,
    maxCoord != 1 ? bBoxCenter.y : 0.0,
    maxCoord != 2 ? bBoxCenter.z : 0.0,
    1.f)) / cut_plane[maxCoord];

  if (model_b_box.boxMin[maxCoord] > border ||
      model_b_box.boxMax[maxCoord] < border)
    return ;

  if (cut_plane[maxCoord] < 0.0)
    model_b_box.boxMin[maxCoord] = border;
  else
    model_b_box.boxMax[maxCoord] = border;

def create_wreckage_entity(template_name : string;
                           eid : EntityId;
                           node_name : string;
                           type_name : string;
                           bbox : BBox3;
                           arm : float3;
                           offset : float3;
                           plane_net_phys : PlaneActor;
                           mass_bbox : BBox3;
                           wreckage_type_props : WreckageTypeProperties;
                           transform : float3x4)
  let orient = DagorMath::quat(transform)

  let vel = float3(plane_net_phys.phys.currentState.velocity)
  let omega = float3(plane_net_phys.phys.currentState.omega)
  let partVel = vel + cross(omega, arm)

  var tmVel : float3x4
  tmVel[0] = normalize_default(partVel, float3(1, 0, 0))
  tmVel[1] = transform[1]
  tmVel[2] = normalize(cross(tmVel[0], tmVel[1]))
  tmVel[1] = cross(tmVel[2], tmVel[0])

  let impulseCoeffs = float3(
    lerp(wreckage_type_props.impulseCoeffsFrom.x, wreckage_type_props.impulseCoeffsTo.x, gfrnd()),
    lerp(wreckage_type_props.impulseCoeffsFrom.y, wreckage_type_props.impulseCoeffsTo.y, gfrnd()),
    lerp(wreckage_type_props.impulseCoeffsFrom.z, wreckage_type_props.impulseCoeffsTo.z, gfrnd())
  )

  let impulse = plane_net_phys.phys.cache.V2 * rotate(tmVel, impulseCoeffs)
  let momentCoeff = 0.1 * (0.2 + 0.8 * gfrnd())
  let moment = momentCoeff * cross(impulse, arm)

  let mass = max(wreckage_type_props.mass0 +
    (mass_bbox.width.x * mass_bbox.width.y * mass_bbox.width.z) * wreckage_type_props.volumeDensity +
    2.0 * (mass_bbox.width.x * mass_bbox.width.y + mass_bbox.width.y * mass_bbox.width.z + mass_bbox.width.z * mass_bbox.width.x) * wreckage_type_props.areaDensity, wreckage_type_props.massMin)

  let center = bbox.center
  let heightEpsilon = 0.03
  let size = float3(max(bbox.width.x, heightEpsilon), max(bbox.width.y, heightEpsilon), max(bbox.width.z, heightEpsilon))

  createEntity(template_name) <| $(var init)
    init |> set("transform", transform)
    init |> set("plane_wreckage__nodeName", node_name)
    init |> set("plane_wreckage__typeName", type_name)
    init |> set("plane_wreckage__owner", eid)
    init |> set("plane_wreckage__center", center)
    init |> set("plane_wreckage__size", size)
    init |> set("plane_wreckage__offset", offset)
    init |> set("plane_wreckage__pos", transform[3] - rotate(transform, offset))
    init |> set("plane_wreckage__orient", float4(orient))
    init |> set("plane_wreckage__startImpulse", impulse)
    init |> set("plane_wreckage__startMoment", moment)
    init |> set("plane_wreckage__vel", partVel)
    init |> set("plane_wreckage__omega", omega)
    init |> set("plane_wreckage__mass", mass)

def calc_nodes_bbox(part_id : int;
                    damage_model : DamageModel;
                    collres : CollisionResource)
  let collisionNodeId = get_collision_node_id(damage_model.dmData, part_id)
  let node = collres_get_node(collres, collisionNodeId)
  if node != null
    let tm = collres_get_node_tm(collres, collisionNodeId)
    let bbox3 = collres_get_node_bbox(collres, collisionNodeId)
    return tm * bbox3
  else
    return BBox3(-float3(0.1, 0.1, 0.1), float3(0.1, 0.1, 0.1))

def update_large_wrecked_part(wreckage_type : int;
                              cut : bool;
                              part_id : int;
                              wreckage_type_props : WreckageTypeProperties;
                              eid : EntityId;
                              transform : float3x4;
                              plane_net_phys : PlaneActor;
                              plane_cutting__cuttingPlanes;
                              plane_cutting__cutPartsId : IntList;
                              damage_model : DamageModel;
                              collres : CollisionResource;
                              plane_wreckage__template : string;
                              var plane_wreckage__createdLarge : BoolList&)
  if plane_wreckage__createdLarge[wreckage_type] == cut
    return

  var bbox = BBox3()
  if (wreckage_type == int(WreckageType.WRECKAGE_WING_L))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_WING_L)], damage_model, collres))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_WING1_L)], damage_model, collres))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_WING2_L)], damage_model, collres))
  elif (wreckage_type == int(WreckageType.WRECKAGE_WING_R))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_WING_R)], damage_model, collres))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_WING1_R)], damage_model, collres))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_WING2_R)], damage_model, collres))
  elif (wreckage_type == int(WreckageType.WRECKAGE_TAIL))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_TAIL)], damage_model, collres))
  elif (wreckage_type == int(WreckageType.WRECKAGE_STAB_L))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_STAB)], damage_model, collres))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_STAB_1)], damage_model, collres))
  elif (wreckage_type == int(WreckageType.WRECKAGE_STAB_R))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_STAB)], damage_model, collres))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_STAB_2)], damage_model, collres))
  elif (wreckage_type == int(WreckageType.WRECKAGE_FIN))
    bbox |> bbox3_add(calc_nodes_bbox(plane_cutting__cutPartsId[int(WreckageCutPartId.WRECK_PART_PART_FIN)], damage_model, collres))

  var arm = float3(0.0, 0.0, 0.0)

  let collisionNodeId = get_collision_node_id(damage_model.dmData, part_id)
  let node = collres_get_node(collres, collisionNodeId)
  if node != null
    let tm = collres_get_node_tm(collres, collisionNodeId)
    arm[wreckage_type_props.armAxis] = tm[3][wreckage_type_props.armAxis]
    if wreckage_type_props.armAxisMinVal > 0.0
      arm[wreckage_type_props.armAxis] = max(arm[wreckage_type_props.armAxis], wreckage_type_props.armAxisMinVal)
    elif wreckage_type_props.armAxisMinVal < 0.0
      arm[wreckage_type_props.armAxis] = min(arm[wreckage_type_props.armAxis], wreckage_type_props.armAxisMinVal)

  if cut
    let bboxMass = bbox
    var bboxBody = BBox3()
    bboxBody = bbox
    assume cuttingPlane = plane_cutting__cuttingPlanes[wreckage_type]
    cut_bbox(bboxBody, cuttingPlane)
    let center = float3(
      lerp(bboxBody.boxMin.x, bboxBody.boxMax.x, wreckage_type_props.massCenter.x),
      lerp(bboxBody.boxMin.y, bboxBody.boxMax.y, wreckage_type_props.massCenter.y),
      lerp(bboxBody.boxMin.z, bboxBody.boxMax.z, wreckage_type_props.massCenter.z))
    bboxBody.boxMin = bboxBody.boxMin - center
    bboxBody.boxMax = bboxBody.boxMax - center
    let offset = -cuttingPlane.w * cuttingPlane.xyz
    create_wreckage_entity(plane_wreckage__template, eid, WRECKAGE_NODE_NAMES[wreckage_type],
                           WRECKAGE_TYPE_NAMES[wreckage_type], bboxBody, arm, offset, plane_net_phys, bboxMass, wreckage_type_props, transform)

  plane_wreckage__createdLarge[wreckage_type] = cut

def update_small_wrecked_part(part_id : int;
                              cut : bool;
                              eid : EntityId;
                              transform : float3x4;
                              plane_net_phys : PlaneActor;
                              damage_model : DamageModel;
                              collres : CollisionResource;
                              plane_wreckage__template : string;
                              var animchar_render : AnimcharRendComponent&;
                              var plane_wreckage__createdSmall : BoolList&)
  if plane_wreckage__createdSmall[part_id] == cut
    return

  let collisionNodeId = get_collision_node_id(damage_model.dmData, part_id)
  let node = collres_get_node(collres, collisionNodeId)
  if node != null
    let nodeNameDm = collres_get_node_name(collres, collisionNodeId)
    let nodeName = ends_with(nodeNameDm, "_dm") ? chop(nodeNameDm, 0, length(nodeNameDm) - 3) : nodeNameDm

    assume sceneInstance = animchar_render.sceneInstance
    let nodeId = *sceneInstance |> scene_instance_getNodeId(nodeName)
    if nodeId >= 0
      if (cut)
        var bbox = collres_get_node_bbox(collres, collisionNodeId)
        let minSize = 2.0 * 0.1
        var width = bbox.width
        width.x = max(width.x, minSize)
        width.y = max(width.y, minSize)
        width.z = max(width.z, minSize)
        bbox.boxMin = -width * 0.5
        bbox.boxMax =  width * 0.5
        let tm = collres_get_node_tm(collres, collisionNodeId)
        let arm = tm[3]
        *sceneInstance |> scene_instance_setNodeOpacity(uint(nodeId), 0.0)
        sceneInstance |> scene_instance_show_node(nodeId, false)
        assume templateName = plane_wreckage__template
        create_wreckage_entity(templateName, eid, nodeName, nodeName, bbox, arm, arm, plane_net_phys, bbox, smallWreckageProperties, transform)
      else
        *sceneInstance |> scene_instance_setNodeOpacity(uint(nodeId), 1.0)
        sceneInstance |> scene_instance_show_node(nodeId, true)

  plane_wreckage__createdSmall[part_id] = cut

[es(tag=gameClient, no_order)]
def plane_damage_cutting_draw_es(info : UpdateStageInfoAct;
                                 eid : EntityId;
                                 plane_wreckage__template : string;
                                 transform : float3x4;
                                 plane_net_phys : PlaneActor;
                                 damage_model : DamageModel;
                                 collres : CollisionResource;
                                 plane_cutting__cuttingPlanes : Point4List;
                                 plane_cutting__largePartsCut : BoolList;
                                 plane_cutting__largePartsCutPartId : IntList;
                                 plane_cutting__smallPartsCut : BoolList;
                                 plane_cutting__cutPartsId : IntList;
                                 var animchar_render : AnimcharRendComponent&;
                                 var plane_wreckage__createdLarge : BoolList&;
                                 var plane_wreckage__createdSmall : BoolList&)
  for wreckageType in each_enum(WreckageType.WRECKAGE_WING_L)
    update_large_wrecked_part(int(wreckageType), plane_cutting__largePartsCut[int(wreckageType)],
                              plane_cutting__largePartsCutPartId[int(wreckageType)], WRECKAGE_TYPE_PROPERTIES[int(wreckageType)],
                              eid, transform, plane_net_phys, plane_cutting__cuttingPlanes, plane_cutting__cutPartsId,
                              damage_model, collres, plane_wreckage__template, plane_wreckage__createdLarge)

  for partId in iter_range(plane_cutting__smallPartsCut)
    update_small_wrecked_part(partId, plane_cutting__smallPartsCut[partId], eid, transform, plane_net_phys,
                              damage_model, collres, plane_wreckage__template, animchar_render, plane_wreckage__createdSmall)

[es(on_appear)]
def plane_damage_cutting_common_es(evt : Event;
                                   damage_model : DamageModel;
                                   var plane_wreckage__createdLarge : BoolList&;
                                   var plane_wreckage__createdSmall : BoolList&)
  plane_wreckage__createdLarge |> clear()
  for _i in each_enum(WreckageType.WRECKAGE_WING_L)
    plane_wreckage__createdLarge |> push(false)

  plane_wreckage__createdSmall |> clear()
  for _i in range(get_damage_part_props_count(damage_model.dmData))
    plane_wreckage__createdSmall |> push(false)

[es(on_appear)]
def plane_damage_initial_cutting_es(evt : Event;
                                    plane_cutting__wingLeftCuttingPos : Point2List;
                                    plane_cutting__wingRightCuttingPos : Point2List;
                                    plane_cutting__tailCuttingPos : float2;
                                    plane_cutting__initialCutType : int;
                                    plane_cutting__initialCut : float;
                                    plane_cutting__leftWingCutState : int;
                                    plane_cutting__rightWingCutState : int;
                                    var plane_cutting__cuttingPlanes : Point4List&)
  if plane_cutting__initialCutType == int(WreckageType.WRECKAGE_WING_L)
    let leftWingCuttingPos = plane_cutting__wingLeftCuttingPos[plane_cutting__leftWingCutState - 1]
    plane_cutting__cuttingPlanes[plane_cutting__initialCutType].w = lerp(leftWingCuttingPos.x, leftWingCuttingPos.y, plane_cutting__initialCut)
  elif plane_cutting__initialCutType == int(WreckageType.WRECKAGE_WING_R)
    let rightWingCuttingPos = plane_cutting__wingRightCuttingPos[plane_cutting__rightWingCutState - 1]
    plane_cutting__cuttingPlanes[plane_cutting__initialCutType].w = lerp(rightWingCuttingPos.x, rightWingCuttingPos.y, plane_cutting__initialCut)
  elif plane_cutting__initialCutType == int(WreckageType.WRECKAGE_TAIL)
    plane_cutting__cuttingPlanes[plane_cutting__initialCutType].w = lerp(plane_cutting__tailCuttingPos.x, plane_cutting__tailCuttingPos.y, plane_cutting__initialCut)

[es(tag=gameClient, on_appear)]
def plane_wreckage_tm_init_es(evt : Event;
                              plane_wreckage__nodeName : string;
                              animchar : AnimcharBaseComponent;
                              var plane_wreckage__tm : float3x4&)
  assume geom = *animchar.nodeTree

  var rootTm : float3x4
  geom |> geomtree_getNodeWtmRelScalar(0, rootTm)
  rootTm = inverse(rootTm)

  let nodeNo = geom |> geomtree_findNodeIndex(plane_wreckage__nodeName)
  if nodeNo < 0
    logerr("[wreckage]: Node /*{plane_wreckage__nodeName}*/ not found")
    return

  geom |> geomtree_getNodeWtmRelScalar(nodeNo, plane_wreckage__tm)
  plane_wreckage__tm = rootTm * plane_wreckage__tm

[es(on_appear)]
def init_plane_wreckage_part_type_id(evt : Event;
                                     plane_wreckage__typeName : string;
                                     plane_wreckage__nodeName : string;
                                     var animchar_render : AnimcharRendComponent&;
                                     var plane_wreckage__typeId : int&)
  plane_wreckage__typeId = find_index(WRECKAGE_TYPE_NAMES, plane_wreckage__typeName)

  assume sceneInstance = animchar_render.sceneInstance
  let nodeId = scene_instance_getNodeId(*sceneInstance, plane_wreckage__nodeName)

  for id in (*(*sceneInstance).lodsResource).names.node.id
    *sceneInstance |> scene_instance_setNodeOpacity(uint(id), 0.0)
    sceneInstance |> scene_instance_show_node(int(id), false)

  *sceneInstance |> scene_instance_setNodeOpacity(uint(nodeId), 1.0)
  sceneInstance |> scene_instance_show_node(nodeId, true)

def find_model_root_cutting_point(geom : GeomNodeTree; name : string; var out_point : float3&)
  let nodeIndex = geom |> geomtree_findNodeIndex(name)
  if nodeIndex >= 0
    var rootTm = IDENT_TM
    geom |> geomtree_getNodeWtmRelScalar(0, rootTm)
    rootTm = inverse(rootTm)
    out_point = rootTm * geomtree_getNodeWposRel(geom, nodeIndex)
    return true
  out_point = float3()
  return false

def find_blk_cutting_point(blk : DataBlock; name : string; var out_point : float3&)
  let paramNum = blk |> datablock_find_param(name)
  if paramNum >= 0
    let paramType = blk |> datablock_getParamType(uint(paramNum))
    if paramType == int(DataBlockParamType.TYPE_MATRIX)
      out_point = datablock_getTm(blk, paramNum)[3]
      return true
    elif paramType == int(DataBlockParamType.TYPE_POINT3)
      out_point = blk |> datablock_getPoint3(paramNum)
      return true
    else
      logerr("emitter /*{name}*/ in blk has incorrect type = /*{paramType}*/")
  out_point = float3()
  return false

def find_root_cutting_point(geom : GeomNodeTree; name : string; blk : DataBlock?; var out_point : float3&)
  if find_model_root_cutting_point(geom, name, out_point)
    return true
  elif blk != null
    return find_blk_cutting_point(*blk, name, out_point)
  out_point = float3()
  return false

[es(on_appear, after=plane_cutting_planes_init_es)]
def init_plane_cutting(evt : Event;
                       animchar : AnimcharBaseComponent;
                       damage_model : DamageModel;
                       plane_phys_damage__blk : string;
                       var plane_cutting__tailCuttingPos : float2&;
                       var plane_cutting__finCuttingPos : float2&;
                       var plane_cutting__wingLeftCuttingPos : Point2List&;
                       var plane_cutting__wingRightCuttingPos : Point2List&;
                       var plane_cutting__wingBiplaneCuttingPlane : float4&;
                       var plane_cutting__wingLowerCuttingPlane : float4&;
                       var plane_cutting__cuttingPlanes : Point4List&;
                       var plane_cutting__wingRearCuttingPlane : float4&;
                       var plane_cutting__wingUpperCuttingPlane : float4&;
                       var plane_cutting__finsFrontCuttingPlane : float4&;
                       var plane_cutting__stabLeftCuttingPos : float2&;
                       var plane_cutting__stabRightCuttingPos : float2&;
                       var plane_cutting__cutPartsId : IntList)
  plane_cutting__cuttingPlanes |> clear()
  for _i in each_enum(WreckageType.WRECKAGE_WING_L)
    plane_cutting__cuttingPlanes |> emplace(float4())

  plane_cutting__wingLeftCuttingPos |> clear()
  plane_cutting__wingRightCuttingPos |> clear()
  for _i in each_enum(FlightModelCutState.FMCS_NONE)
    plane_cutting__wingLeftCuttingPos |> emplace(float2(-1, -1))
    plane_cutting__wingRightCuttingPos |> emplace(float2(-1, -1))

  let partsSize = typeinfo enum_length(type<WreckageCutPartId>)
  if partsSize != length(WRECKAGE_CUT_PART_NAMES)
    logerr("plane cutting: WRECKAGE_CUT_PART_NAMES and WreckageCutPartId have different size")
  let wreckageTypeCount = typeinfo enum_length(type<WreckageType>)
  if length(WRECKAGE_NODE_NAMES) != wreckageTypeCount
    logerr("plane cutting: WRECKAGE_NODE_NAMES and WreckageType have different size")
  if length(WRECKAGE_TYPE_NAMES) != wreckageTypeCount
    logerr("plane cutting: WRECKAGE_TYPE_NAMES and WreckageType have different size")

  plane_cutting__cutPartsId |> resize(partsSize)
  for cutPartId, partName in plane_cutting__cutPartsId, WRECKAGE_CUT_PART_NAMES
    cutPartId = damage_model |> find_part_id_by_name(partName)

  plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_WING_L)] = float4(0, 0, 0, 1)
  plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_WING_R)] = float4(0, 0, 0, 1)
  plane_cutting__wingRearCuttingPlane = float4(0, 0, 0, -1)
  plane_cutting__wingUpperCuttingPlane = float4(0, 0, 0, -1)

  using() <| $(var planeBlk : DataBlock)
    if !datablock_load(planeBlk, plane_phys_damage__blk)
      return

    assume geom = *animchar.nodeTree

    let cuttingBlk = planeBlk |> datablock_get_block_by_name("cutting")

    for s in range(2)
      let side = s == 0 ? "l" : "r"
      let dir = s == 0 ? float3(0, 0, 1) : float3(0, 0, -1)

      assume wingCuttingPos = s == 0 ? plane_cutting__wingLeftCuttingPos : plane_cutting__wingRightCuttingPos

      plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_WING_L) + s] = float4(0, 0, 0, 1)
      var directionIsFound = false

      var wingCutFromPoint : float3
      var wingCutToPoint : float3

      let wingFromCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing0_{side}_from", cuttingBlk, wingCutFromPoint)
      let wingToCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing0_{side}_to", cuttingBlk, wingCutToPoint)

      if wingFromCutPointPresents && wingToCutPointPresents
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_WING_L) + s] = float4(-normalize(wingCutToPoint - wingCutFromPoint), 0.0)
        directionIsFound = true
        wingCuttingPos[int(FlightModelCutState.FMCS_ALL_CUT) - 1] = float2(dot(dir, wingCutFromPoint), dot(dir, wingCutToPoint))

      var wing1CutFromPoint : float3
      var wing1CutToPoint : float3
      let wing1FromCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing1_{side}_from", cuttingBlk, wing1CutFromPoint)
      let wing1ToCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing1_{side}_to", cuttingBlk, wing1CutToPoint)

      if wing1FromCutPointPresents && wing1ToCutPointPresents
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_WING_L) + s] = float4(-normalize(wing1CutToPoint - wing1CutFromPoint), 0.0)
        directionIsFound = true
        wingCuttingPos[int(FlightModelCutState.FMCS_MID_CUT) - 1] = float2(dot(dir, wing1CutFromPoint), dot(dir, wing1CutToPoint))

      var wing2CutFromPoint : float3
      var wing2CutToPoint : float3
      let wing2FromCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing2_{side}_from", cuttingBlk, wing2CutFromPoint)
      let wing2ToCutPointPresents = find_root_cutting_point(geom, "emtr_break_wing2_{side}_to", cuttingBlk, wing2CutToPoint)
      if wing2FromCutPointPresents && wing2ToCutPointPresents
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_WING_L) + s] = float4(-normalize(wing2CutToPoint - wing2CutFromPoint), 0.0)
        directionIsFound = true
        wingCuttingPos[int(FlightModelCutState.FMCS_SMALL_CUT) - 1] = float2(dot(dir, wing2CutFromPoint), dot(dir, wing2CutToPoint))

    var wingRearCutPoint : float3
    if find_root_cutting_point(geom, "emtr_break_wing_tail", cuttingBlk, wingRearCutPoint)
      let wingCutDir = normalize(wingRearCutPoint)
      plane_cutting__wingRearCuttingPlane = float4(wingCutDir, -abs(dot(float3(-1, 0, 0), wingRearCutPoint)))
      plane_cutting__finsFrontCuttingPlane = float4(-wingCutDir, abs(dot(float3(1, 0, 0), wingRearCutPoint)))
    else
      plane_cutting__wingRearCuttingPlane = float4(0, 0, 0, -1)
      plane_cutting__finsFrontCuttingPlane = float4(0, 0, 0, -1)

    var wingBiplaneCutPoint : float3
    if find_root_cutting_point(geom, "emtr_break_wing_biplane", cuttingBlk, wingBiplaneCutPoint)
      plane_cutting__wingBiplaneCuttingPlane = float4(0.0, -1.0, 0.0, -abs(wingBiplaneCutPoint.y))

    var wingLowerCutPoint : float3
    if find_root_cutting_point(geom, "emtr_break_wing_lower", cuttingBlk, wingLowerCutPoint)
      plane_cutting__wingLowerCuttingPlane = float4(0.0, -1.0, 0.0, -abs(wingLowerCutPoint.y))

    var wingUpperCutPoint : float3
    if find_root_cutting_point(geom, "emtr_break_wing_upper", cuttingBlk, wingUpperCutPoint)
      let wingUpperCuttingLen = length(wingUpperCutPoint)
      let wingUpperCuttingDir = wingUpperCutPoint / max(wingUpperCuttingLen, 0.001)
      plane_cutting__wingUpperCuttingPlane = float4(wingUpperCuttingDir, -wingUpperCuttingLen)

    var tailWreckedId = int(WreckageType.WRECKAGE_TAIL)
    if cuttingBlk != null && cuttingBlk |> datablock_getBool("finCut", false)
      tailWreckedId = int(WreckageType.WRECKAGE_FIN)

    assume tailFinCuttingPos = tailWreckedId == int(WreckageType.WRECKAGE_TAIL) ? plane_cutting__tailCuttingPos : plane_cutting__finCuttingPos
    var tailFinCutFrom : float3
    var tailFinCutTo : float3
    if find_model_root_cutting_point(geom, "emtr_break_tail_from", tailFinCutFrom) && find_model_root_cutting_point(geom, "emtr_break_tail_to", tailFinCutTo)
      let tailFinCutNorm = normalize(tailFinCutFrom - tailFinCutTo)
      plane_cutting__cuttingPlanes[tailWreckedId] = float4(tailFinCutNorm.x, tailFinCutNorm.y, tailFinCutNorm.z, 0.0)
      tailFinCuttingPos = float2(dot(-tailFinCutFrom, tailFinCutNorm), dot(-tailFinCutTo, tailFinCutNorm))
    else
      plane_cutting__cuttingPlanes[tailWreckedId] = float4(0, 0, 0, 1)
      tailFinCuttingPos = float2(1, 1)

    if tailWreckedId != int(WreckageType.WRECKAGE_TAIL)
      var tailCutFrom : float3
      var tailCutTo : float3
      if find_blk_cutting_point(*cuttingBlk, "emtr_break_tail_from", tailCutFrom) && find_blk_cutting_point(*cuttingBlk, "emtr_break_tail_to", tailCutTo)
        let tailCutNorm = normalize(tailCutFrom - tailCutTo)
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_TAIL)] = float4(tailCutNorm.x, tailCutNorm.y, tailCutNorm.z, 0.0)
        plane_cutting__tailCuttingPos = float2(dot(-tailCutFrom, tailCutNorm), dot(-tailCutTo, tailCutNorm))
      else
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_TAIL)] = float4(0, 0, 0, 1)
        plane_cutting__tailCuttingPos = float2(1, 1)
    else
      var finCutFrom : float3
      var finCutTo : float3
      if find_root_cutting_point(geom, "emtr_break_fin_from", cuttingBlk, finCutFrom) && find_root_cutting_point(geom, "emtr_break_fin_to", cuttingBlk, finCutTo)
        let finCutNorm = normalize(finCutFrom - finCutTo)
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_FIN)] = float4(finCutNorm.x, finCutNorm.y, finCutNorm.z, 0.0)
        plane_cutting__finCuttingPos = float2(dot(-finCutFrom, finCutNorm), dot(-finCutTo, finCutNorm))
      else
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_FIN)] = float4(0, 0, 0, 1)
        plane_cutting__finCuttingPos = float2(1, 1)

    for s in range(2)
      let side = s == 0 ? "l" : "r"
      assume stabCuttingPos = s == 0 ? plane_cutting__stabLeftCuttingPos : plane_cutting__stabRightCuttingPos
      var stabCutFrom : float3
      var stabCutTo : float3
      if find_root_cutting_point(geom, "emtr_break_stab_{side}_from", cuttingBlk, stabCutFrom) && find_root_cutting_point(geom, "emtr_break_stab_{side}_to", cuttingBlk, stabCutTo)
        let stabCutNorm = normalize(stabCutFrom - stabCutTo)
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_STAB_L) + s] = float4(stabCutNorm.x, stabCutNorm.y, stabCutNorm.z, 0.0)
        stabCuttingPos = float2(dot(-stabCutFrom, stabCutNorm), dot(-stabCutTo, stabCutNorm))
      else
        plane_cutting__cuttingPlanes[int(WreckageType.WRECKAGE_STAB_L) + s] = float4(0, 0, 0, 1)
        stabCuttingPos = float2(1, 1)
