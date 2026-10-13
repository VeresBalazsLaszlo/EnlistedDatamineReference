import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "team" import TEAM_UNASSIGNED
from "%sqstd/frp.nut" import watchedTable2TableOfWatched
from "%ui/ui_library.nut" import *








let whDefValue = freeze({
  watchedHeroEid = ecs.INVALID_ENTITY_ID
  watchedHeroTeam = TEAM_UNASSIGNED
})
let whState = mkWatched(persist, "watchedHero", whDefValue)
let whStateSetValue = @(v) whState.set(v)

let { watchedHeroEid, watchedHeroTeam } = watchedTable2TableOfWatched(whState)

let watchedHeroPlayerEid = mkEcsComputed({
  comps = [["possessedByPlr", ecs.TYPE_EID]]
  comps_rq = [["watchedByPlr", ecs.TYPE_EID]]
  defVal = ecs.INVALID_ENTITY_ID
})


let watchedTeam = Computed(@() watchedHeroEid.get() != ecs.INVALID_ENTITY_ID ? watchedHeroTeam.get() : localPlayerTeam.get())


ecs.register_es("watched_hero_eid_es", {
  onInit = function(_, eid, comp) {
    log("watchedHeroEid:" eid)
    whStateSetValue({
      watchedHeroEid = eid
      watchedHeroTeam = comp.team
    })
  }
  onDestroy = function(_, eid, _comp) {
    if (watchedHeroEid.get() == eid)
      whStateSetValue(whDefValue)
  }
}, {comps_rq=[["watchedByPlr", ecs.TYPE_EID]], comps_ro = [["team", ecs.TYPE_INT, TEAM_UNASSIGNED]]})


return {
  watchedHeroEid,
  watchedHeroPlayerEid,
  watchedTeam
}