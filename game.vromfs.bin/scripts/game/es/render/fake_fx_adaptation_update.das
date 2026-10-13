require ecs
require DagorSystem
require DngCamera
require CollRes
require fx
require ecs
require Grid
require Dacoll
require PhysMat

def get_background_pos_for_fx(len : float)
  var retval = float3(0, 0, 0)

  query(get_cur_cam_entity()) <| $ [es] (transform : float3x4)
    let startpos = transform[3]
    let dir = transform[2]
    retval = startpos + (len * 0.95) * dir

  return retval


[es(REQUIRE=hero, on_event=UpdateStageInfoBeforeRender)]
def es_name(evt : Event; human_weap__tracerayLen : float)
  let background_pos = get_background_pos_for_fx(human_weap__tracerayLen)
  query() <| $ [es] (var effect__background_pos : float3&)
    effect__background_pos = background_pos