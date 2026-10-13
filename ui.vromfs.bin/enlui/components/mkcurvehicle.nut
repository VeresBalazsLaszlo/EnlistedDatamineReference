from "%ui/components/itemsInfo.nut" import itemNameFromItem
from "%ui/components/itemPkg.nut" import statusTier, mkNoVehicle, mkVehicleHint
from "%ui/components/defcomps.nut" import txt, autoscrollText
from "%ui/components/mkSpecialItemIcon.nut" import mkSpecialItemIcon
from "%ui/style/designConst.nut" import squadSlotBgIdleColor, squadSlotBgHoverColor, disabledTxtColor, smallPadding, midPadding, listCtors
from "%ui/style/cursors.nut" import setTooltip
from "%ui/state/appState.nut" import isInBattleState
from "%ui/soldiers/model/state.nut" import armySquadsById
from "%ui/meta/profile.nut" import squadsByArmies
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/vehicles/customizePkg.nut" import mkVehicleImage
from "%ui/soldiers/model/config/outfitConfig.nut" import getSquadCamoByVehicle
from "%ui/meta/servProfile.nut" import vehCamouflages
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/ui_library.nut" import *

let { txtColor } = listCtors

let bgColor = @(sf, isAvailable) sf & S_HOVER ? squadSlotBgHoverColor
  : isAvailable ? squadSlotBgIdleColor
  : disabledTxtColor

let mkVehicleInfo = @(vehicleInfo, soldiersInSquad, sf) {
  size = FLEX
  flow = FLOW_VERTICAL
  children = [
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = [
        autoscrollText({
          vplace = ALIGN_BOTTOM
          text = itemNameFromItem(vehicleInfo)
          textParams = { color = txtColor(sf) }
        })
        {
          hplace = ALIGN_RIGHT
          children = statusTier(vehicleInfo)
        }
      ]
    }
    0 == (vehicleInfo?.crew ?? 0) ? null
      : txt({
          vplace = ALIGN_BOTTOM
          text = " ".join([loc("vehicleDetails/crew"), $"{soldiersInSquad}/{vehicleInfo.crew}"])
          color = txtColor(sf)
        })
  ]
}

let mkCurVehicle = @(
  vehicleInfo, soldiersList, openChooseVehicle = null, topRightChild = null,
  canSpawnOnVehicle = Watched(true)
) watchElemState(function(sf) {
  let vehicle = vehicleInfo.get()
  let camouflage = getSquadCamoByVehicle(vehicle,
    squadsByArmies.get(), armySquadsById.get(), gameProfileLookCfg.get())
  let { gametemplate = null, growthTier = 1 } = vehicle

  return {
    watch = [vehicleInfo, canSpawnOnVehicle, soldiersList, isInBattleState, vehCamouflages,
      squadsByArmies, armySquadsById]
    size = FLEX_H
    behavior = Behaviors.Button
    onClick = openChooseVehicle
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = bgColor(sf, canSpawnOnVehicle.get())
    onHover = @(on) setTooltip(!isInBattleState.get() && on && gametemplate != null
      ? mkVehicleHint(vehicle) : null)
    children = gametemplate == null
      ? mkNoVehicle(sf)
      : [
          mkVehicleImage(vehCamouflages.get(), vehicle, camouflage)
          mkSpecialItemIcon(vehicle, hdpxi(26), { margin = 0 })
          {
            size = FLEX
            flow = FLOW_HORIZONTAL
            padding = midPadding
            halign = ALIGN_RIGHT
            children = [
              mkVehicleInfo(vehicle, soldiersList.get().len(), sf)
              topRightChild
            ]
          }
          {
            vplace = ALIGN_BOTTOM
            hplace = ALIGN_RIGHT
            padding = midPadding
            children = mkBattleRatingShort(growthTier)
          }
        ]
      }
  })

return kwarg(mkCurVehicle)
