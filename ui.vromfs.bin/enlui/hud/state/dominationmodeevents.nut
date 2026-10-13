from "%enlSqGlob/missionType.nut" import MissionType
from "%ui/hud/state/team_scores.nut" import myScore, myScoreBleed, myScoreBleedFast
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/state/missionParams.nut" import missionParams
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")


let defEvent = {text=loc("The enemy's almost won!"), myTeamScores=false}
let defSound = ""






let events = {
  showFailWarning = {
    watch = Computed(@() missionParams.get().type == MissionType.DOMINATION
      && (myScore.get() < 0.2)
      && (myScoreBleed.get() || myScoreBleedFast.get()))
  }
  showFailFastWarning = {
    watch = Computed(@() missionParams.get().type == MissionType.DOMINATION
      && (myScore.get() < 0.1)
      && (myScoreBleed.get() || myScoreBleedFast.get()))
  }
  showLowScore = {
    watch = Computed(@() missionParams.get().type == MissionType.DOMINATION
      && (myScore.get() < 0.05))
  }
}

foreach (e in events) {
  let {event=defEvent, sound = defSound, watch} = e
  keepref(watch)
  watch.subscribe(function(val) {
    if (val) {
      if (sound != "")
        sound_play(sound)
      playerEvents.pushEvent(event)
    }
  })
}
