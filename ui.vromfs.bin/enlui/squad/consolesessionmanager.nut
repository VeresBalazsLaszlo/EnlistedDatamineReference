from "%dngscripts/platform.nut" import is_sony, is_gdk

local isAvailableConsoleSession = true
local updateData = @(_uid) null
local leave = @() null
local invite = @(_uid, _afterFunc) null
local create = @(_uid, _afterFunc) null
local join = @(_sessionId, _inviteId) null

if (is_sony) {
  let psnSessions = require("%ui/sony/session.nut")
  updateData = psnSessions.update_data
  invite = psnSessions.invite
  leave = psnSessions.leave
  create = psnSessions.create
  join = psnSessions.join
}
else if (is_gdk) {
  let xboxSessions = require("%ui/gdk/sessionManager.nut")
  updateData = xboxSessions.update_data
  invite = xboxSessions.invite
  join = xboxSessions.join
  leave = xboxSessions.leave
  create = xboxSessions.create
}
else
  isAvailableConsoleSession = false

return {
  updateData
  leave
  invite
  create
  isAvailableConsoleSession
  join
}