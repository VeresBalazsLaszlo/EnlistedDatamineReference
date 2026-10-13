from "dagor.system" import DBGLEVEL
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/meta/profile.nut" import campaignsByArmy
from "%ui/meta/servProfile.nut" import wallposters
from "%ui/profile/wallpostersPresentation.nut" import getWPPresentation
from "%ui/meta/clientApi.nut" import add_wallposter
from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/ui_library.nut" import *

let wpIdSelected = Watched(null)

let wallpostersServerCfg = mkComputedConfigGet("wallpostersCfg", {})

let wallpostersCfg = Computed(function() {
  let campaigns = campaignsByArmy.get()
  let armies = allArmiesInfo.get()
  let wpReceived = {}
  foreach (wp in wallposters.get())
    wpReceived[wp.tpl] <- true

  let res = []
  foreach (armyId, wpData in wallpostersServerCfg.get())
    foreach (wallposterTpl, wallposter in wpData ?? {}) {
      let { isNotOwnedHidden = false } = wallposter
      let hasReceived = wallposterTpl in wpReceived
      let armyInfo = armies?[armyId]
      res.append({
        armyId = armyInfo ? armyId : null
        armyLocId = armyInfo ? $"country/{armyInfo.country}" : armyId
        wallposterTpl
        isNotOwnedHidden
        hasReceived
        isHidden = isNotOwnedHidden && !hasReceived
        campaignId = campaigns?[armyId].id
        campaignTitle = campaigns?[armyId].title
      }.__update(getWPPresentation(wallposterTpl)))
    }
  res.sort(@(a, b) a.armyId <=> b.armyId || a.wallposterTpl <=> b.wallposterTpl)
  return res
})

let wpCfgFiltered = Computed(@()
  wallpostersCfg.get().filter(@(wp) wp.hasReceived && (!wp.isHidden || DBGLEVEL != 0)))

let isWpHidden = Computed(@() wpCfgFiltered.get().len() == 0)

console_register_command(@(id) add_wallposter(id), "meta.addWallposter")

return {
  wallpostersCfg
  wpCfgFiltered
  wpIdSelected
  isWpHidden
}
