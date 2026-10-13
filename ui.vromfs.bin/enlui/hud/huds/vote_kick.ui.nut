from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/hud/state/vote_kick_state.nut" import voteToKickAccusedName, voteToKickAccused, voteToKickYes, voteToKickNo, lastKickedPlayerInfo
from "%ui/hud/state/chat.nut" import pushSystemMsg
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, casualFlagStyle
from "%ui/style/designConst.nut" import blurBgColor
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/huds/vote_kick_common.nut" import voteToKick, canVoteToKick
from "%ui/components/controlHudHint.nut" import controlHudHint
from "%ui/ui_library.nut" import *

const minWidth = hdpx(200)
const voteToKickPadding = hdpx(8)

lastKickedPlayerInfo.subscribe(function(info) {
  if (info.name == null)
    return

  let text = info.kicked ? "voteKick/accussedKicked" : "voteKick/notEnoughVotes"
  pushSystemMsg(loc(text, { name = info.name }))
})

let voteToKickHeader = @(){
  watch = isGamepad
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  gap = voteToKickPadding
  children = [
    isGamepad.get() ? controlHudHint("HUD.GameMenu") : null
    mkHeaderFlag(
      {
        rendObj = ROBJ_TEXT
        minWidth
        text = loc("voteKick/header")
        padding = voteToKickPadding
      }.__update(fontBody),
      casualFlagStyle.__merge({ offset = 0 })
    )
  ]
}

let voteToKickButtonBody = {
  size = FLEX
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  eventHandlers = {
    ["VoteKick.Yes"] = @(...) voteToKick(voteToKickAccused.get(), true),
    ["VoteKick.No"] = @(...) voteToKick(voteToKickAccused.get(), false)
  }
  behavior = DngBhv.ActivateActionSet
  actionSet = "VoteKick"
  children = [
    tipCmp({
      text = loc("hint/VoteKick.Yes")
      inputId = "VoteKick.Yes"
      style = { rendObj = null }
    })
    tipCmp({
      text = loc("hint/VoteKick.No")
      inputId = "VoteKick.No"
      style = { rendObj = null }
    })
  ]
}

let voteToKickCountBody = @(yesCount, noCount) {
  size = FLEX
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("voteKick/countYes", {count=yesCount} )
    }.__update(fontSub)

    {
      rendObj = ROBJ_TEXT
      text = loc("voteKick/countNo", {count=noCount} )
    }.__update(fontSub)
  ]
}

let voteToKickBody = @(name) @(){
  rendObj = ROBJ_WORLD_BLUR_PANEL
  watch = [isGamepad, canVoteToKick, voteToKickYes, voteToKickNo]
  size = FLEX_V
  minWidth
  flow = FLOW_VERTICAL
  color = blurBgColor
  padding = voteToKickPadding
  gap = hdpx(4)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("voteKick/desc")
    }.__update(fontSub)
    {
      rendObj = ROBJ_TEXT
      text = loc("voteKick/accussedName", {name} )
    }.__update(fontBody)
    !canVoteToKick.get()
        ? voteToKickCountBody(voteToKickYes.get().len(), voteToKickNo.get().len())
      : isGamepad.get() ? null : voteToKickButtonBody
  ]
}

return function() {
  let watch = voteToKickAccusedName
  if (voteToKickAccusedName.get() == null)
     return { watch }

  return {
    watch
    size = const [SIZE_TO_CONTENT, hdpx(184)]
    flow = FLOW_VERTICAL
    minWidth
    margin = const [0, 0, hdpx(50), 0]
    children = [
      voteToKickHeader
      voteToKickBody(voteToKickAccusedName.get())
    ]
  }
}
