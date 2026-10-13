import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/colorize.nut" as colorize
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%ui/style/fontsStyle.nut" import fontBody
from "dagor.debug" import logerr
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor
from "%ui/style/colors.nut" import MsgMarkedText
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/researches/researchesState.nut" import RESEARCHED, researchStatuses, tableStructure, CHANGE_RESEARCH_TPL, changeResearchBalance, changeResearchGoldCost, changeResearch, buyChangeResearch
from "%ui/currency/currenciesList.nut" import enlistedGold
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/style/buttonsStyle.nut" import primaryFlatButtonStyle
from "%ui/ui_library.nut" import *

let textarea = @(text, color) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color
  text
}.__update(fontBody)

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = defTxtColor
}.__update(fontBody)

let balanceText = @() {
    watch = [changeResearchBalance, changeResearchGoldCost]
    margin = const [fsh(5), 0, 0, 0]
  }.__update(changeResearchBalance.get() == 0
    ? {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          mkText(loc("research/change_research_no_orders"))
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            children = mkTextRow(loc("research/can_change_research_by_gold"),
              mkText,
              { ["{price}"] = mkCurrency({  
                currency = enlistedGold
                price = changeResearchGoldCost.get()
              }) })
          }
        ]
      }
    : {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = mkTextRow(loc("research/change_research_order_balance", { count = changeResearchBalance.get() }),
          mkText,
          { ["{balance}"] = mkItemCurrency({  
              currencyTpl = CHANGE_RESEARCH_TPL,
              count = changeResearchBalance.get()
            })
          })
      })

function doChangeResearch(researchFrom, researchTo) {
  if (changeResearchBalance.get() > 0) {
    changeResearch(researchFrom, researchTo)
    return
  }
  purchaseMsgBox({
    price = changeResearchGoldCost.get()
    currencyId = "EnlistedGold"
    title = loc("research/applyChangeResearch")
    purchase = @() buyChangeResearch(researchFrom, researchTo)
    alwaysShowCancel = true
    showOnlyWhenNotEnoughMoney = true
    srcComponent = "change_research_msgbox"
  })
}

function changeResearchMsgbox(newResearch) {
  let { multiresearchGroup = 0, research_id, name = "", params = {} } = newResearch
  let curResearch = tableStructure.get().researches.findvalue(
    @(r) r?.multiresearchGroup == multiresearchGroup
      && r.research_id != research_id
      && researchStatuses.get()?[r.research_id] == RESEARCHED)
  if (curResearch == null) {
    logerr("Try to change research when not researched any in the group")
    return
  }

  let buttons = Computed(function() {
    let res = []
    let isCurrencyAvailable = changeResearchBalance.get() <= 0
    if (changeResearchBalance.get() > 0 || isCurrencyAvailable)
      res.append({ text = loc("research/applyChangeResearch"), customStyle = primaryFlatButtonStyle,
        action = @() doChangeResearch(curResearch.research_id, research_id), isCurrent = true })
    res.append({ text = loc("Cancel"), isCancel = true,
      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } })
    return res
  })

  showMessageWithContent({
    uid = "change_research_confirm"
    content = {
      flow = FLOW_VERTICAL
      size = const [sw(50), SIZE_TO_CONTENT]
      margin = const [fsh(5), 0]
      gap = fsh(3)
      halign = ALIGN_CENTER
      children = [
        textarea(loc("research/changeResearch"), titleTxtColor)
        textarea(
          loc("research/changeResearch/desc",
            {
              curResearch = colorize(MsgMarkedText, loc(curResearch.name, curResearch?.params))
              newResearch = colorize(MsgMarkedText, loc(name, params))
            }),
          defTxtColor)
        balanceText
      ]
    }
    buttons
  })
}

return changeResearchMsgbox