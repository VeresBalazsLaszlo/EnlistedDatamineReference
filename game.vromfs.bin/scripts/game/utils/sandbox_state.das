module sandbox_state shared
require DagorSystem

def is_sandbox_enabled() : bool
  return has_value(get_command_line_arguments(), "-devMode")
