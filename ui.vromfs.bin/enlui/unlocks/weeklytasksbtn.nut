import "%ui/profile/profileScene.nut" as profileScene
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import midPadding, commonBtnHeight, defTxtColor, startBtnWidth, bigPadding, defItemBlur, transpPanelBgColor
  , darkTxtColor, smallPadding, hoverSlotBgColor
from "%ui/components/unseenComponents.nut" import blinkUnseen, unblinkUnseen
from "%ui/unlocks/unseenUnlocksState.nut" import hasWeeklyTasks, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
from "%ui/ui_library.nut" import *

let buttonSize = [startBtnWidth, commonBtnHeight]
let iconSize = [hdpxi(24), hdpxi(30)]


let weeklyUnseenSign = @() {
  watch = [hasUnseenWeeklyTasks, hasUnopenedWeeklyTasks]
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  children = !hasUnseenWeeklyTasks.get() ? null
    : hasUnopenedWeeklyTasks.get() ? blinkUnseen
    : unblinkUnseen
}

let buttonContent = watchElemState(@(sf) {
  rendObj = ROBJ_WORLD_BLUR
  size = buttonSize
  fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
  color = defItemBlur
  behavior = Behaviors.Button
  onClick = @() profileScene("weeklyTasks")
  sound = {
    hover = "ui/enlist/button_highlight"
    click = "ui/enlist/button_click"
    active = "ui/enlist/button_action"
  }
  children = [
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      padding = [0, bigPadding]
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = iconSize
          color = sf & S_HOVER ? darkTxtColor : defTxtColor
          image = Picture("!ui/uiskin/tasks/weekly_tasks_icon.svg:{0}:{1}:K"
          .subst(iconSize[0], iconSize[1]))
        }
        {
          rendObj = ROBJ_TEXT
          size = FLEX_H
          padding = [0, midPadding]
          text = loc("profile/weeklyTasks")
          color = sf & S_HOVER ? darkTxtColor : defTxtColor
        }.__update(fontBody)
      ]
    }
    weeklyUnseenSign
  ]
})


function weeklyTasksUi() {
  let res = { watch = hasWeeklyTasks }
  if (!hasWeeklyTasks.get())
    return res

  return res.__update({
    children = buttonContent
  })
}

return weeklyTasksUi
