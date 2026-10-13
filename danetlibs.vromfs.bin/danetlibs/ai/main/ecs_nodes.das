options always_export_initializer = true
require ecs
require ecs.common
require ecs.safe
require app
require math.base
require strings
require BehNodes
require walkerai
require DngWalkerai
require DagorDataBlock
require DagorSystem
require DagorMath
require debug.logerr_once
require danetlibs.ai.main.ecs_nodes_common


def load_compare_node_ex_side(data : DataBlock;
                              use_self : bool;
                              agent_eid : EntityId;
                              var from_eid_proxy : RealParamProxy&;
                              var value_proxy : RealParamProxy&;
                              var blackboard : DataBlock;
                              var def_val : double&;
                              var use_def_val : bool&;
                              value_name : string;
                              int_param_name : string;
                              real_param_name : string;
                              eid_name : string;
                              eid_param_name : string;
                              default_value_param_name : string)
  let defValParamIdx = data |> datablock_find_param(default_value_param_name)
  use_def_val = defValParamIdx >= 0
  if use_def_val
    def_val = double(datablock_getReal(data, defValParamIdx))

  // Check for literal values first - these don't require an entity
  let paramIdx = data |> datablock_find_param(value_name)
  if paramIdx >= 0
    let paramType = data |> datablock_getParamType(uint(paramIdx))
    if paramType == int(DataBlockParamType.TYPE_INT)
      value_proxy |> RealParamProxy_loadLiteral(double(data |> datablock_getInt(paramIdx)))
      from_eid_proxy |> RealParamProxy_loadLiteral(double(uint(agent_eid)))
      return
    elif paramType == int(DataBlockParamType.TYPE_REAL)
      value_proxy |> RealParamProxy_loadLiteral(double(data |> datablock_getReal(paramIdx)))
      from_eid_proxy |> RealParamProxy_loadLiteral(double(uint(agent_eid)))
      return
    elif paramType == int(DataBlockParamType.TYPE_BOOL)
      let boolValue = data |> datablock_getBool(paramIdx)
      value_proxy |> RealParamProxy_loadLiteral(double(boolValue ? 1 : 0))
      from_eid_proxy |> RealParamProxy_loadLiteral(double(uint(agent_eid)))
      return

  if use_self
    from_eid_proxy |> RealParamProxy_loadLiteral(double(uint(agent_eid)))
    value_proxy |> RealParamProxy_loadFromBlk(data, value_name, agent_eid, int_param_name, real_param_name, blackboard, def_val, use_def_val)
  else
    from_eid_proxy |> RealParamProxy_loadFromBlk(data, eid_name, agent_eid, eid_param_name, "", blackboard)
    value_proxy |> RealParamProxy_preloadEcsParamFromBlk(data, value_name)


/* Supported params:
  lhs/ rhs:
    lhs:i=234
    lhs:r=234.0
    lhs:t="ecs param (int or float)"
    lhsIntParam_thisAgent:t="bb int param" // Use together with 'lhsUseSelf:b=true' !
    lhsRealParam_thisAgent:t="bb float param" // Use together with 'lhsUseSelf:b=true' !

  lhsUseSelf:b=true - use agent's own eid (act as CompareNode)

  if 'lhsUseSelf' is false or unspecified, use either of these
        to specify the entity from which lhs:t will be taken:

    lhsEid:t="ecs param (EntityId)"
    lhsEidParam:t="bb int param storing eid"

  lhsDefaultValue:r=0.0 - fallback if component is missing on target (otherwise logs error like CompareNode)
   operator:t=">="
*/
[beh_node(name="compareNodeEx")]
class CompareNodeEx : BehNodeAdapter
  lhs : RealParamProxy
  rhs : RealParamProxy
  lhsFromEid : RealParamProxy
  rhsFromEid : RealParamProxy
  lhsDefaultValue : double
  rhsDefaultValue : double
  lhsUseDefaultValue : bool
  rhsUseDefaultValue : bool
  compare : function<(a, b : float) : bool> = @@compare_not_equal
  lastLhs : float
  lastRhs : float

  def override loadFromBlk(var data : DataBlock)
    let agentEid = beh_tree_eid(owner)
    let operatorStr = datablock_getStr(data, "operator", "")
    compare = parse_comparison_operator(operatorStr)

    load_compare_node_ex_side(data, datablock_getBool(data, "lhsUseSelf", false),
                              agentEid, lhsFromEid, lhs, owner.blackBoard, lhsDefaultValue, lhsUseDefaultValue,
                              "lhs", "lhsIntParam_thisAgent", "lhsRealParam_thisAgent", "lhsEid", "lhsEidParam", "lhsDefaultValue")
    load_compare_node_ex_side(data, datablock_getBool(data, "rhsUseSelf", false),
                              agentEid, rhsFromEid, rhs, owner.blackBoard, rhsDefaultValue, rhsUseDefaultValue,
                              "rhs", "rhsIntParam_thisAgent", "rhsRealParam_thisAgent", "rhsEid", "rhsEidParam", "rhsDefaultValue")

  def override update(dt : float) : EBehResult
    let ownerEid = beh_tree_eid(owner)

    let lhsRawEid = RealParamProxy_get(lhsFromEid, ownerEid, owner.blackBoard)
    let rhsRawEid = RealParamProxy_get(rhsFromEid, ownerEid, owner.blackBoard)
    let lhsTargetEid = EntityId(uint(lhsRawEid))
    let rhsTargetEid = EntityId(uint(rhsRawEid))

    if ownerEid != lhsTargetEid
      if !RealParamProxy_fetchEcsParam(lhs, lhsTargetEid, lhsDefaultValue, lhsUseDefaultValue)
        lhs = RealParamProxy(0) // Avoid logerr spam
        return EBehResult.ER_FAILED

    if ownerEid != rhsTargetEid
      if !RealParamProxy_fetchEcsParam(rhs, rhsTargetEid, rhsDefaultValue, rhsUseDefaultValue)
        rhs = RealParamProxy(0)
        return EBehResult.ER_FAILED

    lastLhs = float(RealParamProxy_get(lhs, lhsTargetEid, owner.blackBoard))
    lastRhs = float(RealParamProxy_get(rhs, rhsTargetEid, owner.blackBoard))

    return compare(lastLhs, lastRhs) ? EBehResult.ER_SUCCESS : EBehResult.ER_FAILED
