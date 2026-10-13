from "%ui/ui_library.nut" import *
from "%ui/meta/clientApi.nut" import mark_seen_objects
from "%ui/meta/servProfile.nut" import notifiers
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/meta/profile.nut" import curCampSquads
from "%ui/components/modalWindows.nut" import hasModalWindows
from "%ui/components/wndManager.nut" import registerWnd, Wnd
from "%ui/components/wndPermissionFlags.nut" import autoClose
from "%ui/tutorial/tutorialWndState.nut" import isTutorialActive
from "%ui/soldiers/model/newItemsToShow.nut" import NotifyStatus


let newSquadsPromo = Computed(function() {
  let curCampSquadsVal = curCampSquads.get()
  let squadsCfgs = squadsCfgById.get()
  let newSquadsToPromo = {}

  foreach (guid, notifier in notifiers.get()) {
    if (notifier.status != NotifyStatus.NEW || guid not in curCampSquadsVal)
      continue

    let squad = curCampSquadsVal[guid]
    let armyId = getLinkedArmyName(squad)
    let squadCfg = squadsCfgs?[armyId][squad.squadId]
    if (squadCfg != null) {
      local promoSquads = newSquadsToPromo?[armyId]
      if (promoSquads == null) {
        promoSquads = []
        newSquadsToPromo[armyId] <- promoSquads
      }
      promoSquads.append({ guid, squad, armyId, squadCfg })
    }
  }

  return newSquadsToPromo
})

let isMarkSeenInProgress = Watched(false) 

function markNewSquadsSeen() {
  let newSquadsPromoVal = newSquadsPromo.get()
  if (isMarkSeenInProgress.get() || newSquadsPromoVal.len() == 0)
    return

  isMarkSeenInProgress.set(true)

  let guids = []
  foreach (squadsList in newSquadsPromoVal)
    foreach (squad in squadsList)
      guids.append(squad.guid)

  mark_seen_objects(guids, @(_) isMarkSeenInProgress.set(false))
}

let needNewSquadsWindow = registerWnd({
  dataWatch = Computed(@() newSquadsPromo.get().len() > 0 && !isMarkSeenInProgress.get())
  showWatch = Computed(@() !hasModalWindows.get() || isTutorialActive.get())
  closeWatch = autoClose
  name = Wnd.SQUADS
})

return {
  needNewSquadsWindow
  markNewSquadsSeen
  newSquadsPromo
}