import "%dngscripts/ecs.nut" as ecs
let {debug} = require("dagor.debug")
let { get_matching_mode_info = @() {extraParams = {}} } = require_optional("dedicated")
let { EventFirstPlayerConnected } = require("dasevents")

ecs.register_es("save_matching_info",
  { [[EventFirstPlayerConnected]] = function(_, comp){
    let engineerBuildingsLevel = get_matching_mode_info()?.extraParams.engineerBuildingsLevel
    comp.matching_info__engineerBuildingsLevel = engineerBuildingsLevel ?? "1_3"
    comp.matching_info__engineerBuildingsLevelReceived = (comp.matching_info__engineerBuildingsLevelReceived || engineerBuildingsLevel != null)
    debug($"Current matching BR level {comp.matching_info__engineerBuildingsLevel}")
    }
  }
  { comps_rw = [
    ["matching_info__engineerBuildingsLevel", ecs.TYPE_STRING],
    ["matching_info__engineerBuildingsLevelReceived", ecs.TYPE_BOOL]
  ] },
  { tags = "server" }
)
