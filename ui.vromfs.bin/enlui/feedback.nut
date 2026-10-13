import "%ui/components/fontawesome.map.nut" as fa
import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/closeBtn.nut" as closeBtnBase
from "%ui/components/msgbox.nut" import decorObj, showMsgbox
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/options/bigQuery.nut" import bqSendEvent
from "%ui/style/designConst.nut" import defTxtColor, largePadding, sidePadding
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading1
from "%ui/components/textButton.nut" import Regular
from "%ui/style/buttonsStyle.nut" import regularStyle
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/ui_library.nut" import *

const gameSatisfyingWndUID = "feedback_wnd"
const gameRateWndUID = "game_rate_wnd"

const voteIconSize = hdpxi(64)
const voteButtonSize = hdpxi(120)

let selectedIcon = Watched(null)
let editableText = EditableText("")

let customRegularStyle = (clone regularStyle).__update({
  activeTxtColor = regularStyle.hoverTxtColor
  activeBgColor = regularStyle.hoverBgColor
  activeBdColor = regularStyle.hoverBdColor
})

let selectedStyle = (clone customRegularStyle).__update({
  defTxtColor = regularStyle.hoverTxtColor
  defBgColor = regularStyle.hoverBgColor
  defBdColor = regularStyle.hoverBdColor
})

let mkVoteButton = @(icon) Regular(fa[icon], @() selectedIcon.set(icon), {
  btnWidth = voteButtonSize
  btnHeight = voteButtonSize
  textParams = { fontSize = voteIconSize, font = Fonts.fontawesome }
  style = selectedIcon.get() == icon ? selectedStyle : customRegularStyle
})

function closeWindow(resultCallback = null) {
  removeModalWindow(gameSatisfyingWndUID)
  resultCallback?({ isLike = false })
}

function showThanksMessage() {
  showMsgbox(loc("feedback/thanks"))
}

function sendFeedback() {
  let feedback = editableText.text.strip()
  bqSendEvent("feedback_popup_result", { result = feedback })
}

let feedbackModalContent = @() {
  size = FLEX
  valign = ALIGN_CENTER
  children = [
    {
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      margin = largePadding
      children = closeBtnBase({ onClick = @() closeWindow() })
    }
    {
      size = const [FLEX, fsh(40)]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = largePadding
      children = [
        {
          rendObj = ROBJ_TEXT
          color = defTxtColor
          text = loc("feedback/what_didnt_like_msg")
        }.__update(fontHeading1)
        {
          rendObj = ROBJ_BOX
          borderWidth = 2
          padding = hdpx(10)
          borderColor = Color(200, 200, 200)
          fillColor = Color(30, 40, 50)
          children = {
            rendObj = ROBJ_TEXTAREA
            behavior = [Behaviors.TextAreaEdit, Behaviors.WheelScroll]
            size = const [fsh(80), fsh(30)]
            editableText
            onAttach = @(elem) set_kb_focus(elem)
            imeOnFocus = true
          }.__update(fontBody)
        }
        Regular(loc("feedback/send_feedback"), function() {
          sendFeedback()
          closeWindow()
          showThanksMessage()
        }, { hotkeys = [["^J:X"]] })
      ]
    }
  ]
}

function showFeedbackWindow() {
  sendBigQueryUIEvent("feedback_popup")
  addModalWindow({
    key = gameSatisfyingWndUID
    rendObj = ROBJ_SOLID
    color = Color(30,30,30,250)
    size = FLEX
    onClick = @() null
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = feedbackModalContent
  })
}

let mkReviewModalContent = @(resultCallback) {
  size = const [FLEX, fsh(40)]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = sidePadding
  rendObj = ROBJ_BOX
  fillColor = Color(30, 40, 50)
  children = [
    decorObj
    {
      rendObj = ROBJ_TEXT
      color = defTxtColor
      text = loc("feedback/request")
    }.__update(fontHeading1)
    {
      size = FLEX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        @() {
          watch = selectedIcon
          flow = FLOW_HORIZONTAL
          gap = hdpxi(80)
          children = [
            mkVoteButton("thumbs-down")
            mkVoteButton("thumbs-up")
          ]
        }
      ]
    }
    {
      flow = FLOW_HORIZONTAL
      gap = sidePadding
      children = [
        @() {
          watch = selectedIcon
          children = Regular(loc("Apply"), function() {
            removeModalWindow(gameRateWndUID)

            let isLike = selectedIcon.get() == "thumbs-up"
            bqSendEvent("game_satisfying_result", { score = isLike ? "positive" : "negative" })

            if (!isLike)
              showFeedbackWindow()
            else if (!resultCallback)
              showThanksMessage()
            else
              resultCallback({ isLike = true })
          }, { hotkeys = [[$"^J:X | Enter"]], isEnabled = selectedIcon.get() != null })
        }
        Regular(loc("Cancel"), function() {
          removeModalWindow(gameRateWndUID)
        }, { hotkeys = [[$"^{JB.B} | Esc"]] })
      ]
    }
    decorObj
  ]
}

function showGameRateWindow(resultCallback) {
  addModalWindow({
    key = gameRateWndUID
    rendObj = ROBJ_SOLID
    color = Color(30,30,30,250)
    size = FLEX
    onClick = @() null
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkReviewModalContent(resultCallback)
  })
}

function showGameSatisfyingRequest(resultCallback = null) {
  selectedIcon.set(null)
  sendBigQueryUIEvent("game_satisfying_popup")
  showGameRateWindow(resultCallback)
}

console_register_command(function() {
  showGameSatisfyingRequest()
}, "debug.show_game_satisfying_wnd")


return {
  showGameSatisfyingRequest
}
