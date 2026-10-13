import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/data/tutorial_profiles.nut" import getProfile
from "eventbus" import eventbus_send

ecs.register_es("update_tutorial_profile_es",
  {
    onInit = function(_eid, comp) {
      let id = comp["tutorial__profile"]
      let tutorialProfile = getProfile(id) ?? {}
      eventbus_send("updateArmiesData", tutorialProfile)
    }
  },
  { comps_ro=[["tutorial__profile", ecs.TYPE_STRING]] },
  { tags="gameClient" }
)
