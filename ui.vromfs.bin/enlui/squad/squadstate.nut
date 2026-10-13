import "%enlSqGlob/userInfo.nut" as userInfo
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let selfUid = Computed(@() userInfo.get()?.userId)
let squadId = nestWatched("squadId", null)
let isInvitedToSquad = nestWatched("isInvitedToSquad", {})
let squadMembers = nestWatched("squadMembers", {})
let squadLen = Computed(@() squadMembers.get().len())
let squadSelfMember = Computed(@() squadMembers.get()?[selfUid.get()])
let allMembersState = Computed(@() squadMembers.get().map(@(s) s?.state))
let selfMemberState = Computed(@() allMembersState.get()?[selfUid.get()])
let squadLeaderState = Computed(@() allMembersState.get()?[squadId.get()])

let isInSquad = Computed(@() squadId.get() != null)
let isSquadLeader = Computed(@() squadId.get() == selfUid.get())
let isLeavingWillDisbandSquad = Computed(@() squadLen.get() == 1 || (squadLen.get() + isInvitedToSquad.get().len() <= 2))
let enabledSquad = nestWatched("enabledSquad", true)
let canInviteToSquad = Computed(@() enabledSquad.get() && (!isInSquad.get() || isSquadLeader.get()))

let notifyMemberAdded = []
let notifyMemberRemoved = []


function makeSharedData(persistId) {
  let res = {}
  foreach (key in ["clusters", "isAutoCluster", "squadChat", "crossnetworkPlay"])
    res[key] <- nestWatched($"{persistId}{key}", null)
  return res
}
let squadSharedData = makeSharedData("squadSharedData")
let squadServerSharedData = makeSharedData("squadServerSharedData")

return {
  selfUid
  squadId

  isInvitedToSquad
  squadMembers
  isSquadNotEmpty = Computed(@() squadMembers.get().len()>1)
  squadLen
  squadSelfMember
  allMembersState
  selfMemberState
  squadLeaderState

  isInSquad
  isSquadLeader
  isLeavingWillDisbandSquad
  enabledSquad
  canInviteToSquad

  squadSharedData
  squadServerSharedData

  
  notifyMemberAdded
  notifyMemberRemoved
  subsMemberAddedEvent = @(func) notifyMemberAdded.append(func)
  subsMemberRemovedEvent = @(func) notifyMemberRemoved.append(func)
}