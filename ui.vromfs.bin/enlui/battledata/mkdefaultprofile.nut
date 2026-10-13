from "json" import object_to_json_string
from "io" import file
from "dagor.fs" import dir_exists
from "%ui/meta/clientApi.nut" import gen_default_profile, gen_tutorial_profiles
from "dagor.debug" import logerr
from "%ui/ui_library.nut" import *

function prepareProfileData(profile) {
  let deleteSoldierKeys = [
    "bodyScale", 
    "perkPoints", 
    "heroTpl", 
    "appearance__rndSeed", 
  ]
  foreach (squad in profile?.squads ?? [])
    foreach (soldier in squad?.squad ?? [])
      foreach (key in deleteSoldierKeys)
        if (soldier?[key] != null)
          soldier.$rawdelete(key)

  local isSuccess = true
  foreach (squad in profile?.squads ?? []) {
    if ((squad?.squad.len() ?? 0) == 0) {
      isSuccess = false
      logerr($"Squad /*{squad.squadId}*/ is empty! Please fix the squad in profileServer configs.")
    }
  }
  return isSuccess
}

function saveProfileImpl(profile, fileName, path, pretty = true) {
  local filePath = fileName
  if (dir_exists(path))
    filePath = $"{path}/{fileName}"
  else
    console_print($"Directory '{path}' does not exist. Saving to the current directory.")

  let output = file(filePath, "wt+")
  if (fileName.endswith(".nut"))
    output.writestring("return ");
  output.writestring(object_to_json_string(profile, pretty))
  output.close()
  console_print($"Saved to {filePath}")
}

function saveOneProfile(profile, fileName, path, pretty = true) {
  if (profile == null)
    return
  if (prepareProfileData(profile))
    saveProfileImpl(profile, fileName, path, pretty)
}

function saveProfilePack(profiles, to_file) {
  if (profiles == null)
    return
  let isSuccess = profiles.findvalue(@(p) !prepareProfileData(p)) == null
  if (isSuccess)
    saveProfileImpl(profiles, to_file, "../prog/sq_globals/data")
}

const defArmies = ["usa", "ussr", "ger", "jap"]

local consoleProgressId = 0
function startProgress(title) {
  console_command("console.progress_indicator {0} \"{1}\"".subst(++consoleProgressId, title))
  return consoleProgressId
}
let stopProgress = @(id) console_command($"console.progress_indicator {id}")

console_register_command(function(isPretty) {
  let prgId = startProgress("meta.genDefaultProfile")
  gen_default_profile("default", defArmies, function(res) {
    stopProgress(prgId)
    let { defaultProfile = null } = res
    if (defaultProfile == null)
      return
    foreach(armyId, armyData in defaultProfile) {
      let profile = { [armyId] = armyData }
      saveOneProfile(profile, $"{armyId}.json", "../prog/enlisted_pkg_dev/default/data", !!isPretty)
    }
  })
}, "meta.genDefaultProfile")

console_register_command(function(isPretty) {
  let prgId = startProgress("meta.genDevProfile")
  gen_default_profile("dev", defArmies, function(res) {
    stopProgress(prgId)
    let { defaultProfile = null } = res
    if (defaultProfile == null)
      return
    foreach(armyId, armyData in defaultProfile) {
      let profile = { [armyId] = armyData }
      saveOneProfile(profile, $"{armyId}.json", "../prog/gamebase_dev/enlisted_pkg_dev/game/data/dev_profile", !!isPretty)
    }
  })
}, "meta.genDevProfile")

console_register_command(function(isPretty) {
  let prgId = startProgress("meta.genBotsProfile")
  gen_default_profile("bots", defArmies, function(res) {
    stopProgress(prgId)
    foreach (id, data in (res?.defaultProfile ?? {}))
      saveOneProfile(data, $"bots_profile_{id}.nut", "../prog/sq_globals/data", !!isPretty)
  })
}, "meta.genBotsProfile")

console_register_command(function() {
  let prgId = startProgress("meta.genTutorialProfiles")
  gen_tutorial_profiles(function(res) {
    stopProgress(prgId)
    foreach(k, v in res)
      saveProfilePack(v, $"tutorial_profiles_{k}.nut")
  })
}, "meta.genTutorialProfiles")
