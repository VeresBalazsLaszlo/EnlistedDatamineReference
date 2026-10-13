import "%ui/control/gui_buttons.nut" as JB
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/style/colors.nut" import Alert
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%dngscripts/platform.nut" import is_gdk
from "app" import exit_game
from "%ui/ui_library.nut" import *

let getMembersNames = @(members) members.map(@(m) remap_nick(m.state.name))

local showCrossnetworkChatRestrictionMsgBox = @()
  showMsgbox(loc("contacts/msg/crossnetworkChatRestricted", {color = Alert}))

if (is_gdk) {
  let { check_privilege = @(...) null, Communications = -1 } = require_optional("gdk.user")
  showCrossnetworkChatRestrictionMsgBox = @() check_privilege(Communications, true, "")
}

return {
  showSquadMembersCrossPlayRestrictionMsgBox = @(members) showMsgbox("{0}\n{1}".subst(
      loc("squad/action_not_available_crossnetwork_play", {color = Alert}),
      ", ".join(getMembersNames(members))
    ))

  showSquadVersionRestrictionMsgBox = @(members) showMsgbox("{0}\n{1}".subst(
      loc("squad/action_not_available_version", {color = Alert}),
      ", ".join(getMembersNames(members))
    ))

  showNegativeBalanceRestrictionMsgBox = @()
    showMsgbox(loc("gameMode/negativeBalance", {color = Alert}))

  showVersionRestrictionMsgBox = @()
    showMsgbox(loc("msg/gameMode/unsupportedVersion", {color = Alert}))

  showEventVersionRestrictionMsgBox = @() showMsgbox({
    text = loc("msg/newVersionForEventRequirement", {color = Alert})
    buttons = [
      { text = loc("btn/restartAndUpdate"), isCurrent = true, action = @() exit_game() }
      { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
    ]
  })

  showDeserterRestrictionMsgBox = @() showMsgbox(loc("gameMode/penaltyMsg"))

  showCrossnetworkChatRestrictionMsgBox
}