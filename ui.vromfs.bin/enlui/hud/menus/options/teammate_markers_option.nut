from "settings" import set_setting_by_blk_path
from "%ui/hud/menus/options/options_lib.nut" import optionCtor, optionSpinner
from "%ui/state/teammate_markers_state.nut" import teammateMarkersState, teammateMarkersStateUpdate, TeammateMarkers
from "%ui/ui_library.nut" import *

let optionTeammateMarkersCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionSpinner(opt, group, xmbNode)
}

let names = {
  [TeammateMarkers.INDEX_COLOR] = "option/markers_index_color",
  [TeammateMarkers.COLOR] = "option/markers_color",
  [TeammateMarkers.INDEX] = "option/markers_index",
  [TeammateMarkers.DEFAULT] = "option/markers_default",
}

let mkOption = @(title, field, watch, actionCb)
  optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionTeammateMarkersCtor(actionCb)
    var = watch
    setValue = @(v) set_setting_by_blk_path(field, v)
    blkPath = field
    reload = false
    restart = false
    available = [TeammateMarkers.INDEX_COLOR, TeammateMarkers.COLOR, TeammateMarkers.INDEX, TeammateMarkers.DEFAULT]
    valToString = @(id) loc(names[id])
  })

let teammateMarkersOption = mkOption(loc("options/teammate_markers"),
  "teammateMarkers", teammateMarkersState, teammateMarkersStateUpdate)

return {
  teammateMarkersOption
}
