import "%ui/components/spinner.nut" as spinner
from "%enlSqGlob/app_control.nut" import switch_to_menu_scene
from "dagor.system" import dgs_get_settings
from "io" import file
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/style/colors.nut" import WindowTransparent
from "%ui/components/textButton.nut" import Regular
from "%ui/style/designConst.nut" import defInsideBgColor, commonBtnHeight, titleTxtColor
from "%ui/components/defcomps.nut" import noteTextArea
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "eventbus" import eventbus_subscribe
from "%ui/ui_library.nut" import *

let logHG = with_prefix("[CustomHangar] ")

const WND_UID = "hangarDownloadUi"

let defaultSize = [hdpx(432), hdpx(324)]
let waitingSpinner = spinner()
let errorTextState = Watched("")
let isDownloadInProgress = Watched(false)

let defTxtStyle = { color = titleTxtColor }.__update(fontBody)

let btnStyle = {
  size = [SIZE_TO_CONTENT, commonBtnHeight]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
}

let title = noteTextArea({
  size = FLEX_H
  text = loc("hangar/Downloading")
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
  watch = errorTextState
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
  children = errorTextState.get() == ""
    ? [
        title
        {
          size = FLEX
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          flow = FLOW_VERTICAL
          children = waitingSpinner
        }
      ]
    : [
        title
        content(loc(errorTextState.get()))
        {
          size = FLEX
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          gap = hdpx(5)
          children = Regular(loc("replay/Close"), @() removeModalWindow(WND_UID), btnStyle)
        }
      ]
}

let openDownloadModal = @() addModalWindow({
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

async function installHangarMod(url) {
  let response = await httpFetch({ method = "GET", url })
  isDownloadInProgress.set(false)
  logHG("received headers:", response?.headers)

  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    logHG($"request failed: status = {status}, http_code = {http_code}")
    errorTextState.set("mods/failedDownload")
    return
  }

  try {
    let customHangarFile = dgs_get_settings()?.menu?.scene ?? ""
    let resultFile = file(customHangarFile, "wb+")
    resultFile.writeblob(body)
    resultFile.close()
    removeModalWindow(WND_UID)
    switch_to_menu_scene()
  }
  catch(e) {
    errorTextState.set("mods/failedToSave")
    logHG(e)
  }
}

eventbus_subscribe("hangar.install", function(params) {
  logHG($"Install request, download in progress = {isDownloadInProgress.get()} params:", params)
  if (isDownloadInProgress.get())
    return

  let { url = null } = params
  if (url == null)
    return

  isDownloadInProgress.set(true)
  openDownloadModal()
  installHangarMod(url)
})
