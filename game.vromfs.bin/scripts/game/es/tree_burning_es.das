require ecs
require Dacoll
require CollRes
require math.base
require DagorMath
require game.events_game
require app
require gameLibs.pufd_events.pufd_events
require DagorConsole
require DagorDebug3D
require math.random
require player
require enlisted.events_enlisted
require DngNet
require ecs.common
require danetlibs.tree_burning.tree_burning_events

def remove_tree_chain_handle(handle)
  find_query() <| $ [es] (var tree_burning_chain_manager__destroyedChainsHandles : UInt64List&;
                          var tree_burning_chain_manager__destroyedChainsPoses : Point3List&)
    let ind = find_index(tree_burning_chain_manager__destroyedChainsHandles, uint64(handle))
    if ind != -1
      erase(tree_burning_chain_manager__destroyedChainsHandles, ind)
      erase(tree_burning_chain_manager__destroyedChainsPoses, ind)
    return true

[es(tag=server, REQUIRE=tree_burning__ignite_radius)]
def create_tree_burning_chain(evt : EventCreateTreeBurningChain)
  find_query() <| $ [es] (var tree_burning_chain_manager__destroyedChainsHandles : UInt64List&;
                          var tree_burning_chain_manager__destroyedChainsPoses : Point3List&)
    if find_index(tree_burning_chain_manager__destroyedChainsHandles, uint64(evt.riExHandle)) != -1
      return true
    push(tree_burning_chain_manager__destroyedChainsPoses, evt.treeTm[3])
    push(tree_burning_chain_manager__destroyedChainsHandles, uint64(evt.riExHandle))
    createEntity("tree_burning_chain") <| $(var init : ComponentsInitializer)
      set(init, "transform", evt.treeTm)
      set(init, "tree_burning_chain__canopyType", evt.canopyType)
      set(init, "tree_burning_chain__canopyBoxMin", evt.canopyBoxMin)
      set(init, "tree_burning_chain__canopyBoxMax", evt.canopyBoxMax)
      set(init, "tree_burning_chain__treeHandle", evt.riExHandle)
      set(init, "tree_burning_chain__isBush", evt.isBush)
      using() <| $(var fireSources : Point4List&)
        var point = float4()
        point.xyz = evt.burningSourceWpos
        point.w = get_sync_time()
        push(fireSources, point)
        set(init, "tree_burning_chain__fireSources", fireSources)
    return true

[es(tag=server)]
def add_tree_burning_chain_source(evt : EventAddTreeBurningChainSource; var tree_burning_chain__fireSources : Point4List)
  var point = float4()
  point.xyz = evt.burningSourceWpos
  point.w = get_sync_time()
  push(tree_burning_chain__fireSources, point)


[es(no_order, tag=server)]
def tree_burning_chain_init_control(info : ParallelUpdateFrameDelayed;
                                    tree_burning_chain_manager__framesForDebug : int;
                                    var tree_burning_chain_manager__framesToNextInit : int&;
                                    tree_burning_chain_manager__framesPerChainInit : int;
                                    tree_burning_chain_manager__canopyBoxSizeMul : float3;
                                    tree_burning_chain_manager__trunkBoxStep : float;
                                    tree_burning_chain_manager__canopyBoxDisp : float;
                                    tree_burning_chain_manager__debugOn : bool;
                                    tree_burning_chain_manager__canopyBoxStep : float)
  if tree_burning_chain_manager__framesToNextInit != 0
    tree_burning_chain_manager__framesToNextInit = (tree_burning_chain_manager__framesToNextInit + 1) % tree_burning_chain_manager__framesPerChainInit
    return
  find_query() <| $ [es] (transform : float3x4;
                          eid : EntityId;
                          var tree_burning_chain__inited : bool&;
                          var tree_burning_chain__canopyBoxMin : float3&;
                          var tree_burning_chain__canopyBoxMax : float3&;
                          var tree_burning_chain__fireFxEids : EidList&;
                          tree_burning_chain__isBush : bool;
                          var tree_burning_chain__fireFxPoses : Point4List;
                          var tree_burning_chain__deathTime : float&;
                          tree_burning_chain__treeHandle : riex_handle_t)
    if tree_burning_chain__inited
      return false

    tree_burning_chain_manager__framesToNextInit = 1

    using(tree_burning_chain__treeHandle) <| $(var desc : RendInstDesc#)
      using() <| $(var trunkGridVoxel : Point4List&)
        using() <| $(var canopyGridVoxel : BoolList&)
          let canopyBox = transform * BBox3(tree_burning_chain__canopyBoxMin, tree_burning_chain__canopyBoxMax)
          tree_burning_chain__canopyBoxMax = canopyBox.boxMax
          tree_burning_chain__canopyBoxMin = canopyBox.boxMin
          var canopyCenter = (tree_burning_chain__canopyBoxMax + tree_burning_chain__canopyBoxMin) / 2.
          var dir = tree_burning_chain__canopyBoxMax - canopyCenter
          dir.x *= tree_burning_chain_manager__canopyBoxSizeMul.x
          dir.z *= tree_burning_chain_manager__canopyBoxSizeMul.x
          dir.y *= tree_burning_chain_manager__canopyBoxSizeMul.z
          tree_burning_chain__canopyBoxMax = canopyCenter + dir
          dir.y *= tree_burning_chain_manager__canopyBoxSizeMul.y / tree_burning_chain_manager__canopyBoxSizeMul.z
          tree_burning_chain__canopyBoxMin = canopyCenter - dir
          var canopyBoxSize = tree_burning_chain__canopyBoxMax - tree_burning_chain__canopyBoxMin
          canopyCenter = (tree_burning_chain__canopyBoxMax + tree_burning_chain__canopyBoxMin) / 2.

          var canopyGridTransform = IDENT_TM
          for i in range(3)
            canopyBoxSize[i] = floor(abs(canopyBoxSize[i]) / tree_burning_chain_manager__canopyBoxStep)
            canopyGridTransform[3][i] = canopyCenter[i] - canopyBoxSize[i] / 2. * tree_burning_chain_manager__canopyBoxStep
            canopyBoxSize[i] += 1.
            canopyGridTransform[i] *= tree_burning_chain_manager__canopyBoxStep

          resize(canopyGridVoxel, int(canopyBoxSize.x * canopyBoxSize.y * canopyBoxSize.z))
          let collres = getRiGenCollisionResource(desc)
          if collres == null
            return

          tree_burning_chain__inited = true
          let bbox = (*collres).boundingBox

          var trunkGridTransform = IDENT_TM
          for i in range(3) // for a simpler calculation of the location of mesh points relative to the centers of the grid cubes
            trunkGridTransform[i] = normalize(transform[i]) * tree_burning_chain_manager__trunkBoxStep

          trunkGridTransform[3] = transform * bbox.boxMin
          let relPosToTrunkGridMatrix = inverse(trunkGridTransform) * transform

          var trunkBoxSize = relPosToTrunkGridMatrix * bbox.boxMax - relPosToTrunkGridMatrix * bbox.boxMin

          for i in range(3)
            trunkBoxSize[i] = float(int(abs(trunkBoxSize[i]) + 1.))

          resize(trunkGridVoxel, int(trunkBoxSize.x * trunkBoxSize.y * trunkBoxSize.z))

          let nodesCnt = (*collres) |> collres_get_nodesCount()
          let rootTm = getRIGenMatrix(desc)

          let yMul = int(trunkBoxSize.z) // a multipliers for representing a 3-dimensional matrix as an array
          let xMul = int(trunkBoxSize.y) * yMul
          let stepLenForLongNodes = 0.5
          for i in range(nodesCnt)
            let node = (*collres) |> collres_get_node(i)
            collres_node_iterate_face_verts(*collres, int(node.nodeIndex)) <| $ [unused_argument(fi)] (fi : int; fv0, fv1, fv2 : float3)
              let pts = fixed_array(fv0, fv1, fv2)
              for edgeIdx in range(3)
                let curPointGridPos = relPosToTrunkGridMatrix * pts[edgeIdx]
                let nextpointGridPos = relPosToTrunkGridMatrix * pts[(edgeIdx + 1) % 3]
                let stepsCount = int(length(curPointGridPos - nextpointGridPos) / stepLenForLongNodes) + 1
                dir = normalize(nextpointGridPos - curPointGridPos)
                for step in range(stepsCount) // for cases where the mesh edges are too long, we split the edge into several points.
                  let pointGridPos = (step == stepsCount - 1) ? nextpointGridPos : curPointGridPos + dir * float(step) * 0.5
                  let pointDistToGridCellCenter = square(0.5 - pointGridPos.x % 1.) + square(0.5 - pointGridPos.y % 1.) + square(0.5 - pointGridPos.z % 1.)
                  let pointGridInd = int(pointGridPos.x) * xMul + int(pointGridPos.y) * yMul + int(pointGridPos.z)
                  if pointGridInd < 0 || pointGridInd >= length(trunkGridVoxel)
                    continue
                  if trunkGridVoxel[pointGridInd].w == 0. || trunkGridVoxel[pointGridInd].w > pointDistToGridCellCenter
                    trunkGridVoxel[pointGridInd].w = pointDistToGridCellCenter
                    trunkGridVoxel[pointGridInd].xyz = trunkGridTransform * pointGridPos

          let inverseCanopyTm = inverse(canopyGridTransform)
          let canopyGridYMul = int(canopyBoxSize.z)
          let canopyGridXMul = int(canopyBoxSize.y) * canopyGridYMul

          for x in range(int(trunkBoxSize.x))
            for y in range(int(trunkBoxSize.y))
              for z in range(int(trunkBoxSize.z))
                let ind = x * xMul + y * yMul + z
                var nearestVoxelFxPosTooClose = false
                if ind < 0 || ind >= length(trunkGridVoxel) || trunkGridVoxel[ind].w == 0.
                  continue
                for x1 in range(2)
                  for y1 in range(2)
                    for z1 in range(2)
                      if !nearestVoxelFxPosTooClose
                        let ind1 = max(0, x - x1) * xMul + max(0, y - y1) * yMul + max(0, z - z1)
                        if ind1 < 0 || ind1 >= length(trunkGridVoxel)
                          continue
                        nearestVoxelFxPosTooClose ||= ind1 != ind && trunkGridVoxel[ind1].w != 0. && length_sq(trunkGridVoxel[ind].xyz - trunkGridVoxel[ind1].xyz) < tree_burning_chain_manager__trunkBoxStep

                if !nearestVoxelFxPosTooClose
                  trunkGridVoxel[ind].w = 1. // next, we need to distinguish the points of fire on the crown and trunk.
                  push(tree_burning_chain__fireFxPoses, trunkGridVoxel[ind])

                  let canopyGridPos = inverseCanopyTm * trunkGridVoxel[ind].xyz
                  let canopyGridInd = int(canopyGridPos.x) * canopyGridXMul + int(canopyGridPos.y) * canopyGridYMul + int(canopyGridPos.z)
                  if canopyGridInd > 0 && canopyGridInd < length(canopyGridVoxel)
                    canopyGridVoxel[canopyGridInd] = true

          tree_burning_chain__deathTime = info.curTime + tree_burning_chain__deathTime * (tree_burning_chain__isBush ? 0.3 : 1.)
          for x in range(int(canopyBoxSize.x))
            for y in range(int(canopyBoxSize.y))
              for z in range(int(canopyBoxSize.z))
                let ind = x * canopyGridXMul + y * canopyGridYMul + z
                if ind < 0 || ind >= length(canopyGridVoxel) || canopyGridVoxel[ind]
                  continue
                let canopyFirePos = (canopyGridTransform * (float3(float(x), float(y), float(z)) +
                  rnd_dir3() * rnd_float(-tree_burning_chain_manager__canopyBoxDisp, tree_burning_chain_manager__canopyBoxDisp)))
                var newFxPos = float4()
                newFxPos.xyz = canopyFirePos
                newFxPos.w = -1.
                push(tree_burning_chain__fireFxPoses, newFxPos)

    if tree_burning_chain__inited
      resize(tree_burning_chain__fireFxEids, length(tree_burning_chain__fireFxPoses))
      if tree_burning_chain_manager__debugOn
        for pos in tree_burning_chain__fireFxPoses
          draw_debug_sphere_buffered(pos.xyz, 0.3, pos.w > 0. ? E3DCOLOR(0xFFFFFF00) : E3DCOLOR(0xFFFF0000), 12, tree_burning_chain_manager__framesForDebug)
    else
      remove_tree_chain_handle(tree_burning_chain__treeHandle)
      destroyEntity(eid)
    return tree_burning_chain__inited

[es(on_appear, tag=server)]
def init_tree_burning_chain_speeds(evt : Event;
                                   var tree_burning_chain_manager__fireFxTurnOnSpeed : float&)
  query() <| $ [es] (tree_burning__fire_spread_speed : float)
    tree_burning_chain_manager__fireFxTurnOnSpeed *= tree_burning__fire_spread_speed

[es(tag=server, track=(tree_burning_chain__fireSources, tree_burning_chain__inited), REQUIRE=tree_burning_chain__inited)]
def init_fire_poses_burning_on_time_on_new_fires_source_add(evt : Event;
                                                            tree_burning_chain__fireSources : Point4List;
                                                            tree_burning_chain__fireFxEids : EidList;
                                                            var tree_burning_chain__fireFxPoses : Point4List)
  query() <| $ [es] (tree_burning_chain_manager__fireFxTurnOnSpeed : float)
    for fireFxPos, ind in tree_burning_chain__fireFxPoses, count()
      if !!tree_burning_chain__fireFxEids[ind]
        continue
      var minTime = 1000000.
      for fireSource in tree_burning_chain__fireSources
        minTime = min(fireSource.w + length(fireFxPos.xyz - fireSource.xyz) / tree_burning_chain_manager__fireFxTurnOnSpeed, minTime)
      fireFxPos.w = sign(fireFxPos.w) * minTime

[es(no_order, tag=server)]
def tree_burning_chain_update_es(info : ParallelUpdateFrameDelayed;
                                 eid : EntityId;
                                 tree_burning_chain__deathTime : float;
                                 tree_burning_chain__inited : bool;
                                 tree_burning_chain__isBush : bool;
                                 tree_burning_chain__fireFxPoses : Point4List;
                                 var tree_burning_chain__fireFxEids : EidList&)
  if !tree_burning_chain__inited
    return
  if info.curTime > tree_burning_chain__deathTime
    for fireFx in tree_burning_chain__fireFxEids
      destroyEntity(fireFx)
    destroyEntity(eid)
    return

  query() <| $ [es] (tree_burning_chain_manager__canopyFxName : string;
                     tree_burning_chain_manager__bushEffectLifeTime : float;
                     tree_burning_chain_manager__trunkFxName : string)
    let len = length(tree_burning_chain__fireFxPoses)
    var tm = IDENT_TM
    for i in range(len)
      let ind = len - 1 - i
      if abs(tree_burning_chain__fireFxPoses[ind].w) < info.curTime && !tree_burning_chain__fireFxEids[ind]
        tm[3] = tree_burning_chain__fireFxPoses[ind].xyz
        tree_burning_chain__fireFxEids[ind] = createEntity(tree_burning_chain__fireFxPoses[ind].w < 0. ? tree_burning_chain_manager__canopyFxName : tree_burning_chain_manager__trunkFxName) <| $(var init : ComponentsInitializer)
          set(init, "transform", tm)
          if tree_burning_chain__isBush
            set(init, "game_effect__timeToDestroy", tree_burning_chain_manager__bushEffectLifeTime)

[es(tag=server)]
def destroy_fire_fx_on_tree_destroy(evt : EventRendinstDestroyed)
  var pos = float3()
  var isBush = false
  find_query() <| $ [es] (var tree_burning_chain_manager__destroyedChainsHandles : UInt64List&;
                          tree_burning_chain_manager__destroyFx : string;
                          var tree_burning_chain_manager__destroyedChainsPoses : Point3List&)
    let ind = find_index(tree_burning_chain_manager__destroyedChainsHandles, evt.riexHandle)
    if ind != -1
      pos = tree_burning_chain_manager__destroyedChainsPoses[ind]
      erase(tree_burning_chain_manager__destroyedChainsPoses, ind)
      erase(tree_burning_chain_manager__destroyedChainsHandles, ind)

    find_query() <| $ [es] (eid : EntityId;
                            tree_burning_chain__treeHandle : riex_handle_t;
                            transform : float3x4;
                            tree_burning_chain__isBush : bool;
                            tree_burning_chain__fireFxEids : EidList)
      if tree_burning_chain__treeHandle == evt.riexHandle
        for fireFx in tree_burning_chain__fireFxEids
          destroyEntity(fireFx)
        destroyEntity(eid)
        pos = transform[3]
        isBush = tree_burning_chain__isBush
      return tree_burning_chain__treeHandle == evt.riexHandle
    if pos != float3() && !isBush
      createEntity(tree_burning_chain_manager__destroyFx) <| $(var init : ComponentsInitializer)
        var tm = IDENT_TM
        tm[3] = pos
        set(init, "transform", tm)
    return true