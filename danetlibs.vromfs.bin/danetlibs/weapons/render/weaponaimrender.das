require ecs
require AnimV20
require math.base
require DagorMath


[es(tag=render, on_appear)]
def scope_zoom_anim_init(evt : Event;
                         var animchar : AnimcharBaseComponent;
                         var gunmod__scopeAnimParamId : int&)
  if animchar.animGraph == null
    return
  gunmod__scopeAnimParamId = *animchar.animGraph |> anim_graph_getParamId("scope_zoom_anim", int(PT_ScalarParam))


[es(tag=render, no_order)]
def scope_zoom_anim_update(info : UpdateStageInfoAct;
                           gunmod__scopeAnimParamId : int;
                           gunmod__zoomFactor : float;
                           var animchar : AnimcharBaseComponent;
                           gunmod__minVariableZoomFactor : float = -1.0;
                           gunmod__maxVariableZoomFactor : float = -1.0)
  if gunmod__scopeAnimParamId < 0 || animchar.animState == null
    return
  let minZoom = gunmod__minVariableZoomFactor > 0.0 ? gunmod__minVariableZoomFactor : gunmod__zoomFactor
  let maxZoom = gunmod__maxVariableZoomFactor > 0.0 ? gunmod__maxVariableZoomFactor : gunmod__zoomFactor
  let value = cvt(gunmod__zoomFactor, minZoom, maxZoom, 0.0, 1.0)

  *animchar.animState |> anim_state_holder_setParam(gunmod__scopeAnimParamId, value)
