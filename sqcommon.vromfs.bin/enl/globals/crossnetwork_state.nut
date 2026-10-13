from "%dngscripts/platform.nut" import is_gdk, is_sony, is_pc, is_xbox
from "%dngscripts/globalState.nut" import globalWatched
from "settings" import get_setting_by_blk_path
from "%sqstd/frp.nut" import Computed, WatchedRo

const isCrossnetworkChatAvailable = true
let isCrossnetworkChatOptionNeeded = !is_gdk 
const isDebugCrossplay = false

enum CrossplayState {
  OFF = "off"
  CONSOLES = "consoles"
  ALL = "all"
}

let CrossPlayStateWeight = {
  [CrossplayState.OFF] = 0,
  [CrossplayState.CONSOLES] = 1,
  [CrossplayState.ALL] = 2
}

const savedCrossnetworkPlayId = "gameplay/crossnetworkPlay"
let {savedCrossnetworkState, savedCrossnetworkStateUpdate} = globalWatched("savedCrossnetworkState", @() get_setting_by_blk_path(savedCrossnetworkPlayId) ?? CrossplayState.ALL)

const savedCrossnetworkChatId = "gameplay/crossnetworkChat"
let {savedCrossnetworkChatState, savedCrossnetworkChatStateUpdate}  = globalWatched("savedCrossnetworkChatState", @() get_setting_by_blk_path(savedCrossnetworkChatId) ?? true)

let {xboxCrossplayAvailable, xboxCrossplayAvailableUpdate} = globalWatched("xboxCrossplayAvailable", @() false)
let {xboxCrosschatAvailable, xboxCrosschatAvailableUpdate} = globalWatched("xboxCrosschatAvailable", @() false)
let {xboxMultiplayerAvailable, xboxMultiplayerAvailableUpdate} = globalWatched("xboxMultiplayerAvailable", @() true)

let {xboxCrossChatWithFriendsAllowed, xboxCrossChatWithFriendsAllowedUpdate} = globalWatched("xboxCrossChatWithFriendsAllowed", @() true)
let {xboxCrossChatWithAllAllowed, xboxCrossChatWithAllAllowedUpdate} = globalWatched("xboxCrossChatWithAllAllowed", @() true)
let {xboxCrossVoiceWithFriendsAllowed, xboxCrossVoiceWithFriendsAllowedUpdate} = globalWatched("xboxCrossVoiceWithFriendsAllowed", @() true)
let {xboxCrossVoiceWithAllAllowed, xboxCrossVoiceWithAllAllowedUpdate} = globalWatched("xboxCrossVoiceWithAllAllowed", @() true)

let isCrossplayOptionNeeded = WatchedRo(is_xbox || is_sony || isDebugCrossplay)

let availableCrossplayOptions = Computed(function() { 
  if (is_xbox)
    return xboxCrossplayAvailable.get()
      ? [ CrossplayState.OFF, CrossplayState.CONSOLES, CrossplayState.ALL ]
      : [ CrossplayState.OFF ]

  if (is_pc && is_gdk)
    return xboxCrossplayAvailable.get()
      ? [ CrossplayState.ALL ]
      : [ CrossplayState.OFF ]

  if (is_sony)
    return [ CrossplayState.OFF, CrossplayState.CONSOLES, CrossplayState.ALL ]

  return [ CrossplayState.ALL ]
})

let validateCsState = @(state, available) available.contains(state) ? state : available?.top() ?? CrossplayState.ALL

let multiplayerAvailable = Computed(@() xboxMultiplayerAvailable.get())
local crossnetworkPlay = null
local crossnetworkChat = null

if (is_gdk) {
  crossnetworkPlay = Computed(@() xboxCrossplayAvailable.get()
    ? validateCsState(savedCrossnetworkState.get(), availableCrossplayOptions.get())
    : CrossplayState.OFF)
  crossnetworkChat = Computed(@() xboxCrosschatAvailable.get())
}
else if (is_sony || isDebugCrossplay) {
  crossnetworkPlay = Computed(@() validateCsState(savedCrossnetworkState.get(), availableCrossplayOptions.get()))
  crossnetworkChat = Computed(@() savedCrossnetworkChatState.get() ?? false)
}
else {
  crossnetworkPlay = WatchedRo(CrossplayState.ALL)
  crossnetworkChat = WatchedRo(isCrossnetworkChatAvailable)
}

let isCrossnetworkInteractionAvailable = Computed(@()
  isCrossnetworkChatAvailable
  && multiplayerAvailable.get()
  && crossnetworkChat.get())

let canCrossnetworkChatWithAll = Computed(@()
  isCrossnetworkInteractionAvailable.get()
  && xboxCrossChatWithAllAllowed.get())

let canCrossnetworkChatWithFriends = Computed(@()
  isCrossnetworkInteractionAvailable.get()
  && xboxCrossChatWithFriendsAllowed.get())

let canCrossnetworkVoiceWithAll = Computed(@()
  isCrossnetworkInteractionAvailable.get()
  && xboxCrossVoiceWithAllAllowed.get())

let canCrossnetworkVoiceWithFriends = Computed(@()
  isCrossnetworkInteractionAvailable.get()
  && xboxCrossVoiceWithFriendsAllowed.get())

return freeze({
  savedCrossnetworkPlayId
  savedCrossnetworkState, savedCrossnetworkStateUpdate
  xboxCrossplayAvailable, xboxCrossplayAvailableUpdate
  crossnetworkPlay
  needShowCrossnetworkPlayIcon = isDebugCrossplay || is_gdk
  CrossplayState
  xboxCrosschatAvailable, xboxCrosschatAvailableUpdate
  crossnetworkChat
  savedCrossnetworkChatId
  savedCrossnetworkChatState, savedCrossnetworkChatStateUpdate
  CrossPlayStateWeight
  isCrossnetworkChatAvailable
  availableCrossplayOptions
  isCrossplayOptionNeeded
  isCrossnetworkChatOptionNeeded
  xboxMultiplayerAvailable, xboxMultiplayerAvailableUpdate
  multiplayerAvailable
  xboxCrossChatWithFriendsAllowed, xboxCrossChatWithFriendsAllowedUpdate,
  xboxCrossChatWithAllAllowed, xboxCrossChatWithAllAllowedUpdate,
  xboxCrossVoiceWithFriendsAllowed, xboxCrossVoiceWithFriendsAllowedUpdate,
  xboxCrossVoiceWithAllAllowed, xboxCrossVoiceWithAllAllowedUpdate,
  canCrossnetworkChatWithAll
  canCrossnetworkChatWithFriends
  canCrossnetworkVoiceWithAll
  canCrossnetworkVoiceWithFriends
})