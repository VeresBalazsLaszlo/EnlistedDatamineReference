import "%ui/options/crossnetwork_save.nut" as saveCrossnetworkPlayValue
import "%ui/options/crossnetwork_chat_save.nut" as saveCrossnetworkChatValue
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, savedCrossnetworkPlayId, savedCrossnetworkStateUpdate, CrossplayState, savedCrossnetworkChatId, savedCrossnetworkChatStateUpdate, availableCrossplayOptions
  , isCrossplayOptionNeeded, isCrossnetworkChatOptionNeeded
from "%ui/hud/menus/options/options_lib.nut" import optionSpinner, defCmp, optionCtor, optionCheckBox, getOnlineSaveData, mkDisableableCtor
from "%ui/state/queueState.nut" import isInQueue
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated, settings
from "settings" import get_setting_by_blk_path
from "%ui/squad/squadState.nut" import selfMemberState, isSquadLeader
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let settingsCrossnetworkPlay = Computed(function() {
  local val = null
  if (onlineSettingUpdated.get())
    val = settings.get()?[savedCrossnetworkPlayId]

  if (val == null)
    val = get_setting_by_blk_path(savedCrossnetworkPlayId)

  return val
})

let settingsCrossnetworkChat = Computed(function() {
  local val = null
  if (onlineSettingUpdated.get())
    val = settings.get()?[savedCrossnetworkChatId]

  if (val == null)
    val = get_setting_by_blk_path(savedCrossnetworkChatId) ?? true

  return val
})

function setValBySettings(val) {
  if (!onlineSettingUpdated.get())
    return
  savedCrossnetworkStateUpdate(val)
}

subscribeAndInit(setValBySettings, settingsCrossnetworkPlay)
onlineSettingUpdated.subscribe(@(val) val ? setValBySettings(settingsCrossnetworkPlay.get()) : null)


function setValChatBySettings(val) {
  if (!onlineSettingUpdated.get())
    return
  savedCrossnetworkChatStateUpdate(val)
}

subscribeAndInit(setValChatBySettings, settingsCrossnetworkChat)

let isOptionActive = Computed(@() !isInQueue.get()
  && (isSquadLeader.get() || !selfMemberState.get()?.ready))

let mkOptionCrossplayOption = @() {
  name = loc("gameplay/crossnetwork_play"),
  hint = loc("guiHints/crossnetwork_play"),
  tab = "Game",
  widgetCtor = mkDisableableCtor(
    Computed(@() isOptionActive.get() ? null : loc("options/blocked_in_queue")),
    optionSpinner)
  originalVal = CrossplayState.ALL,
  var = crossnetworkPlay,
  available = availableCrossplayOptions,
  isEqual = defCmp,
  setValue = saveCrossnetworkPlayValue,
  valToString = @(v) loc($"option/crossplay/{v}")
  isAvailableWatched = isCrossplayOptionNeeded
}

function mkOptionCrosschatOption() {
  let { watch, setValue } = getOnlineSaveData(savedCrossnetworkChatId,
    @() get_setting_by_blk_path(savedCrossnetworkChatId) ?? true)
  return optionCtor({
    name = loc("gameplay/crossnetwork_chat")
    tab = "Game"
    widgetCtor = optionCheckBox
    var = watch
    setValue = @(val) saveCrossnetworkChatValue(val, setValue)
    blkPath = savedCrossnetworkChatId
    isAvailableWatched = Computed(@() isCrossplayOptionNeeded.get() && isCrossnetworkChatOptionNeeded)
  })
}

return { crossnetworkOptions = [
  mkOptionCrossplayOption()
  isCrossnetworkChatOptionNeeded ? mkOptionCrosschatOption() : null
]}