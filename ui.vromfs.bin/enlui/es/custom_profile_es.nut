import "%dngscripts/ecs.nut" as ecs
from "%sqstd/json.nut" import loadJson
from "eventbus" import eventbus_send

ecs.register_es("update_custom_profile_es",
  {
    onInit = function(_eid, comp) {
      let customProfile = loadJson(comp["customProfile"])
      eventbus_send("updateArmiesData", customProfile)
    }
  },
  { comps_ro=[["customProfile", ecs.TYPE_STRING]] },
  { tags="gameClient" }
)
