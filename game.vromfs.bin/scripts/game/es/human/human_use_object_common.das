module human_use_object_common shared
require ecs
require DngNet
require math.base
require game.es.events
require enlisted.events_enlisted


def check_use_dist(user_eid : EntityId; used_object_eid : EntityId) : bool
  var result = false
  query(user_eid) <| $ [es] (transform aka human_transform : float3x4; human_use_object__thresholdDist : float = 12.f)
    query(used_object_eid) <| $ [es] (transform : float3x4)
      result = length_sq(transform[3] - human_transform[3]) <= square(human_use_object__thresholdDist)
  return result

def human_try_use_object(user_eid : EntityId;
                         used_object_eid : EntityId;
                         alternative_use : bool = false)
  if check_use_dist(user_eid, used_object_eid)
    if has(used_object_eid, "customClientUsabilityCheck") && has(user_eid, "hero")
      sendEvent(user_eid, HumanUseObjectRequestClient(objectEid = used_object_eid))
    elif !is_server()
      if alternative_use
        send_net_event(user_eid, HumanUseObjectRequestAlt(objectEid = used_object_eid))
      else
        sendEvent(user_eid, HumanUseObjectRequest(objectEid = used_object_eid))
    else
      if alternative_use
        sendEvent(used_object_eid, CmdUseAlt(requesterEid = user_eid))
      else
        sendEvent(used_object_eid, CmdUse(requesterEid = user_eid))