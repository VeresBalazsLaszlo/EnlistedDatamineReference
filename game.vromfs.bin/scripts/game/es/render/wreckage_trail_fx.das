require ecs
require math.base
require DagorRandom
require strings
require fx


def update_effect(fx_tm : float3x4;
                  fx_velocity : float3;
                  fx_eid : EntityId&)
  query(fx_eid) <| $ [es] (var effect : TheEffect&)
    effect_set_emitter_tm(effect, fx_tm)
    effect_set_velocity(effect, fx_velocity)

[es(tag=render, on_disappear)]
def wreckage_trail_on_disappear(evt : Event;
                                wreckage_trail__fxEid : EntityId)
  destroyEntity(wreckage_trail__fxEid)


[es(tag=render, after=wreckage_phys_es)]
def wreckage_trail_on_update(info : UpdateStageInfoAct;
                             transform : float3x4;
                             plane_wreckage__offset : float3;
                             plane_wreckage__vel : float3;
                             wreckage_trail__effects : StringList;
                             var wreckage_trail__fxEid : EntityId&;
                             var wreckage_trail__isEffectsStarted : bool&)
  var offsetTm = IDENT_TM
  offsetTm[3] = plane_wreckage__offset
  let effectTm = transform * offsetTm
  if !wreckage_trail__isEffectsStarted
    let effectIndex = min(rnd_int(0, length(wreckage_trail__effects)), length(wreckage_trail__effects) - 1)
    wreckage_trail__fxEid = createEntity(string(wreckage_trail__effects[effectIndex])) <| $(var init)
      set(init, "transform", effectTm)
    wreckage_trail__isEffectsStarted = true
  update_effect(effectTm, plane_wreckage__vel, wreckage_trail__fxEid)
