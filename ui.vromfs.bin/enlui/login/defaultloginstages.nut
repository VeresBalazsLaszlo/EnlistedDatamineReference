import "%dngscripts/platform.nut" as platform
from "%enlSqGlob/offline_mode.nut" import disableRemoteNetServices
from "%ui/ui_library.nut" import *

return disableRemoteNetServices ? require("%ui/login/chains/login_pc.nut")
  : platform.is_gdk ? require("%ui/login/chains/login_xbox.nut")
  : platform.is_sony ? require("%ui/login/chains/login_sony.nut")
  : require("%ui/login/chains/login_pc.nut")
