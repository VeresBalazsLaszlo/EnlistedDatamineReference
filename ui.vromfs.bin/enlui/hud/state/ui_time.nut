from "dagor.time" import get_time_msec
from "%ui/ui_library.nut" import *

let cTime = Watched(0)
function updateCtime(){
  cTime.set((get_time_msec()/1000).tointeger())
}
gui_scene.setInterval(1, updateCtime)

return {
  curTimePerSec = cTime
}