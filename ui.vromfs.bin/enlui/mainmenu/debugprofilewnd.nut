import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/meta/servProfile.nut" as servProfile
from "%ui/components/debugWnd.nut" import openDebugWnd
from "%ui/ui_library.nut" import *

let combined = servProfile.__merge({ userInfo })
let tabs = combined.keys()
  .sort(@(a, b) a <=> b)
  .map(@(n) { id = n, data = combined[n], maxItems = 100 })

return @() openDebugWnd({
  wndUid = "debug_profile_wnd"
  tabs = tabs
})
