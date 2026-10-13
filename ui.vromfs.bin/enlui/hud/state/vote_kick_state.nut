import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerEid
from "dasevents" import VoteKickResult
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/ui_library.nut" import *


let voteToKickTemplate = mkEcsComputed({
  comps = [["vote_to_kick__kickVotingTemplate", ecs.TYPE_STRING]]
  tags = "gameClient"
})
let voteToKickEnabled = Computed(@() voteToKickTemplate.get() != null)



let kickVoting = mkEcsComputed({
  comps = [
    ["kick_voting__accused", ecs.TYPE_EID],
    ["kick_voting__voteYes", ecs.TYPE_EID_LIST],
    ["kick_voting__voteNo", ecs.TYPE_EID_LIST],
  ]
  tags = "gameClient"
})



let playersNameTeam = mkEcsComputedEidMap({
  comps = [
    ["name", ecs.TYPE_STRING],
    ["team", ecs.TYPE_INT],
  ]
  comps_rq = [["vote_to_kick__kicked", ecs.TYPE_BOOL]]
})


let accusedVote = Computed(function() {
  let vote = kickVoting.get()
  if (vote == null || vote.kick_voting__accused == localPlayerEid.get())
    return null
  let accused = playersNameTeam.get()?[vote.kick_voting__accused]
  return accused?.team == localPlayerTeam.get() ? vote : null
})

let voteToKickAccusedName = Computed(function() {
  let vote = accusedVote.get()
  let accused = vote == null ? null : playersNameTeam.get()?[vote.kick_voting__accused]
  return accused == null ? null : remap_nick(accused.name)
})
let voteToKickYes = Computed(@() accusedVote.get()?.kick_voting__voteYes ?? [])
let voteToKickNo = Computed(@() accusedVote.get()?.kick_voting__voteNo ?? [])
let voteToKickAccused = Computed(@() accusedVote.get()?.kick_voting__accused ?? ecs.INVALID_ENTITY_ID)

let lastKickedPlayerInfo = Watched({ name = null, kicked = false })

ecs.register_es("vote_kick_notify_es",
  {
    [VoteKickResult] = function(evt, _eid, comp) {
        if (comp.team != localPlayerTeam.get() || comp.is_local)
          return
        lastKickedPlayerInfo.set({
          name = remap_nick(comp.name)
          kicked = evt.kicked
        })
    },
  },
  {
    comps_ro = [
      ["name", ecs.TYPE_STRING],
      ["team", ecs.TYPE_INT],
      ["is_local", ecs.TYPE_BOOL],
    ],
  },
  {tags="gameClient"}
)

return {
  voteToKickEnabled
  voteToKickAccusedName
  voteToKickYes
  voteToKickNo
  voteToKickAccused
  lastKickedPlayerInfo
}