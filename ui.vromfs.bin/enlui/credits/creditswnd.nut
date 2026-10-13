import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/components/spinner.nut" as spinner
import "%ui/components/closeBtn.nut" as closeBtnBase
from "%ui/components/mkDotPaginator.nut" import mkDotPages
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/style/designConst.nut" import smallPadding, bigGap, darkTxtColor, titleTxtColor,
  defTxtColor, hoverSlotBgColor, selectedPanelBgColor, fullTransparentBgColor, accentColor,
  transpBgColor, transpPanelBgColor
from "%ui/ui_library.nut" import *
from "%ui/credits/creditsState.nut" import isCreditsConfigLoaded, isCurCreditsLoading,
  creditsConfig, curDocument, curIndex, openCredits, resetCredits, curPage, totalPages


const WND_ID = "credits_window"
let creditsAreaSize = const [sw(55), sh(75)]

let isCreditsWindowOpened = mkWatched(persist, "isCreditsWindowOpened", false)
let creditsWindowOpen = @() isCreditsWindowOpened.set(true)
let creditsWindowClose = @() isCreditsWindowOpened.set(false)

let closeButton = closeBtnBase({ onClick = creditsWindowClose }).__update({ vplace = ALIGN_TOP })
let waitingSpinner = spinner()
let scrollHandler = ScrollHandler()

curPage.subscribe(@(_) scrollHandler.scrollToY(0))

function switchTab(delta) {
  let newIndex = curIndex.get() + delta
  if (newIndex >= 0 && newIndex < creditsConfig.get().len())
    openCredits(newIndex)
}

function mkSelectorTab(cfg, idx) {
  let text = loc(cfg.locId, cfg.name)
  let isCurrent = Computed(@() curIndex.get() == idx)

  function onClick() {
    if (isCurrent.get())
      return

    openCredits(idx)
    scrollHandler.scrollToY(0)
  }

  return watchElemState(@(sf) {
    watch = isCurrent
    size = FLEX
    maxWidth = hdpx(200)
    padding = smallPadding
    rendObj = ROBJ_BOX
    fillColor = sf & S_HOVER ? hoverSlotBgColor
      : isCurrent.get() ? selectedPanelBgColor
      : fullTransparentBgColor
    borderWidth = isCurrent.get() ? [0, 0, smallPadding, 0] : 0
    borderColor = accentColor
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    skipDirPadNav = false
    onClick
    children = {
      rendObj = ROBJ_TEXTAREA
      size = FLEX_H
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      color = sf & S_HOVER ? darkTxtColor
        : isCurrent.get() ? titleTxtColor
        : defTxtColor
      text
    }
  })
}

let hkClose = ["^Esc | Space", { action = creditsWindowClose, description = loc("mainmenu/btnClose") }]
let hkLB = ["^J:LB | Left", @() switchTab(-1), loc("shop/previousItem")]
let hkRB = ["^J:RB | Right", @() switchTab(1), loc("shop/nextItem")]

let creditsSelector =@() {
  watch = [isCreditsConfigLoaded, creditsConfig]
  size = const [FLEX, fsh(6)]
  flow = FLOW_HORIZONTAL
  children = !isCreditsConfigLoaded.get() ? null
    : creditsConfig.get().map(mkSelectorTab)
}

function creditsDocument() {
  local children = waitingSpinner
  if (isCreditsConfigLoaded.get() && !isCurCreditsLoading.get()) {
    children = [
      scrollbar.makeVertScroll({
        size = FLEX_H
        padding = smallPadding
        children = {
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          text = curDocument.get()
          behavior = Behaviors.TextArea
          color = defTxtColor
        }
      }, { scrollHandler })
    ]
    if (totalPages.get() > 1)
      children.append({
        size = const [SIZE_TO_CONTENT, fsh(4)]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = mkDotPages(curPage, totalPages.get())
      })
  }
  return {
    watch = [isCreditsConfigLoaded, isCurCreditsLoading, totalPages, curDocument]
    rendObj = ROBJ_SOLID
    color = transpBgColor
    size = creditsAreaSize
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = true
    children
  }
}

let creditsWindow = {
  size = FLEX
  behavior = Behaviors.Button
  sound = { click = "ui/enlist/button_click" }
  children = [
    {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = transpPanelBgColor
      flow = FLOW_VERTICAL
      padding = bigGap
      gap = bigGap
      children = [
        closeButton
        creditsDocument
        creditsSelector
      ]
    }
  ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hotkeys = [hkClose, hkLB, hkRB]
}

function open() {
  sceneWithCameraAdd(creditsWindow, WND_ID)
  openCredits(0)
}

function close() {
  sceneWithCameraRemove(creditsWindow)
  resetCredits()
}

isCreditsWindowOpened.subscribe(@ (v) v ? open() : close())


return {
  creditsWindowOpen
}