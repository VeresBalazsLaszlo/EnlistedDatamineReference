import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/meta/profile.nut" import squadsByArmies
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let expiredRentedSquads = Watched({})

function updateExpiredRentedSquads(_ = null) {
  let res = {}
  let curTime = serverTime.get()
  local nextExpireTime = 0
  foreach (armyId, squads in squadsByArmies.get())
    foreach (guid, squad in squads) {
      let { expireTime = 0 } = squad
      if (expireTime > 0) {
        if (expireTime <= curTime)
          res[guid] <- armyId
        else
          nextExpireTime = nextExpireTime <= 0
            ? expireTime
            : min(nextExpireTime, expireTime)
      }
    }
  expiredRentedSquads.set(res)

  let timeLeft = nextExpireTime - curTime
  if (timeLeft > 0)
    gui_scene.resetTimeout(timeLeft, updateExpiredRentedSquads)
  else
    gui_scene.clearTimer(updateExpiredRentedSquads)
}

subscribeAndInit(updateExpiredRentedSquads, squadsByArmies)

return {
  expiredRentedSquads
}
