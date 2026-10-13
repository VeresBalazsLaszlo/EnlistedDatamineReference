require ecs
require gameLibs.render_events.render_events


// flyingTurret has animchar__updatable=false and not animchar__actOnDemand tag, so animchar_before_render_es's
// shadow_cast_dist invalidate (gated on `actOnDemand || updatable`) skips it. Do it explicitly.
[es(tag=render, after=animchar_before_render_es, REQUIRE=flyingTurret)]
def flying_turret_shadow_invalidate_es(info : UpdateStageInfoBeforeRender;
                                       var animchar_render__shadow_cast_dist : float&)
  animchar_render__shadow_cast_dist = -1.0
