module interactable_common shared
require ecs
require math
require math.base
require DagorMath
require Grid
require AnimV20
require GeomNodeTree

def find_interactable(grid_name_hash : uint; tm : float3x4; player_tm : float3x4; rad : float; ignore_checks : bool;
                      find_check : block<(eid : EntityId) : bool>)
  var minDist = FLT_MAX
  var bestEntity = INVALID_ENTITY_ID
  for_each_entity_in_grid(grid_name_hash, BSphere3(tm[3], rad), GridEntCheck.BOUNDING) <| $(eid : EntityId)
    if !invoke(find_check, eid)
      return
    query(eid) <| $ [es] (interactCheckOffset : float3 = float3(0.0, 0.0, 0.0);
                          interactable : bool = true;
                          interactDist : float = 1.5;
                          isAlive : bool = true;
                          interactAngleLimits : float2 = float2(-60.0, 60.0);
                          transform : float3x4)
      if !interactable || !isAlive
        return
      var entityTM = transform
      entityTM[3] = transform * interactCheckOffset
      let dirToHands = entityTM[3] - tm[3]
      let dirToPlayer = entityTM[3] - player_tm[3]
      let curDistSq = length_sq(dirToHands)
      let curDist2DSq = length_sq(dirToHands.xz)
      if !ignore_checks && curDist2DSq > length_sq(dirToPlayer.xz)
        return
      let dot = dot(dirToHands * safeinv(sqrt(curDistSq)), tm[0])
      let dirDot = (1.0 - dot) * curDistSq
      if !ignore_checks && (curDistSq > square(interactDist) || dirDot > minDist)
        return
      let itm = inverse(entityTM)
      let localPos = itm * tm[3]
      let localPosToPlayer = itm * player_tm[3]
      let angleLimits = DEG_TO_RAD * interactAngleLimits
      let horzAngle = atan2(localPos.x, localPos.z)
      let horzAngleToPlayer = atan2(localPosToPlayer.x, localPosToPlayer.z)
      if !ignore_checks && (max(horzAngle, horzAngleToPlayer) > angleLimits.y || min(horzAngle, horzAngleToPlayer) < angleLimits.x)
        return
      minDist = dirDot
      bestEntity = eid
  return bestEntity


def find_interactable(grid_name_hash : uint; eid : EntityId; rad : float; ignore_checks : bool;
                      find_check : block<(eid : EntityId) : bool>)
  var found = INVALID_ENTITY_ID
  query(eid) <| $ [es] (transform : float3x4;
                        human__aimTm : float3x4;
                        bindedCamera : EntityId = INVALID_ENTITY_ID;
                        human_use_object__nodeId : int = -1;
                        human_weap__throwMode : bool = false;
                        animchar : AnimcharBaseComponent;
                        human_net_phys__isClimbing : bool = false)
    if human_net_phys__isClimbing || human_weap__throwMode
      return
    var aimTm = human__aimTm
    let camTmRef = get_TMatrix(bindedCamera, "transform")
    if camTmRef != null
      let camTm = *camTmRef
      aimTm[0] = camTm[2]
      aimTm[1] = normalize(cross(normalize(cross(aimTm[0], float3(0f, 1f, 0f))), aimTm[0]))
      aimTm[2] = normalize(cross(aimTm[0], aimTm[1]))
      aimTm[3] = (human_use_object__nodeId > 0
        ? geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId)
        : camTm[3])
    found = find_interactable(grid_name_hash, aimTm, transform, rad, ignore_checks, find_check);
  return found
