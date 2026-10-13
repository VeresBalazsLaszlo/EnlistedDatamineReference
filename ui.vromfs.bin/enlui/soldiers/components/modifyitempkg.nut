import "%ui/components/spinner.nut" as spinner
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%sqstd/math.nut" import round_by_value
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import activeTxtColor, midPadding
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%ui/style/cursors.nut" import setTooltip, normalTooltipTop
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/soldiers/model/mkItemModifyData.nut" import mkItemUpgradeData, mkItemDisposeData
from "%ui/soldiers/model/itemActions.nut" import isItemActionInProgress
from "%ui/soldiers/model/state.nut" import armySquadsById
from "%ui/researches/researchesState.nut" import allResearchStatus
from "%ui/soldiers/model/squadInfoState.nut" import isObjGuidBelongToRentedSquad
from "%ui/soldiers/model/unseenUpgrades.nut" import markSeenUpgrades, curUnseenAvailableUpgrades,
  isUpgradeUsed
from "%ui/growth/growthState.nut" import getSortedGrowthsByResearch, getSortedGrowthsByVehicle
from "%ui/researches/researchesFocus.nut" import focusResearch, findResearchesUpgradeUnlock,
  getClosestResearch
from "%ui/soldiers/components/squadsComps.nut" import showRentedSquadLimitsBox
from "%ui/soldiers/components/modifyItemComp.nut" import openUpgradeItemMsg, openDisposeItemMsg
from "%ui/mainMenu/sectionsState.nut" import jumpToArmyGrowth
from "%ui/ui_library.nut" import *

let waitingSpinner = spinner(hdpx(25))
let unseenIcon = blinkUnseenIcon(0.8).__update({ hplace = ALIGN_RIGHT })

let hintText = @(text) {
  rendObj = ROBJ_TEXT
  color = activeTxtColor
  text
}.__update(fontSub)

let openResearchGrowthMsgbox = @(growth) showMsgbox({
  text = loc("itemUpgradeNoSquad",
    { squad = loc(getSquadPresentation(growth.reward.squadId)?.nameLocId ?? "unknown") })
  buttons = [
    {
      text = loc("GoToGrowth")
      action = @() jumpToArmyGrowth(growth.id)
      isCurrent = true
    }
    { text = loc("Close"), isCancel = true }
  ]
})

let openResearchUpgradeMsgbox = @(research) showMsgbox({
  text = loc("itemUpgradeResearch")
  buttons = [
    {
      text = loc("mainmenu/btnResearch")
      action = @() focusResearch(research)
      isCurrent = true
    }
    { text = loc("Close"), isCancel = true }
  ]
})

function mkDisposeBtn(item, override = null) {
  let disposeDataWatch = mkItemDisposeData(item)
  return function() {
    let watch = [disposeDataWatch, isItemActionInProgress]
    let disposeData = disposeDataWatch.get()
    if (!disposeData.isDisposable)
      return { watch }

    let { disposeMult, isDestructible = false, isRecyclable = false } = disposeData
    let bonus = round_by_value(disposeMult * 100 - 100, 1).tointeger()
    let labelLocId = isRecyclable ? "btn/recycle"
      : isDestructible ? "btn/dispose"
      : "btn/downgrade"
    let hintLocId = isRecyclable ? "tip/btnRecycle"
      : isDestructible ? "tip/btnDispose"
      : "tip/btnDowngrade"
    return {
      watch
      flow = FLOW_VERTICAL
      gap = midPadding
      halign = ALIGN_CENTER
      children = [
        bonus <= 0 ? null : hintText(loc("disposeBonus", { bonus }))
        Regular(loc(labelLocId),
          @() openDisposeItemMsg(item, disposeData), {
            cursor = normalTooltipTop
            onHover = @(on) setTooltip(on ? loc(hintLocId) : null)
            isEnabled = !isItemActionInProgress.get()
          })
      ]
    }.__update(override ?? {})
  }
}

function mkUpgradeBtn(item, override = null) {
  let upgradeDataWatch = mkItemUpgradeData(item)
  let isUnseen = Computed(@()
    !isUpgradeUsed.get() && item?.basetpl in curUnseenAvailableUpgrades.get())
  let tipUpgradeLocId = item?.itemtype == "vehicle" ? "tip/btnUpgradeVehicle" : "tip/btnUpgrade"
  return function() {
    let watch = [upgradeDataWatch, isUnseen]
    let upgradeData = upgradeDataWatch.get()
    if (!upgradeData.isUpgradable)
      return { watch }

    let { isResearchRequired, armyId, hasEnoughOrders, upgradeMult, itemBaseTpl } = upgradeData
    if (isResearchRequired) {
      local researchCb = null
      let researches = findResearchesUpgradeUnlock(armyId, item)
      local growthList = getSortedGrowthsByResearch(armyId, researches?[0])
      if (growthList.len() == 0)
        growthList = getSortedGrowthsByVehicle(armyId, itemBaseTpl)
      let squads = growthList.map(@(v) v.reward.squadId)
      let researchedSquad = squads.findvalue(@(squad) squad in armySquadsById.get()?[armyId])
      let growth = growthList?[0]
      if (researchedSquad == null) {
        if (growth != null)
          researchCb = @() openResearchGrowthMsgbox(growth)
      }
      else {
        let research = getClosestResearch(armyId, researches, allResearchStatus.get()?[armyId] ?? {})
        if (research != null)
          researchCb = @() openResearchUpgradeMsgbox(research)
      }

      if (researchCb == null)
        return { watch }

      return {
        watch
        children = Regular(loc("btn/upgrade"), researchCb, {
          cursor = normalTooltipTop
          onHover = @(on) setTooltip(on ? loc(tipUpgradeLocId) : null)
        })
      }.__update(override ?? {})
    }

    let discount = round_by_value(100 - upgradeMult * 100, 1).tointeger()
    let bCtor = hasEnoughOrders ? Primary : Regular
    return {
      watch
      flow = FLOW_VERTICAL
      gap = midPadding
      halign = ALIGN_CENTER
      children = [
        upgradeMult == 1.0 ? null : hintText(loc("upgradeDiscount", { discount }))
        {
          children = [
            bCtor(loc("btn/upgrade"),
              function() {
                if (isObjGuidBelongToRentedSquad(item?.guid))
                  showRentedSquadLimitsBox()
                else
                  openUpgradeItemMsg(item, upgradeData)
              },
              {
                margin = 0
                cursor = normalTooltipTop
                onHover = function(on) {
                  if (isUnseen.get())
                    hoverHoldAction("unseenUpdate", itemBaseTpl,
                      @(tpl) markSeenUpgrades(armyId, [tpl]))(on)
                  setTooltip(on ? loc(tipUpgradeLocId) : null)
                }
              })
            isUnseen.get() ? unseenIcon : null
          ]
        }
      ]
    }.__update(override ?? {})
  }
}

return {
  waitingSpinner
  mkDisposeBtn
  mkUpgradeBtn
}
