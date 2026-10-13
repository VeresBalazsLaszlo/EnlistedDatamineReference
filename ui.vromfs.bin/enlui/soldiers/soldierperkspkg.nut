import "%ui/control/gui_buttons.nut" as JB
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/researches/researchesFocus.nut" import focusResearch, findResearchTrainClass, hasResearchSquad
from "%ui/components/soldierClasses.nut" import soldierClasses
from "%ui/ui_library.nut" import *

function showTrainResearchMsg(soldier, cb = null) {
  let { sClass = "unknown" } = soldier
  let armyId = getLinkedArmyName(soldier)
  let research = findResearchTrainClass(soldier)
  if (research == null)
    showMsgbox(loc("msg/cantTrainClassHigher"))
  else if (!hasResearchSquad(armyId, research))
    showMsgbox(loc("msg/needUnlockSquadToTrain",
      { sClass = loc(soldierClasses?[sClass].locId ?? "unknown") }))
  else
    showMsgbox({
      text = loc("msg/needResearchToTrainHigher")
      buttons = [
        { text = loc("GoToResearch")
          action = function() {
            cb?()
            focusResearch(research)
          }
          customStyle = { hotkeys = [[ "^J:Y | Enter" ]] }
        }
        { text = loc("Cancel")
          isCurrent = true
          customStyle = { hotkeys = [[ $"^{JB.B} | Esc" ]]}
        }
      ]
    })
}

return {
  showTrainResearchMsg
}
