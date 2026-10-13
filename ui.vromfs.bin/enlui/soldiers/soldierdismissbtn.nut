import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/spinner.nut" as spinner
import "%ui/components/colorize.nut" as colorize
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody
from "%ui/components/msgbox.nut" import showMessageWithContent, showMsgbox
from "%ui/style/designConst.nut" import midPadding, msgHighlightedTxtColor
from "%ui/components/defcomps.nut" import txt
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/components/textButton.nut" import Regular
from "%ui/soldiers/model/chooseSoldiersState.nut" import reserveSoldiers, applySoldierManage, dismissSoldiers, isDismissInProgress
from "%ui/helpers/metalink.nut" import getLinkedArmyName, getLinkedSquadGuid
from "%ui/soldiers/model/reserve.nut" import curArmyReserve, curArmyReserveCapacity
from "%ui/soldiers/model/config/soldierRetireConfig.nut" import RETIRE_ORDER, retireReturn
from "%ui/ui_library.nut" import *

let waitingSpinner = spinner(hdpx(25))

let mkDismissText = @(text, params = {}) {
  size = const [sw(50), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(params)

let mkDismissWarning = @(armyId, guids, heroCount, totalCost, cb) showMessageWithContent({
  content = {
    flow = FLOW_VERTICAL
    size = FLEX_H
    halign = ALIGN_CENTER
    gap = hdpx(40)
    children = [
      mkDismissText(loc("retireSoldier/title"),
        fontHeading2.__merge({ size = const [sw(35), SIZE_TO_CONTENT] }))
      mkDismissText(loc("retireSoldier/desc", {
          count = guids.len()
          number = colorize(msgHighlightedTxtColor, guids.len())
        }), fontBody)
      heroCount == 0 ? null : mkDismissText(loc("retireSoldier/hero", { count = heroCount }),
        fontBody.__merge({ color = msgHighlightedTxtColor }))
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = [
          txt(loc("retireSoldier/currencyWillReturn", { count = guids.len() })).__update(fontBody)
          mkItemCurrency({ currencyTpl = RETIRE_ORDER, count = totalCost })
        ]
      }
    ]
  }
  buttons = [
    {
      text = loc("Yes")
      action = function() {
        dismissSoldiers(armyId, guids, cb)
      }
      isCurrent = true
    }
    {
      text = loc("Cancel"), isCancel = true,
      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
    }
  ]
})

let mkApplyChangesWarning = @(cb = null) showMsgbox({
  text = loc("msg/applySoldiersChangesRequired")
  buttons = [
    { text = loc("Apply"),
      action = function() {
        applySoldierManage()
        cb?()
      }
      isCurrent = true
    }
    { text = loc("Cancel")
      isCancel = true
      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
    }
  ]
})

function retireReturnCost(reserveSoldiersVal, retireReturnVal, curArmyReserveCapacityV,
    curArmyReserveV, guid, sClass, tier) {
  if (reserveSoldiersVal.findindex(@(s) s.guid == guid ) == null)
    return null

  let retireCount = retireReturnVal?[sClass][tier] ?? 0
  if (retireCount == 0
      || curArmyReserveCapacityV == 0
      || curArmyReserveV.len() == 0)
    return null

  return retireCount
}

function mkDismissBtn(soldier, override = {}, btnOverride = {}, cb = @() null) {
  if (soldier == null)
    return null

  let { guid, sClass, tier, isHero } = soldier
  let armyId = getLinkedArmyName(soldier)
  return function() {
    let watch = [ curArmyReserve, curArmyReserveCapacity, isDismissInProgress,
      retireReturn, reserveSoldiers ]
    let totalCost = retireReturnCost(reserveSoldiers.get(), retireReturn.get(),
      curArmyReserveCapacity.get(), curArmyReserve.get(), guid, sClass, tier)
    if (totalCost == null)
      return { watch }

    let heroCount = isHero ? 1 : 0
    return {
      watch
      hplace = ALIGN_RIGHT
      children = [
        isDismissInProgress.get()
          ? waitingSpinner
          : Regular(loc("btn/removeSoldier"),
              @() getLinkedSquadGuid(soldier) != null
                ? mkApplyChangesWarning(cb)
                : mkDismissWarning(armyId, [guid], heroCount, totalCost, cb),
              btnOverride)
      ]
    }.__update(override)
  }
}


let bigDismissBtn = @(soldier) mkDismissBtn(soldier,
  { size = FLEX_H }, { btnWidth = FLEX })

let dismissBtn = @(soldier, cb = @() null) mkDismissBtn(soldier, {}, {}, cb)

return {
  retireReturnCost
  mkDismissWarning
  mkApplyChangesWarning
  bigDismissBtn
  dismissBtn
}
