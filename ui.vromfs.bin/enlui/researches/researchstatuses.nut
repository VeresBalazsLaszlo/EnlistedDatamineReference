import "%ui/researches/changeResearchMsgbox.nut" as changeResearchMsgbox
import "%ui/researches/multiresearchWarningMsgbox.nut" as multiresearchWarningMsgbox
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import titleTxtColor
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/researches/researchesState.nut" import tableStructure, researchStatuses, researchAction, curSquadProgress, buySquadLevel, LOCKED, DEPENDENT
  , NOT_ENOUGH_EXP, GROUP_RESEARCHED, CAN_RESEARCH, RESEARCHED, CHANGE_RESEARCH_TPL, BALANCE_ATTRACT_TRIGGER
from "%ui/ui_library.nut" import *

let hoverImage = require("%ui/components/hoverImage.nut")



let activeTxtStyle = { color = titleTxtColor }.__update(fontBody)

let mkInfo = @(researchInfo) (researchInfo?.multiresearchGroup ?? 0) <= 0 ? null
  : loc("research/groupCanResearch")
let mkActiveText = @(text) { rendObj = ROBJ_TEXT, text }.__update(activeTxtStyle)


let statusCfg = {
  [LOCKED] = @(_researchDef) {
    warning = loc("research/warnResearchLocked")
  },
  [DEPENDENT] = @(researchDef) {
    warning = loc("Need to research previous")
    onResearch = function() {
      foreach (researchId in researchDef.requirements)
        if (researchStatuses.get()?[researchId] != RESEARCHED)
          hoverImage.attractToImage(researchId)
    }
  },
  [NOT_ENOUGH_EXP] = @(researchDef) {
    warning = loc("Not enough army exp")
    info = mkInfo(researchDef)
    onResearch = function() {
      anim_start(BALANCE_ATTRACT_TRIGGER)

      let action = @() buySquadLevel(function(isSuccess) {
        if (!isSuccess)
          return
        sound_play("ui/purchase_level_squad")
        researchAction(researchDef.research_id)
      })

      let { nextLevelExp = 0, exp = 0, levelCost = 0 } = curSquadProgress.get()
      if (exp > 0 && exp >= nextLevelExp) {
        action()
        return
      }

      if (levelCost <= 0)
        return

      purchaseMsgBox({
        price = levelCost
        currencyId = "EnlistedGold"
        title = loc("Not enough army exp")
        description = loc("buy/squadLevelConfirmForResearch")
        purchase = @() multiresearchWarningMsgbox(
          researchDef, tableStructure.get().researches, action
        )
        alwaysShowCancel = true
        srcComponent = "buy_researches_level_on_research"
      })
    }
  },
  [GROUP_RESEARCHED] = @(researchDef) {
    info = loc("research/groupResearched")
    researchText = loc("research/changeResearch")
    onResearch = @() changeResearchMsgbox(researchDef)
    researchPrice = {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = mkTextRow(loc("research/researchPrice"), mkActiveText,
        { ["{price}"] = mkItemCurrency({ currencyTpl = CHANGE_RESEARCH_TPL, count = 1 }) }) 
    }
  },
  [CAN_RESEARCH] = @(researchDef) {
    info = mkInfo(researchDef)
    onResearch = @() multiresearchWarningMsgbox(researchDef, tableStructure.get().researches,
      function() {
        sound_play("ui/upgrade_unlock")
        researchAction(researchDef.research_id)
      })
  }
}

return statusCfg
