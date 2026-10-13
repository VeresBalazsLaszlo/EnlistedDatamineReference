import "%ui/components/colorize.nut" as colorize
from "%ui/components/msgbox.nut" import isMsgboxInList, showMsgbox
from "%ui/squad/squadState.nut" import isSquadLeader, allMembersState
from "%ui/contacts/contact.nut" import getContactRealnick
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%ui/components/itemsInfo.nut" import getCampaignTitle
from "%ui/style/colors.nut" import MsgMarkedText
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/ui_library.nut" import *

const MSG_UID = "member_locked_campaign_msgbox"
let viewedWarnings = mkWatched(persist, "viewedWarnings", {})
let curCampViewed = Computed(@() viewedWarnings.get()?[COMMON_CAMPAIGN])

isSquadLeader.subscribe(function(v) {
  if (!v)
    viewedWarnings.mutate(@(w) w.clear())
})

let needWarningUserId = keepref(Computed(function() {
  if (!isSquadLeader.get())
    return null
  let userId = allMembersState.get().findindex(@(m, uId)
    "unlockedCampaigns" in m && !m.unlockedCampaigns.contains(COMMON_CAMPAIGN) && !(curCampViewed.get()?[uId] ?? false))
  return userId
}))

function showWarningMsgbox(userId) {
  if (userId == null || isMsgboxInList(MSG_UID))
    return

  let name = remap_nick(getContactRealnick(userId.tostring()))
  showMsgbox({
    uid = MSG_UID
    text = loc("msg/memberCampaignLocked", {
      player = colorize(MsgMarkedText, name)
      campaign = colorize(MsgMarkedText, getCampaignTitle(COMMON_CAMPAIGN))
    })
    buttons = [{ text = loc("Ok"),
      action = @() viewedWarnings.mutate(@(v) v[COMMON_CAMPAIGN] <- (v?[COMMON_CAMPAIGN] ?? {}).__merge({ [userId] = true }))
      isCurrent = true
      isCancel = true
    }]
  })
}

needWarningUserId.subscribe(showWarningMsgbox)
