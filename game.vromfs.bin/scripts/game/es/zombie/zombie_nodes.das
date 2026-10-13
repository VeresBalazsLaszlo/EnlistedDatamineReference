options always_export_initializer = true

require ecs
require BehNodes
require DagorDataBlock
require debug.logerr_once
require HumanPhys
require DngHuman
require RiDestr
require RendInst
require Dacoll
require DagorDebug3D

[beh_node(name="findDestructableNearTarget")]
class findDestructableNearTarget : BehNodeAdapter
  traceDist : float = 1.0
  targetParam : string
  @hidden targetParamHash : uint

  def override loadFromBlk(var data : DataBlock)
    traceDist = data |> datablock_getReal("traceDist", traceDist)
    data |> load_ecs_param("targetParam", targetParam, targetParamHash, thisNode)

  def override update(dt : float) : EBehResult
    var res : EBehResult = EBehResult.ER_FAILED
    let eid = beh_tree_eid(owner)
    let targetPosRef = eid |> get_Eid(targetParam, targetParamHash)
    if targetPosRef == null
      logerr_once("{eid}: checkDistanceToPos can't to find target position '{targetParam}:{targetParamHash}' {*thisNode |> beh_node_hierarchy_name(true)}")
      return res
    query(beh_tree_eid(owner)) <| $ [es] (agent_dangers__standShootPos : float3)
      query(*targetPosRef) <| $ [es] (transform : float3x4)
                                     // var human_net_phys : HumanActor)
        var len = length(transform[3] - agent_dangers__standShootPos)
        if len < traceDist
          var norm : float3
          var pmid : int
          var riDesc = RendInstDesc()
          let dir = normalize(transform[3] - agent_dangers__standShootPos)
          if traceray_normalized(agent_dangers__standShootPos, dir, len, pmid, norm, ETF_RI, riDesc, -1)//, human_phys_getTraceHandle(human_net_phys.phys))
            if riDesc.isValid && !riex_isImmortal(uint(riDesc.pool))
              res = EBehResult.ER_SUCCESS
    return res
