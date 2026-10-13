from "%sqstd/json.nut" import loadJson
from "dagor.debug" import logerr
from "types" import Array, String

let i = @(pos) "enlisted_idle_{0}_weapon".subst(pos >= 10 ? pos : $"0{pos}")

const pathToCfg = "config/menu_poses_for_weapons.json"

local weaponToAnimState = freeze({
  defaultPoses = [i(11)]
  unarmedPoses = ["enlisted_idle_01", "enlisted_idle_02","enlisted_idle_03", "enlisted_idle_04"]
  standardRifle = [9, 12, 13, 14, 15, 16, 18].map(i)
  specificRifle = [9, 12, 14, 16, 18].map(i)
  specificGun = [9, 11, 12, 13, 14, 15, 16, 18].map(i)
  standardPistol = ["enlisted_idle_03", "enlisted_idle_02", i(19)]
})
local weaponToSittingAnimState = {defaultPoses = [i(20)]}


function transformArrayOfPoses(arr, arrName) {
  foreach (idx, pose_name in arr) {
    let t = type(pose_name)
    if (t=="string")
      continue
    if (t=="integer")
      arr[idx] = i(pose_name)
    else {
      println($"in {arrName}, at position {idx} should be string (pose name) or integer (default pose name), but found {t}")
      logerr("incorrect pose in pose list")
    }
  }
  return arr
}

function cvtToPosesLists(jsonData, keyName, namedPoses) {
  let posesData = jsonData?[keyName]
  if (!posesData)
    return null

  let posesList = {}
  foreach (k, v in posesData) {
    if (k.startswith("__"))
      continue

    if (v instanceof Array)
      posesList[k] <- transformArrayOfPoses(v, k)
    else if (v instanceof String) {
      if (v in namedPoses)
        posesList[k] <- namedPoses[v]
      else
        logerr($"unknown named pose /*{v}*/")
    }
    else {
      println($"{k}:{v}")
      logerr($"incorrect pose list for /*{keyName}*/")
    }
  }
  return posesList
}

function loadPosesFromJson() {
  let fromJson = loadJson(pathToCfg)
  let { namedPoses = {} } = fromJson
  foreach (k, v in namedPoses)
    transformArrayOfPoses(v, k)

  weaponToAnimState = cvtToPosesLists(fromJson, "weaponToAnimState", namedPoses)
    ?? weaponToAnimState
  weaponToSittingAnimState = cvtToPosesLists(fromJson, "weaponToSittingAnimState", namedPoses)
    ?? weaponToSittingAnimState
}

loadPosesFromJson()

let getMentionedAnimStates = @(weaponToAnimStates) weaponToAnimStates.reduce(function(tbl, val) {
  val.each(@(id) tbl[id] <- true)
  return tbl
}, {})

let allIdleAnims =
  getMentionedAnimStates(weaponToAnimState)
  .__merge(getMentionedAnimStates(weaponToSittingAnimState))
  .keys().sort()

return freeze({
  weaponToAnimState
  weaponToSittingAnimState
  allIdleAnims
})