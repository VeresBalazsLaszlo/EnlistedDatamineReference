from "%dngscripts/sound_system.nut" import sound_set_volume
from "%ui/ui_library.nut" import *

foreach (opt in ["MASTER","ambient","weapon","effects","voices","interface","music"]) {
  let capOpt = opt
  console_register_command(function(val) {sound_set_volume(capOpt, val)}, $"snd.set_volume_{opt}")
}
console_register_command(function(val) {sound_set_volume("MASTER", val)}, "snd.set_volume")
