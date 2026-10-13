import "%ui/components/mkBulletTypeIcon.nut" as mkBulletTypeIcon
import "%dngscripts/ecs.nut" as ecs
from "%ui/components/itemsInfo.nut" import itemNameFromTemplate
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "das.hitcam" import get_weapons_for_hangar_hitcam
from "%ui/meta/profile.nut" import curCampItems
from "%ui/ui_library.nut" import *

let weaponsTable = {}
let selWeaponEid = Watched(ecs.INVALID_ENTITY_ID)

function initWeaponList() {
  if (weaponsTable.len() == 0)
    foreach (weapon in get_weapons_for_hangar_hitcam())
      weaponsTable[weapon] <- true
}

let db = ecs.g_entity_mgr.getTemplateDB()

function getTurrets(templateId) {
  if (templateId == null)
    return []

  let template = db.getTemplateByName(templateId)
  if (template == null)
    return []

  let turrets = template?.getCompValNullable("turret_control__turretInfo").getAll() ?? []
  let ammoDistribution = template?.getCompValNullable("turrets__initAmmoDistribution").getAll() ?? []
  let mgAmmoDistribution = template?.getCompValNullable("turrets__initAmmoDistributionMachineguns").getAll() ?? []

  let turretsListRes = []
  foreach (turret in turrets) {
    let { gun = "" } = turret
    let gunTemplates = gun.split("+")
    let isMain = gunTemplates.contains("main_turret")
    let isTurret = gunTemplates.contains("turret_with_several_types_of_shells")
    turretsListRes.append({
      gunTemplateId = gunTemplates?[0] ?? ""
      isMain
      isTurret
      slots = (isTurret ? ammoDistribution : mgAmmoDistribution).map(@(v) v.slot)
    })
  }

  return turretsListRes
}

function hasSameWeapons(weapons, templateId, name) {
  if (weapons?[name] == null)
    weapons[name] <- []

  let turretIds = getTurrets(templateId).map(@(v) v.gunTemplateId).sort()
  foreach (storedWeapons in weapons[name]) {
    if (isEqual(storedWeapons, turretIds))
      return true
  }

  weapons[name].append(turretIds)
  return false
}

let oppositeArmies = {
  jap = "usa"
  usa = "jap"
  ussr = "ger"
  ger = "ussr"
}

function mkHitcamData() {
  let oppositeArmy = oppositeArmies[curArmy.get()]
  let hitcamArmyId = Watched(oppositeArmy)
  let hitcamVehicleId = Watched(null)
  let weaponId = Watched(null)
  let ammoIndex = Watched(0)
  let shotDistance = Watched(50)
  let hitcamAmmoList = Watched([])

  let userVehicleIds = Computed(function() {
    let vehicleIds = {}

    curCampItems.get().each(function(item) {
      if (item?.itemtype == "vehicle"
          && item?.itemsubtype == "tank"
          && item?.gametemplate != null)
        vehicleIds[item.gametemplate] <- true
    })

    return vehicleIds
  })

  let hitcamVehiclesList = Computed(function() {
    let armyId = hitcamArmyId.get()
    if (armyId == null)
      return []

    let res = {}
    let weapons = {}

    let vehicleIds = userVehicleIds.get()
    foreach (template in allItemTemplates.get()?[armyId] ?? {}) {
      if (template?.itemtype == "vehicle"
          && template?.itemsubtype == "tank"
          && (!template?.isZeroHidden || vehicleIds?[template?.gametemplate])) {
        let { gametemplate = null } = template
        if (gametemplate != null
            && gametemplate not in res) {
          let name = itemNameFromTemplate(template)
          if (!hasSameWeapons(weapons, gametemplate, name))
            res[gametemplate] <- name
        }
      }
    }

    return res.topairs().sort(@(a, b) a[1] <=> b[1])
  })

  let setVehicleId = @(_v = null) hitcamVehicleId.set(hitcamVehiclesList.get()?[0][0])
  hitcamVehiclesList.subscribe(setVehicleId)
  setVehicleId()

  let turretsList = Computed(@() getTurrets(hitcamVehicleId.get()))

  function setAmmoData(_v = null) {
    let ammoListByTurret = []
    let usedIds = {}
    foreach (turret in turretsList.get()) {
      let { gunTemplateId, isTurret, slots } = turret
      if (gunTemplateId not in weaponsTable)
        return

      let gunTemplate = db.getTemplateByName(gunTemplateId)
      let gunName = loc(gunTemplate?.getCompValNullable("item__name") ?? "guns/noName")
      let ammoBlocksList = gunTemplate?.getCompValNullable("gun__ammoSetsInfo").getAll() ?? []
      let gunIcon = gunTemplate?.getCompValNullable("gun__icon")

      let turretAmmo = { gunTemplateId, gunName, ammoData = [] }
      foreach (slot in slots) {
        let ammo = ammoBlocksList?[slot][0]
        if (ammo == null)
          continue

        let aType = isTurret ? ammo?.type : null
        if (aType == "flamethrower")
          continue

        let id = ammo.blk
        if (usedIds?[id])
          continue

        usedIds[id] <- true

        turretAmmo.ammoData.append({
          slot
          aType
          icon = mkBulletTypeIcon({ bulletType = aType, icon = gunIcon }, [100, 100])
        })
      }
      ammoListByTurret.append(turretAmmo)
    }
    hitcamAmmoList.set(ammoListByTurret)
  }

  function getFirstAvailableSlot() {
    foreach (i, data in hitcamAmmoList.get()) {
      if (data?.ammoData[0].slot != null)
        return i
    }

    return 0
  }

  function setWeaponId(_v = null) {
    let slot = getFirstAvailableSlot()
    weaponId.set(hitcamAmmoList.get()?[slot].gunTemplateId)
    ammoIndex.set(hitcamAmmoList.get()?[slot].ammoData[0].slot)
  }

  function createWeaponEntity(_v = null) {
    ecs.g_entity_mgr.destroyEntity(selWeaponEid.get())
    selWeaponEid.set(ecs.g_entity_mgr.createEntity(weaponId.get(), {}))
  }

  turretsList.subscribe(setAmmoData)
  hitcamAmmoList.subscribe(setWeaponId)
  weaponId.subscribe(createWeaponEntity)

  setAmmoData()
  setWeaponId()
  createWeaponEntity()

  return {
    hitcamArmyId, hitcamVehicleId, weaponId, ammoIndex, shotDistance, hitcamAmmoList, turretsList,
    hitcamVehiclesList
  }
}

return {
  mkHitcamData
  initWeaponList
  selWeaponEid
}
