import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/briefingState.nut" import showBriefingOnSquadChange, briefingState, showBriefingForTime, showBriefingOnHeroChange
from "%ui/hud/state/hero_squad.nut" import squadEid
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/teams.nut" import localPlayerTeamInfo
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *

let showedBriefing = {
    
}
localPlayerTeam.subscribe(@(_) showedBriefing.clear())

let firstSpawnBriefingShown = mkWatched(persist, "firstSpawnBriefingShown", false)

controlledHeroEid.subscribe(function(value) {
  let curBriefing = localPlayerTeamInfo.get()?["team__briefing"] ?? ""
  let curBriefingCommon = briefingState.get()?["common"] ?? ""
  function showBrief(){
    showedBriefing[curBriefing] <- 1
    showedBriefing[curBriefingCommon] <- 1
    showBriefingForTime.set(briefingState.get()?.showtime ?? 10.0)
  }
  if (value == ecs.INVALID_ENTITY_ID)
    return
  if (!firstSpawnBriefingShown.get()){
    firstSpawnBriefingShown.set(true)
    showBrief()
    return
  }
  if (!showBriefingOnHeroChange.get()) {
    return
  }
  showBrief()
})

squadEid.subscribe(function(_){
  if (!showBriefingOnSquadChange.get())
    return
  showBriefingForTime.set(briefingState.get()?.showtime ?? 10.0)
})
