from "%enlSqGlob/appInfo.nut" import exe_version
from "%sqstd/frp.nut" import ComputedImmediate
from "%ui/state/clientState.nut" import gameLanguage
from "settings" import get_setting_by_blk_path
from "%ui/httpPkg.nut" import getPlatformId, getLanguageId
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "json" import parse_json
from "statsd" import send_counter
from "clientlog" import send_error_log
from "%ui/ui_library.nut" import *

let { metaTutorialConfigById } = require("%ui/meta/tutorial/meta_tutorial_config.nut")


local URL_TUTOR = get_setting_by_blk_path("tutorUrl") ?? ""
if (URL_TUTOR == "")
  URL_TUTOR = "https://newsfeed.gap.gaijin.net/api/pages/enlisted/{languageId}/{index}?platform={platformId}" 

local URL_VERSIONS = get_setting_by_blk_path("tutorVersionUrl") ?? ""
if (URL_VERSIONS == "")
  URL_VERSIONS = "https://newsfeed.gap.gaijin.net/api/pages/enlisted/{languageId}/?platform={platformId}" 


let tutorCache = persist("tutorCache", @() {})
let selectedPageLoaded = Watched(false)
let selectedPageContent = Watched(null)
let selectedTutor = Watched(null)

function logError(event, params = {}) {
  log(event, params)
  send_error_log(event, {
    attach_game_log = true
    collection = "events"
    meta = {
      hint = "error"
      exe_version = exe_version.get()
      language = gameLanguage
    }.__update(params)
  })
}

function setTutorResult(result) {
  selectedPageContent.set(result)
  log("show tutor:", result?.content)
  selectedPageLoaded.set(true)
}

async function requestTutor(id) {
  selectedPageLoaded.set(false)
  selectedPageContent.set(null)

  if (id in tutorCache) {
    setTutorResult(tutorCache[id])
    return
  }

  let config = metaTutorialConfigById[id]
  let url = URL_TUTOR.subst({ languageId = getLanguageId(), platformId = getPlatformId(),
    index = config.link })

  let response = await httpFetch({ method = "GET", url })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("tutor_receive_errors", 1, { http_code, stage = "get_tutor" })
    return
  }

  local result
  try {
    result = parse_json(body?.as_string())?.result
  } catch(e) {
  }

  if (result == null) {
    logError("tutor_parse_errors", { stage = "get_tutor" })
    send_counter("tutor_parse_errors", 1, { stage = "get_tutor" })
    return
  }

  log("tutor_success_data")
  setTutorResult(result)
  let resId = result?.id
  if (resId)
    tutorCache[resId] <- result
}

async function requestVersions() {
  let url = URL_VERSIONS.subst({ languageId = getLanguageId(), platformId = getPlatformId() })

  let response = await httpFetch({ method = "GET", url })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("tutor_receive_errors", 1, { http_code, stage = "get_versions" })
    return
  }

  local result
  try {
    result = parse_json(body?.as_string())?.result
  } catch(e) {}

  if (result == null) {
    logError("tutor_receive_errors", { stage = "get_versions" })
    send_counter("tutor_receive_errors", 1, { stage = "get_versions" })
    return
  }

  log("tutor_success_versions", result)
  foreach (item in result?.items ?? []) {
    let { id, rev } = item
    let cachedRev = tutorCache?[id].rev
    if (cachedRev && cachedRev < rev) {
      tutorCache.$rawdelete(id)
    }
  }
}

let isPageContentLoaded = ComputedImmediate(@() selectedPageLoaded.get()
  && selectedPageContent.get() != null)

return {
  isPageContentLoaded
  requestTutor
  selectedPageContent
  selectedTutor
  requestVersions
}
