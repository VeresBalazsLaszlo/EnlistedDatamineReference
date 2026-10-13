from "%ui/meta/servProfile.nut" import rewardedSingleMissons
from "%ui/tutorial/battleTutorial.nut" import lastGameTutorialId
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/state/singleMissionRewardState.nut" import singleMissionRewardIdUpdate, singleMissionRewardSumUpdate
from "%ui/ui_library.nut" import *

let singleMissionRewardIdInt = keepref(Computed(function() {
  let id = lastGameTutorialId.get()
  if (id == null || (rewardedSingleMissons.get()?[id].version ?? 0) >= (gameProfile.get()?.tutorials[id].version ?? 0))
    return null
  return id
}))

singleMissionRewardIdInt.subscribe(@(v) singleMissionRewardIdUpdate(v))

let singleMissionRewardSumInt = keepref(Computed(@()
  gameProfile.get()?.tutorials[singleMissionRewardIdInt.get()].expSum ?? 0))

singleMissionRewardSumInt.subscribe(@(v) singleMissionRewardSumUpdate(v))