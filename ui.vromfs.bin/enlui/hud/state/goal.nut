from "%sqstd/timers.nut" import debounce
from "%ui/hud/state/briefingState.nut" import briefingState
from "%ui/hud/state/teams.nut" import localPlayerTeamInfo
from "%ui/hud/state/respawnState.nut" import needSpawnMenu, respawnsInBot
from "%ui/ui_library.nut" import *

let { hints } = require("%ui/hud/state/eventlog.nut")

let isWaitToShow = Watched(false)

let goalText = Computed(function() {
  local locId = localPlayerTeamInfo.get()?["team__briefing"] ?? ""
  if (locId == "")
    locId = briefingState.get()?.briefing_common ?? ""
  return locId == "" ? "" : loc($"{locId}/short", loc(locId))
})

let goalTtl = Computed(@() localPlayerTeamInfo.get()?["team__goalShowTime"] ?? -1.)

let showGoal = @() hints.pushEvent(goalTtl.get() > 0. ? { uid = "goal", text = goalText.get(), ttl = goalTtl.get()} : { uid = "goal", text = goalText.get()})
function showGoalWhenReady() {
  if (needSpawnMenu.get())
    isWaitToShow.set(true)
  else
    showGoal()
}

goalText.subscribe(@(_) showGoalWhenReady())
localPlayerTeamInfo.subscribe(function(teamInfo) {
  if (teamInfo?["team__forceEnableBriefing"] ?? false)
    showGoalWhenReady()
})

needSpawnMenu.subscribe(function(show) {
  if (show || !isWaitToShow.get())
    return
  isWaitToShow.set(false)
  showGoal()
})


let markShowAfterSpawn = debounce(function() {
  if (needSpawnMenu.get() && !respawnsInBot.get())
    isWaitToShow.set(true)
}, 0.5)
needSpawnMenu.subscribe(@(_) markShowAfterSpawn())
respawnsInBot.subscribe(@(_) markShowAfterSpawn())

console_register_command(showGoal, "ui.add_goal_msg")