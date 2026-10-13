require ecs
require fx
require math.base
require DagorMath
require DngPlane


[es(tag=render, no_order)]
def plane_wreck_fx_update(info : UpdateStageInfoAct;
                          plane_wreck_fx__effect : string;
                          plane_wreck_fx__effect_ttl : float;
                          transform : float3x4;
                          plane_net_phys : PlaneActor;
                          var plane_wreck_fx__fxEid : EidList&;
                          var plane_wreck_fx__ttl : FloatList&;
                          plane_cutting__largePartsCut : BoolList;
                          plane_cutting__cuttingPlanes : Point4List)
  for cut, fxEid, plane, ttl in plane_cutting__largePartsCut, plane_wreck_fx__fxEid, plane_cutting__cuttingPlanes, plane_wreck_fx__ttl
    if cut
      let offset = -plane.w * plane.xyz
      var offsetTm = IDENT_TM
      offsetTm[3] = offset
      let effectTm = transform * offsetTm
      if fxEid == INVALID_ENTITY_ID && ttl <= plane_wreck_fx__effect_ttl
        fxEid = createEntity(plane_wreck_fx__effect) <| $(var init)
          set(init, "transform", effectTm)
      ttl += info.dt
      if fxEid != INVALID_ENTITY_ID
        if ttl > plane_wreck_fx__effect_ttl
          destroyEntity(fxEid)
          fxEid = INVALID_ENTITY_ID
        else
          query(fxEid) <| $ [es] (var effect : TheEffect&)
            effect_set_emitter_tm(effect, effectTm)
            let vel = float3(plane_net_phys.phys.currentState.velocity)
            effect_set_velocity(effect, vel)
    else
      if fxEid != INVALID_ENTITY_ID
        destroyEntity(fxEid)
        fxEid = INVALID_ENTITY_ID
      ttl = 0.0


[es(tag=render, on_appear)]
def plane_wreck_fx_init(evt : Event;
                        var plane_wreck_fx__fxEid : EidList&;
                        var plane_wreck_fx__ttl : FloatList&;
                        plane_cutting__largePartsCut : BoolList)
  plane_wreck_fx__fxEid |> resize(length(plane_cutting__largePartsCut))
  for val in plane_wreck_fx__fxEid
    val = INVALID_ENTITY_ID
  plane_wreck_fx__ttl |> resize(length(plane_cutting__largePartsCut))
  for val in plane_wreck_fx__ttl
    val = 0.0
