import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/colorize.nut" as colorize
import "steam" as steam
from "%ui/login/login_chain.nut" import startLogin
from "%ui/login/loginActions.nut" import setLoginActions
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/style/designConst.nut" import accentTitleTxtColor, warningColor
from "%ui/state/steamState.nut" import openSteamRelinkUrl, isLinkToSteamEnabled, STEAM_LINK_SEEN_ID
from "%ui/state/windowState.nut" import steamOverlayActive
from "%ui/options/onlineSettings.nut" import settings, save
from "auth" import YU2_NOT_FOUND, force_token_renew, token_renew_event, YU2_OK, get_user_info, YU2_ALREADY
from "eventbus" import eventbus_subscribe_onehit
from "app" import exit_game
from "%ui/ui_library.nut" import *

let defLoginCb = require("%ui/login/login_cb.nut")
let logX = with_prefix("[STEAM LINK] ")


let isMsgBoxSeen = @() (settings.get()?[STEAM_LINK_SEEN_ID] ?? 0) > 0 





function isNotPlayedInOtherGame() {
  let { tags = [] } = get_user_info()
  return tags.findindex(@(v) v != "player_el" && v.contains("player_")) == null
}
let isFirstLaunch = @() ((settings.get()?.curArmies.len() ?? 0) == 0) && isNotPlayedInOtherGame()


local enabledLoginViaGaijinNet = false
local saveTimestamp = false

function loginSteamAccount(isFirst = false) {
  logX($"start login steam account, onlyKnown {!isFirst}")
  saveTimestamp = true
  startLogin({ onlyKnown = !isFirst })
}

let successFinishedLinkMsgBox = @() showMsgbox({
  text = loc("msg/steam/successLinkingAccount")
  buttons = [{
    text = loc("Proceed"),
    action = function() {
      logX("Passed by tag steamlink_el, login")
      loginSteamAccount()
    }
  }]
})

function steamAccountUsageMsg(addWarning = true) {
  let isFirst = isFirstLaunch()
  logX($"show steamAccountUsageMsg, isFirstLaunch {isFirst}, addWarning {addWarning}")

  let mainTextLocId = isFirst ? "msg/steam/loginByGaijinNet/newbie" : "msg/steam/loginByGaijinNet"
  let mainTextNoteLocId = isFirst ? "msg/steam/loginByGaijinNetNote/newbie" : "msg/steam/loginByGaijinNetNote"
  let secButtonLocId = isFirst ? "CreateSteamAccount" : "useExistingSteamAccount"

  showMsgbox({
    text = "\n\n".join([
      loc(mainTextLocId, { note = colorize(accentTitleTxtColor, loc(mainTextNoteLocId)) }),
      addWarning ? colorize(warningColor, loc("msg/steam/errorLinking")) : null
    ], true)

    buttons = [
      { text = loc("LoginViaGaijinNet"), isCurrent = true, action = function() {
          
          
          
          enabledLoginViaGaijinNet = true
          openSteamRelinkUrl()
      }}
      { text = loc(secButtonLocId),
        action = @() loginSteamAccount(isFirst) }
    ]
})}


function showConsolePlayerError(state, addWarning = true) {
  logX($"show PSNPlayerError")
  let mainText = state?.stageResult.error == "Forbidden"
    ? loc("error/XBOX_USERS_CAN_ONLY_PLAY_ON_CONSOLES")
    : loc($"error/{state.stageResult.error}")

  showMsgbox({
    text = "\n".join([
      mainText,
      "\n",
      loc("msg/steam/consoleAccountLink"),
      addWarning ? colorize(warningColor, loc("msg/steam/errorLinking")) : null
    ], true)

    buttons = [
      {
        id = "Link"
        text = loc("linkAnotherGaijinNetAccount"),
        isCurrent = true,
        action = function() {
          
          
          
          enabledLoginViaGaijinNet = true
          openSteamRelinkUrl()
      }}
      {
        id = "Exit"
        text = loc("gamemenu/btnQuit"),
        action = exit_game
      }
    ]
  })
}


function onInterrupt(state) {
  if (state?.status == YU2_NOT_FOUND) {
    if (!isLinkToSteamEnabled) {
      loginSteamAccount()
      return
    }

    if (enabledLoginViaGaijinNet) {
      steamAccountUsageMsg(true)
      return
    }

    startLogin({ onlyKnown = false })
    return
  }
  else if (state?.status == YU2_ALREADY) {
    
    state.params.afterErrorProcessed <- function(_state) {
      saveTimestamp = false
      steamAccountUsageMsg()
    }
  }
  else if (state?.stageResult.error == "PSN_USERS_CAN_ONLY_PLAY_ON_CONSOLES"
    || state?.stageResult.error == "Forbidden") {
    showConsolePlayerError(state, enabledLoginViaGaijinNet)
    return
  }

  defLoginCb.onInterrupt(state)
}

function onSuccess(state) {
  let isLinkMsgSeen = isMsgBoxSeen()
  logX($"continueLogin {isLinkMsgSeen} || {saveTimestamp} || {enabledLoginViaGaijinNet}")

  if (isLinkMsgSeen || enabledLoginViaGaijinNet || saveTimestamp) {
    if (saveTimestamp || enabledLoginViaGaijinNet) {
      setLoginActions({onAuthComplete = [
        function() {
          logX("Save timestamp for profile")
          settings.mutate(@(set) set[STEAM_LINK_SEEN_ID] <- serverTime.get())
          save()
        }
      ]})
      enabledLoginViaGaijinNet = false
    }
    defLoginCb.onSuccess(state)
  }
  else if (isLinkMsgSeen && get_user_info()?.tags.contains("steam_el")) {
    logX("autologin because if tag steam_el")
    enabledLoginViaGaijinNet = true
    loginSteamAccount(false)
  }
  else
    steamAccountUsageMsg(false)

  saveTimestamp = false
}

function onForceTokenReceivedCb(res) {
  if (!steam.is_running())
    return

  if (res?.status == YU2_OK && enabledLoginViaGaijinNet && get_user_info()?.tags.contains("steamlink_el"))
    successFinishedLinkMsgBox()
  else {
    logX($"Error appeared on update token, {res?.status}, {enabledLoginViaGaijinNet}", get_user_info())
    steamAccountUsageMsg()
  }
  enabledLoginViaGaijinNet = false
}

steamOverlayActive.subscribe(function(v) {
  if (v)
    return

  if (!enabledLoginViaGaijinNet)
    return

  eventbus_subscribe_onehit(token_renew_event, onForceTokenReceivedCb)
  force_token_renew()
})

return {
  onSuccess
  onInterrupt
}