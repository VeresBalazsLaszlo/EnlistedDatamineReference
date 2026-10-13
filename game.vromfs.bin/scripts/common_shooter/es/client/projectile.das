require ecs
require fx
require math.base
require enlisted.events_enlisted


[es(tag=render, after=update_projectile_es)]
def effect_projectile_waiter_es(info : ParallelUpdateFrameDelayed;
                                eid : EntityId;
                                effect__templateAfterSuccessWait : string;
                                projectile__visualPos : float3)
  if length_sq(projectile__visualPos) > 0.0
    reCreateEntityFrom(eid, effect__templateAfterSuccessWait)


[es(tag=render, after=effect_projectile_waiter_es)]
def effect_projectile_es(info : ParallelUpdateFrameDelayed;
                         projectile__visualPos : float3;
                         var effect : TheEffect&)
  var newTm = IDENT_TM
  newTm[3] = projectile__visualPos
  effect_set_emitter_tm(effect, newTm)
