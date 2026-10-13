import "%dngscripts/ecs.nut" as ecs
let { CmdReplayRewind } = require("dasevents")
let { replay_play, replay_get_play_file } = require("app")
let { currentReplayInfo } = require("%enlSqGlob/replay_state.nut")
let logRPL = require("%enlSqGlob/library_logs.nut").with_prefix("[Replay] ")

ecs.register_es("replay_on_rewind_es",
  {
    [CmdReplayRewind] = function (evt, _eid, comp) {
      if (comp.replay__isRewinding)
        return
      comp.replay__isRewinding = true
      comp.replay__isKeyFrameRewind = true
      let rewindToTime = evt.time / 1000.0
      
      let mission_name = currentReplayInfo.get()?["mission_name"]
      let synthesizedScene = (mission_name != null) ? $"gamedata/scenes/{mission_name}.blk" : ""
      logRPL($"Rewinding replay to {rewindToTime}")
      replay_play(currentReplayInfo.get()?["path"] ?? replay_get_play_file(), rewindToTime, currentReplayInfo.get()?["mod_info"], synthesizedScene)
    },
  },
  {
    comps_rw = [
      ["replay__isRewinding", ecs.TYPE_BOOL],
      ["replay__isKeyFrameRewind", ecs.TYPE_BOOL]
    ],
  }, { tags = "playingReplay" }
)
