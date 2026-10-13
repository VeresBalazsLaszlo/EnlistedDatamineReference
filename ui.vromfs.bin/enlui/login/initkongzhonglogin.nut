import "auth" as auth
from "%ui/login/login_chain.nut" import startLogin
from "%ui/state/login_state.nut" import isLoggedIn
from "app" import get_circuit
from "eventbus" import eventbus_subscribe
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/ui_library.nut" import *
from "auth.kongzhong" import login_kongzhong

let {
  browser_add_window_method = @(_n,_c) null,
  BROWSER_EVENT_INITIALIZED = null
} = require_optional("browser")
local isLoginStarted = false

const LOGIN_WND_UID = "login_back_window"
const BROWSER_WND_UID = "webbrowser_window"

let onLogingWnd = {
  key = LOGIN_WND_UID
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture("ui/stalingrad_login_screen_blured.avif")
  keepAspect = KEEP_ASPECT_FILL
}

function onKongZhongAuthResult(result) {
  if (result.status == auth.YU2_OK && !isLoginStarted) {
    isLoginStarted = true
    removeModalWindow(BROWSER_WND_UID)
    startLogin({})
    addModalWindow(onLogingWnd)
  }
}

isLoggedIn.subscribe(function(v){
  if (v){
    isLoginStarted = false
    removeModalWindow(LOGIN_WND_UID)
  }
})


function handleBrowserWindowMethodCall(val) {
  if ("name" in val && "p1" in val) {
    if (val.name == "onKongZhongLoginComplete") {
      eventbus_subscribe("auth_kongzhong", onKongZhongAuthResult)
      login_kongzhong({ kz_token = val.p1, circuit = get_circuit() }, "auth_kongzhong")
    }
  }
}

function handleBrowserEvent(val) {
  if ("eventType" in val && val.eventType == BROWSER_EVENT_INITIALIZED)
    browser_add_window_method("onKongZhongLoginComplete", 1)
}

eventbus_subscribe("browser_window_method_call", handleBrowserWindowMethodCall)
eventbus_subscribe("browser_event", handleBrowserEvent)
