import "%enlSqGlob/userInfo.nut" as userInfo
import "wegame" as wegame
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "json" import parse_json
from "settings" import get_setting_by_blk_path
from "app" import encode_uri_component
from "dagor.debug" import logerr
from "hash" import md5

let { get_kongzhong_accountid = null } = require_optional("auth.kongzhong")
let { send_counter = null } = require_optional("statsd")

let OBSCENE_FILTER_URL = get_setting_by_blk_path("obsceneFilterUrl") ?? ""

let signKey = get_setting_by_blk_path("signKey") ?? ""

let hasObsceneFilter = OBSCENE_FILTER_URL != ""

async function requestObsceneFilter(phraseToFilter){
  if (!hasObsceneFilter)
    return phraseToFilter

  if (wegame.is_running())
    return wegame.filter_words(phraseToFilter)

  local words = phraseToFilter
  local replace_sensitive = 0
  local gameKey = "cj"
  local userId = get_kongzhong_accountid?()
  local playerName = userInfo.get().name
  local playerId = userInfo.get().userId
  local areaId = 1
  local sign = md5($"words{words}replace_sensitive{replace_sensitive}userId{userId}playerName{playerName}playerId{playerId}areaId{areaId}signKey{signKey}")
  let url = OBSCENE_FILTER_URL.subst({ words = encode_uri_component(words), replace_sensitive,
    gameKey, userId, playerName = encode_uri_component(playerName), playerId, areaId, sign })

  let response = await httpFetch({ method = "GET", url })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter?("obscene_filter_receive_errors", 1, { http_code })
    return null
  }

  local result
  try {
    result = parse_json(body?.as_string())?.data.replace_string
  } catch(e) {
    logerr(e)
  }
  if (result == null) {
    logerr("ObsceneFilter result is null")
    return null
  }
  return result
}

return requestObsceneFilter
