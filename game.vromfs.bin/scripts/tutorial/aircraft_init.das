options no_aot

require app
require ecs.fs
require ECSGlobalTags

[init]
def load
  var ok = true

  if ecs_has_tag("gameClient") || is_in_aot()
    ok = load_folder("%scripts/tutorial/es/aircraft") && ok
    ok = load_folder("%scripts/tutorial/es/common") && ok

  if is_in_aot()
    assert(ok)
