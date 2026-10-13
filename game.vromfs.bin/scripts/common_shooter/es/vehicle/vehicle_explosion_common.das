module vehicle_explosion_common shared

require ecs
require DagorMath
require DagorMathUtils
require AnimV20
require GeomNodeTree
require math.base
require math.ang
require strings


def open_hatches_at_seed(seed_eid : EntityId;
                         var animchar : AnimcharBaseComponent;
                         hatch_angles : Object;
                         hatch_pos_offsets : Object;
                         hatch_open_chance : float)
  let seedU = uint(seed_eid)
  let chanceSeedU = hash_combine_u32(seedU, 1u)
  let nodeCount = int((*animchar.nodeTree).nodeCount)
  for boneIdx in range(nodeCount)
    let boneName = string(*animchar.nodeTree |> geomtree_getNodeName(boneIdx))
    if !starts_with(boneName, "hatch")
      continue
    let r01Chance = hash_to_unit_float(hash_combine_u32(chanceSeedU, uint(boneIdx)))
    if r01Chance >= hatch_open_chance
      continue
    let angleRange = get_Point2(hatch_angles, boneName) ?? float2(45.0, 135.0)
    let posOffset = get_Point3(hatch_pos_offsets, boneName) ?? float3(0.0, 0.0, 0.0)
    let r01 = hash_to_unit_float(hash_combine_u32(seedU, uint(boneIdx)))
    let angleDeg = angleRange.x + (angleRange.y - angleRange.x) * r01
    let rotM = make_rot_cw_zyx(float3(deg_to_rad(-angleDeg), 0.0, 0.0))
    var restTm : float3x4
    *animchar.originalNodeTree |> geomtree_getNodeTmScalar(boneIdx, restTm)
    var curTm : float3x4
    *animchar.nodeTree |> geomtree_getNodeTmScalar(boneIdx, curTm)
    let cosTol = 0.9999
    // Skips hatches that aren't closed, to avoid conflict with other hatch code
    if dot(restTm[0], curTm[0]) < cosTol || dot(restTm[1], curTm[1]) < cosTol || dot(restTm[2], curTm[2]) < cosTol
      continue
    var newTm = restTm * rotM
    newTm[3] = newTm[3] + posOffset
    *animchar.nodeTree |> geomtree_setNodeTmScalar(boneIdx, newTm)
