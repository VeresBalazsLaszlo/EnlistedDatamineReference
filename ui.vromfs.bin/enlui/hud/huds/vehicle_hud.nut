from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/state/vehicle_view_state.nut" import enabled, gear, neutralGear, rpm, cruiseControl, speed, isAutomaticTransmission
from "%ui/hud/state/vehicle_state.nut" import isVehicleAlive
from "%ui/ui_library.nut" import *

let mkText = @(txt) {
  rendObj = ROBJ_TEXT
  text = txt
  padding = const [0, hdpx(2)]
  minHeight = fsh(2)
  valign = ALIGN_BOTTOM
}.__update(fontSub)

let mkLabel = @(txt) mkText(txt).__update({ minWidth = fsh(4) })

const CRUISE_CONTROL_MAX = 3

function mkGear(g, neutral) {
  return g < neutral ? $"{loc("vehicle_hud/GearR")}{neutral-g}"
    : g == neutral ? loc("vehicle_hud/GearN")
    : $"{g-neutral}"
}

let mkCruiseControl = @(cc) cc < 0 ? loc("vehicle_hud/CcR")
  : cc >= CRUISE_CONTROL_MAX ? loc("vehicle_hud/CcMax")
  : $"{cc}"

let vehicleGearInfo = @() {
  watch = [gear, neutralGear]
  flow = FLOW_HORIZONTAL
  children = [
    mkLabel(loc("vehicle_hud/Gear"))
    mkText(mkGear(gear.get(), neutralGear.get()))
  ]
}

let vehicleRpmInfo = @() {
  watch = rpm
  flow = FLOW_HORIZONTAL
  children = [
    mkLabel(loc("vehicle_hud/Rpm"))
    mkText($"{rpm.get()}")
  ]
}

let vehicleSpeedInfo = @() {
  watch = speed
  flow = FLOW_HORIZONTAL
  children = [
    mkLabel(loc("vehicle_hud/Spd"))
    mkText($"{speed.get()} {loc("vehicle_hud/Kmh")}")
  ]
}

let vehicleTransmissionInfo = @() {
  watch = [isAutomaticTransmission, cruiseControl]
  flow = FLOW_HORIZONTAL
  children = !isAutomaticTransmission.get()
    ? null
    : [
        mkLabel(loc("vehicle_hud/Cc"))
        mkText(mkCruiseControl(cruiseControl.get()))
      ]
}

let vehicleHudComponents = [
  vehicleGearInfo
  vehicleRpmInfo
  vehicleSpeedInfo
  vehicleTransmissionInfo
]

return @() {
  flow = FLOW_VERTICAL
  watch = [enabled, isVehicleAlive]
  children = !enabled.get() || !isVehicleAlive.get() ? null : vehicleHudComponents
}