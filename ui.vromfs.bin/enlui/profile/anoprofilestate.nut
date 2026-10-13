import "%ui/profile/botStatsGen.nut" as makeBotData
from "%ui/userstats/userstat.nut" import requestAnoPlayerStats
from "%ui/ui_library.nut" import *

let isAnoProfileOpened = mkWatched(persist, "isProfileOpened", false)
let anoProfileData = mkWatched(persist, "anoProfileData", false)

function fetchAnotherProfile(userid){
  requestAnoPlayerStats(userid, function(result) {
    anoProfileData.mutate(@(v) v.__update({ stats = result?.response.stats, isFinal = true }))
    isAnoProfileOpened.set(true)
  })
}

function showAnoProfile(profile){
  if (profile.player.userid != -1) {
    anoProfileData.set(profile)
    fetchAnotherProfile(profile?.player.userid)
  } else {
    anoProfileData.set(makeBotData(profile))
    isAnoProfileOpened.set(true)
  }
}

console_register_command(@(userid, name) showAnoProfile({
    player = {
      name
      userid
      nickFrame = "nickFrame_1"
      portrait = "tunisia_axis_t3_1"
      rank = 3
      rating = 1400
    }
  }), "ui.anoProfileTest")

return {
  isAnoProfileOpened
  anoProfileData
  showAnoProfile
}
