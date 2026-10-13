from "eventbus" import eventbus_subscribe
from "%ui/components/msgbox.nut" import showMsgbox
import "%ui/login/ui/supportLink.nut" as supportLink
import "%ui/login/ui/background.nut" as background
import "%ui/components/urlText.nut" as urlText
import "%ui/components/checkbox.nut" as checkBox
import "%ui/components/progressText.nut" as progressText
import "%ui/components/fontIconButton.nut" as fontIconButton
import "dagor.system" as system
import "%ui/components/textInput.nut" as textInput
import "%ui/login/ui/reginfo.nut" as regInfo
import "%ui/login/ui/loginDarkStripe.nut" as loginDarkStripe
from "auth" import YU2_2STEP_AUTH, YU2_WRONG_LOGIN, set_login_web_timeout, get_web_login_session_id, get_2step_external, get_2step_external_code
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "app" import local_storage, get_circuit_conf
from "dagor.time" import get_time_msec
from "settings" import save_settings, get_setting_by_blk_path, set_setting_by_blk_path
from "%ui/components/textButton.nut" import Accented, loginBtnStyle, loginBtnStyleDisabled, Regular
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/mainMsgBoxes.nut" import exitGameMsgBox
from "%ui/components/msgbox.nut" import getCurMsgbox, msgboxGeneration
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/login/login_chain.nut" import startLogin, currentStage, resetCurrentStage
from "%ui/login/ui/loginUiParams.nut" import loginBlockOverride
from "%ui/login/loginPkg.nut" import enlsitedLogo
from "%ui/ui_library.nut" import *
from "types" import String

const WEB_LOGIN_TIMEOUT = 120.0

let circuitConf = get_circuit_conf()

let forgotPasswordUrl = circuitConf?.recoveryPasswordURL
  ?? get_setting_by_blk_path("forgotPasswordUrl")
  ?? "https://login.gaijin.net/en/sso/forgotPassword"

let forgotPassword = urlText(loc("forgotPassword"), forgotPasswordUrl, {
  opacity = 0.7
  hplace = ALIGN_CENTER
}.__update(fontSub))

const EXTERNAL_TOTP_CALLBACK_EVENT = "EXTERNAL_TOTP_CALLBACK_EVENT"

let twoStepLocKey = @(method) method == "email" ? "2fa code/email"
  : method == "app" ? "2fa code/app"
  : "2 step code"

const autologinBlkPath = "autologin"
let doAutoLogin = mkWatched(persist, "doAutoLogin", get_setting_by_blk_path(autologinBlkPath) ?? false)

const DUPLICATE_ACTION_DELAY_MSEC = 100 
const AFTER_ERROR_PROCESSED_ID = "after_go_login_error_processed"

let arg_login = system.get_arg_value_by_name("auth_login")
let arg_password = system.get_arg_value_by_name("auth_password")
let storedLogin = arg_login ? arg_login : local_storage.hidden.get_value("login")
let storedPassword = arg_password ? arg_password : local_storage.hidden.get_value("password")
let need2Step = mkWatched(persist, "need2Step", null)
local lastLoginCalled = - DUPLICATE_ACTION_DELAY_MSEC
local focusedFieldIdxBeforeExitMsg = -1

isLoggedIn.subscribe_with_nasty_disregard_of_frp_update(@(_v) need2Step.set(null))

let formStateLogin = Watched(storedLogin ?? "")
let formStatePassword = Watched(storedPassword ?? "")
let formStateTwoStepCode = Watched(system.get_arg_value_by_name("two_step") ?? "")
let formStateSaveLogin = Watched(storedLogin != null)
let formStateSavePassword = Watched(storedPassword != null)
let formStateFocusedFieldIdx = Watched(null)
let formStateAutoLogin = Watched(get_setting_by_blk_path(autologinBlkPath) ?? false)
let areInputsEmpty = Computed(@() formStateLogin.get() == "" || formStatePassword.get() == "")

formStateAutoLogin.subscribe_with_nasty_disregard_of_frp_update(function(v) {
  set_setting_by_blk_path(autologinBlkPath, v)
  save_settings()
})
function availableFields() {
  return [
    formStateLogin,
    formStatePassword,
    (need2Step.get() ? formStateTwoStepCode : null),
    formStateSaveLogin,
    (formStateSaveLogin.get() ? formStateSavePassword : null),
    formStateAutoLogin
  ].filter(@(val) val)
}


function tabFocusTraverse(delta) {
  let tabOrder = availableFields()
  let curIdx = formStateFocusedFieldIdx.get()
  if (curIdx==null)
    set_kb_focus(tabOrder[0])
  else {
    let newIdx = (curIdx + tabOrder.len() + delta) % tabOrder.len()
    set_kb_focus(tabOrder[newIdx])
  }
}
let persistActions = persist("persistActions", @() {})

persistActions[AFTER_ERROR_PROCESSED_ID] <- function(processState) {
  let status = processState?.status
  if (status == YU2_2STEP_AUTH) {
    let { external = false, gj_pass = false, wt_assist = false, email = false } = get_2step_external()
    let twoStepMethod = email ? "email" : (gj_pass || wt_assist) ? "app" : "unknown"
    need2Step.set(twoStepMethod)
    formStateTwoStepCode.set("")
    set_kb_focus(formStateTwoStepCode)
    if (external) {
      get_2step_external_code(EXTERNAL_TOTP_CALLBACK_EVENT)
    }
  }
  else if (status == YU2_WRONG_LOGIN) {
    set_kb_focus(formStateLogin)
    anim_start(formStateLogin)
  }
}
formStateLogin.subscribe_with_nasty_disregard_of_frp_update(@(_) need2Step.set(null))

function checkLoginAvailable(){
  if (currentStage.get()!=null) {
    log($"Ignore start login due current loginStage is {currentStage.get()}")
    return false
  }
  let curTime = get_time_msec()
  if (curTime < lastLoginCalled + DUPLICATE_ACTION_DELAY_MSEC) {
    log("Ignore start login due duplicate action called")
    return false
  }
  lastLoginCalled = curTime
  return true
}

let needShowError = @(processState) processState?.status != YU2_2STEP_AUTH
let afterErrorProcessed = @(processState) persistActions[AFTER_ERROR_PROCESSED_ID](processState)

function doPasswordLogin() {
  if (!checkLoginAvailable())
    return
  local isValid = true
  foreach (f in availableFields()) {
    if (typeof(f.get())=="string" && !f.get().len()) {
      anim_start(f)
      isValid = false
    }
  }
  if (isValid) {
    let twoStepCode = need2Step.get() ? formStateTwoStepCode.get() : null
    startLogin({
      login_id = formStateLogin.get(),
      password = formStatePassword.get(),
      saveLogin = formStateSaveLogin.get(),
      savePassword = formStateSavePassword.get() && formStateSaveLogin.get(),
      two_step_code = twoStepCode
      afterErrorProcessed
      needShowError
    })
  } else
    showMsgbox(loc("login/error/incorrect_login_arguments"))
}

eventbus_subscribe(EXTERNAL_TOTP_CALLBACK_EVENT, function(evt) {
  if (evt?.totp != null) {
    formStateTwoStepCode.set(evt.totp)
    doPasswordLogin()
  }
})

let started_web_login = mkWatched(persist, "started_web_login", false)

function onWebLoginTimeout() {
  if (isLoggedIn.get() || currentStage.get() == null)
    return

  started_web_login.set(false)
  resetCurrentStage()
  showMsgbox(loc("login/error/web_login_timeout"))
}

function doWebLogin(session_id) {
  if (!checkLoginAvailable())
    return

  let params = {session_id, needShowError, afterErrorProcessed}
  if (formStateSaveLogin.get() && !doAutoLogin.get()) {
    if ((formStateLogin.get()?.len() ?? 0) > 0) {
      params.__update({saveLogin = true, login_id = formStateLogin.get()})
      if (formStateSavePassword.get() && (formStatePassword.get()?.len() ?? 0) > 0 )
        params.__update({savePassword = true, password = formStatePassword.get(),})
    }
  }
  startLogin(params)
}

const WEB_LOGIN_GET_SESSION_ID = "WEB_LOGIN_GET_SESSION"

eventbus_subscribe(WEB_LOGIN_GET_SESSION_ID, function(evt) {
  log("WEB_LOGIN", WEB_LOGIN_GET_SESSION_ID, evt)
  let { session_id = null, status=null } = evt
  if ( status != 0 && !(session_id instanceof String)) {
    showMsgbox(loc("login/error/getting_web_login_session"))
    started_web_login.set(false)
    return
  }
  started_web_login.set(false)
  doWebLogin(session_id)
})

function startWebLogin() {
  started_web_login.set(true)
  set_login_web_timeout(WEB_LOGIN_TIMEOUT)
  get_web_login_session_id(WEB_LOGIN_GET_SESSION_ID)
  gui_scene.resetTimeout(WEB_LOGIN_TIMEOUT, onWebLoginTimeout)
}

function onMessageBoxChange(_) {
  if (!getCurMsgbox() && focusedFieldIdxBeforeExitMsg!=-1) {
    let fields = availableFields()
    if (focusedFieldIdxBeforeExitMsg in fields)
      set_kb_focus(fields[focusedFieldIdxBeforeExitMsg])
    focusedFieldIdxBeforeExitMsg = -1
  }
}

function showExitMsgBox(){
  focusedFieldIdxBeforeExitMsg = formStateFocusedFieldIdx.get()
  set_kb_focus(null)
  exitGameMsgBox()
}

function makeFormItemHandlers(field, debugKey=null, idx=null) {
  return {
    onFocus = @() formStateFocusedFieldIdx.set(idx)
    onBlur = @() formStateFocusedFieldIdx.set(null)
    onEscape = @() showExitMsgBox()
    onAttach = function(elem) {
      if (getCurMsgbox() != null)
        return
      let focusOn = need2Step.get() ? formStateTwoStepCode
            : ((formStatePassword.get()=="" && formStateLogin.get()!="") ? formStatePassword : formStateLogin)
      if (field == focusOn)
        set_kb_focus(elem)
    }

    onReturn = function() { log("Start Login from text field", debugKey); doPasswordLogin() }
  }
}


function formText(field, options={}, idx=null) {
  return textInput.Underlined(field, options.__merge(makeFormItemHandlers(field, options?.title, idx)))
}

let capslockText = {rendObj = ROBJ_TEXT text=loc("capsLock", "Caps Lock") color = Color(50,200,255)}
let capsDummy = {rendObj = ROBJ_TEXT text=null}
function capsLock() {
  let children = (gui_scene.keyboardLocks.get() & KBD_BIT_CAPS_LOCK) ? capslockText : capsDummy
  return {
    watch = gui_scene.keyboardLocks
    size = SIZE_TO_CONTENT
    hplace = ALIGN_CENTER
    children = children
  }
}

const keyboardLangColor = Color(100,100,100)
function keyboardLang(){
  local text = gui_scene.keyboardLayout.get()
  if (text instanceof String)
    text = text.slice(0,5)
  else
    text = ""
  return {
    watch = gui_scene.keyboardLayout
    rendObj = ROBJ_TEXT text=text color=keyboardLangColor  hplace=ALIGN_RIGHT vplace=ALIGN_CENTER padding=const [0,hdpx(5),0,0]
  }
}

function formPwd(field, options={}, idx=null) {
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      {
        size = FLEX_H
        children = [
          textInput.Underlined(field, options.__merge(makeFormItemHandlers(field, options?.debugKey, idx)))
          keyboardLang
        ]
      }
      capsLock
    ]
  }
}
let formCheckbox = @(field, options={}, idx=null) checkBox(field,
      options.title, makeFormItemHandlers(field, options?.title, idx))

let loginBtn = @(){
  watch = areInputsEmpty
  size = FLEX_H
  children = Accented(loc("Login"),
    function() { log("Start Login by login btn"); doPasswordLogin() },
    { halign = ALIGN_CENTER
      size = const [FLEX, hdpx(70)]
      hotkeys = [["^J:Y", { description = { skip = true }}]]
      style = areInputsEmpty.get() ? loginBtnStyleDisabled : loginBtnStyle
    }.__update(fontHeading2)
  )
}

let hotkeysRootChild = { hotkeys = [
    ["^Tab", @() tabFocusTraverse(1)],
    ["^L.Shift Tab | R.Shift Tab", @() tabFocusTraverse(-1)],
    ["^Esc", @() showExitMsgBox()]
  ] }

let webLoginBtn = Regular(loc("login/web"), function(){
  log("Start Web Login by login btn")
  startWebLogin()
}, const {margin = hdpx(1), size = FLEX_H, halign = ALIGN_CENTER})

function loginOptions() {
  let res = [
    {t = formText, w = formStateLogin, p = {placeholder=loc("login (e-mail)"), inputType="mail", title="login", showPlaceHolderOnFocus=true}.__update(fontBody)},
    {t = formPwd, w = formStatePassword, p = {placeholder=loc("password"), password="\u2022", title="password", showPlaceHolderOnFocus=true}.__update(fontBody)},
    need2Step.get() ? {t=formText, w = formStateTwoStepCode, p = { placeholder=loc(twoStepLocKey(need2Step.get())), title="twoStepCode", showPlaceHolderOnFocus=true}.__update(fontBody)} : null,
    {t = formCheckbox, w = formStateSaveLogin, p = {title=loc("Store login (e-mail)")}},
    formStateSaveLogin.get() ? {t = formCheckbox, w = formStateSavePassword, p = {title=loc("Store password (this is unsecure!)")}} : null
  ].filter(@(v) v!=null).map(@(v, idx) v.t(v.w, v.p, idx))
  res.append(forgotPassword)
  res.insert(0, regInfo)
  return res
}

function createLoginForm() {
  return [
    @() {
      watch = [formStateSaveLogin, need2Step]
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = loginOptions()
    }
    @() {
      watch = currentStage
      size = FLEX_H
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = currentStage.get() == null ? [loginBtn, webLoginBtn] : null
    }
    hotkeysRootChild
  ]
}

let coincidenceBlock = {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  color = Color( 150, 150, 150)
  text = loc("coincidence")
}

function loginRoot() {
  let children = isLoggedIn.get() ? null
    : currentStage.get() || started_web_login.get() ? progressText(loc("loggingInProcess"))
    : createLoginForm()
  return {
    watch = [currentStage, need2Step, formStateSaveLogin, isLoggedIn, started_web_login, loginBlockOverride]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    onAttach = function() {
      msgboxGeneration.subscribe(onMessageBoxChange)
      if (doAutoLogin.get()) {
        doAutoLogin.set(false)
        doPasswordLogin()
      }
    }
    onDetach = @() msgboxGeneration.unsubscribe(onMessageBoxChange)
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children
  }.__update(loginBlockOverride.get())
}

let enterHandler = @(){
  hotkeys = [["^Enter", function() {
    if ((formStateLogin.get()?.len() ?? 0) > 1
        && (formStatePassword.get()?.len() ?? 0) > 1)
      doPasswordLogin()
  }]]
}

return {
  size = FLEX
  children = [
    background
    loginDarkStripe
    {
      flow = FLOW_VERTICAL
      hplace = ALIGN_RIGHT
      vplace = ALIGN_CENTER
      pos = [-sw(15), 0]
      children = [
        enlsitedLogo
        loginRoot
        supportLink
        coincidenceBlock
      ]
    }
    {
      hplace = ALIGN_RIGHT
      margin = safeAreaBorders.get()[1]
      children = fontIconButton("power-off", { onClick = showExitMsgBox })
    }
    enterHandler
  ]
}
