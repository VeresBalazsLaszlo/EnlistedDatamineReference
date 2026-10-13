import "%ui/userstats/serverTime.nut" as serverTime
from "%enlSqGlob/permission_utils.nut" import readPermissions, readPenalties
from "%enlSqGlob/userInfoState.nut" import userInfo, userPermissions, userPermissionsUpdate
from "dagor.workcycle" import setInterval, clearTimer, resetTimeout
from "%ui/state/clientState.nut" import appId
from "%ui/charClient/charClient.nut" import char_request
from "%ui/ui_library.nut" import *

function updateUserRightsInternal(cb = null) {
  let uInfo = userInfo.get()
  if (uInfo == null)
    return

  let { userId = -1 } = uInfo
  let request = {
    appid = appId
  }

  char_request("cln_get_user_rights", request,
    function(result) {
      if (typeof result != "table") {
        println("ERROR: invalid cln_get_user_rights result")
        cb?("INTERNAL_SERVER_ERROR")
        return
      }

      if (userInfo.get()?.userId != userId)
        return

      let upv = userPermissions.get()
      let resClientPermJwt = result?.clientPermJwt
      let resDedicatedPermJwt = result?.dedicatedPermJwt
      let resPenaltiesJwt = result?.penaltiesJwt
      if (resClientPermJwt == null && resDedicatedPermJwt == null && resPenaltiesJwt == null
          && upv?.penaltiesJwt == null && upv?.dedicatedPermJwt == null && upv?.permissions == null) {
        cb?("NOTHING_TO_UPDATE")
        return
      }

      cb?("UPDATED_SUCCESFULL")
      userPermissionsUpdate(upv.__merge({
        permissions = readPermissions(resClientPermJwt, userId)
        penalties = readPenalties(resPenaltiesJwt, userId)
        penaltiesJwt = resPenaltiesJwt
        dedicatedPermJwt = resDedicatedPermJwt
      }))
    }
  )
}

const rightsUpdateTimeout = 300 
setInterval(rightsUpdateTimeout, updateUserRightsInternal)

function updateUserRights(cb = null) {
  clearTimer(updateUserRightsInternal)
  updateUserRightsInternal(cb)
  setInterval(rightsUpdateTimeout, updateUserRightsInternal)
}


let activePenalties = Watched([])

let penaltyExpiredTimeSec = @(p) ((p?.start.tointeger() ?? 0) + (p?.duration.tointeger() ?? 0))/1000

function recalcActivePenalties() {
  let time = serverTime.get()
  let userPenalties = userPermissions.get()?.penalties.value ?? []
  let penalties = userPenalties.filter(@(p) penaltyExpiredTimeSec(p) - time > 0)
  activePenalties.set(freeze(penalties))
}

let nextPenaltyExpireTime = keepref(Computed(@() activePenalties.get().reduce(function(res, p) {
  let expireTime = penaltyExpiredTimeSec(p)
  return (expireTime <= 0 || (res > 0 && expireTime > res)) ? res : expireTime
}, 0)))

nextPenaltyExpireTime.subscribe(function(t){
  let timeleft = t - serverTime.get()
  if (timeleft > 0)
    resetTimeout(timeleft, recalcActivePenalties)
})
userPermissions.subscribe(@(_) recalcActivePenalties())
recalcActivePenalties()


let hasClientPermission = @(permission) Computed(@()
  userPermissions.get()?.permissions.value.contains(permission) ?? false)

let getPenaltyExpiredTime = @(category, penalty, details) Computed(function() {
  return activePenalties.get().reduce(function(res, p) {
    if (p?.category != category || p?.penalty != penalty || p?.details != details)
      return res
    let expireTime = penaltyExpiredTimeSec(p)
    return (expireTime <= 0 || expireTime < res) ? res : expireTime
  }, 0)
})

console_register_command(@() updateUserRights(console_print), "user_rights.update")
console_register_command(@(category, penalty, details)
  console_print(getPenaltyExpiredTime(category, penalty, details)),
  "user_rights.getPenaltyExpiredTime")
console_register_command(@(permission)
  console_print(hasClientPermission(permission)), "user_rights.hasClientPermission")
console_register_command(@()
  console_print(userPermissions.get()?.permissions.value), "user_rights.allPermissions")

return {hasClientPermission, getPenaltyExpiredTime}
