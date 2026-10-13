#default:forbid-root-table

from "%ui/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs
from "frp" import warn_on_deprecated_methods,
  set_slow_subscriber_threshold_usec, get_slow_subscriber_threshold_usec
from "settings" import get_setting_by_blk_path
from "modules" import on_module_unload
from "dagor.system" import DBGLEVEL

warn_on_deprecated_methods( DBGLEVEL>0)

require("%enlSqGlob/offline_mode.nut")

ecs.clear_vm_entity_systems()

require("%dngscripts/globalState.nut").setUniqueNestKey("Enlist")
require("%enlSqGlob/sqevents.nut")
let {logerr, clear_logerr_interceptors} = require("dagor.debug")
let {scan_folder} = require("dagor.fs")
require("%ui/sound_console.nut")
require("%ui/ui_config.nut")
require("%ui/sound_handlers.nut")
clear_logerr_interceptors()
let {safeAreaAmount,safeAreaVerPadding, safeAreaHorPadding} = require("%ui/state/safeArea.nut")

console_register_command(@() dump_observables(), "script.dump_observables")

let slowComputed = get_slow_subscriber_threshold_usec()
let slowComputedThreshold = get_setting_by_blk_path("debug/slowComputedThreshold")
if (slowComputedThreshold != null)
  set_slow_subscriber_threshold_usec(slowComputedThreshold)
else
  set_slow_subscriber_threshold_usec(100_000_000)
on_module_unload(@(...) set_slow_subscriber_threshold_usec(slowComputed))


let use_realfs = (DBGLEVEL > 0) ? true : false
let files = scan_folder({root=$"%ui/es", vromfs = true, realfs = use_realfs, recursive = true, files_suffix=".nut"})
foreach (i in files) {
  try {
    require(i)
  } catch (e) {
    logerr($"UI module {i} was not loaded - see log for details")
  }
}

try{
  require("%ui/hud/onHudScriptLoad.nut")
}
catch(e){
  log(e)
  logerr("onHudScriptLoad was not loaded - see log for details")
}

let {isCursorNeeded} = require("%ui/showCursor.nut")
let {msgboxes} = require("%ui/msgboxes.nut")
let {uiDisabled, levelLoaded, isInBattleState} = require("%ui/state/appState.nut")
let {loadingUI, showLoading} = require("%ui/loading/loading.nut")
let { hotkeysButtonsBar } = require("%ui/hotkeysPanel.nut")
let {editorActivness, uiInEditor} = require("%ui/state/editorState.nut")
let {serviceInfo} = require("%ui/service_info.nut")
let {canShowReplayHud, canShowGameHudInReplay} = require("%ui/hud/replay/replayState.nut")
let {isReplay} = require("%ui/hud/state/replay_state.nut")

let hud = function(){
  try {
    return require("%ui/hud.nut")
  }
  catch(e){
    log(e)
    logerr("errr loading hud.nut")
  }
}()

let {editor, editorOverlay, editorModeLabel} = require("%ui/editor.nut")
let {sandboxEditorEnabled, sandboxEditor} = require("%ui/sandbox_editor.nut")
let {extraPropPanelCtors = null} = require("%daeditor/state.nut")
if (extraPropPanelCtors!=null)
  extraPropPanelCtors.set([require("%ui/components/extraIcon3DView.nut")])

require("%ui/getAppIdsList.nut").setAppIdsList([1131, 1132, 1168, 1178])
require("%ui/onScriptLoad.nut")

require("%sqstd/regScriptDebugger.nut")(debugTableData)



log($"loading enlist VM")
require("%ui/voiceChat/voiceStateHandlers.nut")
require("%ui/state/roomState.nut")

let {dbgSafeArea} = require("%ui/dbgSafeArea.nut")
let friendlyErrorsBtn = require("%ui/friendly_logerr.ui.nut")
let platform = require("%dngscripts/platform.nut")
let cursors = require("%ui/style/cursors.nut")
let {modalWindowsComponent} = require("%ui/components/modalWindows.nut")
let {isLoggedIn} = require("%ui/state/login_state.nut")
let mainScreen = require("%ui/mainScreen.nut")
let {inspectorRoot} = require("%darg/helpers/inspector.nut")
let {globInput, screenshotsEventHandlers} = require("%ui/glob_input.nut")
require("daRg.debug").requireFontSizeSlot(DBGLEVEL>0 && VAR_TRACE_ENABLED) 
let {popupBlock} = require("%ui/popup/popupBlock.nut")
let registerScriptProfiler = require("%sqstd/regScriptProfiler.nut")
let {underUiLayer, aboveUiLayer} = require("%ui/uiLayers.nut")
let { fadeBlackUi } = require("%ui/fadeToBlack.nut")
let {getCurrentLoginUi, loginUiVersion} = require("%ui/login/currentLoginUi.nut")
let version_info = require("%ui/components/versionInfo.nut")
let {noServerStatus, saveDataStatus} = require("%ui/mainMenu/info_icons.nut")
let speakingList = require("%ui/speaking_list.nut")
let modsDownloadInfo = require("%ui/gameModes/sandbox/modsDownloadInfo.ui.nut")
let { steam_is_running = @() false } = require_optional("steam")

let {mkSettingsMenuUi, showSettingsMenu} = require("%ui/hud/menus/settings_menu.nut")
let settingsMenuUi = mkSettingsMenuUi({
  onClose = @() showSettingsMenu.set(false)
})
let {controlsMenuUi, showControlsMenu} = require("%ui/hud/menus/controls_setup.nut")

if (platform.is_gdk)
  require("%ui/gdk/onLoad.nut")
else if (platform.is_sony)
  require("%ui/sony/onLoad.nut")
else if (steam_is_running())
  require("%ui/steam/onLoadSteam.nut")
if (platform.is_gdk || platform.is_sony)
  require("%ui/invitation/onInviteAccept.nut")


require("%ui/netUtils.nut")
require("%ui/autoexec.nut")
require("%ui/charClient/charClient.nut")
require("%ui/chat/chatState.nut").subscribeHandlers()
let {fpsBar, latencyBar} = require("%ui/fpsBar.nut")

let serviceInfoOutBattle = !(platform.is_pc || DBGLEVEL > 0) ? null : {
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(2)
  children = [fpsBar, latencyBar]
}

registerScriptProfiler("enlist")

let underUi = @(){
  size = FLEX
  watch = underUiLayer.generation
  children = underUiLayer.getComponents()
}

let aboveUi = @(){
  size = FLEX
  watch = aboveUiLayer.generation
  children = aboveUiLayer.getComponents()
}

let logerrsUi = @(){
  watch = safeAreaAmount
  halign = ALIGN_RIGHT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER size = [sw(100)*safeAreaAmount.get(), sh(100)*safeAreaAmount.get()]
  children = friendlyErrorsBtn
}

let infoIcons = @(){
  margin = [max(safeAreaVerPadding.get()/2.0,fsh(2)), max(safeAreaHorPadding.get()/1.2,fsh(2))]
  watch = [safeAreaHorPadding, safeAreaVerPadding]
  children = [noServerStatus, saveDataStatus]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
}

let loginScreen = @(){
  watch = loginUiVersion
  children = getCurrentLoginUi()
  size = FLEX
}

function curScreen(){
  local children
  if (showSettingsMenu.get())
    children = settingsMenuUi
  else if (showControlsMenu.get())
    children = controlsMenuUi
  else if (isLoggedIn.get() == false)
    children = loginScreen
  else
    children = mainScreen
  return {
    size = FLEX
    onAttach = function(){
      log($"Enlist UI started")
    }
    watch = [isLoggedIn, showControlsMenu, showSettingsMenu]
    children
  }
}

function battleUi() {

  let children = uiDisabled.get() ? [{eventHandlers = screenshotsEventHandlers}] : (showLoading.get() || !levelLoaded.get())
      ? [ loadingUI, speakingList, msgboxes, globInput ]
      : [
          hud
          modalWindowsComponent
          msgboxes
          hotkeysButtonsBar
          speakingList
          globInput
        ]


  if (editorActivness.get() && !uiInEditor.get())
    children.replace([globInput])

  if (!uiDisabled.get() && levelLoaded.get())
    children.append(serviceInfo)
  if (isReplay.get()) {
    let idxToRemove = children.findindex(@(v) v == hotkeysButtonsBar)
    if (idxToRemove != null)
      children.remove(idxToRemove)
    children.append({
      eventHandlers = {
        ["Replay.DisableHUD"] = @(_event) canShowReplayHud.set(!canShowReplayHud.get()),
        ["Replay.DisableGameHUD"] = @(_event) canShowGameHudInReplay.set(!canShowGameHudInReplay.get())
      }
    })
  }

  return {
    watch = [uiDisabled, editorActivness, uiInEditor, isReplay, levelLoaded, showLoading]
    size = FLEX
    children
  }
}

let outOfBattleChildren = freeze([
  globInput, fadeBlackUi, underUi, curScreen, version_info, aboveUi, modalWindowsComponent,
  msgboxes, popupBlock, speakingList, logerrsUi, infoIcons, inspectorRoot, serviceInfoOutBattle,
  hotkeysButtonsBar, modsDownloadInfo
])

let showCursor = Computed(@() !isInBattleState.get() || (isCursorNeeded.get() && !editorActivness.get()))
let showUi = Computed(@() !editorActivness.get() || uiInEditor.get())

return @() {
  cursor = showCursor.get() ? cursors.normal : null
  watch = [ showCursor, isInBattleState, showUi, editorActivness, sandboxEditorEnabled ]
  children = []
    .extend(!showUi.get()
      ? []
      : isInBattleState.get()
        ? [battleUi]
        : outOfBattleChildren
    ).append(dbgSafeArea, editorActivness.get() ? editor : null,
              editorActivness.get() && !sandboxEditorEnabled.get() ? editorOverlay : null,
              editorActivness.get() ? editorModeLabel : null,
              sandboxEditorEnabled.get() ? sandboxEditor : null)
}
