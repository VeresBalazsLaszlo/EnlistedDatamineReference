import "dagor.random" as random
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/ui_library.nut" import *

let awardsLog = require("%ui/hud/state/eventlog.nut").awards

let lastShownId = mkWatched(persist, "lastShownId", 0)


function trackComponents(_evt, eid, comp) {
  if (eid!=localPlayerEid.get())
    return

  let awards = comp.awards
  let len = awards.len()
  local firstNewIdx = null

  for (local i=len-1; i>=0; --i) {
    let a = awards[i].getAll()
    if (a.id <= lastShownId.get())
      break
    firstNewIdx = i
  }

  if (firstNewIdx != null) {
    for (local i=firstNewIdx; i<len; ++i) {
      let a = awards[i].getAll()
      if (loc($"hud/awards/{a.type}", "") != "") {
        awardsLog.pushEvent({
          ttl = 5.0
          awardData = a
          unique = a?.unique
        })
      }
      lastShownId.set(max(lastShownId.get(), a.id))
    }
  }
}


ecs.register_es("award_ui_es", {
    onInit = trackComponents,
    onChange = trackComponents,
  }, {comps_track = [["awards", ecs.TYPE_ARRAY]]})


function addTestPlayerAward(awardType) {
  awardsLog.pushEvent({
    ttl = 5.0
    awardData = { type=awardType, id=lastShownId.get()+1 }
  })
}

let test_awards_types = ["Headshot", "Grenade kill", "s", "long long long award", "Melee kill", "kill"]

console_register_command(function() {
  let rand_seed = random.get_rnd_seed()
  let awardType = test_awards_types?[rand_seed%(test_awards_types.len()-1)] ?? "test"
  addTestPlayerAward(awardType)
  }, "ui.add_test_award")
