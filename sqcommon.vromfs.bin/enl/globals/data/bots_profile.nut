from "%enlSqGlob/offline_mode.nut" import disableRemoteNetServices
from "%sqstd/functools.nut" import memoize

const possibleBotsArmies = {
  ardennes_axis = true
  ardennes_allies = true
  tunisia_allies = true
  stalingrad_allies = true
  pacific_axis = true
  berlin_allies = true
  berlin_axis = true
  pacific_allies = true
  moscow_allies = true
  moscow_axis = true
  normandy_allies = true
  tunisia_axis = true
  normandy_axis = true
  stalingrad_axis = true
}

let getBotsProfile = memoize(function(id) {
  if (id not in possibleBotsArmies)
    return null
  return require($"%enlSqGlob/data/bots_profile_{id}.nut")
})

if (disableRemoteNetServices) {  
  foreach(k in possibleBotsArmies.keys())
    getBotsProfile(k)
}
return {
  possibleBotsArmies
  getBotsProfile
}