import "%ui/components/spinner.nut" as spinner
import "datacache" as datacache
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/colors.nut" import WindowTransparent
from "%ui/components/defcomps.nut" import noteTextArea
from "%ui/components/textButton.nut" import Regular
from "%ui/style/designConst.nut" import defInsideBgColor, commonBtnHeight, titleTxtColor
from "%ui/replay/replayDownloadState.nut" import replayDownload, REPLAY_DOWNLOAD_NONE, REPLAY_DOWNLOAD_PROGRESS, REPLAY_DOWNLOAD_FAILED
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/replay/replaySettings.nut" import replayPlay
from "%ui/state/appState.nut" import isInBattleState
from "%ui/ui_library.nut" import *

const WND_UID = "replayDownloadUi"
let waitingSpinner = spinner()

let btnStyle = {
  size = [SIZE_TO_CONTENT, commonBtnHeight]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
}

let defaultSize = [hdpx(432), hdpx(324)]
let replayWndClose = @() removeModalWindow(WND_UID)
let defTxtStyle = { color = titleTxtColor }.__update(fontBody)

let closeButton = Regular(loc("replay/Close"), replayWndClose, btnStyle)

let playButton = Regular(loc("replay/Play"), function() {
  let filename = replayDownload.get().filename
  replayDownload.mutate(function (v) {
    v.state = REPLAY_DOWNLOAD_NONE
    v.stateText  = ""
    v.filename = ""
    v.downloadRequestId = ""
    v.contentLen = -1
  })

  replayPlay(filename)
}, btnStyle)

let abortButton = Regular(loc("replay/Abort"), @() datacache.abort_requests(replayDownload.get().downloadRequestId), btnStyle)

let title = noteTextArea({
  size = FLEX_H
  text = loc("replay/Downloading")
  halign = ALIGN_CENTER
}).__update(defTxtStyle)

let content = @(message) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  margin = const [hdpx(30), 0]
  vplace = ALIGN_CENTER
  text = message
}.__update(defTxtStyle)

let infoContainer = @() {
  watch = replayDownload
  size = defaultSize
  gap = hdpx(20)
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  padding = hdpx(20)
  fillColor = WindowTransparent
  borderRadius = hdpx(2)
  rendObj = ROBJ_WORLD_BLUR_PANEL
  transform = true
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
  children = replayDownload.get().state == REPLAY_DOWNLOAD_PROGRESS
    ? [
        title
        {
          size = FLEX
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          flow = FLOW_VERTICAL
          children = [
            waitingSpinner
            replayDownload.get().contentLen >= 0
              ? content(loc("replay/fileSizeMb", { size = replayDownload.get().contentLen >> 20 }))
              : null
          ]
        }
        replayDownload.get().downloadRequestId != ""
          ? abortButton
          : null
      ]
    : [
        title
        content(loc(replayDownload.get().stateText))
        {
          size = FLEX
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          gap = hdpx(5)
          children = [
              replayDownload.get().state != REPLAY_DOWNLOAD_FAILED && !isInBattleState.get()
                ? playButton
                : null
              closeButton
          ]
        }
      ]
}

let open = @() addModalWindow({
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = defInsideBgColor
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  stopMouse = true
  children = infoContainer
  onClick = @() null
})

if (replayDownload.get().state != REPLAY_DOWNLOAD_NONE)
  open()

replayDownload.subscribe(@(v) v.state != REPLAY_DOWNLOAD_NONE ? open() : replayWndClose())
