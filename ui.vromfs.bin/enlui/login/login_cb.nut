from "dagor.debug" import logerr
from "auth" import YU2_OK, YU2_WRONG_LOGIN
from "%enlSqGlob/userInfoState.nut" import userInfoUpdate, userPermissionsUpdate
from "%enlSqGlob/permission_utils.nut" import readPermissions, readPenalties
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/login/loginActions.nut" import getLoginActions
from "app" import exit_game
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/login/chineseKongZhongVersion.nut" import isKZVersion
from "%ui/ui_library.nut" import *
from "%ui/login/regionalOperator.nut" import migrationUrl, migratedUrl, isRegionalOperator,
  hasGlobalMigrated, hasGlobalAccount
import "%ui/components/urlText.nut" as urlText
from "types" import Function


function showStageErrorMsgBox(errText, state, mkChildren = null, uid = null) {
  let afterErrorProcessed = state.params?.afterErrorProcessed
  if (errText == null) {
    afterErrorProcessed?(state)
    return
  }

  local urlObj = null
  let errorTxt = state.stageResult?.error ?? ""
  let linkUrl = loc($"{errorTxt}/link/url", "")
  let linkText = loc($"{errorTxt}/link/text", "")
  if (linkUrl != "" && linkText != "") {
    urlObj = urlText(linkText, linkUrl)
  }

  let msgboxParams = {
    uid
    text = errText
    onClose = @() afterErrorProcessed?(state)
    children = (mkChildren ?? @(v) v)(urlObj)
  }

  let closeGameBtn = {
    text = loc("gamemenu/btnQuit")
    action = @() exit_game()
    isCurrent = true
  }

  if (isKZVersion)
    msgboxParams.buttons <- [closeGameBtn]
  else if (state.stageResult?.quitBtn ?? false) {
    msgboxParams.buttons <- [
      { text = loc("mainmenu/btnClose") }
      closeGameBtn
    ]
  }

  showMsgbox(msgboxParams)
  sound_play("ui/enlist/login_fail")
}

function onSuccess(state) {
  let { auth_result, external_auth = null } = state.stageResult
  let { userId, name, nameorig = null, token, tags = [] } = auth_result
  let { globalJwt = null, globalToken = null, globalUserId = null, globalTags = [] } = external_auth
  let urlCtor = migrationUrl != "" ? @(_) urlText(migrationUrl) : null

  if (!isRegionalOperator && hasGlobalMigrated(tags)) {
    showStageErrorMsgBox(loc("error/loginMigratedPlayerProfile"), state, urlCtor)
    return false
  }

  if (isRegionalOperator && hasGlobalAccount(tags, globalTags)) {
    showStageErrorMsgBox(loc("error/nonMigratedPlayerProfile"), state, urlCtor)
    return false
  }

  let { clientPermJwt = null, penaltiesJwt = null, dedicatedPermJwt = null, chard_token = null,
    externalid = [] } = state.stageResult?.char
  let mainToken = globalJwt ?? globalToken ?? token
  if (mainToken == null) {
    logerr("Game token is null")
    log(state.stageResult)
  }

  let trueUserId = globalUserId ?? userId
  userInfoUpdate({
    userId = trueUserId
    localUserId = userId
    userIdStr = userId.tostring()
    name
    nameorig = (nameorig ?? "") != "" ? nameorig : remap_nick(name)
    token = mainToken
    localToken = token
    tags
    chardToken = chard_token
    externalid
  }.__update(state.userInfo))
  userPermissionsUpdate({
    permissions = readPermissions(clientPermJwt, trueUserId)
    penalties = readPenalties(penaltiesJwt, trueUserId)
    penaltiesJwt
    dedicatedPermJwt
  })
  getLoginActions()?.onAuthComplete?.filter(@(v) v instanceof Function)?.map(@(action) action())
  return null
}

function getErrorText(state) {
  if (!(state.params?.needShowError(state) ?? true))
    return null

  if (!state.stageResult?.needShowError)
    return null

  let { status = YU2_OK } = state
  if (status != YU2_OK)
    return "{0}\n{1}".subst(loc("loginFailed/authError"),
      loc("responseStatus/{0}".subst(state.stageResult.error), state.stageResult.error))

  if ((state.stageResult?.char?.success ?? true) != true)
    return loc($"error/{state.stageResult.char.error}")

  let { errorStr = null } = state.stageResult
  if (errorStr != null)
    return errorStr

  let errorId = state.stageResult?.error
  if (errorId != null)
    return loc(errorId)

  return null
}

function onInterrupt(state) {
  local fnLink
  let { status = YU2_OK } = state
  if (isRegionalOperator && status == YU2_WRONG_LOGIN && migratedUrl != "") {
    fnLink = @(_) urlText(migratedUrl)
  }

  showStageErrorMsgBox(getErrorText(state), state, fnLink)
}

return {
  onSuccess
  onInterrupt
  showStageErrorMsgBox
}
