import "%ui/hud/huds/vehicle_change_indicator.nut" as indicatorCtor
from "%ui/hud/state/enter_exit_vehicle.nut" import enterVehicleState, exitVehicleState
from "%ui/ui_library.nut" import *

let enterTotalTime = Computed(@() enterVehicleState.get()?.enterTotalTime ?? 0.0)
let enterStartTime = Computed(@() enterVehicleState.get()?.enterStartTime ?? 0.0)
let enterEndTime = Computed(@() enterStartTime.get() + enterTotalTime.get())

let exitTotalTime = Computed(@() exitVehicleState.get()?.exitTotalTime ?? 0.0)
let exitStartTime = Computed(@() exitVehicleState.get()?.exitStartTime ?? 0.0)
let exitEndTime = Computed(@() exitStartTime.get() + exitTotalTime.get())

return {
  enterVehicleIndicator = indicatorCtor(enterEndTime, enterTotalTime, loc("vehicle/hint/enter", "Enter"))
  exitVehicleIndicator = indicatorCtor(exitEndTime, exitTotalTime, loc("vehicle/hint/exit", "Exit"))
}