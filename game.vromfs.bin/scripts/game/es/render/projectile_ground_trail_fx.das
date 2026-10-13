// Copyright (C) Gaijin Games KFT.  All rights reserved.

require ecs
require fx
require math.base
require DagorSystem
require BallisticsProps
require DaWeaponProps
require DaWeapons
require enlisted.events_enlisted


[es(tag=render, on_appear, REQUIRE_NOT=staticEffect)]
def projectile_ground_trail_init(evt : Event;
                                 launch_desc : LaunchDesc;
                                 @shared_comp projectile_ground_trail_fx__caliberThresholds : FloatList;
                                 @shared_comp projectile_ground_trail_fx__effectTemplates : StringList;
                                 var projectile_ground_trail_fx__effect : das_string&;
                                 var projectile_ground_trail_fx__fxEid : EntityId&)
  if int(get_fx_target()) <= int(FxQuality FX_QUALITY_MEDIUM)
    return
  projectile_get_props(int(launch_desc.shellId.shellId)) <| $(props : ProjectileProps)
    for threshold, tmpl in projectile_ground_trail_fx__caliberThresholds, projectile_ground_trail_fx__effectTemplates
      if props.caliber <= threshold
        if !empty(tmpl)
          projectile_ground_trail_fx__effect := tmpl
          projectile_ground_trail_fx__fxEid = createEntity(string(tmpl)) <| $(var init)
            set(init, "transform", launch_desc.tm)
        return


[es(tag=render, on_disappear)]
def projectile_ground_trail_destroy(evt : Event;
                                    projectile_ground_trail_fx__fxEid : EntityId)
  destroyEntity(projectile_ground_trail_fx__fxEid)


[es(tag=render, after=update_projectile_es)]
def projectile_ground_trail_update(info : ParallelUpdateFrameDelayed;
                                   projectile__visualPos : float3;
                                   projectile_ground_trail_fx__fxEid : EntityId)
  query(projectile_ground_trail_fx__fxEid) <| $ [es] (var effect : TheEffect&)
    var tm = IDENT_TM
    tm[3] = projectile__visualPos
    effect_set_emitter_tm(effect, tm)
