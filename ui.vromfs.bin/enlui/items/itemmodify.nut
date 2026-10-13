from "%ui/meta/profile.nut" import curCampItems
from "math" import min

function mkGuidsCountTbl(guids, total) {
  local toProcess = total
  let res = {}
  foreach (guid in guids) {
    let { count = 0 } = curCampItems.get()?[guid]
    if (count == 0)
      continue
    let processed = min(count, toProcess)
    res[guid] <- processed
    toProcess -= processed
    if (toProcess == 0)
      break
  }
  return res
}

return {
  mkGuidsCountTbl
}
