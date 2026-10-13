from "%ui/components/missionsPresentation.nut" import getMissionPresentation

let allInfo = {}

let misPrefixToCampaign = {
  volokolamsk = "moscow"
  normandy = "normandy"
  berlin = "berlin"
  tunisia = "tunisia"
  stalingrad = "stalingrad"
  pacific = "pacific"
  rzhev = "rzhev"
  ardennes = "ardennes"
  burma = "burma"
  manchuria = "manchuria"
}

function mkMissionInfo(scene) {
  let id = scene == "" ? "" : scene.split("/").top().split(".")[0]
  let campaign = misPrefixToCampaign.findvalue(@(_, prefix) id.indexof(prefix) == 0)
  return getMissionPresentation(id).__merge({ id, campaign })
}

function getMissionInfo(scene) {
  if (scene not in allInfo)
    allInfo[scene] <- mkMissionInfo(scene)
  return allInfo[scene]
}

return getMissionInfo
