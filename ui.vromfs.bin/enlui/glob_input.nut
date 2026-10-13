from "screencap" import take_screenshot_nogui, take_screenshot
from "%ui/ui_library.nut" import *

let voiceHotkeys = require("%ui/voiceChat/voiceControl.nut")

let screenshotsEventHandlers = {
    ["Global.Screenshot"] = @(...) take_screenshot(),
    ["Global.ScreenshotNoGUI"] = @(...) take_screenshot_nogui()
  }
let eventHandlers = clone screenshotsEventHandlers
foreach (k, v in voiceHotkeys.eventHandlers)
  eventHandlers[k] <- v

return {
  globInput = {eventHandlers}
  screenshotsEventHandlers
}
