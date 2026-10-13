import "%ui/items/itemsMapping.nut" as itemsMapping
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/battlepass/rewardsPkg.nut" import mkRewardImages, mkRewardTooltip
from "%ui/items/itemsPresentationUtils.nut" import rewardBgSizePx
from "%sqstd/underscore.nut" import arrayByRows
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/style/cursors.nut" import withTooltip
from "%ui/ui_library.nut" import *

const WND_UID = "debugRewardsView"
let isOpened = mkWatched(persist, "isOpened", false)
const gap = 20

function rewardsContent() {
  let all = itemsMapping.get().reduce(@(res, reward, id) res.append({ id, reward }), [])
  all.sort(@(a, b) a.id <=> b.id)
  let columns = (sw(95) / (rewardBgSizePx[0] + gap)).tointeger()
  return makeVertScroll({
    watch = itemsMapping
    padding = gap
    gap
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    children = arrayByRows(all, columns).map(@(row) {
      gap
      flow = FLOW_HORIZONTAL
      children = row.map(@(data) {
        children = [
          withTooltip(mkRewardImages(data.reward, rewardBgSizePx), @() mkRewardTooltip(data.reward))
          {
            rendObj = ROBJ_TEXT
            text = data.id
            vplace = ALIGN_BOTTOM
          }
        ]
      })
    })
  },
  {
    size = FLEX_H
    maxHeight = sh(100)
  })
}

let open = @() addModalWindow({
  key = WND_UID
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  valign = ALIGN_CENTER
  children = rewardsContent
  onClick = @() isOpened.set(false)
})

if (isOpened.get())
  open()
isOpened.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))

console_register_command(@() isOpened.set(!isOpened.get()), "debug.unlockRewardsView")
