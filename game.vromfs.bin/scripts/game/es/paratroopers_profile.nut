import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let { logerr, debug } = require("dagor.debug")
let { loadJson } = require("%sqstd/json.nut")
let { convertGunMods, applyGunUpgrades } = require("%scripts/game/utils/profile_init.nut")
let { EventFirstPlayerConnected, CmdUpdateParatroopersSchemes } = require("dasevents")
let { isNoBotsMode } = require("%enlSqGlob/missionType.nut")
let { get_matching_mode_info = @() {extraParams = {}} } = require_optional("dedicated")

function filterPresets(tag, presets) {
  for(local i = presets.len() - 1; i >= 0; i--) {
    if ((tag == null || tag == "") && (presets[i]?.tags?[0] ?? "") != "")
      tag = presets[i].tags[0]
    if ((tag != null && tag != "") && presets[i]?.tags != null && !presets[i].tags.contains(tag))
      presets.remove(i)
  }
}

let matchingInfoQuery = ecs.SqQuery("matchingInfoQuery", { comps_ro = [["matching_info__engineerBuildingsLevel", ecs.TYPE_STRING]]})

ecs.register_es("parse_paratroopers_schemes",
  { [[EventFirstPlayerConnected, CmdUpdateParatroopersSchemes]] = function(_, comp) {
    comp.paratroopers__supplySchemesAndSquads = loadJson(comp.paratroopers__supplySchemesAndSquadsJson)
    if (comp.paratroopers__supplySchemesAndSquads == null) {
      comp.paratroopers__supplySchemesAndSquads = { ["default"] = "default" }
    }
    let profilePath = isNoBotsMode() ? comp.paratroopers__supplySchemesNoBotsJson : comp.paratroopers__supplySchemesJson
    comp.paratroopers__supplySchemes = loadJson(profilePath)
    if (comp.paratroopers__supplySchemes == null) {
      logerr($"Failed to load paratoopers profile /*{profilePath}*/")
      return
    }
    let db = ecs.g_entity_mgr.getTemplateDB()
    local tag = get_matching_mode_info()?.extraParams.paratruper_tags ?? ""
    if (tag == ""){
      tag = matchingInfoQuery.perform(@(_, comp2) comp2.matching_info__engineerBuildingsLevel == "1_3" ? "low" : "high")
    }
    debug($"Applying paratroopers scheme tag {tag}")
    foreach (squad in comp.paratroopers__supplySchemes) {
      filterPresets(tag, squad)
      foreach(preset in squad) {
        foreach(soldier in preset.soldiers) {
          convertGunMods(db, soldier)
          applyGunUpgrades(soldier)
        }
      }
    }
  }},
  { comps_ro = [
      ["paratroopers__supplySchemesJson", ecs.TYPE_STRING],
      ["paratroopers__supplySchemesNoBotsJson", ecs.TYPE_STRING],
      ["paratroopers__supplySchemesAndSquadsJson", ecs.TYPE_STRING]
    ]
    comps_rw = [
      ["paratroopers__supplySchemes", ecs.TYPE_OBJECT],
      ["paratroopers__supplySchemesAndSquads", ecs.TYPE_OBJECT]
    ]
  },
  { tags = "server" })
