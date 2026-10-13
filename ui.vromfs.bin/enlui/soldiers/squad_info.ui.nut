import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesConfig
import "%ui/components/mkSoldiersList.nut" as mkMainSoldiersBlock
import "%ui/components/mkCurVehicle.nut" as mkCurVehicle
import "%ui/soldiers/components/squadHeader.nut" as squadHeader
import "%ui/helpers/squad_vehicle_seats.nut" as mkVehicleSeats
from "%ui/components/textButton.nut" import Regular
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import bigPadding, smallPadding, defTxtColor, slotBaseSize, squadSlotBgIdleColor
from "%ui/components/blinkingIcon.nut" import blinkingIcon
from "%ui/soldiers/model/state.nut" import curArmy, curSquadId, curSquad, curSquadParams,
  curVehicle, armySquadsById
from "%ui/meta/perks/perksExp.nut" import perkLevelsGrid
from "%ui/soldiers/model/reserve.nut" import curArmyReserve
from "%ui/vehicles/unseenVehicles.nut" import unseenSquadsVehicle
from "%ui/soldiers/model/squadInfoState.nut" import vehicleCapacity, isSquadRented, buyRentedSquad
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo, curSoldiersDataList, curSoldierIdx
from "%ui/soldiers/model/readySoldiers.nut" import curSquadSoldiersStatus
from "%ui/vehicles/vehiclesListState.nut" import hasSquadVehicle, selectVehParams
from "%ui/soldiers/model/chooseSoldiersState.nut" import openChooseSoldiersWnd
from "%ui/meta/clientApi.nut" import set_squad_outfit_preset
from "%ui/meta/curCampaign.nut" import looksByArmy, outfitCampaignsByArmies
from "%ui/meta/profile.nut" import curCampItems
from "%ui/style/cursors.nut" import setTooltip
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/shop/soldiersPurchaseState.nut" import unseenSoldierShopItems
from "%ui/components/unseenComps.nut" import smallUnseenNoBlink
from "%ui/soldiers/model/soldiersState.nut" import mkAlertInfo
from "%ui/mainMenu/sectionsState.nut" import curSection, Section
from "%ui/shop/armyShopState.nut" import goodManageData
from "%ui/components/defcomps.nut" import txt
from "%ui/components/mkCampaignSelector.nut" import mkSquadListOutfitButton
from "%ui/ui_library.nut" import *


let { manageBlinkingObject } = require("%ui/components/blinkingIcon.nut")

function mkSquadInfo() {
  let vehicleInfo = Computed(function() {
    let vehGuid = curVehicle.get()
    if (vehGuid == null)
      return null

    return curCampItems.get()?[vehGuid]
  })


  function openChooseVehicle(event) {
    if (event.button >= 0 && event.button <= 2)
      selectVehParams.mutate(@(params) params.__update({
        armyId = curArmy.get()
        squadId = curSquadId.get()
        isCustomMode = false
        isHitcamMode = false
      }))
  }


  let allowedReserve = Computed(function() {
    let { maxClasses = null } = curSquadParams.get()
    if (maxClasses == null)
      return 0
    let classesCfgV = sClassesConfig.get()
    return curArmyReserve.get().reduce(function(res, s) {
      let kind = s?.sKind ?? classesCfgV?[s.sClass].kind
      return (maxClasses?[kind] ?? 0) > 0 ? res + 1 : res
    }, 0)
  })


  function openManageSoldiers() {
    let squad = curSquad.get()
    let { guid = null, squadId = null } = squad
    let armyId = getLinkedArmyName(squad)
    if (isSquadRented(squad)) {
      buyRentedSquad.set({ armyId, squadId, hasMsgBox = true })
      return
    }
    openChooseSoldiersWnd(guid, curSoldierInfo.get()?.guid)
  }

  function manageSoldiersBtn() {
    let hasUnseesSoldiers = unseenSoldierShopItems.get().len() > 0
    let hasManageBlink = "squadId" in goodManageData.get()
    let count = allowedReserve.get()
    let countText = count == 0
      ? loc("soldier/manageButton")
      : loc("soldier/manageButtonWithCount", { count })
    return {
      watch = [unseenSoldierShopItems, allowedReserve, goodManageData]
      size = FLEX_H
      children = [
        Regular(countText,
          openManageSoldiers, {
            fgChild = {
              flow = FLOW_HORIZONTAL
              hplace = ALIGN_RIGHT
              vplace = ALIGN_TOP
              gap = smallPadding
              padding = smallPadding
              children = [
                hasUnseesSoldiers
                  ? smallUnseenNoBlink.__merge({ size = hdpxi(15), fontSize = hdpxi(14) })
                  : null
              ]
            }
            hotkeys = [["^J:LS"]]
            onHover = @(on) setTooltip(on ? loc("msg/canAddSoldierToSquad") : null)
            btnWidth = FLEX
            rendObj = ROBJ_WORLD_BLUR_PANEL
          }
        )
        hasManageBlink ? manageBlinkingObject : null
      ]
    }
  }

  let curSquadUnseenVehicleCount = Computed(@() unseenSquadsVehicle.get()?[curSquad.get()?.guid].len() ?? 0)
  function unseenVehiclesMark() {
    let res = { watch = curSquadUnseenVehicleCount }
    if (curSquadUnseenVehicleCount.get() > 0)
      res.__update(blinkingIcon("arrow-up", curSquadUnseenVehicleCount.get()))
    return res
  }

  let freeSeatsInVehicle = Computed(function() {
    let seatsOrder = mkVehicleSeats(vehicleInfo.get())
    return seatsOrder.slice(curSoldiersDataList.get().len())
  })

  let wrapParams = {
    width = slotBaseSize[0] - bigPadding *2
    hGap = smallPadding
    vGap = smallPadding
    halign = ALIGN_CENTER
  }

  function freeSeatsBlock(freeSeats) {
    if (freeSeats.len() == 0)
      return null
    let uniqSeats = {}
    let seatsToShow = []
    foreach(seat in freeSeats) {
      let { locName } = seat
      if (locName not in uniqSeats) {
        uniqSeats[locName] <- true
        let seatsCount = freeSeats.reduce(function(res, v) {
          if (v.locName == locName)
            res++
          return res
        }, 0)
        local seatText = seatsCount < 2 ? loc(locName)
          : $"{loc(locName)} {loc("common/amountShort", { count = seatsCount })}"
        if (seatsToShow.len() > 0)
          seatText = $", {seatText}"
        seatsToShow.append(seatText)
      }
    }
    return {
      size = FLEX_H
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = squadSlotBgIdleColor
      flow = FLOW_VERTICAL
      padding = [smallPadding, bigPadding]
      halign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_TEXT
          hplace = ALIGN_CENTER
          text = loc("vehicle_seats/freeSeats")
          color = defTxtColor
        }.__update(fontSub)
        wrap(seatsToShow.map(txt), wrapParams)
      ]
    }
  }


  return function() {
    let watch = [ curSquad, vehicleInfo, freeSeatsInVehicle, curSoldiersDataList ]
    let squad = curSquad.get()
    if (squad == null)
      return { watch }

    let armyId = getLinkedArmyName(squad)
    let { guid = null, squadId = null } = squad

    return {
      watch
      size = FLEX_V
      onDetach = function() {
        if (curSection.get() != Section.MAIN)
          curSoldierIdx.set(null)
      }
      onAttach = function() {
        let { soldierIdx = null } = goodManageData.get()
        if (soldierIdx != null)
          gui_scene.setTimeout(0.5, @() curSoldierIdx.set(soldierIdx))
      }
      children = mkMainSoldiersBlock({
        soldiersListWatch = curSoldiersDataList
        expToLevelWatch = Computed(@() perkLevelsGrid.get()?.expToLevel)
        hasVehicleWatch = Computed(@() hasSquadVehicle(curSquad.get()))
        vehicleInfo
        curSoldierIdxWatch = curSoldierIdx
        soldiersReadyWatch = curSquadSoldiersStatus
        emptySlotsNum = max(0, (curSquadParams.get()?.size ?? 0) - curSoldiersDataList.get().len())
        emptySlotHandler = openManageSoldiers
        curVehicleUi = mkCurVehicle({
          openChooseVehicle
          vehicleInfo
          topRightChild = unseenVehiclesMark
          soldiersList = curSoldiersDataList
        })
        canDeselect = true
        addCardChild = mkAlertInfo
        headerBlock = squadHeader({
          curSquad = curSquad
          curSquadParams = curSquadParams
          soldiersList = curSoldiersDataList
          vehicleCapacity = vehicleCapacity
          soldiersStatuses = curSquadSoldiersStatus
        })
        outfitBlock = mkSquadListOutfitButton(
          Computed(function() {
            if (curVehicle.get() == null
                && (outfitCampaignsByArmies.get()?[armyId].len() ?? 0) <= 1)
              return {}
            return looksByArmy.get()?[armyId]
          }),
          Computed(@() armySquadsById.get()?[armyId][squadId].campaignOutfit ?? ""),
          @(campaignId) set_squad_outfit_preset(guid, campaignId))

        bottomObj = {
          size = FLEX_H
          margin = vehicleInfo.get() != null ? null : [bigPadding, 0, 0, 0]
          flow = FLOW_VERTICAL
          gap = smallPadding
          children = [
            freeSeatsBlock(freeSeatsInVehicle.get())
            manageSoldiersBtn
          ]
        }
      })
    }
  }
}

return {mkSquadInfo}
