from "%enlSqGlob/crossnetwork_state.nut" import CrossplayState
from "%dngscripts/platform.nut" import is_gdk, is_sony, is_pc
from "%sqstd/string.nut" import endsWith, startsWith
from "%ui/ui_library.nut" import *


let consoleCompare = {
  live = { 
    isFromPlatform = @(name) endsWith(name, "@live") || startsWith(name, "^")
    isPlatform = is_gdk
  }
  psn = {
    isFromPlatform = @(name) endsWith(name, "@psn") || startsWith(name, "*")
    isPlatform = is_sony
  }
}

function canInterractCrossPlatform(name, crossnetworkChatValue) {
  if (crossnetworkChatValue)
    return true

  foreach (p in consoleCompare)
    if (p.isFromPlatform(name))
      return p.isPlatform

  
  if (is_gdk)
    return false

  return is_pc 
}

function canInterractCrossPlatformByCrossplay(name, crossplayValue) {
  if (crossplayValue == CrossplayState.ALL)
    return true

  if (crossplayValue == CrossplayState.OFF)
    return canInterractCrossPlatform(name, false)

  
  foreach (p in consoleCompare)
    if (p.isFromPlatform(name))
      return true

  return false
}

return {
  canInterractCrossPlatform
  consoleCompare
  canInterractCrossPlatformByCrossplay
}
