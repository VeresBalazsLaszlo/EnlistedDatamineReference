from "%ui/ui_library.nut" import *
let localSettings = require("%ui/options/localSettings.nut")("quickMatch/")

const defaultRandomTeam = false
let matchRandomTeamCommon = localSettings(defaultRandomTeam, "matchRandomTeam")
let matchRandomTeamEvent = localSettings(defaultRandomTeam, "matchRandomTeamEvent")
let isInEventGM = Watched(false)
let setEventGm = @(v) isInEventGM.set(v)
let matchRandomTeam = Computed(@() isInEventGM.get()
  ? matchRandomTeamEvent.get()
  : matchRandomTeamCommon.get())

return {
  matchRandomTeam
  matchRandomTeamEvent
  matchRandomTeamCommon
  setEventGm
}