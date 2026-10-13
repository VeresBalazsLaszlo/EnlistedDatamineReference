import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid, watchedTeam
from "%ui/hud/state/get_team.nut" import getTeam
from "%ui/ec_to_watched.nut" import mkWatchedSetAndStorage
from "%ui/ui_library.nut" import *

let {
  active_grenades_Set,
  active_grenades_GetWatched,
  active_grenades_UpdateEid,
  active_grenades_DestroyEid
} = mkWatchedSetAndStorage("active_grenades_")


function getWillDamageHero(heroEid, grenadeOwner, grenadeRethrower) {
  if (grenadeOwner == heroEid && heroEid != ecs.INVALID_ENTITY_ID && grenadeOwner != ecs.INVALID_ENTITY_ID)
    return true
  let heroTeam = watchedTeam.get()
  if (!is_teams_friendly(heroTeam, getTeam(grenadeOwner)))
    return true
  if (grenadeRethrower != ecs.INVALID_ENTITY_ID && !is_teams_friendly(heroTeam, getTeam(grenadeRethrower)))
    return true
  return false
}

ecs.register_es(
  "active_grenades_hud_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp){
      if (!(comp.active || comp["shell__explTime"] == 0.0))
        active_grenades_DestroyEid(eid)
      else{
        let grenadeOwner = comp["shell__owner"]
        let grenadeRethrower = comp["shell__rethrower"]
        let heroEid = watchedHeroEid.get() ?? ecs.INVALID_ENTITY_ID
        let willDamageHero = getWillDamageHero(heroEid, grenadeOwner, grenadeRethrower)
        active_grenades_UpdateEid(eid, {
            willDamageHero
            maxDistance = comp["hud_marker__max_distance"]
          }
       )
      }
    }
    function onDestroy(_, eid, _comp){
      active_grenades_DestroyEid(eid)
    }
  },
  {
    comps_ro = [
      ["shell__explTime", ecs.TYPE_FLOAT, 0.0],
      ["shell__owner", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["shell__rethrower", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0]
    ]
    comps_track = [["active", ecs.TYPE_BOOL]]
    comps_rq = ["hud_grenade_marker"]
    comps_no = ["gun__hideInUi"]
  }
)

return {
  active_grenades_Set,
  active_grenades_GetWatched
}