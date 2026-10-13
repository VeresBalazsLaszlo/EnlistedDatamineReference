import "%ui/hud/state/isAnyMenuVisible.nut" as isAnyMenuVisible
from "%ui/hud/state/vehicle_state.nut" import inTank, inPlane
from "%ui/ui_library.nut" import *

return {
  isVisible = Computed(@() (inTank.get() || inPlane.get()) && !isAnyMenuVisible.get())
}