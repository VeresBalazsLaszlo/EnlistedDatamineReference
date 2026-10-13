options no_aot

require ecs.fs
require ECSGlobalTags

[export]
def load_animation_test_behaviour(base_path : string) : bool
  var ok = true

  if ecs_has_tag("render")  || is_in_aot()
    if (ecs_has_tag("dev") && typeinfo builtin_module_exists(DngActor) && typeinfo builtin_module_exists(DngHuman))
      ok = load_sub_folder(base_path, "debug") && ok

  return ok



