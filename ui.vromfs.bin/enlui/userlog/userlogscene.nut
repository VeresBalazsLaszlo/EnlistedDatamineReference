import "%ui/control/gui_buttons.nut" as JB
import "%ui/userLog/userLogPurchasesUi.nut" as userLogPurchasesUi
import "%ui/userLog/userLogBattlesUi.nut" as userLogBattlesUi
import "%ui/components/mkWindowTab.nut" as mkWindowTab
from "%ui/components/textButton.nut" import Regular
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/style/designConst.nut" import defBgColor, blurBgColor, tinyOffset, smallOffset, smallPadding
from "%ui/userLog/userLogState.nut" import userLogsRequest, isUserLogsRequesting
from "%ui/ui_library.nut" import *

const USERLOG_WIDTH = fsh(100)

let isOpened = mkWatched(persist, "isOpened", false)
let curTabIdx = mkWatched(persist, "curTabIdx", 0)
let tabsList = [
  {
    locId = "userLog/purchases"
    content = userLogPurchasesUi
  }
  {
    locId = "userLog/battles"
    content = userLogBattlesUi
  }
]

function switchTab(newIdx){
  if (newIdx > tabsList.len()-1)
    newIdx = 0
  else if (newIdx < 0)
    newIdx = tabsList.len()-1
  if (tabsList?[newIdx] != null)
    curTabIdx.set(newIdx)
}

let prevTab = @() switchTab(curTabIdx.get() - 1)
let nextTab = @() switchTab(curTabIdx.get() + 1)

let tabsUi = @() {
  watch = [curTabIdx, isGamepad]
  rendObj = ROBJ_SOLID
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  color = defBgColor
  hotkeys = [["^J:RB | Tab", nextTab], ["^J:LB | L.Shift Tab", prevTab]]
  children = [isGamepad.get() ? mkHotkey("^J:LB", prevTab) : null].extend(
    tabsList.map(@(tab, idx)
      mkWindowTab(
        tab?.mkTitleComponent ?? loc(tab?.locId ?? ""),
        @() curTabIdx.set(idx),
        idx == curTabIdx.get(),
        { margin = [0, tinyOffset], skipDirPadNav=true},
        tab?.unseenWatch ?? Watched(null)
      )
    )
  )
  .append(isGamepad.get() ? mkHotkey("^J:RB", nextTab) : null)
}

let tabsContentUi = @() {
  watch = curTabIdx
  size = FLEX
  children = makeVertScroll({
      size = FLEX_H
      margin = [0,smallPadding,0,0]
      children = tabsList[curTabIdx.get()].content
    },
    { styling = thinStyle }
  )
}

let userLogWindow = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = [safeAreaBorders, isUserLogsRequesting, isGamepad]
  size = const [USERLOG_WIDTH, FLEX]
  key = isGamepad.get()
  flow = FLOW_VERTICAL
  gap = smallOffset
  margin = [safeAreaBorders.get()[0]+sh(2), safeAreaBorders.get()[1], safeAreaBorders.get()[0]+sh(7), safeAreaBorders.get()[1]]
  hplace = ALIGN_CENTER
  color = blurBgColor
  hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn"), action = @() isOpened.set(false)} ]]
  children = [
    tabsUi
    isUserLogsRequesting.get()
      ? null
      : tabsContentUi
    isGamepad.get() ? null : Regular(loc("BackBtn"), @() isOpened.set(false))
  ]
}

function open() {
  userLogsRequest()
  sceneWithCameraAdd(userLogWindow, "events")
}

function close() {
  sceneWithCameraRemove(userLogWindow)
}

if (isOpened.get())
  open()

isOpened.subscribe(@ (v) v ? open() : close())

console_register_command(@() isOpened.set(true), "ui.userLog")

return @() isOpened.set(true)
