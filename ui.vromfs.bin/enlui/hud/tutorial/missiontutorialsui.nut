import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/huds/tips/tipComponent.nut" import tipAlternate
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/textButton.nut" import Regular
from "%ui/hud/tutorial/missionTutorialsState.nut" import curMissionTutorial, markSeenMissionHint, curSeenMissionHints, isControlTutorialVisible
from "%ui/hud/state/interactive_state.nut" import addInteractiveElement, removeInteractiveElement
from "%ui/style/designConst.nut" import smallPadding, bigPadding, defBdColor, panelBgColor, defTxtColor, activeTxtColor, sidePadding
from "%ui/ui_library.nut" import *

let { controlTutorialsCfg } = require("%ui/hud/tutorial/missionTutorialsState.nut")


const interactiveKey = "missionTutorial"


let closeButton = Regular("OK", function() {
  let cfg = curMissionTutorial.get()
  if (cfg != null)
    markSeenMissionHint(cfg.id)
}, { hotkeys = [[$"^{JB.B} | Space | Enter | Esc", { description = loc("Close") }]] })


let mkTutorialImage = @(image) image == "" ? null
  : {
      rendObj = ROBJ_IMAGE
      size = const [hdpxi(600), hdpxi(300)]
      image = Picture(image)
    }

let mkTutorialHeader = @(titleLocId) titleLocId == "" ? null
  : {
      rendObj = ROBJ_TEXT
      text = loc(titleLocId)
      color = activeTxtColor
    }

let mkTutorialDesc = @(tutorialLocId) tutorialLocId == "" ? null
  : {
      rendObj = ROBJ_TEXTAREA
      size = FLEX_H
      behavior = Behaviors.TextArea
      color = defTxtColor
      text = loc(tutorialLocId)
    }


function controlTutorialUi() {
  let seen = curSeenMissionHints.get()
  return {
    watch = [isControlTutorialVisible, curSeenMissionHints]
    flow = FLOW_VERTICAL
    padding = bigPadding
    margin = [0, sidePadding]
    vplace = ALIGN_CENTER
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    borderColor = defBdColor
    fillColor = panelBgColor
    children = !isControlTutorialVisible.get() ? null
      : controlTutorialsCfg.map(function(cfg) {
          let input = tipAlternate({
            textsInputs = cfg.details.map(@(detail) {
              inputId = detail.inputId, text = loc(detail.locId)
            })}.__merge({ style = { rendObj = null } }.__update(fontSub)))

          let seenMark = (seen?[cfg.id] ?? false)
            ? faComp("check-circle")
            : faComp("circle-thin")

          return {
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            valign = ALIGN_CENTER
            children = [
              seenMark
              input
            ]
          }
        })
  }
}


function missionTutorialUi() {
  let watch = [isGamepad, curMissionTutorial]
  if (curMissionTutorial.get() == null)
    return { watch }

  let { titleLocId = null, tutorialLocId = null, image = null } = curMissionTutorial.get()
  return {
    key = interactiveKey
    watch
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    children = {
      size = const [sh(70), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = bigPadding
      padding = const [hdpx(20), hdpx(30)]
      halign = ALIGN_CENTER
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      borderColor = defBdColor
      fillColor = panelBgColor
      onAttach = @() addInteractiveElement(interactiveKey)
      onDetach = @() removeInteractiveElement(interactiveKey)
      children = [
        mkTutorialHeader(titleLocId ?? "")
        mkTutorialDesc(tutorialLocId ?? "")
        mkTutorialImage(image ?? "")
        closeButton
      ]
    }
  }
}

return {
  missionTutorialUi
  controlTutorialUi
}
