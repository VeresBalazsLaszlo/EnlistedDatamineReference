from "%ui/hud/state/spectator_state.nut" import isSpectator
from "%ui/hud/state/human_teammates.nut" import teammatesAliveNum
from "%ui/ui_library.nut" import *

let hasSpectatorKeys = Computed(@() isSpectator.get()  && teammatesAliveNum.get() > 1)

return hasSpectatorKeys