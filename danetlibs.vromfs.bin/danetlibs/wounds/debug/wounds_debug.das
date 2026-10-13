options no_aot
require ecs
require DagorConsole
require DagorShaders

[console_cmd(name="wounds.debug_torn_wounds_mode", hint="<0 off, 1 coverage, 2 distance heatmap, 3 threshold bands>")]
def apply_torn_wounds_debug_mode_cmd(mode : int)
  DagorShaders::set_int(get_shader_variable_id("debug_torn_wounds"), mode)
  if mode != 0
    console_print("no effect while debug_torn_wounds is assumed (daNetGame/shaders/_build/common_assumes.blk); remove the assume and recompile shaders")
