from "%dngscripts/platform.nut" import is_pc, is_gdk
from "%ui/ui_library.nut" import *

local buyAccess = null
if (is_pc && !is_gdk) {
  let { openUrl } = require("%ui/components/openUrl.nut")
  buyAccess = @() openUrl("https://enlisted.net/#!/cbt/shop")
}
else
  buyAccess = require("%ui/consoleStore/consoleStore.nut").openBundles

return buyAccess