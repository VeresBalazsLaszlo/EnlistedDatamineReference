from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody
from "%ui/mainMenu/sectionsState.nut" import curSectionDetails
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/ui_library.nut" import *

let menuDescShown = mkOnlineSaveData("menuDescShown", @() {})
const TaskTextDesc = Color(150, 150, 160, 220)

function showDescription(section) {
  let descId = section?.descId
  if ((descId ?? "") == "")
    return

  let id = section.id
  let shown = menuDescShown.watch.get()
  if (id in shown)
    return
  menuDescShown.setValue(shown.__merge({ [id] = true }))

  let description = {
    content = {
      flow = FLOW_VERTICAL
      size = FLEX_H
      halign = ALIGN_CENTER
      gap = hdpx(40)
      children = [
        {
          size = const [sw(35), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc(section.locId)
        }.__update(fontHeading2)
        {
          size = const [sw(50), SIZE_TO_CONTENT]
          halign = ALIGN_LEFT
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = TaskTextDesc
          text = loc(descId)
          parSpacing = hdpx(20)
        }.__update(fontBody)
      ]
    }
    buttons = [{ text = loc("Ok"), isCurrent = true, isCancel = true }]
  }
  showMessageWithContent(description)
}

console_register_command(@() menuDescShown.setValue({}), "ui.resetMenuDescriptions")

curSectionDetails.subscribe(showDescription)