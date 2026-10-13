import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/components/spinner.nut" as spinner
from "%ui/components/formatText.nut" import formatText
from "%ui/changeLogState.nut" import curPatchnote, chosenPatchnoteContent, selectPatchnote, chosenPatchnoteTitle, chosenPatchnoteLoaded, versions, patchnotesReceived, extNewsUrl
from "%ui/style/designConst.nut" import smallPadding, titleTxtColor, defTxtColor, transpBgColor, weakTxtColor, accentColor, hoverSlotBgColor
  , darkTxtColor, fullTransparentBgColor, selectedPanelBgColor
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/meta/tutorial/meta_tutorial_utils.nut" import processHyphenations
from "%ui/ui_library.nut" import *
from "types" import Array







let waitingSpinner = spinner()

let scrollHandler = ScrollHandler()

function onTabClicked(v) {
  if (curPatchnote.get() != v) {
    selectPatchnote(v)
    scrollHandler.scrollToY(0)
  }
}

function mkVersionTab(v) {
  let isCurrent = Computed(@() curPatchnote.get() == v)
  let group = ElemGroup()
  return watchElemState(@(sf) {
    watch = isCurrent
    rendObj = ROBJ_BOX
    size = FLEX
    valign = ALIGN_CENTER
    group
    behavior = Behaviors.Button
    fillColor = sf & S_HOVER ? hoverSlotBgColor
      : isCurrent.get() ? selectedPanelBgColor
      : fullTransparentBgColor
    borderWidth = isCurrent.get() ? [0, 0, hdpx(4), 0] : 0
    borderColor = accentColor
    onClick = @() onTabClicked(v)
    skipDirPadNav = false 
    maxWidth = hdpx(200)
    padding = smallPadding
    children = {
      rendObj = ROBJ_TEXTAREA
      size = FLEX_H
      group
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      color = sf & S_HOVER ? darkTxtColor
        : isCurrent.get() ? titleTxtColor
        : defTxtColor
      text = v?.titleshort ?? v.tVersion
    }
  })
}

let missedPatchnoteText = formatText([loc("NoUpdateInfo", "Oops... No information yet :(")])
let isVersionsExists = Computed(@() versions.get().len() > 0)

let patchnoteSelector = @() {
  watch = [versions, patchnotesReceived, isVersionsExists, isGamepad]
  size = const [FLEX, fsh(6)]
  flow = FLOW_HORIZONTAL
  halign = isGamepad.get() ? ALIGN_CENTER : ALIGN_LEFT
  onAttach = function(){
    if (patchnotesReceived.get() && curPatchnote.get()!=null)
      selectPatchnote(curPatchnote.get())
  }
  children = patchnotesReceived.get() && isVersionsExists.get()
    ? (clone versions.get()).reverse().map(mkVersionTab)
    : missedPatchnoteText
}

let seeMoreUrl = {
  t="url"
  platform="pc,ps4"
  url=extNewsUrl
  v=loc("visitGameSite", "See game website for more details")
  margin = const [hdpx(50), 0, 0, 0]
}

let patchnoteLoading = freeze({
  flow  = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(20)
  valign = ALIGN_CENTER size = const [FLEX, fsh(20)]
  padding = fsh(2)
  children = [
    formatText([{v = loc("Loading"), t = "h2", halign = ALIGN_CENTER}])
    waitingSpinner
  ]
})

function currentPatchnote(){
  local text = chosenPatchnoteContent.get() ?? ""
  if (text == "")
    text = missedPatchnoteText
  if (!(text instanceof Array))
    text = [text, seeMoreUrl]
  else
    text = (clone text).append(seeMoreUrl)
  if (chosenPatchnoteTitle.get() != "")
    text = [{v = chosenPatchnoteTitle.get(), t="h1"}].extend(text)
  text = processHyphenations(text)
  return {
    rendObj = ROBJ_SOLID
    color = transpBgColor
    watch = [chosenPatchnoteLoaded, chosenPatchnoteContent, chosenPatchnoteTitle, curPatchnote]
    children = scrollbar.makeVertScroll({
      size = FLEX_H
      padding = smallPadding
      children = chosenPatchnoteLoaded.get()
        ? [{
            rendObj = ROBJ_TEXT
            text = curPatchnote.get()?.date.split("T")[0]
            hplace = ALIGN_RIGHT
            color = weakTxtColor
          }].append(formatText(text))
        : patchnoteLoading
    }, { scrollHandler })
    size = const [sw(55), sh(75)]
  }
}

return {
  currentPatchnote
  patchnoteSelector
}
