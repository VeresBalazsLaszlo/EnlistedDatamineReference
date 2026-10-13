from "%dngscripts/platform.nut" import is_sony, is_gdk
from "dagor.debug" import logerr
from "%ui/ui_library.nut" import *

local openConsumable = @() logerr("[Console Store][Consumable] Not supported platform")
local openBundles = @() logerr("[Console Store][Bundles] Not supported platform")
local openBundle = @(id) logerr($"[Console Store][Bundle] Not supported platform {id}")

if (is_gdk) {
  let store = require("%ui/consoleStore/consoleStoreXbox.nut")
  
  openConsumable = @() store.show_details("9N1V69DPV83B")
  openBundles = @() store.show_marketplace(store.PKDurable)
  openBundle = @(id) store.show_details(id)
}
else if (is_sony) {
  let store = require("%ui/consoleStore/consoleStorePsn.nut")
  openConsumable = @() store.show_category("ENLISTEDGOLD")
  openBundles = @() store.show_category("ENLISTEDSQUADS")
  openBundle = @(id) store.show_pack_by_id(id)
}

return {
  openConsumable
  openBundles
  openBundle
}
