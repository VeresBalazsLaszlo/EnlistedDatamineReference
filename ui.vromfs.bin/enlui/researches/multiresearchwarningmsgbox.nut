import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/colorize.nut" as colorize
import "%ui/components/checkbox.nut" as checkbox
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor
from "%ui/style/colors.nut" import MsgMarkedText
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/options/onlineSettings.nut" import settings
from "%ui/ui_library.nut" import *

const SAVE_ID = "seen/multiresearchWarning"

let dontShowAgain = Computed(@() settings.get()?[SAVE_ID] ?? false)
let setDontShowAgain = @(val) settings.mutate(@(v) v[SAVE_ID] <- val)

let textarea = @(text, color) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color
  text
}.__update(fontBody)

function multiresearchWarningMsgbox(research, pageResearches, unlockAction) {
  let { multiresearchGroup = 0, research_id, name = "", params = {} } = research
  if (dontShowAgain.get() || multiresearchGroup <= 0) {
    unlockAction()
    return
  }
  let group = pageResearches.filter(@(r) r?.multiresearchGroup == multiresearchGroup && r.research_id != research_id)
  if (group.len() == 0) {
    unlockAction()
    return
  }

  showMessageWithContent({
    uid = "multiresearch_confirm"
    content = {
      flow = FLOW_VERTICAL
      size = const [sw(50), SIZE_TO_CONTENT]
      margin = const [fsh(5), 0]
      gap = fsh(3)
      halign = ALIGN_CENTER
      children = [
        textarea(loc("research/groupCanResearch"), titleTxtColor)
        textarea(
          loc("research/groupCanResearch/desc",
            {
              research = colorize(MsgMarkedText, loc(name, params))
              otherInGroup = ", ".join(group.values().map(@(r) colorize(MsgMarkedText, loc(r.name, r?.params))))
            }),
          defTxtColor)
        checkbox(dontShowAgain,
          {
            text = loc("msgbox/dontShowAgain")
            color = titleTxtColor
          }.__update(fontBody),
          {
            setValue = setDontShowAgain
            textOnTheLeft = true
          })
      ]
    }
    buttons = [
      { text = loc("Yes"),
        action = unlockAction
        isCurrent = true
      }
      { text = loc("Cancel")
        isCancel = true
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}

console_register_command(function() {
  if (SAVE_ID in settings.get())
    settings.mutate(@(v) v.$rawdelete(SAVE_ID))
}, "dontShowAgain.multiresearch.reset")

return multiresearchWarningMsgbox