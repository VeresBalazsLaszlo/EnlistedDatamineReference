import "%ui/control/gui_buttons.nut" as JB
from "%ui/style/fontsStyle.nut" import fontHeading1, fontSub, fontHeading2
from "%ui/components/textButton.nut" import Regular
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, casualFlagStyle
from "%ui/hud/state/vote_kick_state.nut" import voteToKickAccusedName, voteToKickYes, voteToKickNo, voteToKickAccused
from "%ui/style/designConst.nut" import blurBgFillColor, commonBtnHeight
from "%ui/hud/huds/vote_kick_common.nut" import voteToKick, canVoteToKick
from "%ui/ui_library.nut" import *

const voteToKickPadding = hdpx(8)

let VoteToKickButtonStyleDisable = {
  size = FLEX_H
  isEnabled = false
}

let voteKickButtonsBody = [
  Regular(loc("hint/VoteKick.Yes"), @() voteToKick(voteToKickAccused.get(), true), {
    size = [FLEX, commonBtnHeight]
    hotkeys = [ ["^J:Y", {description={skip=true} sound="click"}] ]
  })
  Regular(loc("hint/VoteKick.No"), @() voteToKick(voteToKickAccused.get(), false), {
    size = [FLEX, commonBtnHeight]
    hotkeys = [ ["^J:X", {description={skip=true} sound="click"}] ]
  })
]

let voteKickVotesBody = @(yesCount, noCount) [
  Regular(loc("voteKick/countYes", {count=yesCount} ), null, VoteToKickButtonStyleDisable )
  Regular(loc("voteKick/countNo", {count=noCount} ), null, VoteToKickButtonStyleDisable )
]

let voteToKickHeader = mkHeaderFlag(
  {
    rendObj = ROBJ_TEXT
    text = loc("voteKick/header")
    padding = const [voteToKickPadding, hdpx(24)]
  }.__update(fontHeading1),
  casualFlagStyle.__merge({ offset = voteToKickPadding * 2})
)

let voteToKickBody = @(name) {
  size = const [sh(35), sh(12)]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = blurBgFillColor
  flow = FLOW_VERTICAL
  padding = voteToKickPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = FLEX_H
      text = loc("voteKick/desc")
    }.__update(fontSub)
    {
      rendObj = ROBJ_TEXT
      size = FLEX
      valign = ALIGN_CENTER
      text = loc("voteKick/accussedName", {name} )
    }.__update(fontHeading2)
  ]
}

return function() {
  let res = {
    watch = [voteToKickAccusedName, canVoteToKick, voteToKickYes, voteToKickNo]
  }

  if (voteToKickAccusedName.get() == null)
    return res

  return res.__update({
    size = const [sh(35), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    pos = const [sh(90), sh(34)]
    children = [
      voteToKickHeader
      voteToKickBody(voteToKickAccusedName.get())
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        padding = [voteToKickPadding, 0]
        gap = voteToKickPadding
        children = canVoteToKick.get()
          ? voteKickButtonsBody
          : voteKickVotesBody(voteToKickYes.get().len(), voteToKickNo.get().len())
      }
    ]
    eventHandlers = {
      [JB.A] = @(_event) @() voteToKick(voteToKickAccused.get(), true),
      [JB.B] = @(_event) @() voteToKick(voteToKickAccused.get(), false),
    }
  })
}