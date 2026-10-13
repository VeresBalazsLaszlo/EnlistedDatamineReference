from "%ui/hud/state/entity_use_state.nut" import medkitEndTime, medkitStartTime
from "string" import format
from "%ui/ui_library.nut" import *

let timeStates = require("%ui/hud/state/time_state.nut")
let {curTime} = timeStates

const picSz = hdpxi(30)
let picProgress = Picture("ui/skin#round_border.svg:{0}:{0}".subst(picSz))

let bg ={rendObj = ROBJ_VECTOR_CANVAS color = Color(90,90,90,50) fillColor = Color(0,0,0,90) size=[picSz,picSz] commands=[[VECTOR_ELLIPSE, 50, 50, 100, 100]]}

const fgColor = Color(64,255,150)
const bgColor = Color(128,128,128)

let progress = @() {
  pos = const [0, hdpx(120)]
  size = const [picSz,picSz]
  children = [
    bg
    @(){
      rendObj = ROBJ_TEXT
      watch = [medkitEndTime, curTime]
      text = format("%.1f", max(medkitEndTime.get() - curTime.get(), 0.0))
      hplace=ALIGN_CENTER
      vplace = ALIGN_CENTER
    }
    @(){
      size = const [picSz*2,picSz*2]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      hplace=ALIGN_CENTER vplace = ALIGN_CENTER
      image = picProgress
      watch = [medkitStartTime, medkitEndTime, curTime]
      fgColor = fgColor
      bgColor = bgColor
      fValue = (curTime.get() - medkitStartTime.get()) / max(0.1, medkitEndTime.get() - medkitStartTime.get())
    }
  ]
}
let showMedkitUsage = Computed(@() medkitEndTime.get() > timeStates.curTime.get())
return function() {
  return {
    watch = showMedkitUsage
    children = showMedkitUsage.get() ? progress : null
  }
}
