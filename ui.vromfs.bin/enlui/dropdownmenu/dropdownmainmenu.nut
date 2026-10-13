import "%ui/dropdownmenu/mkDropDownMenuBlock.nut" as mkDropMenuBtn
import "%ui/helpers/isChineseVersion.nut" as isChineseVersion
import "%ui/mainMenu/debugProfileWnd.nut" as debugProfileWnd
import "%ui/mainMenu/debugConfigsWnd.nut" as debugConfigsWnd
import "%ui/mainMenu/qrWindow.nut" as qrWindow
import "%ui/profile/profileScene.nut" as profileScene
from "%enlSqGlob/app_control.nut" import switch_to_menu_scene, setUseCustomMenuScene, getCustomMenuSceneFile
from "%ui/mainMenu/defMainMenuItems.nut" import btnCredits
from "%ui/openChangelog.nut" import openChangelog
from "%ui/state/queueState.nut" import isInQueue
from "%ui/mpRoom/customGamesWnd.nut" import customGamesOpen
from "%ui/state/client_user_rights.nut" import hasClientPermission
from "dagor.system" import DBGLEVEL
from "app" import is_user_game_mod
from "%dngscripts/platform.nut" import is_sony, is_gdk, is_xbox
from "%ui/components/openUrl.nut" import openUrl
from "%ui/supportUrls.nut" import enlistedForumUrl, feedbackUrl
from "%ui/changeLogState.nut" import changelogDisabled
from "%ui/components/msgbox.nut" import showMsgbox
from "dagor.localize" import doesLocTextExist
from "%ui/replay/replaySettings.nut" import isReplayTabHidden
from "%ui/unlocks/taskRewardsState.nut" import hasBattlePass, isSeasonEnds
from "%ui/battlepass/bpWindowState.nut" import openBPwindow
from "%ui/benchmark/benchmarkState.nut" import openBenchmarksList
from "%ui/featureFlags.nut" import hasGpuBenchmark
from "settings" import get_setting_by_blk_path
from "%ui/state/steamState.nut" import isLinkEmailAvailable, hasDropLinkButton
from "%ui/meta/tutorial/meta_tutorial_window.nut" import showMetaTutorialWindow
from "%ui/meta/tutorial/meta_tutorial_config.nut" import Tutorial
from "%ui/soldiers/model/state.nut" import resetProfile
from "dagor.fs" import file_exists
from "system" import remove
from "%ui/ui_library.nut" import *

let { btnOptions, btnControls, btnExit, SEPARATOR, btnGSS, btnSupport, btnCBR, btnLegals, btnLinkEmail, btnDropSeenSteamLinkMsg } = require("%ui/mainMenu/defMainMenuItems.nut")


let btnHelp = {
  id = "Help"
  name = loc("meta/tutorial/help")
  cb = @() showMetaTutorialWindow(Tutorial.MAIN)
}

let btnBattlePass = {
  id = "BattlePass"
  name = loc("bp/battlePass")
  cb = @() openBPwindow()
}

let btnCustomGames = {
  id  = "CustomGames"
  name = loc("Custom games")
  cb = customGamesOpen
}

let btnChangelog = changelogDisabled ? null : {
  id = "Changelog"
  name = loc("gamemenu/btnChangelog")
  cb = openChangelog
}

let gameStoryMsg = doesLocTextExist("gameStoryMsg") ? loc("gameStoryMsg") : ""
let btnShowGameStory = gameStoryMsg == "" ? null : {
  id = "GameStory"
  name = loc("gamemenu/btnGameStory")
  cb = @() showMsgbox(gameStoryMsg)
}

let btnDebugProfile = {
  id = "DebugProfile"
  name = loc("Debug Profile")
  cb = debugProfileWnd
}

let btnDebugConfigs = {
  id = "DebugConfigs"
  name = loc("Debug Configs")
  cb = debugConfigsWnd
}

let btnResetProfile = {
  id = "ResetProfile"
  name = loc("Reset Profile")
  cb = resetProfile
}

let btnForum = enlistedForumUrl == "" ? null : {
  id = "Forum"
  name = loc("forum")
  cb = !is_gdk ? @() openUrl(enlistedForumUrl)
    : @() qrWindow({url = enlistedForumUrl, header = loc("forum")})
}

let btnFeedback = feedbackUrl == "" ? null : {
  id = "Feedback"
  name = loc("feedback", "Feedback")
  cb = @() openUrl(feedbackUrl)
}

let btnReplays = {
  id = "replay"
  name = loc("replay/records")
  cb = @() profileScene("replay")
}

let btnResetHangar = {
  id = "resetHanhar"
  name = loc("hangar/reset")
  cb = @() showMsgbox({
    text = loc("hangar_reset_confirmation")
    buttons = [
      {
        text = loc("Yes")
        action = function() {
          let userMenuSceneFile = getCustomMenuSceneFile()
          setUseCustomMenuScene(false)
          println($"trying to remove user menu scene: {userMenuSceneFile}")
          if (file_exists(userMenuSceneFile))
            remove(userMenuSceneFile)
          switch_to_menu_scene()
        }
      }
      { text=loc("No"), isCurrent = true}
    ]
  })
}

let btnBenchmark = {
  id = "Benchmark"
  name = loc("benchmark/menu_option")
  cb = openBenchmarksList
}

let perksSimulationUrl = get_setting_by_blk_path("perksSimulationUrl") ?? ""
let btnPerksSimulation = {
  id = "PerksSimulation"
  name = loc("btn/perksSimulation")
  cb = @() openUrl(perksSimulationUrl)
}


let videoTipsUrl = get_setting_by_blk_path("videoTipsUrl") ?? ""
let btnVideoTips = {
  id = "VideoTips"
  name = loc("btn/VideoTips")
  cb = @() openUrl(videoTipsUrl)
}


let customGamesPermission = hasClientPermission("debug_custom_games")
let needCustomGames = Computed(@() (DBGLEVEL > 0 || customGamesPermission.get())
  && !isInQueue.get())

let serverDataPermission = hasClientPermission("debug_server_data")
let canDebugProfile = Computed(@() DBGLEVEL > 0 || serverDataPermission.get())

function buttons(){
  let res = []
  if (needCustomGames.get())
    res.append(btnCustomGames)
  res.append(btnShowGameStory, btnChangelog)
  if (!isReplayTabHidden.get())
    res.append(btnReplays)
  if (hasGpuBenchmark.get())
    res.append(btnBenchmark)
  if (is_user_game_mod())
    res.append(btnResetHangar)

  res.append(SEPARATOR)

  res.append(btnHelp)
  if (hasBattlePass.get() && !isSeasonEnds.get())
    res.append(btnBattlePass)
  res.append(btnOptions, btnControls, btnSupport)
  if (perksSimulationUrl != "")
    res.append(btnPerksSimulation)
  if (videoTipsUrl != "")
    res.append(btnVideoTips)
  res.append(btnForum, btnFeedback, btnGSS)
  if (isLinkEmailAvailable.get())
    res.append(btnLinkEmail)
  if (hasDropLinkButton.get())
    res.append(btnDropSeenSteamLinkMsg)
  if (!isChineseVersion) {
    res.append(btnCBR)
    res.append(btnLegals)
  }
  res.append(btnCredits)
  if (!is_sony && !is_xbox)
    res.append(btnExit)
  if (canDebugProfile.get()) {
    res.append(SEPARATOR, btnDebugProfile, btnDebugConfigs)
    if (needCustomGames.get())
      res.append(btnResetProfile)
   }

  return res.filter(@(v) v!=null)
}
let watch = [needCustomGames, canDebugProfile, isReplayTabHidden, hasBattlePass,
  isLinkEmailAvailable, hasDropLinkButton, isSeasonEnds]

return mkDropMenuBtn(buttons, watch)
