import "%dngscripts/ecs.nut" as ecs
from "settings" import get_setting_by_blk_path, set_setting_by_blk_path
from "%ui/state/violenceState.nut" import violenceState, violenceStateUpdate
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionCheckBox, optionCtor
from "%dngscripts/platform.nut" import ps4RegionName, SCE_REGION
from "%ui/ui_library.nut" import *

let { forcedViolenceState } = require("%ui/state/violenceState.nut")

let optionViolenceCtor = @(actionCb) function (opt, group, xmbNode) {
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
    @() get_setting_by_blk_path(blkPath) ?? true)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionViolenceCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
  })
}

let isOptionsAvailable = @() ecs.g_entity_mgr.getTemplateDB().getTemplateByName("violence_settings") != null

let violenceOptions = []
if (isOptionsAvailable()) {
  if (forcedViolenceState.isBloodEnabled == null)
    violenceOptions.append(mkOption(loc("gameplay/violence_blood"), "violence_blood", @(enabled) violenceStateUpdate(violenceState.get().__merge({isBloodEnabled = enabled}))))

  if (forcedViolenceState.isGoreEnabled == null)
    
    if (ps4RegionName != SCE_REGION.SCEJ)
      violenceOptions.append(mkOption(loc("gameplay/violence_gore"),  "violence_gore",  @(enabled) violenceStateUpdate(violenceState.get().__merge({isGoreEnabled = enabled}))))
    else {
      violenceStateUpdate(violenceState.get().__merge({isGoreEnabled = false}))
      set_setting_by_blk_path("gameplay/violence_gore", false)
    }
}

return { violenceOptions }