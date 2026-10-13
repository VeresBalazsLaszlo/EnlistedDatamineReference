from "%ui/meta/configs.nut" import mkComputedConfigView
from "%ui/meta/clientApi.nut" import rent_squad
from "%ui/ui_library.nut" import *

let rentSquadsConfig = mkComputedConfigView(function(cfg) {
  let costSchemes = cfg?.rentPrices ?? {}
  return (cfg?.rentConfig.squads ?? {})
    .map(@(armyCfg) armyCfg.map(@(schemeId) costSchemes?[schemeId] ?? []))
})


function rentSquad(armyId, squadId, rentTime, price) {
  rent_squad(armyId, squadId, rentTime, price)
}


return {
  rentSquadsConfig
  rentSquad
}
