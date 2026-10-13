from "%ui/meta/configs.nut" import mkComputedConfigView
from "%ui/ui_library.nut" import *

let perkList = mkComputedConfigView(function(cfg) {
  let list = cfg?.perks.list
  let res = {}
  if (list == null)
    return res

  foreach (id, p in list) {
    let perk = clone p
    perk.perkId <- id
    perk.locId <- perk?.locId ?? id
    res[id] <- perk
  }
  return res
})

return perkList