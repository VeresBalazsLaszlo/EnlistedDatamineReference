from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/meta/configs.nut" import serverConfigs, mkComputedConfigView
from "%ui/ui_library.nut" import *

let ordered = Computed(@() (serverConfigs.get()?.squads_config ?? {})
  .map(@(list, armyId) list.map(@(squad, sIdx)
    squad.__merge(getSquadPresentation(squad?.id, armyId) ?? {}, { index = sIdx }))
  )
)

let allSquadTypes = mkComputedConfigView(function(cfg) {
  let res = []
  let squadTypeTracker = {}
  let squadsConfig = cfg?.squads_config ?? {}
  foreach(army in squadsConfig)
    foreach(squad in army) {
      let { squadType } = squad
      if (squadType not in squadTypeTracker) {
        res.append({
          squadType
          nameText = loc($"squadType/{squadType}")
        })
        squadTypeTracker[squadType] <- true
      }
    }
  return res.sort(@(a, b) a.nameText <=> b.nameText)
})

let byId = Computed(@() ordered.get().map(function(list) {
  let res = {}
  foreach (squad in list)
    res[squad.id] <- squad
  return res
}))

return {
  squadsCfgOrdered = ordered
  squadsCfgById = byId
  allSquadTypes
}