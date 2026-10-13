import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/navState.nut" import addScene, removeScene
from "%ui/changelog.ui.nut" import currentPatchnote, patchnoteSelector
from "%ui/components/textButton.nut" import Regular
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/changeLogState.nut" import chosenPatchnote, curPatchnoteIdx, nextPatchNote,
  prevPatchNote, updateVersion, markLastSeen, changelogDisabled, needShowPatchnote, setViewedTs
from "%ui/components/wndManager.nut" import registerWnd, Wnd, WndEvents
from "%ui/components/wndPermissionFlags.nut" import canShowWindows, autoClose
from "%ui/style/designConst.nut" import transpPanelBgColor
from "%ui/ui_library.nut" import *

let isOpened = mkWatched(persist, "isOpened", false)

let btnStyle = {
  size = FLEX_H
}

function close() {
  markLastSeen()
  isOpened.set(false)
}
let open = @() isOpened.set(true)

const gap = hdpx(10)
let btnNext  = Regular(loc("shop/nextItem"), nextPatchNote,
  btnStyle.__merge({hotkeys = [["Enter"]]}))
let btnClose = Regular(loc("mainmenu/btnClose"), close,
  btnStyle.__merge({hotkeys=[[$"^{JB.B} | Esc"]]}))
let closeBtn = fontIconButton("close", {
  skipDirPadNav = true
  onClick = close
  hplace = ALIGN_RIGHT
  hotkeys=[[$"^{JB.B} | Esc", {description=loc("Close")}]]
})

let nextButton = @() {
  size = SIZE_TO_CONTENT
  minWidth = hdpxi(155)
  children = curPatchnoteIdx.get() != 0 ? btnNext : btnClose
  watch = curPatchnoteIdx
  hplace = ALIGN_RIGHT
  onAttach = function(elem) {
    if (isGamepad.get()) {
      move_mouse_cursor(elem, false)
    }
  }
}

let attractorForCursorDirPad = {
  behavior = Behaviors.Button
  size = const [hdpx(50), ph(66)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  eventPassThrough = true
}

let hkLB = ["^J:LB | Left", prevPatchNote, loc("shop/previousItem")]
let hkRB = ["^J:RB | Right", nextPatchNote, loc("shop/nextItem")]

let clicksHandler = {
  size = FLEX
  eventPassThrough = true
  behavior = Behaviors.Button
  hotkeys = [hkLB, hkRB]
  onClick = nextPatchNote
}

let changelogRoot = {
  size = FLEX
  children = [
    clicksHandler
    {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = transpPanelBgColor
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      padding = gap
      gap = gap
      children = [
        closeBtn
        currentPatchnote
        @() {
          watch = isGamepad
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          gap = gap
          valign = ALIGN_CENTER
          children = [
            patchnoteSelector
            isGamepad.get() ? null : nextButton
          ]
        }
      ]
    }
    attractorForCursorDirPad
  ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hotkeys = [
    ["Esc | Space", {action=close, description = loc("mainmenu/btnClose")}]
  ]
}

let addLogScene = @() addScene(changelogRoot)
if (isOpened.get())
  addLogScene()
isOpened.subscribe(function(opened) {
  if (opened) {
    addLogScene()
    return
  }
  updateVersion()
  chosenPatchnote.set(null)
  removeScene(changelogRoot)
})

let needOpenChangelog = registerWnd({
  dataWatch = Computed(@() needShowPatchnote.get() && !changelogDisabled)
  showWatch = canShowWindows
  closeWatch = autoClose
  name = Wnd.CHANGELOG
  handlers = { [WndEvents.SUPPRESS] = setViewedTs }
})

needOpenChangelog.subscribe(function(v) {
  if (!v)
    return
  open()
  setViewedTs()
})

return {
  openChangelog = open
}
