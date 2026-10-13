require ecs
require AnimV20
require DagorShaders
require DagorMaterials
require DagorMath

[es(tag=render, tag=not_inside_tools, on_appear, after=vehicle_trails_create_emitter_es)]
def set_deform_hmap_params_es(evt : Event;
                              var animchar_render : AnimcharRendComponent&;
                              vehicle_trails__surface_pressure_mult : float)
  let paramsVarId = get_shader_variable_id("deform_hmap_pressure", true)
  recreate_material(animchar_render) <| $(mat)
    mat |> set_real_param(paramsVarId, vehicle_trails__surface_pressure_mult)
