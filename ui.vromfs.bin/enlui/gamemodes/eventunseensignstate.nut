import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *
from "types" import Integer

let unseenEventTimeOffset = get_setting_by_blk_path("unseenEventTimeOffset")
let isNotifierAvailable = unseenEventTimeOffset instanceof Integer
const SECONDS_IN_DAY = 86400

let nextTimeToShow = mkOnlineSaveData("nextTimeToShow", @() 0)
let nextTimeToShowStored = nextTimeToShow.watch


function markEventSeen() {
  if (!isNotifierAvailable || serverTime.get() < nextTimeToShowStored.get())
    return
  let curTime = serverTime.get()
  let curDaySec = (curTime + unseenEventTimeOffset) % SECONDS_IN_DAY
  nextTimeToShow.setValue(curTime + SECONDS_IN_DAY - curDaySec)
}


let isEventUnseen = isNotifierAvailable
  ? Computed(@() serverTime.get() > nextTimeToShowStored.get())
  : Watched(false)


return {
  isEventUnseen
  markEventSeen
}