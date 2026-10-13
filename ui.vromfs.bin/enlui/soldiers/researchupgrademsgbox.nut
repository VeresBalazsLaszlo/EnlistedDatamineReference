from "%ui/researches/researchesFocus.nut" import findSlotUnlockRequirement, focusResearch
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/components/soldierClasses.nut" import soldierClasses
from "%ui/soldiers/model/config/equipIncreaseConfig.nut" import equipSlotIncreaseCfg
from "%ui/shop/shopState.nut" import setAutoChapter
from "%ui/mainMenu/sectionsState.nut" import setCurSection, Section
from "dagor.localize" import doesLocTextExist
from "%ui/ui_library.nut" import *

function gotoResearchUpgradeMsgBox(soldier, slotType, _slotId) {
  let { sClass = "unknown", equipScheme = {} } = soldier
  let soldierClass = loc(soldierClasses?[sClass].locId ?? "unknown")
  let buttons = [{ text = loc("Ok"), isCancel = true }]
  let researchSlot = slotType in equipSlotIncreaseCfg.get() ? "backpack" : slotType

  if (researchSlot not in equipScheme) {
    showMsgbox({
      text = loc("Not available for class", { soldierClass } )
      buttons
    })
    return
  }

  let { research = null } = findSlotUnlockRequirement(soldier, researchSlot)
  local unlock = null
  if (research != null)
    buttons.append({ text = loc("GoToResearch"),
      action = @() focusResearch(research), isCurrent = true })
  else
    buttons.append({ text = loc("GoToEquipment"),
      action = function() {
        setAutoChapter("item_group")
        setCurSection(Section.SHOP)
      }
    })

  let needBackpack = research == null && unlock == null && researchSlot != slotType

  local textMsg
  if (needBackpack) {
    let msgLocId = $"slotBlocked/{slotType}"
    textMsg = doesLocTextExist(msgLocId)
      ? loc(msgLocId)
      : loc("slotBlockedDefault")
  } else if (unlock != null)
    textMsg = loc("slotClassSquad", { level = unlock.level })
  else
    textMsg = loc("slotClassResearch", { soldierClass })

  showMsgbox({
    text = textMsg
    buttons
  })
}

return gotoResearchUpgradeMsgBox