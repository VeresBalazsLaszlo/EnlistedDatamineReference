from "%dngscripts/platform.nut" import is_windows
from "videomode" import get_video_modes
from "%ui/hud/menus/options/monitor_state.nut" import monitorValue
from "dagor.system" import get_primary_screen_info
from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *
from "types" import Array

const RESOLUTIONS = [ [1024,768], [1280,720], [1280,1024], [1920,1080], [1920,1200],
  [2520,1080], [2560,1440], [3840,1080], [3840,2160] ]

const defVideoMode = "fullscreenwindowed" 
let originalValVideoMode = get_setting_by_blk_path("video/mode") ?? defVideoMode
let videoModeVar = Watched(originalValVideoMode)
let isExclusiveFullscreen = Computed(@() videoModeVar.get() == "fullscreen")

function getResolutions(monitor) {
  local { list, current } = get_video_modes(monitor)

  
  if (is_windows && list.len() <= 2) {
    let newList = list.filter(@(v) v instanceof Array)
    local maxRes = newList?[newList.len() - 1]
    if (maxRes == null) {
      try {
        let { pixelsWidth, pixelsHeight } = get_primary_screen_info()
        maxRes = [ pixelsWidth, pixelsHeight ]
      }
      catch(e) { 
        return { list, current }
      }
    }
    let resolutions = RESOLUTIONS.filter(@(v) v[0] <= maxRes[0] && v[1] <= maxRes[1]
      && newList.findvalue(@(r) r[0] == v[0] && r[1] == v[1]) == null)
    newList.extend(resolutions)
    newList.sort(@(a, b) a[0] <=> b[0] || a[1] <=> b[1])
    newList.insert(0, "auto")
    list = newList
  }

  return { list, current }
}


local availableResolutions = getResolutions(monitorValue.get())

let resolutionList = Watched(availableResolutions.list)
let resolutionValue = Watched(availableResolutions.current)

monitorValue.subscribe(function(val) {
  availableResolutions = getResolutions(val)
  resolutionList.set(availableResolutions.list)
  resolutionValue.set("auto")
})

return {
  resolutionList
  resolutionValue
  defVideoMode
  originalValVideoMode
  videoModeVar
  isExclusiveFullscreen
}