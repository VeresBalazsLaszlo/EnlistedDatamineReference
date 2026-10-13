require game.es.sandbox_config_common
require daslib/quirrel_boost
require enlisted.game.utils.sandbox_state

[quirrel_bind(module_name="das.sandbox_config")]
def is_sandbox_context() : bool
  return is_sandbox_enabled()

[quirrel_bind(module_name="das.sandbox_config")]
def sandbox_config_get_int_value(name : string; defval : int) : int
  return sandbox_config_get_int(name, defval)

[quirrel_bind(module_name="das.sandbox_config")]
def sandbox_config_get_string_value(name : string; defval : string) : string
  return sandbox_config_get_string(name, defval)
