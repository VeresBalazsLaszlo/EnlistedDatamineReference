from "%ui/hud/state/revive_syringe_use_state.nut" import reviveSyringeEndTime, reviveSyringeStartTime
from "string" import format
from "%ui/style/fontsStyle.nut" import fontBody
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
  hplace=ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    bg
    @(){
      rendObj = ROBJ_TEXT
      watch = [reviveSyringeEndTime, curTime]
      text = format("%.1f", max(reviveSyringeEndTime.get() - curTime.get(), 0.0))
      hplace=ALIGN_CENTER
      vplace = ALIGN_CENTER
    }
    @(){
      size = const [picSz*2,picSz*2]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      hplace=ALIGN_CENTER vplace = ALIGN_CENTER
      image = picProgress
      watch = [reviveSyringeStartTime, reviveSyringeEndTime, curTime]
      fgColor = fgColor
      bgColor = bgColor
      fValue = (curTime.get() - reviveSyringeStartTime.get()) / max(0.1, reviveSyringeEndTime.get() - reviveSyringeStartTime.get())
    }
  ]
}

let reviveSyringeUsageTip = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = loc("tips/revive_syringe_from_teammate")
  textColor = Color(200,40,40,110)
}.__update(fontBody)


let reviveSyringeUsage = Computed(@() reviveSyringeEndTime.get() > timeStates.curTime.get())
return function() {
  return {
    watch = reviveSyringeUsage
    children = [
      reviveSyringeUsage.get() ? reviveSyringeUsageTip : null
      reviveSyringeUsage.get() ? progress : null
    ]
  }
}
