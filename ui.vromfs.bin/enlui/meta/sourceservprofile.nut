from "%enlSqGlob/offline_mode.nut" import disableRemoteNetServices, app_is_offline_mode
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/meta/configs.nut" import EVENT_SAVE_DISABLE_NETWORK_DATA
from "%sqstd/json.nut" import saveJson, loadJson
from "eventbus" import eventbus_subscribe
from "dagor.memtrace" import set_huge_alloc_threshold
from "%ui/ui_library.nut" import *

const DISABLE_NETWORK_PROFILE = "disable_network_profile.json"

let profileStructure = freeze({
  items = {}
  wallposters = {}
  soldiers = {}
  soldiersLook = {}
  soldiersOutfit = {}
  soldierPerks = {}
  squads = {}
  armies = {}
  researchProgress = {}
  squadProgress = {}
  growthState = {}
  growthProgress = {}
  purchasesCount = {}
  purchasesExt = {}
  rewardedSingleMissons = {}
  premium = {}
  armyStats = {}
  activeBoosters = {}
  decorators = {}
  vehDecorators = {}
  vehCamouflages = {}
  medals = {}
  offers = {}
  metaConfig = {}
  missionRates = {}
  armyEffects = {}
  slotsIncrease = {}
  notifiers = {}
  rewardsLog = {}
})

function loadOfflineProfile() {
  let prevSize = set_huge_alloc_threshold(66560 << 10)
  let data = loadJson(DISABLE_NETWORK_PROFILE)
  set_huge_alloc_threshold(prevSize)
  let res = {}
  foreach(k, _ in profileStructure)
    res[k] <- data?[k] ?? {}
  return res
}

let sourceProfileData = nestWatched("player_profile_data",
  (disableRemoteNetServices && !app_is_offline_mode())
    ? loadOfflineProfile()
    : (clone profileStructure)
)

function dumpProfile(...) {
  saveJson(DISABLE_NETWORK_PROFILE, sourceProfileData.get().map(@(w) w.get()), { logger = log_for_user })
  console_print($"Current user profile saved to {DISABLE_NETWORK_PROFILE}")
}

eventbus_subscribe(EVENT_SAVE_DISABLE_NETWORK_DATA, dumpProfile)

return {
  profileStructure
  sourceProfileData
  hasSourceServProfile = Computed(@() sourceProfileData.get().armies.len() > 0)
}
