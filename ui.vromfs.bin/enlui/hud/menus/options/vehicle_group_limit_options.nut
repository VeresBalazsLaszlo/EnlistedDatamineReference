import "%ui/hud/menus/options/vehicleGroupLimitState.nut" as vehicleGroupLimit
import "%dngscripts/ecs.nut" as ecs
from "settings" import get_setting_by_blk_path
from "dasevents" import sendNetEvent, CmdLimitVehicleByGroup
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionCheckBox, optionCtor
from "%ui/ui_library.nut" import *

let localPlayerQuery = ecs.SqQuery("localPlayerQuery", {comps_rq = ["localPlayer"]})

vehicleGroupLimit.subscribe(function(v) {
  localPlayerQuery.perform(@(eid, _comp) sendNetEvent(eid, CmdLimitVehicleByGroup({isLimited=v})))
})

let optionLimitVehicleByGroupCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

function mkOption(title, field, actionCb) {
  let blkPath = $"gameplay/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? false)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionLimitVehicleByGroupCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
  })
}

return [
  mkOption(loc("gameplay/limit_vehicle_by_group"), "limit_vehicle_by_group", @(enabled) vehicleGroupLimit.set(enabled))
]
