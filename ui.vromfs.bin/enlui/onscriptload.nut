import "%ui/hud/menus/options/get_quality_preset_option.nut" as qualityPresetOption
import "%ui/mainMenu/mainMenu.nut" as mainMenu
import "%ui/queueWaitingInfo.ui.nut" as quickMatchQueueInfoCmp
import "%ui/notifications/leaveQueueNotification.nut" as leaveQueueNotification
from "%ui/hud/menus/options/render_options.nut" import renderOptions
from "%ui/hud/menus/options/sound_options.nut" import soundOptions
from "%ui/hud/menus/options/voicechat_options.nut" import voiceChatOptions
from "%dngscripts/platform.nut" import is_sony
from "%ui/mainMenu/mainMenuComp.nut" import setMainMenuComp
from "%ui/hud/menus/settings_menu.nut" import setMenuOptions, menuTabsOrder
from "%ui/hud/menus/options/harmonization_options.nut" import harmonizationOption
from "%ui/hud/menus/options/voiceover_options.nut" import voiceoverOption
from "%ui/hud/menus/options/incognito_options.nut" import incognitoOption
from "%ui/hud/menus/options/dirty_words_filter_option.nut" import dirtyWordsOption
from "%ui/hud/menus/options/harmonization_nick_options.nut" import harmonizationNickOption
from "%ui/hud/menus/options/camera_fov_option.nut" import cameraFovOption
from "%ui/hud/menus/vehicle_camera_fov_option.nut" import vehicleCameraFovOption
from "%ui/hud/menus/options/plane_camera_options.nut" import planeFlightSenseOption
from "%ui/hud/menus/vehicle_camera_follow_option.nut" import vehicleCameraFollowOption
from "%ui/hud/menus/options/bigger_fonts_options.nut" import biggerFontsOption
from "%ui/hud/menus/options/other_options.nut" import minimizeWarningsOption
from "%ui/hud/menus/options/teammate_markers_option.nut" import teammateMarkersOption
from "%ui/gameModes/gameModesWnd/gameModeWnd.nut" import isGameModeWndOpened
from "%ui/quickMatch.nut" import matchRandomTeam
from "%ui/soldiers/model/state.nut" import curArmy, selectArmy
from "%ui/gameModes/eventModesState.nut" import isEventModesOpened, customRoomsModeSaved, isCustomRoomsMode
from "%ui/state/appState.nut" import isInBattleState
from "%ui/components/msgbox.nut" import removeAllMsgboxes
from "%ui/ui_library.nut" import *

require("%enlSqGlob/sqevents.nut")
require("%ui/notifications.nut")
require("%ui/currency/currenciesList.nut")
require("%ui/sections.nut")
require("%ui/scene/scene_control.nut")
require("%ui/meta/profileRefresh.nut")
require("%ui/meta/dumpStats.nut")
require("%ui/soldiers/model/configArmiesDump.nut")
require("%ui/vehicles/configCamoDump.nut")
require("%ui/faceGen.nut")
require("%ui/battleData/sendSoldiersData.nut")
require("%ui/battleData/mkDefaultProfile.nut")
require("%ui/battleData/singleMissionRewardId.nut")
require("%ui/battleData/applyBattleExp.nut")
setMainMenuComp(mainMenu)
require("%ui/notifications/mainMenuDescription.nut")
require("%ui/notifications/premiumExpiration.nut")
require("%ui/notifications/memberLockedCampaign.nut")
require("%ui/notifications/serviceNotificationMonitor.nut")
require("%ui/login/initLogin.nut")
require("%ui/login/initLoginStages.nut")
require("%ui/login/onLoginWarnings.nut")
require("%ui/currency/initPurchaseActions.nut")

require("%ui/tutorial/tutorialWnd.nut")
require("%ui/soldiers/chooseSquadsScene.nut")
require("%ui/soldiers/chooseSoldiersScene.nut")
require("%ui/tutorial/squadTutorialsMsg.nut")
require("%ui/tutorial/growthTutorial.nut")
require("%ui/items/selectItemScene.nut")


require("%ui/soldiers/notReadySquadsMsg.nut")
require("%ui/complaints/complain.nut")
require("%ui/guidelinesPopup.nut")
require("%ui/shop/shopResultMsgbox.nut")
require("%ui/webHandlers/webHandlers.nut")
require("%ui/weGameHandlers/weGameHandlers.nut")
require("%ui/battlepass/bpWindow.nut")
require("%ui/battlepass/debugBpRewardsView.nut")
require("%ui/eventPass/eventPassWindow.nut")
require("%ui/unlocks/dailyRewardsUi.nut")
require("%ui/gameModes/eventModesWindow.nut")
require("%ui/gameModes/createEventRoomWnd.nut")
require("%ui/gameModes/missionsRatingWnd.nut")
require("%ui/leaderboard/leaderboardWnd.nut")
require("%ui/profile/profileScene.nut")
require("%ui/profile/anoProfileScene.nut")
require("%ui/profile/unseenProfileStuffs.nut")
require("%ui/contacts/externalIdsManager.nut")
require("%ui/soldiers/soldierCustomizationScene.nut")
require("%ui/usermail/usermailScene.nut")
require("%ui/vehicles/selectVehicleScene.nut")
require("%ui/vehicles/customizeScene.nut")
require("%ui/vehicles/hitcamScene.nut")
require("%ui/soldiers/model/console_cmd.nut")
require("%ui/replay/replayDownloadInfo.nut")
require("%ui/replay/replayWebHadlers.nut")
require("%ui/gameModes/hangarWebHandlers.nut")
require("%ui/items/itemCollageScene.nut")
require("%ui/shop/rentedSquadDialog.nut")
require("%ui/notifications/benchmarkNotification.nut")
require("%ui/shop/updateSeenBundles.nut")
require("%ui/benchmark/benchmarkUi.nut")
require("%ui/options/onlineSettingsOnShutdown.nut")
require("%ui/steam/steam_events_wnd.nut")


let { violenceOptions } = require("%ui/hud/menus/options/violence_options.nut")
let planeControlOptions = require("%ui/hud/menus/options/plane_control_options.nut")
let { cameraShakeOptions } = require("%ui/hud/menus/options/camera_shake_options.nut")
let { hudOptions } = require("%ui/hud/menus/options/hud_options.nut")
let { crossnetworkOptions } = require("%ui/options/crossnetwork_options.nut")
let { leaderboardOptions } = require("%ui/hud/menus/options/leaderboard_options.nut")
let narratorOptions = require("%ui/hud/menus/options/narrator_options.nut")
let autoleanOptions = require("%ui/hud/menus/options/autolean_options.nut")
let vehicleGroupLimitOptions = require("%ui/hud/menus/options/vehicle_group_limit_options.nut")


let options = [qualityPresetOption, cameraFovOption, vehicleCameraFovOption,
  planeFlightSenseOption, vehicleCameraFollowOption, harmonizationOption,
  harmonizationNickOption, dirtyWordsOption, incognitoOption,
  biggerFontsOption, minimizeWarningsOption, teammateMarkersOption, voiceoverOption]
options.extend(
  renderOptions, soundOptions, voiceChatOptions, cameraShakeOptions, violenceOptions, planeControlOptions,
  crossnetworkOptions, leaderboardOptions, hudOptions, narratorOptions, autoleanOptions, vehicleGroupLimitOptions
)

setMenuOptions(options)

menuTabsOrder.set([
  {id = "Graphics", text=loc("options/graphicsParameters")},
  {id = "Sound", text = loc("sound")},
  {id = "Game", text = loc("options/game")},
  {id = "VoiceChat", text = loc("controls/tab/VoiceChat")},
])

require("%ui/backgroundContentUpdater.nut")

let { aboveUiLayer } = require("%ui/uiLayers.nut")
aboveUiLayer.add(quickMatchQueueInfoCmp, "quickMatchQueue")

require("%ui/mainScene/webPromo.nut")

leaveQueueNotification({
  watch = curArmy
  setValue = selectArmy
  askLeave = @() !matchRandomTeam.get()
})
leaveQueueNotification({
  watch = isEventModesOpened
})
leaveQueueNotification({
  watch = isCustomRoomsMode
  setValue = @(v) customRoomsModeSaved.set(v)
})
leaveQueueNotification({
  watch = isGameModeWndOpened
})


require("%ui/debriefing/debriefingWindow.nut")
require("%ui/gameRateState.nut")

let fonts = require("%ui/style/fontsStyle.nut")
require("%ui/components/fontsDebugWnd.nut")(fonts)

isInBattleState.subscribe(function(v) {
  if (v)
    removeAllMsgboxes()
})

if (is_sony)
  require("%ui/sony/supportedPlatforms.nut").set(["PS4", "PS5"])

console_register_command(@(trigger) anim_start(trigger), "anim.start")
console_register_command(@(trigger) anim_request_stop(trigger), "anim.stop")
console_register_command(@(trigger) anim_skip(trigger), "anim.skip")
console_register_command(@(trigger) anim_skip_delay(trigger), "anim.skipDelay")
