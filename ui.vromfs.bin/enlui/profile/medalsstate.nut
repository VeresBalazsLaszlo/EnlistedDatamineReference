from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/meta/servProfile.nut" import medals
from "%ui/meta/clientApi.nut" import add_medal
from "%ui/profile/medalsPresentation.nut" import medalsPresentation
from "%ui/ui_library.nut" import *

let medalsServerCfg = mkComputedConfigGet("medalsCfg", {})

let medalsCfg = Computed(function() {
  let receivedById = {}
  foreach (medal in medals.get()) {
    let { id, cTime } = medal
    receivedById[id] <- (receivedById?[id] ?? []).append(cTime)
  }

  return medalsServerCfg.get()
    .map(@(medalCfg, id) medalCfg
      .__merge({ id, received = receivedById?[id] ?? [] }, medalsPresentation?[id] ?? {})
    )
})

let medalsByCampaign = Computed(function() {
  let res = {}
  foreach (medal in medalsCfg.get()) {
    let { campaign, received } = medal
    if (received.len() == 0)
      continue

    if (campaign not in res)
      res[campaign] <- []
    res[campaign].append(medal)
  }

  return res.map(@(campaignMedals) campaignMedals
    .sort(@(a, b) (b?.weight ?? 0) <=> (a?.weight ?? 0) || a.id <=> b.id))
})


let hasMedals = Computed(@() medalsByCampaign.get().len() > 0)

console_register_command(@(id) add_medal(id), "meta.addMedal")


return {
  medalsCfg
  medalsByCampaign
  hasMedals
}
