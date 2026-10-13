import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *
from "dasevents" import CmdOpenArtilleryMap
let artilleryBoxShellTypes = Watched([])
let isHeroUseArtilleryBox = Watched(false)

let localPlayerArtillery = mkEcsComputed({
  comps = [
    ["artillery__available", ecs.TYPE_BOOL],
    ["artillery__availableAtTime", ecs.TYPE_FLOAT],
  ]
  
  comps_rq = ["player", ["artillery__wasAvailableForSquad", ecs.TYPE_EID]]
  comps_filter = [["is_local", ecs.TYPE_BOOL]]
  filter = "is_local"
})

let artilleryIsAvailable = Computed(@() localPlayerArtillery.get()?.artillery__available ?? false)
let artilleryAvailableAtTime = Computed(@() localPlayerArtillery.get()?.artillery__availableAtTime ?? -1.0)



let teamAircraftRequests = mkEcsComputedEidMap({
  comps = [
    ["team__aircraftRequestAvailableAtTime", ecs.TYPE_FLOAT],
    ["team__aircraftRequestFromBoxAvailableAtTime", ecs.TYPE_FLOAT],
    ["team__id", ecs.TYPE_INT]
  ]
})

let localTeamAircraftRequest = Computed(function() {
  let team = localPlayerTeam.get()
  foreach (row in teamAircraftRequests.get())
    if (row.team__id == team)
      return row
  return null
})

let aircraftRequestAvailableAtTime = Computed(@() localTeamAircraftRequest.get()?.team__aircraftRequestAvailableAtTime ?? -1.0)
let aircraftRequestFromBoxAvailableAtTime = Computed(@() localTeamAircraftRequest.get()?.team__aircraftRequestFromBoxAvailableAtTime ?? -1.0)

let heroRadioEid = mkEcsComputed({
  comps = [["human_weap__radioEid", ecs.TYPE_EID]]
  comps_rq = ["hero"]
  defVal = ecs.INVALID_ENTITY_ID
})
let isHeroRadioman = Computed(@() heroRadioEid.get() != ecs.INVALID_ENTITY_ID)

let localPlayerArtilleryTemplates = mkEcsComputed({
  comps = [["artillery__templates", ecs.TYPE_STRING_LIST]]
  comps_rq = ["player"]
  comps_filter = [["is_local", ecs.TYPE_BOOL]]
  filter = "is_local"
  defVal = []
})


let normalArtillerShelTypes = Computed(function() {
  let db = ecs.g_entity_mgr.getTemplateDB()
  return localPlayerArtilleryTemplates.get().map(function(templateName) {
    let artilleryTemplate = db.getTemplateByName(templateName)
    return {
      name = artilleryTemplate?.getCompValNullable("artillery__name") ?? templateName
      radius = artilleryTemplate?.getCompValNullable("artillery_zone__radius") ?? 0.
      isLine = artilleryTemplate?.getCompValNullable("artillery__isLineShape") ?? false
      maxLength = artilleryTemplate?.getCompValNullable("artillery__maxLineLength") ?? 0.0
      requestPhrase = artilleryTemplate?.getCompValNullable("artillery__strikeRequestSpeech") ?? "artStrikeRequest"
      responsePhrase = artilleryTemplate?.getCompValNullable("artillery__strikeRespondSpeech") ?? "artStrikeRespond"
    }
  })
})

let artilleryAvailableShellTypes = Computed(@() isHeroUseArtilleryBox.get() ? artilleryBoxShellTypes.get() : normalArtillerShelTypes.get())

ecs.register_es("artillery_box_shell_types", {
  [CmdOpenArtilleryMap] = function(_, comp) {
    let db = ecs.g_entity_mgr.getTemplateDB()
    let templatesNames = ecs.obsolete_dbg_get_comp_val(comp.human_use_object__selectedObject, $"artillery_box__artilleryTemplates{localPlayerTeam.get()}", [])
    if (templatesNames.len() == 0){
      artilleryBoxShellTypes.set([])
      isHeroUseArtilleryBox.set(false)
    }
    else{
      let types = templatesNames.getAll().map(function(templateName) {
          let artilleryTemplate = db.getTemplateByName(templateName)
          return {
            name = artilleryTemplate?.getCompValNullable("artillery__name") ?? templateName
            radius = artilleryTemplate?.getCompValNullable("artillery_zone__radius") ?? 0.
            isLine = artilleryTemplate?.getCompValNullable("artillery__isLineShape") ?? false
            maxLength = artilleryTemplate?.getCompValNullable("artillery__maxLineLength") ?? 0.0
            requestPhrase = artilleryTemplate?.getCompValNullable("artillery__strikeRequestSpeech") ?? "artStrikeRequest"
            responsePhrase = artilleryTemplate?.getCompValNullable("artillery__strikeRespondSpeech") ?? "artStrikeRespond"
          }
        })
      artilleryBoxShellTypes.set(types)
      isHeroUseArtilleryBox.set(true)
    }
  },
},
{
  comps_ro=[["human_use_object__selectedObject", ecs.TYPE_EID]]
  comps_rq=["hero"]
},
{
  before="artilllery_map_ui_es"
})



let teamArtilleryLimits = mkEcsComputedEidMap({
  comps = [
    ["artillery_limit__current", ecs.TYPE_INT_LIST],
    ["artillery_limit__max", ecs.TYPE_INT_LIST],
    ["team__id", ecs.TYPE_INT],
  ]
})



let artilleryIsAvailableByLimit = Computed(function() {
  let team = localPlayerTeam.get()
  foreach (row in teamArtilleryLimits.get()) {
    if (row.team__id != team)
      continue
    let current = row.artillery_limit__current
    foreach (i, maxCount in row.artillery_limit__max)
      if ((current?[i] ?? 0) < maxCount)
        return true
    return false
  }
  return true
})

let artilleryAvailableTimeLeft = mkCountdownTimerPerSec(artilleryAvailableAtTime)
let aircraftRequestAvailableTimeLeft = mkCountdownTimerPerSec(aircraftRequestAvailableAtTime)
let aircraftRequestFromBoxAvailableTimeLeft = mkCountdownTimerPerSec(aircraftRequestFromBoxAvailableAtTime)
let activeAircraftRequestTimeLeft = Computed(@() isHeroUseArtilleryBox.get()
  ? aircraftRequestFromBoxAvailableTimeLeft.get()
  : aircraftRequestAvailableTimeLeft.get())
let artilleryIsReady = Computed(@() artilleryIsAvailable.get() && artilleryAvailableTimeLeft.get() <= 0 && artilleryIsAvailableByLimit.get())

return {
  artilleryAvailableTimeLeft = artilleryAvailableTimeLeft
  activeAircraftRequestTimeLeft
  artilleryIsReady = artilleryIsReady
  artilleryIsAvailable = artilleryIsAvailable
  isHeroRadioman = isHeroRadioman
  artilleryIsAvailableByLimit
  artilleryAvailableShellTypes
}