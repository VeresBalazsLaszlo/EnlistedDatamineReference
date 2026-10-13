import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

const missionParamsDefault = {
  name = null
  type = null
  missionId = null
  campaign = null
}

let missionEntity = mkEcsComputed({
  comps = [
    ["mission_name", ecs.TYPE_STRING],
    ["mission_type", ecs.TYPE_STRING, ""],
    ["mission_campaign", ecs.TYPE_STRING, ""]
  ]
})

let missionParams = Computed(function() {
  let params = missionEntity.get()
  if (params == null)
    return missionParamsDefault
  let { mission_campaign, mission_name, mission_type } = params
  return {
    name = mission_name == "" ? null
      : loc(mission_name, { mission_type = loc($"missionType/{mission_type}") })
    type = mission_type == "" ? null : mission_type
    missionId = mission_name == "" ? null : mission_name
    campaign = mission_campaign == "" ? null : loc($"{mission_campaign}/full")
  }
})

return {
  missionParams
}
