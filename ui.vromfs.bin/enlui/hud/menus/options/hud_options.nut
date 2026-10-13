import "%dngscripts/platform.nut" as platform
from "settings" import get_setting_by_blk_path
from "%ui/hud/menus/options/options_lib.nut" import getOnlineSaveData, optionCheckBox, optionCtor
from "%ui/hud/state/hudOptionsState.nut" import hudMarkerEnable, minimalistHud, setShowBattleChat, forceDisableBattleChat, showSelfAwards, showTeammateName, showTeammateMarkers
  , showCrosshairHints, showTips, showGameModeHints, showPlayerUI
from "%ui/ui_library.nut" import *

let mkWidgetCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

function mkOption(title, field, defVal, actionCb, isAvailable = @() true) {
  let blkPath = $"gameplay/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? defVal)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = mkWidgetCtor(actionCb)
    var = watch
    setValue
    defVal
    blkPath
    isAvailable
  })
}

return {
  hudOptions = [
    mkOption(loc("gameplay/hud_markers"), "hud_markers", true, @(enabled) hudMarkerEnable.set(enabled))
    mkOption(loc("gameplay/show_teammate_name"), "show_teammate_name", true,
      @(enabled) showTeammateName.set(enabled))
    mkOption(loc("gameplay/show_teammate_markers"), "show_teammate_markers", true,
      @(enabled) showTeammateMarkers.set(enabled))
    mkOption(loc("gameplay/show_crosshair_hints"), "show_crosshair_hints", true,
      @(enabled) showCrosshairHints.set(enabled))
    mkOption(loc("gameplay/show_tips"), "show_tips", true,
      @(enabled) showTips.set(enabled))
    mkOption(loc("gameplay/show_game_mode_hints"), "show_game_mode_hints", true,
      @(enabled) showGameModeHints.set(enabled))
    mkOption(loc("gameplay/show_player_ui"), "show_player_ui", true,
      @(enabled) showPlayerUI.set(enabled))
    mkOption(loc("gameplay/minimalist_hud"), "minimalist_hud", false,
      @(enabled) minimalistHud.set(enabled))
    !platform.is_pc || forceDisableBattleChat.get()
      ? null
      : mkOption(loc("gameplay/show_battle_chat", "Show Battle Chat"), "show_battle_chat", true, setShowBattleChat)
    mkOption(loc("gameplay/self_awards"), "show_self_awards", true, @(enabled) showSelfAwards.set(enabled))
  ]
}