import "%ui/hud/state/armyData.nut" as armyData
import "%ui/components/mkSoldiersList.nut" as mkMainSoldiersBlock
import "%ui/components/mkCurVehicle.nut" as mkCurVehicle
import "%ui/hud/huds/player_info/medkitIcon.nut" as mkMedkitIcon
import "%ui/hud/huds/player_info/repairIcon.nut" as mkRepairIcon
import "%ui/hud/huds/player_info/flaskIcon.nut" as mkFlaskIcon
from "%ui/hud/state/respawnState.nut" import soldiersList, curSoldierIdx, canSpawnOnVehicleBySquad, vehicleInfo, squadIndexForSpawn, freeTankInfo
from "%ui/hud/huds/player_info/grenadeIcon.nut" import mkGrenadeIcon
from "%ui/hud/huds/player_info/mineIcon.nut" import mkMineIcon
from "%ui/style/designConst.nut" import defTxtColor, darkTxtColor, smallPadding
from "%ui/ui_library.nut" import *

const sIconSize = hdpxi(15)

let canSpawnOnVehicle = Computed(@()
  canSpawnOnVehicleBySquad.get()?[squadIndexForSpawn.get()] ?? false)

function addCardChild(soldier, sf, _isSelected) {
  let { grenadeType = null, mineType = null, targetHealCount = 0, targetRepairCount = 0, hasFlask = false } = soldier
  let color = sf & S_HOVER ? darkTxtColor : defTxtColor
  return {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = hdpx(2)
    padding = smallPadding
    children = [
      targetHealCount > 0 ? mkMedkitIcon(sIconSize, color) : null
      targetRepairCount > 0 ? mkRepairIcon(sIconSize, color) : null
      hasFlask ? mkFlaskIcon(sIconSize, color) : null
      mkGrenadeIcon(grenadeType, sIconSize, color) ?? mkMineIcon(mineType, sIconSize, color)
    ]
  }
}

let squadInfo = @(curVehicleInfo) mkMainSoldiersBlock({
  soldiersListWatch = soldiersList
  expToLevelWatch = Computed(@() armyData.get()?.expToLevel)
  curVehicleInfo
  hasVehicleWatch = Computed(@() curVehicleInfo.get() != null)
  curSoldierIdxWatch = curSoldierIdx
  curVehicleUi = mkCurVehicle({ canSpawnOnVehicle, vehicleInfo = curVehicleInfo, soldiersList })
  canDeselect = false
  addCardChild
})

let normSquadInfo = squadInfo(vehicleInfo)
let freeTankSquadInfo = squadInfo(freeTankInfo)

return {
  normSquadInfo
  freeTankSquadInfo
}
