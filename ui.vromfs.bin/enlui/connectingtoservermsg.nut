import "%ui/components/progressText.nut" as progressText
from "%ui/navState.nut" import addScene, removeScene
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/state/roomState.nut" import RoomState, isInRoom, roomState, roomIsLobby, leaveRoom
from "%ui/components/textButton.nut" import Regular
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/ui_library.nut" import *

const TIME_TO_ALLOW_CANCEL = 7.0

let isNeedMsg = keepref(Computed(@() isInRoom.get()
  && !roomIsLobby.get()
  && roomState.get() != RoomState.GAME_STARTED))

let canCancelMsg = Watched(false)
let allowCancel = @() canCancelMsg.set(true)

let cancelGameLaunchBtn = Regular(loc("mainmenu/btnCancel"),
  @() leaveRoom(),
  {
    halign = ALIGN_CENTER
    textParams = fontHeading2
  }
)

function gameLaunchingMsg() {
  let cancelGameLaunch = canCancelMsg.get() ? cancelGameLaunchBtn : null
  return {
    watch = canCancelMsg
    size = const [pw(100), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    hplace = ALIGN_LEFT
    vplace = ALIGN_TOP
    pos = const [0,sh(70)]
    valign = ALIGN_TOP
    halign = ALIGN_CENTER
    gap = hdpx(50)
    children = [
      progressText(loc("gameIsFound"))
      cancelGameLaunch
    ]
  }
}

function open() {
  addScene(gameLaunchingMsg)
  sound_play("ui/match_found")
}

if (isNeedMsg.get())
  open()

isNeedMsg.subscribe(function(isNeed) {
  canCancelMsg.set(false)

  if (isNeed) {
    gui_scene.resetTimeout(TIME_TO_ALLOW_CANCEL, allowCancel)
    open()
  }
  else {
    gui_scene.clearTimer(allowCancel)
    removeScene(gameLaunchingMsg)
  }
})
