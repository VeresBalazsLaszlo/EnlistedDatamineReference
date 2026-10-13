from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let steamUids = nestWatched("steamUids", {
  uid2steam = {}
  steam2uid = {}
})
let uid2steam = Computed(@() steamUids.get().uid2steam)
let steam2uid = Computed(@() steamUids.get().steam2uid)

function steamUidsUpdate(steam2UidNewList) {
  let res = clone steamUids.get()
  res.steam2uid = res.steam2uid.__merge(steam2UidNewList)
  let newUid2steam = {}
  foreach (k,v in steam2UidNewList)
    newUid2steam[v] <- k
  res.uid2steam = res.uid2steam.__merge(newUid2steam)
  steamUids.set(res)
}

return {
  steamUidsUpdate
  uid2steam
  steam2uid
}
