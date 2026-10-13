from "%ui/meta/configs.nut" import mkComputedConfigView
from "%ui/ui_library.nut" import *

let sClassesCfg = mkComputedConfigView(function(cfg) {
  let baseClasses = cfg?.soldier_classes ?? {}
  let tiers = (cfg?.perkPointsTiers ?? {})
  return baseClasses.map(@(c) c.__merge({ pointsByTiers = tiers?[c?.pointsGenId] ?? [] }))
})

return sClassesCfg