require ecs
require app
require DngHuman
require AnimV20
require GeomNodeTree
require common_sounds.modules.common_sounds_events
require ecs.safe
require daslib/strings_boost
require danetlibs.package_soldier.render.fx.footstep_events
require math.base
require Dacoll
require DagorMath
require game.es.camera_common

[es(tag=gameClient, REQUIRE_NOT=deadEntity, REQUIRE=irqFootsteps)]
def human_footsteps_fx_irq(evt : CmdSoundStepIrq;
                           footprint_emitter__left_foot_node : int;
                           footprint_emitter__right_foot_node : int;
                           eid : EntityId;
                           var human_net_phys : HumanActor&;
                           transform : float3x4;
                           animchar : AnimcharBaseComponent;
                           footstep__maxDistanceFromCameraToUpdate : float;
                           footstep_fx__time_interval : float;
                           var footstep_fx__next_times : float2&;
                           @shared_comp human_steps_sound__irqs : Array)
  if length_sq(transform[3] - get_cam_itm()[3]) > square(footstep__maxDistanceFromCameraToUpdate)
    return

  let irqName = split((human_steps_sound__irqs?[evt.objIdx] ?as Object).irq ?? "", "_")[0]
  var nodeInd = -1
  var nodeId = -1
  if irqName == "left"
    nodeId = footprint_emitter__left_foot_node
    nodeInd = 0
  elif irqName == "right"
    nodeId = footprint_emitter__right_foot_node
    nodeInd = 1
  else
    return
  if get_sync_time() < footstep_fx__next_times[nodeInd]
    return
  footstep_fx__next_times[nodeInd] = get_sync_time() + footstep_fx__time_interval
  var nodeWtm = IDENT_TM
  geomtree_getNodeWtmScalar(*animchar.nodeTree, nodeId, nodeWtm)
  var t = 0.3
  let dir = float3(0., -1., 0.)
  var norm = float3()
  var pmid : int
  var riDesc = RendInstDesc()
  if traceray_normalized(nodeWtm[3], dir, t, pmid, norm, ETF_DEFAULT, riDesc, human_net_phys.phys.rayMatId, human_net_phys.phys |> human_phys_getTraceHandle())
    let intersect = nodeWtm[3] + dir * t
    sendEvent(eid, EventFootStep(pos = intersect, normal = norm, direction = nodeWtm[2], nodeId = nodeId))
