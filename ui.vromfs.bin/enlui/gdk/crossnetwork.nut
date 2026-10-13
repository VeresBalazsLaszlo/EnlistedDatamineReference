from "%enlSqGlob/crossnetwork_state.nut" import xboxCrossplayAvailableUpdate, xboxCrosschatAvailableUpdate, xboxMultiplayerAvailableUpdate, xboxCrossChatWithFriendsAllowedUpdate, xboxCrossChatWithAllAllowedUpdate, xboxCrossVoiceWithFriendsAllowedUpdate, xboxCrossVoiceWithAllAllowedUpdate
from "%ui/voiceChat/voiceChatGlobalState.nut" import voiceChatRestrictedUpdate
from "%gdkLib/crossnetwork.nut" import multiplayerPrivilege, communicationsPrivilege, crossnetworkPrivilege, textWithAnonUser, voiceWithAnonUser, CommunicationsState
from "%sqstd/frp.nut" import subscribeAndInit

function onMultiplayerPrivilege(val) {
  xboxMultiplayerAvailableUpdate(val)
}
subscribeAndInit(onMultiplayerPrivilege, multiplayerPrivilege)


function onCommunicationsPrivilege(val) {
  xboxCrosschatAvailableUpdate(val)
  voiceChatRestrictedUpdate(!val)
}
subscribeAndInit(onCommunicationsPrivilege, communicationsPrivilege)


function onCrossnetworkPrivilege(val) {
  xboxCrossplayAvailableUpdate(val)
}
subscribeAndInit(onCrossnetworkPrivilege, crossnetworkPrivilege)


function onTextWithAnonUser(val) {
  xboxCrossChatWithFriendsAllowedUpdate(
    val == CommunicationsState.FriendsOnly || val == CommunicationsState.Allowed
  )
  xboxCrossChatWithAllAllowedUpdate(val == CommunicationsState.Allowed)
}
subscribeAndInit(onTextWithAnonUser, textWithAnonUser)


function onVoiceWithAnonUser(val) {
  xboxCrossVoiceWithFriendsAllowedUpdate(
    val == CommunicationsState.FriendsOnly || val == CommunicationsState.Allowed
  )
  xboxCrossVoiceWithAllAllowedUpdate(val == CommunicationsState.Allowed)
}
subscribeAndInit(onVoiceWithAnonUser, voiceWithAnonUser)