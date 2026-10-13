import "%dngscripts/platform.nut" as platform
from "%ui/ui_library.nut" import *

require("%ui/connectingToServerMsg.nut")
require("%ui/notifications/disconnectedControllerMsg.nut")
require("%ui/soldiers/newItemsWnd.nut")
require("%ui/soldiers/receivedSquadsWnd.nut")
require("%ui/shop/dropRouletteWindow.nut")



if (platform.is_gdk)
  require("%ui/gdk/rateGame.nut")
