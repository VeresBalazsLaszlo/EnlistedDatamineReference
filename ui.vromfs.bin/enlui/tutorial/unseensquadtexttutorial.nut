from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/tutorial/squadTextTutorialPresentation.nut" import tutorials
from "%ui/ui_library.nut" import *

const TUTORIALS_SQUAD_SEEN = "seen/squadTutorial"

let squadTutorialSeen = Computed(@() settings.get()?[TUTORIALS_SQUAD_SEEN] ?? {})

let unseenSquadTutorials = Computed(function() {
  if (!onlineSettingUpdated.get())
    return {}

  let seen = squadTutorialSeen.get()
  let res = {}
  foreach (squadId in tutorials.keys()){
    if (squadId not in seen)
      res[squadId] <- true
  }
  return res
})


function markSeenSquadTutorial(guid) {
  if (!(squadTutorialSeen.get()?[guid] ?? false))
    settings.mutate(function(set) {
      set[TUTORIALS_SQUAD_SEEN] <- (set?[TUTORIALS_SQUAD_SEEN] ?? {}).__merge({ [guid] = true })
    })
}

console_register_command(function() {
  settings.mutate(function(s) {
    if (TUTORIALS_SQUAD_SEEN in s)
      s.$rawdelete(TUTORIALS_SQUAD_SEEN)
  })
}, "meta.resetSeenSquadTutorials")

return {
  unseenSquadTutorials
  markSeenSquadTutorial
}