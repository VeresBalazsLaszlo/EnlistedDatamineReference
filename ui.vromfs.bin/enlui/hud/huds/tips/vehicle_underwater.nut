from "%ui/hud/state/vehicle_underwater_state.nut" import vehicleUnderWaterEndTime, vehicleUnderWaterMaxTime
from "string" import format
from "%ui/ui_library.nut" import *

let timeState = require("%ui/hud/state/time_state.nut")
let {curTime} = timeState
const picSz = hdpxi(30)
let picProgress = Picture("ui/skin#round_border.svg:{0}:{0}".subst(picSz))

let bg ={rendObj = ROBJ_VECTOR_CANVAS color = Color(90,90,90,50) fillColor = Color(0,0,0,90) size=[picSz,picSz] commands=[[VECTOR_ELLIPSE, 50, 50, 100, 100]]}

const fgColor = Color(230,30,150)
const bgColor = Color(128,128,128)

let progress = {
  pos = const [0, hdpx(120)]
  size = const [picSz,picSz]
  children = [
    bg
    @(){
      rendObj = ROBJ_TEXT
      watch = [vehicleUnderWaterEndTime, curTime]
      text = format("%.1f", max(vehicleUnderWaterEndTime.get() - curTime.get(), 0.0))
      hplace=ALIGN_CENTER vplace = ALIGN_CENTER}
    @(){
      size = const [picSz*2,picSz*2]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      hplace=ALIGN_CENTER vplace = ALIGN_CENTER
      image = picProgress
      watch = [vehicleUnderWaterEndTime, vehicleUnderWaterMaxTime, curTime]
      fgColor = fgColor
      bgColor = bgColor
      fValue = (vehicleUnderWaterEndTime.get() - curTime.get()) / vehicleUnderWaterMaxTime.get()
    }
  ]
}

let vehicleUnderWater = Computed(@() vehicleUnderWaterEndTime.get() > timeState.curTime.get())
return function() {
  return {
    watch = [vehicleUnderWater]
    children = vehicleUnderWater.get() ? progress : null
  }
}
