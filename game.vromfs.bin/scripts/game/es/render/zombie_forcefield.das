require ecs
require AnimV20
require DngDm
require DagorShaders
require DagorMaterials
require DagorMath

let
  forcefield_colorVarId = get_shader_variable_id("forcefield_color", true)

[es(tag=render, on_appear, REQUIRE=zombie_forcefield, track=render_forcefield__color)]
def set_zombie_forcefield_params_es(evt : Event;
                                    render_forcefield__color : float4)
  assume color = render_forcefield__color
  DagorShaders::set_float4(forcefield_colorVarId, color.x, color.y, color.z, color.w)