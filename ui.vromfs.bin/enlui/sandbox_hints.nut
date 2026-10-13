import "%daeditor/components/textButton.nut" as textButton
import "%ui/components/checkbox.nut" as checkbox
from "%daeditor/components/window.nut" import registerWindow, hideWindow, showWindow
from "%ui/editor.nut" import editorIsActive
from "%ui/ui_library.nut" import *
from "%darg/laconic.nut" import *

let entity_editor = require_optional("entity_editor")

const EDITOR_HINT_WINDOW_ID = "editor_hint_window"

let hintShown = Watched(false)
let hintMessage = Watched("")
let hintWarning = Watched(false)
local hintCb = @() null

let hintStep = mkWatched(persist, "hintStep", 0)
local wasStartHintClosed = false

let hintWelcomeKeepShowing = Watched(true)
const SETTING_EDITOR_WELCOME_HINT = "daEditor/sandboxWelcomeHint"
let { save_settings=null, get_setting_by_blk_path=null, set_setting_by_blk_path=null } = require_optional("settings")
hintWelcomeKeepShowing.set(get_setting_by_blk_path?(SETTING_EDITOR_WELCOME_HINT) ?? true)
hintWelcomeKeepShowing.subscribe(function(v) {
  set_setting_by_blk_path?(SETTING_EDITOR_WELCOME_HINT, v)
  save_settings?()
})

function showHintWindow() {
  showWindow(EDITOR_HINT_WINDOW_ID)
}

function close() {
  wasStartHintClosed = true
  hintShown.set(false)
  hideWindow(EDITOR_HINT_WINDOW_ID)
  gui_scene.resetTimeout(0.3, @() hintCb())
}

let hintWindow = registerWindow({
  id = EDITOR_HINT_WINDOW_ID
  windowStyle = {fillColor = Color(40,40,40,120)}
  initialSize = [sw(32), sh(26)]
  minSize     = [sw(32), sh(26)]
  maxSize     = [sw(32), sh(26)]
  content = @() {
    flow  = FLOW_VERTICAL
    size = FLEX_H
    gap  = hdpx(2)
    watch = [hintWarning, hintStep, hintMessage]
    halign = ALIGN_CENTER
    children = [
      hflow( Gap(hdpx(5)), VACenter, Size(FLEX, SIZE_TO_CONTENT), Padding(hdpx(5),hdpx(5)), RendObj(ROBJ_SOLID), Colr(60,60,90),
        txt(!hintWarning.get() ? "Sandbox" : "Sandbox Warning"),
        hintStep.get() == 1 ? { size = FLEX_H } : null,
        hintStep.get() == 1 ? checkbox(hintWelcomeKeepShowing, {text = "Show at startup"}) : null
      )
      {
        size = const [sw(30), sh(15)]
        children = {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = FLEX_H
          padding = const [hdpx(4), hdpx(3)]
          margin = const [hdpx(30), 0]
          color = Color(255,255,255)
          text = hintMessage.get()
          valign = ALIGN_TOP
        }
      }
      textButton("Continue", close, {hotkeys = [["Esc"]]})
    ]
    onClose = close
  }
})

function showHintMessage(text, callback=@() null) {
  showHintWindow()
  hintMessage.set(text)
  hintWarning.set(false)
  hintShown.set(true)
  hintCb = callback
}

function showHintWarning(text, callback=@() null) {
  showHintWindow()
  hintMessage.set(text)
  hintWarning.set(true)
  hintShown.set(true)
  hintCb = callback
}


function showHintCheckRespawns() {
  if (!editorIsActive.get() || hintStep.get() != 2)
    return
  local has_respawns = entity_editor?.get_instance()?.checkSceneEntities("respbase") ?? false
  hintStep.set(-1)
  if (!has_respawns)
    showHintWarning("Mission is missing respawn points.\n\nPlease, add at least one Mission respawn point.")
}

function showHintCheckTeams() {
  if (!editorIsActive.get() || hintStep.get() != 1)
    return
  local has_teams  = entity_editor?.get_instance()?.checkSceneEntities("teamTag") ?? false
  hintStep.set(2)
  if (!has_teams)
    showHintWarning("Mission is missing players teams.\n\nPlease, add at least one Mission team.", showHintCheckRespawns)
  else
    showHintCheckRespawns()
}

editorIsActive.subscribe(function(_v) {
  if (hintShown.get())
    return
  
  if (hintStep.get() == 1)
    gui_scene.resetTimeout(0.1, showHintCheckTeams)
  else if (hintStep.get() == 2)
    gui_scene.resetTimeout(0.1, showHintCheckRespawns)
})


function showHints() {
  if (hintStep.get() > 0)
    return

  hintStep.set(1)
  if (hintWelcomeKeepShowing.get())
    showHintMessage("Welcome to Enlisted Sandbox.\n\nPress F12 to toggle open editor. Then F1 for help.\nPlease, read accompanying documentation for more detailed information.", showHintCheckTeams)
  else
    showHintCheckTeams()
}

return {
  showHints
  hintShown
  hintWindow
  hintWelcomeKeepShowing
  wasStartHintClosed = @() wasStartHintClosed
}
