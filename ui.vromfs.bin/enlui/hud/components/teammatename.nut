from "%ui/ui_library.nut" import *
const fontFxFactor = min(hdpx(48), 64)
const fontSize = hdpx(21)
const fontFxColor = Color(0, 0, 0, 60)

return function teammateName(eid, name, color){
  if ((name ?? "") == "")
    return null
  return {
    rendObj = ROBJ_TEXT
    color
    text = name
    markerFlags = DngBhv.MARKER_KEEP_SCALE
    data = { eid }
    fontFx = FFT_BLUR
    fontFxColor
    fontFxFactor
    fontSize
    behavior = DngBhv.DistToPriority
    transform = true
  }
}