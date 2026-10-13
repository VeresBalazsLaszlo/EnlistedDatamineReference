require ecs
require ecs.common
require enlisted.events_enlisted
require game.es.camera_common
require DagorMath
require AnimV20

[es(tag=render, REQUIRE_NOT=animchar__actOnDemand, before=(animchar_es, net_phys_update_es))]
def update_animchar_dtThreshold_es(info : ParallelUpdateFrameDelayed;
                                   animchar__visible : bool;
                                   var animchar__dtThreshold : float&;
                                   animchar__invisDtThreshold : float = 0.4;
                                   animchar__minDtThreshold : float = 0.0)
  animchar__dtThreshold = animchar__visible ? animchar__minDtThreshold : max(animchar__invisDtThreshold, animchar__minDtThreshold)


[es(tag=render, before=(animchar_es, net_phys_update_es, update_animchar_dtThreshold_es))]
def update_animchar_visibility_es(info : UpdateStageInfoAct;
                                  var animchar__visible : bool&;
                                  animchar_visbits : animchar_visbits_t;
                                  animchar__considerAsVisible : Tag const?;
                                  animchar_render__enabled : bool = true;
                                  animchar_bbox : bbox3f const? = null;
                                  animchar__alwaysVisibleInRadiusSq = 0.)
  if animchar__considerAsVisible != null // need for some entites such as hero skeleton (no skip animchar update by threshold etc)
    animchar__visible = true
    return

  if !animchar_render__enabled
    animchar__visible = false
    return

  animchar__visible = (int(animchar_visbits) & (int(AnimcharVisbits.VISFLG_MAIN_CAMERA_RENDERED) |
                       int(AnimcharVisbits.VISFLG_CSM_SHADOW_RENDERED) | int(AnimcharVisbits.VISFLG_COCKPIT_VISIBLE) |
                       int(AnimcharVisbits.VISFLG_SEMI_TRANS_RENDERED) | int(AnimcharVisbits.VISFLG_RENDER_CUSTOM))) != 0

  if !animchar__visible && animchar__alwaysVisibleInRadiusSq > 0. && animchar_bbox != null
    animchar__visible = distance_sq(get_cam_itm()[3], (*animchar_bbox).bmin.xyz) < animchar__alwaysVisibleInRadiusSq
