from "%ui/meta/configs.nut" import mkComputedConfigView, mkComputedConfigGet
from "%ui/ui_library.nut" import *

let gameProfile = mkComputedConfigGet("gameProfile", {})

let allArmiesInfo = mkComputedConfigView(function(cfg) {
  let res = {}
  foreach (c in cfg?.gameProfile.campaigns ?? {})
    foreach (a in c?.armies ?? {})
      res[a.id] <- a
  return res
})

let gameProfileLookCfg = mkComputedConfigView(@(cfg) cfg?.gameProfile.look ?? {})

return {
  gameProfile
  gameProfileLookCfg
  allArmiesInfo
}
