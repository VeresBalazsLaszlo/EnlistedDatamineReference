from "dasevents" import sendNetEvent, CmdVoteToKick
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/hud/state/vote_kick_state.nut" import voteToKickYes, voteToKickNo
from "%ui/ui_library.nut" import *

let voteToKick = @(accused, voteYes)
  sendNetEvent(localPlayerEid.get(), CmdVoteToKick({ voteYes accused }))

let canVoteToKick = Computed(@()
  (voteToKickYes.get().findindex(@(v) v == localPlayerEid.get()) == null
    && voteToKickNo.get().findindex(@(v) v == localPlayerEid.get()) == null))

return {
  voteToKick
  canVoteToKick
}