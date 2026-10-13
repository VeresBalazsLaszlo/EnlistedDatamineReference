from "%ui/style/designConst.nut" import smallPadding
from "%ui/meta/configs.nut" import serverConfigs
from "%ui/meta/profile.nut" import campItemsByLink
from "%sqstd/math.nut" import ceil
from "%ui/ui_library.nut" import *

const ammoSize = hdpxi(14)

function calcAmmo(item, soldierGuid, weapData, slotType, configsVal, itemsByLink) {
  local increase = 1.0
  if (slotType == "primary") { 
    let slotsItems = itemsByLink?[soldierGuid] ?? []
    let { equip_ammo_increase = {} } = configsVal
    let itemsToIncreaseAmmo = slotsItems.reduce(@(res, slot) res.extend(slot), [])
    foreach (slot in itemsToIncreaseAmmo)
      increase += equip_ammo_increase?[slot?.basetpl] ?? 0.0
  }
  let ammoInGun = weapData.bullets
  let totalAmmo = max(ammoInGun * ceil(item.ammonum * increase), ammoInGun)
  let ammoInBag = totalAmmo - ammoInGun
  return { totalAmmo, ammoInBag, ammoInGun }
}


let mkAmmoInfo = @(item, soldierGuid, weapData, slotType, override = {})
  function() {
    let { color = null } = override
    let ammo = calcAmmo(item, soldierGuid, weapData, slotType, serverConfigs.get(), campItemsByLink.get())
    return {
      watch = [serverConfigs, campItemsByLink]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        {
          size = ammoSize
          rendObj = ROBJ_IMAGE
          image = Picture("ui/skin#ammo_icon.svg:{0}:{0}".subst(ammoSize))
          color
        }
        {
          rendObj = ROBJ_TEXT
          text = ammo.ammoInBag > 0 ? $"{ammo.ammoInGun}/{ammo.ammoInBag}" : ammo.ammoInGun
          fontSize = ammoSize
          color
        }
      ]
    }.__update(override)
  }


return {
  mkAmmoInfo
}
