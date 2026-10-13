import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let components = {
  briefing = [ecs.TYPE_BOOL],
  header = [ecs.TYPE_STRING, "briefing/header"],
  common_header = [ecs.TYPE_STRING, ""],
  briefing_common = [ecs.TYPE_STRING, ""],
  common = [ecs.TYPE_STRING, ""],
  hints_header = [ecs.TYPE_STRING, "briefing/common_hints_header"],
  hints = [ecs.TYPE_STRING, "common/controls"],
  showtime = [ecs.TYPE_FLOAT, 10.0],
  


}

let defState = components.map(@(v) v?[1])

let comps = []
foreach (name, defVal in components)
  comps.append([name].extend(defVal))


let briefingEcs = mkEcsComputed({comps})
let briefingState = Computed(@() briefingEcs.get() ?? defState)
let showBriefingOnSquadChange = Watched(false)
ecs.register_es("es_ui_briefing_show_on_squad_change", {
    onInit =  @(_eid, _comp) showBriefingOnSquadChange.set(true)
    onDestroy =  @(_eid, _comp) showBriefingOnSquadChange.set(false)
  }, {comps_rq = ["show_briefing_on_squad_change"]}
)

let showBriefingOnHeroChange = Watched(false)
ecs.register_es("es_ui_briefing_show_on_hero_change", {
    onInit =  @(_eid, _comp) showBriefingOnHeroChange.set(true)
    onDestroy =  @(_eid, _comp) showBriefingOnHeroChange.set(false)
  }, {comps_rq = ["show_briefing_on_hero_change"]}
)

let showBriefing = mkWatched(persist, "showBriefing", false)

return {
  briefingState
  showBriefingOnHeroChange
  showBriefingOnSquadChange
  showBriefingForTime = Watched(null)
  showBriefing
}
