from "%enlSqGlob/offline_mode.nut" import disableRemoteNetServices
from "%sqstd/functools.nut" import memoize

const knownTutorialProfiles = {aircraft=true, tank=true, def=true, engineer=true}

let getProfile = memoize(function(id) {
  if (id not in knownTutorialProfiles) {
    println($"unknown tutorialProfile = {id}")
    return null
  }
  return require($"%enlSqGlob/data/tutorial_profile_{id}.nut")
})

if (disableRemoteNetServices) { 
  foreach(k in knownTutorialProfiles.keys())
    getProfile(k)
}

return {
  getProfile
}