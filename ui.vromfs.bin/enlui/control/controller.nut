from "%dngscripts/gamepadConnection.nut" import register_for_input_devices_count_change
from "%ui/control/controllerDisconnected.nut" import controllerDisconnectedUpdate

register_for_input_devices_count_change(@(counts) controllerDisconnectedUpdate((counts?.gamepads ?? 0) == 0))