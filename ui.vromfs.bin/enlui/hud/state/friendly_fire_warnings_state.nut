import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *

let totalPenalty = Watched(0)
let currentPenalty = Watched(0)
let showFriendlyFireWarning = Watched(false)

currentPenalty.subscribe(@(penalty) showFriendlyFireWarning.set(penalty < 0))

const WARNING_VISIBLE_TIME = 5.0

let warningTimer  = @() currentPenalty.set(0)

ecs.register_es("friendly_fire_warning_state", {
    function onInit(_, comp) {
      if (comp.is_local)
        totalPenalty.set(comp["scoring_player__friendlyFirePenalty"])
    },
    function onChange(_, comp) {
      if (comp.is_local) {
        let updatedPenalty = comp["scoring_player__friendlyFirePenalty"]
        let prevTotalPenalty = totalPenalty.get()
        let diff = updatedPenalty - prevTotalPenalty
        currentPenalty.modify(@(v) v + diff)
        totalPenalty.set(updatedPenalty)
        gui_scene.resetTimeout(WARNING_VISIBLE_TIME, warningTimer )
      }
    }
  },
  { comps_track = [
      ["scoring_player__friendlyFirePenalty", ecs.TYPE_INT],
    ],
    comps_ro = [["is_local", ecs.TYPE_BOOL]]
  },
  { tags="gameClient"}
)

return {
  friendlyFirePenalty = currentPenalty
  showFriendlyFireWarning
}