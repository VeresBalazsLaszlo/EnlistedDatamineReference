import "%ui/components/closeBtn.nut" as closeBtnBase
from "%ui/style/designConst.nut" import midPadding, defItemBlur
from "%dngscripts/globalState.nut" import nestWatched
from "settings" import get_setting_by_blk_path
from "%ui/networkedUrls.nut" import getPromoUrl
from "%ui/components/openUrl.nut" import openUrl, AuthenticationMode
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "json" import parse_json
from "statsd" import send_counter
from "%ui/components/browserWidget.nut" import isBrowserClosed
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/components/wndManager.nut" import registerWnd, Wnd, WndEvents
from "%ui/components/wndPermissionFlags.nut" import canShowWindows, autoClose
from "%ui/ui_library.nut" import *

const WND_UID = "WEB_PROMO_WND"

let dbgPromoUrl = Watched(null)

let promoUrl = getPromoUrl() ?? get_setting_by_blk_path("promoUrl")
let hasSeen = nestWatched("hasSeenWebPromo", false)
let webPromoBody = Watched(null)

let needRequestWebPromo = keepref(Computed(@() isLoggedIn.get()
  && (promoUrl != null || dbgPromoUrl.get() != null)
  && !hasSeen.get()))

let canShowWebPromo = registerWnd({
  dataWatch = Computed(@() needRequestWebPromo.get() && webPromoBody.get() != null)
  showWatch = canShowWindows
  closeWatch = autoClose
  name = Wnd.WEB_PROMO
  handlers = { [WndEvents.SUPPRESS] = @() webPromoBody.set(null) }
})

function closeWnd() {
  hasSeen.set(true)
  removeModalWindow(WND_UID)
}

let closeButton = closeBtnBase({
  hplace = ALIGN_RIGHT
  margin = [midPadding, midPadding, 0,0]
  onClick = closeWnd
})

async function requestWebPromo() {
  let response = await httpFetch({ method = "GET", url = promoUrl ?? dbgPromoUrl.get() })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("webpromo_request_receive_errors", 1, { http_code })
    log($"haven't received web promos. http_code = {http_code}")
    return
  }

  local parsed
  try {
    parsed = parse_json(body?.as_string())
  } catch(e) {
    log(e)
    return
  }
  webPromoBody.set(parsed[0])
}

function showWebPromo() {
  let { picUrl = null, jumpUrl = null } = webPromoBody.get()
  if (picUrl == null)
    return

  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_WORLD_BLUR
    color = defItemBlur
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    onClick = closeWnd
    children = {
      size = const [fsh(106), fsh(65)]
      children = [
        {
          size = FLEX
          rendObj = ROBJ_IMAGE
          image = Picture(picUrl)
          keepAspect = KEEP_ASPECT_FILL
          imageHalign = ALIGN_CENTER
          imageValign = ALIGN_CENTER
          behavior = Behaviors.Button
          onClick = function() {
            closeWnd()
            if (jumpUrl != null)
              openUrl(jumpUrl, AuthenticationMode.WEGAME_AUTH)
          }
        }
        closeButton
      ]
    }
  })
}

isBrowserClosed.subscribe(@(v) v ? hasSeen.set(true) : null)

canShowWebPromo.subscribe(function(v) {
  if (v)
    showWebPromo()
})
needRequestWebPromo.subscribe(function(v) {
  if (v)
    requestWebPromo()
})

console_register_command(function(url) {
  hasSeen.set(false)
  dbgPromoUrl.set(url)
}, "openWebPromo")