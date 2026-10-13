from "%ui/meta/clientApi.nut" import gen_testdrive_squad_profile_jwt_v2, gen_testdrive_vehicle_profile_jwt_v2, gen_testdrive_weapon_profile_jwt_v2
from "%ui/battleData/sendSoldiersData.nut" import mkJwtArmiesCbNoRetries, saveJwtResultToJson, setNextBattleData
from "%ui/configs/battleScenes.nut" import getTestDriveScene
from "%ui/gameLauncher.nut" import startGame
from "%ui/components/textButton.nut" import Regular
from "%ui/featureFlags.nut" import canTestDriveItems
from "%ui/ui_library.nut" import *

let isTestDriveProfileInProgress = Watched(false)


let getArmyId = @(data) data.findindex(@(_) true)


function startSquadTestDrive(squadId, shopItemGuid = "") {
  if (isTestDriveProfileInProgress.get())
    return

  isTestDriveProfileInProgress.set(true)
  gen_testdrive_squad_profile_jwt_v2(squadId, shopItemGuid,
    mkJwtArmiesCbNoRetries(function(jwt, data) {
      isTestDriveProfileInProgress.set(false)
      if (jwt == "")
        return

      let armyId = getArmyId(data)
      setNextBattleData(armyId, jwt, data)
      startGame({ game = "enlisted", scene = getTestDriveScene(armyId) })
    }))
}


function startVehicleTestDrive(templateId) {
  if (isTestDriveProfileInProgress.get())
    return

  isTestDriveProfileInProgress.set(true)
  gen_testdrive_vehicle_profile_jwt_v2(templateId, "",
    mkJwtArmiesCbNoRetries(function(jwt, data) {
      isTestDriveProfileInProgress.set(false)
      if (jwt == "")
        return

      let armyId = getArmyId(data)
      setNextBattleData(armyId, jwt, data)
      startGame({ game = "enlisted", scene = getTestDriveScene(armyId) })
    }))
}


function startWeaponTestDrive(templateId) {
  if (isTestDriveProfileInProgress.get())
    return

  isTestDriveProfileInProgress.set(true)
  gen_testdrive_weapon_profile_jwt_v2(templateId,
    mkJwtArmiesCbNoRetries(function(jwt, data) {
      isTestDriveProfileInProgress.set(false)
      if (jwt == "")
        return

      let armyId = getArmyId(data)
      setNextBattleData(armyId, jwt, data)
      startGame({ game = "enlisted", scene = getTestDriveScene(armyId) })
    }))
}


let saveSquadTestDriveToFile = @(squadId)
  gen_testdrive_squad_profile_jwt_v2(squadId, "",
    mkJwtArmiesCbNoRetries(@(jwt, data) saveJwtResultToJson(jwt, data, $"sendSquadTestDrive_{squadId}")))

let saveVehicleTestDriveToFile = @(templateId)
  gen_testdrive_vehicle_profile_jwt_v2(templateId, "",
    mkJwtArmiesCbNoRetries(@(jwt, data) saveJwtResultToJson(jwt, data, $"sendVehicleTestDrive_{templateId}")))

let saveWeaponTestDriveToFile = @(templateId)
  gen_testdrive_weapon_profile_jwt_v2(templateId,
    mkJwtArmiesCbNoRetries(@(jwt, data) saveJwtResultToJson(jwt, data, $"sendWeaponTestDrive_{templateId}")))


console_register_command(saveSquadTestDriveToFile, "profileData.squadTestDriveToJson")
console_register_command(saveVehicleTestDriveToFile, "profileData.vehicleTestDriveToJson")
console_register_command(saveWeaponTestDriveToFile, "profileData.weaponTestDriveToJson")


let testDriveByItemType = {
  vehicle = true
  boltaction = true
  boltaction_noscope = true
  submgun = true
  mgun = true
  assault_rifle = true
  assault_semi = true
  semiauto = true
  semiauto_sniper = true
  shotgun = true
  carbine_pistol = true
  rifle_at_grenade_launcher = true
  rifle_grenade_launcher = true
  mortar = true
  flamethrower = true
  launcher = true
  antitank_rifle = true
  infantry_launcher = true
  carbine_tanker = true
  flaregun = true
  sideweapon = true
}

function mkTestDriveButtonUi(item, locId, override = {}, cb = @() null) {
  if (item == null)
    return null

  let { basetpl, itemtype } = item
  if (!(testDriveByItemType?[itemtype] ?? false))
    return null

  let watch = [canTestDriveItems, isTestDriveProfileInProgress]
  return @() !canTestDriveItems.get() || isTestDriveProfileInProgress.get()
    ? { watch }
    : {
        watch
        children = Regular(loc(locId),
          function() {
            if (itemtype == "vehicle")
              startVehicleTestDrive(basetpl)
            else
              startWeaponTestDrive(basetpl)
            cb()
          }, override
        )
      }.__update(override)
}

let canTestDriveItem = @(item)
  item != null && (testDriveByItemType?[item.itemtype] ?? false)

let mkCommonTestDriveButtonUi = @(item, override = {}, cb = @() null)
  canTestDriveItem(item)
    ? mkTestDriveButtonUi(item, "testDrive/common", override, cb)
    : null

function mkItemTestDriveButtonUi(item, override = {}, cb = @() null) {
  if (!canTestDriveItem(item))
    return null

  let testDriveLocId = item.itemtype == "vehicle" ? "testDrive/vehicle" : "testDrive/item"
  return mkTestDriveButtonUi(item, testDriveLocId, override, cb)
}


return {
  isTestDriveProfileInProgress
  startSquadTestDrive
  mkItemTestDriveButtonUi
  mkCommonTestDriveButtonUi
}
