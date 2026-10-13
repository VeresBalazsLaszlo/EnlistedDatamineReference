import "%ui/hud/huds/immunity_marks.nut" as immunityMarks
from "%ui/hud/huds/crosshair.nut" import mkCrosshair, mkCrosshairElement

let crosshairImmunityMarks = mkCrosshair(@() [immunityMarks], [])

return mkCrosshairElement(crosshairImmunityMarks)