import "%ui/components/faComp.nut" as faComp
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/soldiers/model/squadClassLimits.nut" as getClassLimitsComp
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor, smallPadding, bigPadding, panelBgColor, gap, noteTxtColor, disabledTxtColor, msgHighlightedTxtColor
from "%ui/components/defcomps.nut" import autoscrollText, txt, note
from "%ui/style/cursors.nut" import setTooltip, withTooltip
from "%ui/soldiers/readyStatus.nut" import READY
from "%ui/components/squadsUiComps.nut" import mkSquadSpecIcon
from "%ui/components/soldiersUiComps.nut" import kindIcon, kindName
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/soldiers/armySquadTier.nut" import getLiveSquadBR, BRInfoBySquads
from "%ui/components/battleRatingPkg.nut" import mkBattleRating
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/ui_library.nut" import *

let getMaxSquadSizeComp = @(curSquadParams, vehicleCapacity) Computed(function() {
  let { size = 1 } = curSquadParams.get()
  let vCapacity = vehicleCapacity.get()
  return vCapacity > 0 ? min(size, vCapacity) : size
})

let mkClassLimitsHint = @(classLimits) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gap
  children = [
    {
      rendObj = ROBJ_TEXT
      size = const [hdpx(30), SIZE_TO_CONTENT]
      text = $"{classLimits.used}/{classLimits.total}"
    }
    kindIcon(classLimits.sKind, hdpx(30))
    kindName(classLimits.sKind).__update(fontSub, { color = defTxtColor })
  ]
}

let mkClassAmountHint = @(sClassLimits, squad) @() {
  watch = [sClassLimits, squad, BRInfoBySquads]
  flow = FLOW_VERTICAL
  gap
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = hdpx(400)
      text = loc("hint/squadClassLimits")
    }
  ]
    .extend(sClassLimits.get().map(mkClassLimitsHint))
    .append(mkBattleRating(getLiveSquadBR(BRInfoBySquads.get(), squad.get()?.squadId)))
}

let classAmount = @(sKind, total, used) {
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    kindIcon(sKind, hdpx(24))
    note({ text = $"{used}/{total}" })
  ]
}

let mkSquadClassesUi = @(sClassLimits) @() {
  watch = sClassLimits
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  margin = [0, bigPadding]
  halign = ALIGN_RIGHT
  gap = {
    rendObj = ROBJ_SOLID
    size = const [hdpx(1), ph(80)]
    vplace = ALIGN_CENTER
    color = disabledTxtColor
    margin = [0, smallPadding]
  }
  children = sClassLimits.get()
    .filter(@(c) c.total > 0)
    .map(@(c) classAmount(c.sKind, c.total, c.used))
}

let sizeHint = @(battleAmount, maxAmount) @() {
  watch = [battleAmount, maxAmount]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(500)
  color = defTxtColor
  text = loc("hint/maxSquadSize", {
    battle = battleAmount.get()
    max = maxAmount.get()
  })
}

let mkSquadSizeUi = @(battleAmount, maxSquadSize) function() {
  let watch = [battleAmount, maxSquadSize]
  let size = maxSquadSize.get()
  if (size <= 0)
    return { watch }

  return {
    watch
    flow = FLOW_VERTICAL
    margin = [0, bigPadding]
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(!on ? null : tooltipCtor(sizeHint(battleAmount, maxSquadSize)))
    skipDirPadNav = true
    children = [
      {
        size = hdpx(24)
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = faComp("user", {
          fontSize = hdpx(18)
          color = noteTxtColor
        })
      }
      txt({ text = $"{battleAmount.get()}/{size}", color = noteTxtColor})
    ]
  }
}


let mkExpBonus = @(expBonus) function() {
  let res = { watch = expBonus }
  let bonus = 100 * expBonus.get()
  return bonus == 0 ? res
    : withTooltip(res.__update({
        rendObj = ROBJ_TEXT
        vplace = ALIGN_CENTER
        color = msgHighlightedTxtColor
        text = loc("bonusExp/short", { value = $"+{bonus}" })
      }, fontSub), @() loc("tooltip/heroSquadExpBonus"))
}


function squadHeader(curSquad, curSquadParams, soldiersList, vehicleCapacity, soldiersStatuses) {
  let maxSquadSize = getMaxSquadSizeComp(curSquadParams, vehicleCapacity)
  let battleAmount = Computed(@() soldiersList.get()
    .reduce(@(res, s) soldiersStatuses.get()?[s.guid] == READY ? res + 1 : res, 0))
  let sClassLimits = getClassLimitsComp(curSquad, curSquadParams, soldiersList, soldiersStatuses)
  let expBonus = Computed(function() {
    let { heroExpBonus = 0.0 } = gameProfile.get()
    return soldiersList.get().reduce(@(res, soldier)
      (soldier?.isHero ?? false) ? max(res, heroExpBonus) : res, 0.0)
  })
  let group = ElemGroup()

  return function() {
    let watch = curSquad
    let squad = curSquad.get()
    if (!squad)
      return { watch }

    return {
      watch
      size = const [FLEX, hdpx(70)]
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      group
      onHover = @(on) setTooltip(on ? tooltipCtor(mkClassAmountHint(sClassLimits, curSquad)) : null)
      skipDirPadNav = true
      rendObj = ROBJ_SOLID
      color = panelBgColor
      children = [
        {
          size = const [FLEX, hdpx(26)]
          flow = FLOW_HORIZONTAL
          gap
          children = [
            mkSquadSpecIcon(squad)
            {
              size = FLEX_H
              margin = [smallPadding, bigPadding]
              children = autoscrollText({
                vplace = ALIGN_CENTER
                group
                text = utf8ToUpper(loc(squad?.titleLocId))
                color = noteTxtColor
                textParams = fontSub
              })
            }
            mkExpBonus(expBonus)
          ]
        }
        {
          size = FLEX
          flow = FLOW_HORIZONTAL
          children = [
            mkSquadSizeUi(battleAmount, maxSquadSize)
            mkSquadClassesUi(sClassLimits)
          ]
        }
      ]
    }
  }
}

return kwarg(squadHeader)