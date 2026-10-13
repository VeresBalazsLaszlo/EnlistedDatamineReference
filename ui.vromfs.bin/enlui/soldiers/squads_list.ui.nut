import "%ui/soldiers/model/squadsParams.nut" as squadsParams
import "%ui/components/mkSquadsList.nut" as mkCurSquadsList
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import multySquadPanelSize, smallPadding, darkTxtColor
from "%ui/soldiers/model/state.nut" import curArmy, curSquadId, setCurSquadId, curChosenSquads, curUnlockedSquads, soldiersBySquad
from "%ui/researches/researchesState.nut" import allSquadsLevels
from "%ui/soldiers/model/soldierPerks.nut" import notChosenPerkSquads
from "%ui/vehicles/unseenVehicles.nut" import unseenSquadsVehicle
from "%ui/soldiers/model/unseenSquads.nut" import unseenSquads
from "%ui/soldiers/model/chooseSquadsState.nut" import openChooseSquadsWnd
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%ui/shop/armySlotDiscount.nut" import armySlotDiscount
from "%ui/components/soldiersUiComps.nut" import mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN
from "%ui/components/textButton.nut" import Regular, textColor
from "%ui/soldiers/armySquadTier.nut" import getLiveSquadBR, BRInfoBySquads
from "%ui/shop/currencyComp.nut" import mkDiscountWidget
from "%ui/ui_library.nut" import *

let unseenIcon = blinkUnseenIcon(0.7)

let mkUnseenAlert = @(guid) mkAlertIcon(ITEM_ALERT_SIGN, Computed(@()
  (unseenSquadsVehicle.get()?[guid].len() ?? 0) > 0
))

let mkPerksAlert = @(squadId) mkAlertIcon(PERK_ALERT_SIGN, Computed(@()
  squadId in notChosenPerkSquads.get()?[curArmy.get()]))

let managementIcon = @(sf) {
  rendObj = ROBJ_IMAGE
  size = const [hdpxi(45), hdpxi(30)]
  keepAspect = KEEP_ASPECT_FIT
  image = Picture("ui/skin#icons/squad_icon.svg:{0}:{1}".subst(hdpxi(45), hdpxi(30)))
  color = sf & S_HOVER ? darkTxtColor : 0xEEB3BDC1
}

function mkSlotAlertsComponent(squadId, guid){
  return @() {
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_RIGHT
    valign = ALIGN_CENTER
    children = [
      mkUnseenAlert(guid)
      mkPerksAlert(squadId)
    ]
  }
}

let unseenSquadsIcon = @() {
  watch = [unseenSquads, curArmy]
  hplace = ALIGN_RIGHT
  children = (unseenSquads.get()?[curArmy.get()] ?? {}).findindex(@(v) v)
    ? unseenIcon
    : null
}


let mkSquadManagementBtn = @(restSquadsCount)
  Regular(@(_textField, _params, _handler, _group, sf)
    {
      size = FLEX
      children = [
        @() {
          flow = FLOW_HORIZONTAL
          watch = [restSquadsCount]
          halign = ALIGN_CENTER
          vplace = ALIGN_CENTER
          valign = ALIGN_CENTER
          gap = smallPadding
          size = FLEX
          children = [
            managementIcon(sf)
            restSquadsCount.get() < 1 ? null : {
              rendObj = ROBJ_TEXT
              color = textColor(sf)
              text = $"+{restSquadsCount.get()}"
            }.__update(fontSub)
          ]
        }
        unseenSquadsIcon
        @() {
          size = FLEX_H
          watch = armySlotDiscount
          children = armySlotDiscount.get() == 0 ? null
            : mkDiscountWidget(armySlotDiscount.get(), { size = const [hdpx(60), hdpx(25)],
                hplace = ALIGN_LEFT })
        }
      ]
    },
    @() openChooseSquadsWnd(curArmy.get(), curSquadId.get()),
    {
      btnWidth = multySquadPanelSize[0]
      rendObj = ROBJ_WORLD_BLUR_PANEL
    })


function mkSquadsList() {
  let restSquadsCount = Computed(@()
    max(curUnlockedSquads.get().len() - curChosenSquads.get().len(), 0))

  let squadManageButton = mkSquadManagementBtn(restSquadsCount)
  let brInfoBySquadsVal = BRInfoBySquads.get()
  let curSquadsList = Computed(@() (curChosenSquads.get() ?? [])
    .map(function(squad) {
      let {squadId, guid} = squad
      let { size = 0 } = squadsParams.get()?[curArmy.get()][squadId]
      let currentSize = soldiersBySquad.get()?[guid].len() ?? 0
      return squad.__merge({
        addChild = mkSlotAlertsComponent(squadId, guid)
        level = allSquadsLevels.get()?[squadId] ?? 0
        battleRating = getLiveSquadBR(brInfoBySquadsVal, squadId)
        squadSize = currentSize < size ? $"{currentSize}/{size}" : currentSize
      })
    }))

  return mkCurSquadsList({
    curSquadsList
    curSquadId
    setCurSquadId
    addedObj = squadManageButton
  })
}

return {
  mkSquadsList
}
