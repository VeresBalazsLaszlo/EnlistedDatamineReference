from "%ui/meta/clientApi.nut" import update_meta_config
from "%ui/meta/servProfile.nut" import metaConfig
from "%ui/meta/sourceServProfile.nut" import sourceProfileData
from "%ui/ui_library.nut" import *

enum ProhibitionStatus {
  Undefined = "Undefined"
  Allowed = "Allowed"
  Prohibited = "Prohibited"
}

let metaGen = Watched(0)

function updateMetaCfg(key, value) {
  let metaCfg = clone metaConfig.get()
  metaCfg[key] <- value
  sourceProfileData.mutate(@(profile) profile.metaConfig = metaCfg)
  update_meta_config(metaCfg, @(_) metaGen.modify(@(v) v + 1))
}

let isLootBoxProhibited = Computed(@() (metaConfig.get()?.prohibitingLootbox
  ?? ProhibitionStatus.Prohibited) == ProhibitionStatus.Prohibited)

let timeFromLastLogin = Computed(@() metaConfig.get()?.timeFromLastLogin ?? 0)

let timeFromFirstLogin = Computed(@() metaConfig.get()?.timeFromFirstLogin ?? 0)

function setProhibitingLootbox(state) {
  updateMetaCfg("prohibitingLootbox", state)
}

console_register_command(@() console_print(metaConfig.get()), "meta.printMetaConfig")

return {
  isLootBoxProhibited
  ProhibitionStatus
  setProhibitingLootbox
  metaGen
  timeFromLastLogin
  timeFromFirstLogin
}
