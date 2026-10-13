import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/ui_library.nut" import *

from "%ui/debriefing/debriefingDataState.nut" import dataToShow
from "%ui/debriefing/debriefingDbgState.nut" import dbgShow
from "%ui/debriefing/debriefingState.nut" import debriefingShow
from "%ui/hud/components/mkScoresStatisticsUtils.nut" import getPlayerPlace
from "%ui/state/appState.nut" import isInBattleState
from "%ui/steam/steamRateState.nut" import getSteamRateWindowAvailability, suggestionRateSteam, getSteamReviewSeenState, setSteamReviewSeenState
from "%ui/steam/steamRateWnd.nut" import openSteamReviewWnd


let isDebriefingResultSatisfying = Watched(false)

dataToShow.subscribe(function(data) {
  if (!data || data.len() == 0)
    return

  let { success = false, deserter = false } = data?.result
  let place = getPlayerPlace(data)
  let isPlaceAppropriate = place > 0 && place <= suggestionRateSteam.minPlaceOnWin
  if (success && !deserter && isPlaceAppropriate) {
    isDebriefingResultSatisfying.set(true)
  }
})

function onDebriefingClose(v) {
  if (v || !isDebriefingResultSatisfying.get())
    return

  let availability = getSteamRateWindowAvailability.get()
  if (availability?.tryNextTime) {
    let state = clone getSteamReviewSeenState.get()
    if (state == null)
      return

    state.lastTimeSeen = serverTime.get()
    setSteamReviewSeenState(state)
  }
  else if (availability?.isAvailable)
    openSteamReviewWnd()
}

dbgShow.subscribe(onDebriefingClose)
debriefingShow.subscribe(onDebriefingClose)
isInBattleState.subscribe(function(v) {
  if (v)
    isDebriefingResultSatisfying.set(false)
})
