import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
import "%ui/hud/state/getFramedNickByEid.nut" as getFramedNickByEid
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerEid, localPlayerTeam, localPlayerGroupMembers
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/helpers/timers.nut" import setIntervalForUpdateFunc
from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "%ui/hud/state/hudOptionsState.nut" import minimalistHud
from "%ui/helpers/remap_nick.nut" import remap_others
from "dasevents" import EventKillReport
from "%ui/hud/state/zombie_mode.nut" import isZombieMode
from "%ui/hud/state/zombie_zones_state.nut" import isZombieObjectiveMode
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let awardsLog = require("%ui/hud/state/eventlog.nut").awards
let { EventLogState } = require("%ui/hud/state/eventlog_state.nut")

let killBySpyCount = mkOnlineSaveData("ui/hud/killed_by_spy_shown", @() 0)
let shownTipCount = killBySpyCount.watch
let showKillLog = Computed (@() !minimalistHud.get() && !forcedMinimalHud.get())

function collapseByFunc(lastev, event){
  if (lastev?.killer.player_eid != event?.killer.player_eid
      || event?.damageType != lastev?.damageType
      || event?.victim.player_eid != lastev?.victim.player_eid)
    return false
  return true
}
let killLogState = EventLogState({id = "killLogState", collapseByFunc})

setIntervalForUpdateFunc(0.45, @(dt) killLogState.update(dt))

let deathsLog = EventLogState({id = "deathsLogState", maxActiveEvents=3, ttl=10})

setIntervalForUpdateFunc(0.45, @(dt) deathsLog.update(dt))


function killEventText(victim, killer) {
  if (victim.isHero) {
    if (killer.vehicle) {
      let killerName = ecs.obsolete_dbg_get_comp_val(killer.eid, "item__name", "")
      return loc(killerName)
    }
    return (killer.isHero) ? loc("log/local_player_suicide") : killer.name
  }

  let victimName = victim.name ?? (
    victim?.inMyTeam
      ? victim.inMySquad ? loc("log/squadmate") : loc("log/teammate")
      : null
  )

  return (victimName != null)
    ? loc("log/eliminated", {user = loc(victimName)})
    : victim.inMyTeam
      ? loc("log/eliminated_teammate")
      : loc("log/eliminated_enemy")
}

let getAwardForKill = @(victim, killer, scoreId) {
  text = killEventText(victim, killer)
  type = "kill"
  groupKey = $"kill_{victim?.name}"
  scoreId
}

function onReportKill(evt, _eid, _comp) {
  let heroEid     = controlledHeroEid.get()
  let myTeam      = localPlayerTeam.get()
  let locPlayer   = localPlayerEid.get()

  let victimInMySquad = evt.victimPlayer == locPlayer
  let victimInMyTeam = is_teams_friendly(myTeam, evt.victimTeam)
  let victimInMyGroup = !victimInMySquad && evt.victimPlayer in localPlayerGroupMembers.get()

  let needRemapName = (!isZombieObjectiveMode.get() && !isZombieMode.get())
    || victimInMyTeam || victimInMySquad || victimInMyGroup

  let victim = {
    eid = evt.victim
    player_eid = evt.victimPlayer
    vehicle = evt.isVictimVehicle
    inMyTeam = victimInMyTeam
    inMySquad = victimInMySquad
    inMyGroup = victimInMyGroup
    isHero = heroEid != ecs.INVALID_ENTITY_ID && evt.victim == heroEid
    name = evt.isVictimVehicle ? loc(evt.victimName, "")
      : !victimInMySquad && evt.victimPlayer != ecs.INVALID_ENTITY_ID
        ? getFramedNickByEid(evt.victimPlayer, !victimInMyGroup)
      : needRemapName ? remap_others(evt.victimName, !victimInMyGroup)
      : evt.victimName
    rank = evt.victimRank
  }
  let killerInMyGroup = evt.killerPlayer != locPlayer
    && evt.killerPlayer in localPlayerGroupMembers.get()
  let killer = {
    eid = evt.killer
    player_eid = evt.killerPlayer
    vehicle = evt.isKillerVehicle
    inMyTeam = is_teams_friendly(myTeam, evt.killerTeam)
    inMySquad = evt.killerPlayer == locPlayer
    inMyGroup = killerInMyGroup
    isHero = heroEid != ecs.INVALID_ENTITY_ID && evt.killer == heroEid
    name = evt.killerPlayer != ecs.INVALID_ENTITY_ID
      ? getFramedNickByEid(evt.killerPlayer, !killerInMyGroup)
      : remap_others(evt.killerName, !killerInMyGroup)
    rank = evt.killerRank
  }

  if (showKillLog.get()) {
    killLogState.pushEvent({
      event = "kill"
      gunName = evt.gunName
      isHeadshot = evt.isHeadshot
      damageType = evt.damageType
      typeIcon = evt.typeIcon
      victim = victim
      killer = killer
      ttl = [evt.victim, evt.killer].contains(heroEid) ? 8 : 5
    })

    if (evt.killer == heroEid && !ecs.obsolete_dbg_get_comp_val(evt.victim, "dontShowKillAward", false)) {
      let award = {awardData = getAwardForKill(victim, killer, evt.scoreId)}
      awardsLog.pushEvent(award)
    }
  }

  if (evt.victim == heroEid && heroEid != evt.killer && evt.killer != ecs.INVALID_ENTITY_ID){
    if (evt.killedByDisguisedSpy && shownTipCount.get() < 3){
      killBySpyCount.setValue(shownTipCount.get() + 1)
      playerEvents.pushEvent({text = loc("hint/spiesDoesntHaveMarker")})
    }

    deathsLog.pushEvent({
      event = "death",
      name=killer.name,
      inMyTeam=killer.inMyTeam,
      ttl=7,
      killedByDisguisedSpy = evt.killedByDisguisedSpy
    })
  }
}

function clearDeathLog(){
  deathsLog.events.mutate(@(v) v.clear())
}

controlledHeroEid.subscribe(@(_v) gui_scene.resetTimeout(1, clearDeathLog))
ecs.register_es("ui_kill_report_es", {
    [EventKillReport] = onReportKill
  }, {}
)

local num = 0
console_register_command(function() {
  num+=1
  deathsLog.pushEvent({
    name = $"test name {num}",
    inMyTeam = false,
    ttl=7,
    event = "death"
  })
}, "ui.death_event")

return {
  deathsLog
  killLogState
}