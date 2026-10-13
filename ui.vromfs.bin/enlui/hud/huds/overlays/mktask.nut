from "%ui/components/tasksPkg.nut" import mkTaskEmblem, taskHeader, taskMinHeight, taskSlotPadding, taskDescription, taskDescPadding
from "%ui/style/designConst.nut" import darkBgColor, smallPadding
from "%ui/userstats/unlocksState.nut" import DAILY_TASK_KEY
from "%ui/ui_library.nut" import *

function mkTaskContent(unlockDesc) {
  let {
    isCompleted = false, isFinished = false, required = 0, current = 0, stage = 0
  } = unlockDesc
  let progress = { isCompleted, required, current, isFinished, stage }
  return watchElemState(@(sf) {
    size = FLEX_H
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    children = {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      valign = ALIGN_CENTER
      children = [
        mkTaskEmblem(unlockDesc, progress)
        taskHeader(unlockDesc, progress, true, sf)
      ]
    }
  })
}

let mkUnlockSlot = @(unlockDesc) watchElemState(@(sf) {
  size = FLEX_H
  minHeight = taskMinHeight
  behavior = Behaviors.Button
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_SOLID
      size = FLEX
      color = darkBgColor
    }
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      padding = taskSlotPadding
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        mkTaskContent(unlockDesc)
        unlockDesc?.table != DAILY_TASK_KEY ? null
          : taskDescription(unlockDesc.localization.description, sf, {
              margin = taskDescPadding
            })
      ]
    }
  ]
})

return mkUnlockSlot
