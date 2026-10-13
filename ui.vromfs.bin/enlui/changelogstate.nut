import "%ui/unlocks/isNewbie.nut" as isNewbie
from "%ui/userstats/unlocksState.nut" import unlockProgress
from "%enlSqGlob/appInfo.nut" import exe_version
from "%dngscripts/globalState.nut" import nestWatched
from "clientlog" import send_error_log
from "statsd" import send_counter
from "%sqstd/timers.nut" import throttle
from "dagor.time" import get_time_msec
from "%sqstd/version.nut" import mkVersionFromString, versionToInt
from "%ui/state/clientState.nut" import gameLanguage
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "json" import parse_json
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated, settings
from "%ui/httpPkg.nut" import getPlatformId, getLanguageId
from "settings" import get_setting_by_blk_path
from "%ui/state/appState.nut" import isInBattleState
from "%ui/state/client_version.nut" import maxVersionInt
from "%sqstd/string.nut" import isStringInteger
from "app" import get_circuit_conf
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *


let changelogDisabled = get_setting_by_blk_path("disableChangelog") ?? false
let circuitConf = get_circuit_conf()

let extNewsUrl = circuitConf?.newsUrl
  ?? get_setting_by_blk_path("newsUrl")
  ?? "https://enlisted.net/news/#!/"

let changelogVersionsUrl = circuitConf?.versionUrl
  ?? get_setting_by_blk_path("versionUrl")
  ?? "https://newsfeed.gap.gaijin.net/api/patchnotes/enlisted/{language}/?platform={platform}" 

let changelogPatchnoteUrl = circuitConf?.patchnoteUrl
  ?? get_setting_by_blk_path("patchnoteUrl")
  ?? "https://newsfeed.gap.gaijin.net/api/patchnotes/enlisted/{language}/{id}?platform={platform}" 

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

const SAVE_ID = "ui/lastSeenVersionId"

let lastSeenVersionIdState = Computed(function() {
  if (!onlineSettingUpdated.get())
    return -1
  let val = settings.get()?[SAVE_ID]
  return isStringInteger(val) ? val.tointeger() : 0
})

let chosenPatchnote = Watched(null)
let chosenPatchnoteLoaded = nestWatched("chosenPatchnoteLoaded", false)
let chosenPatchnoteContent = nestWatched("chosenPatchnoteContent", "")
let chosenPatchnoteTitle = nestWatched("chosenPatchnoteTitle", "")
let patchnotesReceived = nestWatched("patchnotesReceived", false)
let versions = nestWatched("versions", [])

const MAX_TAB_INDEX = 7




const LEGACY_ID = "ui/lastSeenVersionInfoNum"

let shouldUpdateLegacyData = keepref(Computed(@() onlineSettingUpdated.get()
  && LEGACY_ID in settings.get()
  && versions.get().len() > 0))

shouldUpdateLegacyData.subscribe(function(v) {
  if (!v)
    return
  let iVersion = settings.get()[LEGACY_ID]
  let id = versions.get().findvalue(@(ver) versionToInt(ver.version) == iVersion)?.id ?? 0
  defer(@() settings.mutate(function(value) {
    value[SAVE_ID] <- id
    value.$rawdelete(LEGACY_ID)
  }))
})



function mkVersion(v){
  local tVersion = v?.version ?? ""
  let versionl = tVersion.split(".").len()
  local versionType = v?.type
  if (versionl!=4) {
    log($"incorrect patchnote version {tVersion}")
    if (versionl==3) {
      tVersion = $"{tVersion}.0"
      if (versionType==null)
        versionType = "major"
    }
    else
      throw null
  }
  let version = mkVersionFromString(tVersion)
  local titleshort = v?.titleshort ?? "undefined"
  if (titleshort == "undefined" || titleshort.len() > 50 )
    titleshort = null
  return {
    version
    title = v?.title ?? tVersion
    tVersion
    versionType
    titleshort
    iVersion = versionToInt(version)
    id = v.id
    date = v?.date ?? ""
    alwaysShowPopup = v?.alwaysShowPopup ?? false
  }
}

function filterVersions(vers) {
  let res = []
  local foundMajor = false
  foreach (idx, version in vers) {
    if (idx >= MAX_TAB_INDEX && foundMajor)
      break
    else if (maxVersionInt.get() > 0 && maxVersionInt.get() < version.iVersion) {
      continue
    }
    else if (version.versionType=="major"){
      res.append(version)
      foundMajor = true
    }
    else if (idx < MAX_TAB_INDEX && !foundMajor){
      res.append(version)
    }
  }
  return res
}

async function requestPatchnotes() {
  patchnotesReceived.set(false)
  let url = changelogVersionsUrl.subst({
    language = getLanguageId()
    platform = getPlatformId()
  })

  let response = await httpFetch({ method = "GET", url })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("changelog_receive_errors", 1, { http_code, stage = "get_versions" })
    return
  }

  local result
  try {
    result = parse_json(body?.as_string())?.result
  } catch(_e) {
  }

  if (result == null) {
    logError("changelog_parse_errors", { stage = "get_versions" })
    send_counter("changelog_parse_errors", 1, { stage = "get_versions" })
    versions.set([])
    patchnotesReceived.set(false)
    return
  }

  versions.set(filterVersions(result.map(mkVersion)))
  patchnotesReceived.set(true)
}

function findBestVersionToshow(versionsList = versions, lastSeenVersionNum = 0) {
  
  lastSeenVersionNum = lastSeenVersionNum ?? 0
  versionsList = versionsList ?? []
  local res = null
  foreach (version in versionsList) {
    if (version.alwaysShowPopup && res == null)
      return version
    if (lastSeenVersionNum < version.id) {
      if (version.versionType == "major")
        return version
      res = version
    }
    else
      break
  }
  return res
}

let unseenPatchnote = Computed(@() !onlineSettingUpdated.get() ? null
  : findBestVersionToshow(versions.get(), lastSeenVersionIdState.get()))

let curPatchnote = Computed(@()
  chosenPatchnote.get() ?? unseenPatchnote.get() ?? versions.get()?[0])

function markSeenVersion(v) {
  if (v == null)
    return
  if (v.id > lastSeenVersionIdState.get())
    settings.mutate(@(value) value[SAVE_ID] <- v.id)
}

function markLastSeen() {
  let v = versions.get()?[0]
  markSeenVersion(v)
}

let updateVersion = @() markSeenVersion(curPatchnote.get())

let patchnotesCache = persist("patchnotesCache", @() {})

function setPatchnoteResult(result){
  chosenPatchnoteContent.set(result?.content ?? [])
  chosenPatchnoteTitle.set(result?.title ?? "")
  log("show patchnote:",result?.content)
  chosenPatchnoteLoaded.set(true)
  updateVersion()
}

async function requestPatchnote(v) {
  if (v.id in patchnotesCache) {
    setPatchnoteResult(patchnotesCache[v.id])
    return
  }

  chosenPatchnoteLoaded.set(false)
  let url = changelogPatchnoteUrl.subst({
    language = getLanguageId()
    platform = getPlatformId()
    id = v.id
  })

  let response = await httpFetch({ method = "GET", url })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code)
    send_counter("changelog_receive_errors", 1, { http_code, stage = "get_patchnote" })

  local result
  try {
    result = parse_json(body?.as_string())?.result
  } catch(_e) {
  }

  if (result == null) {
    logError("changelog_parse_errors", { stage = "get_patchnote" })
    send_counter("changelog_parse_errors", 1, { stage = "get_patchnote" })
    return
  }

  log("changelog_success_patchnote")
  setPatchnoteResult(result)
  if (result?.id)
    patchnotesCache[result.id] <- result
}

let curPatchnoteIdx = Computed( @() versions.get().indexof(curPatchnote.get()) ?? 0)

let haveUnseenVersions = Computed(@() unseenPatchnote.get() != null)

function selectPatchnote(v) {
  chosenPatchnote.set(v)
  requestPatchnote(v)
}

let mkChangePatchNote = @(delta=1) function() {
  if (versions.get().len() == 0)
    return
  let nextIdx = clamp(curPatchnoteIdx.get()-delta, 0, versions.get().len()-1)
  let patchnote = versions.get()[nextIdx]
  selectPatchnote(patchnote)
}

let nextPatchNote = mkChangePatchNote()
let prevPatchNote = mkChangePatchNote(-1)

patchnotesReceived.subscribe(function(v){
  if (isNewbie.get()) {
    markLastSeen()
    return
  }
  if (!v || !haveUnseenVersions.get() || curPatchnote.get() == null)
    return

  selectPatchnote(curPatchnote.get())
})

console_register_command(function() {
  if (SAVE_ID in settings.get())
    settings.mutate(@(v) v.$rawdelete(SAVE_ID))
}, "changelog.reset")

console_register_command(requestPatchnotes, "changelog.requestVersions")


let patchnote = nestWatched("patchnote", {
  cachedUpdatedVersion = -1
  timeShown = -1
  requestMadeTime = -1
})
let setViewedTs = @() patchnote.mutate(@(val) val.timeShown = val.requestMadeTime)

const MIN_SEC_BETWEEN_REQUESTS = 10 
let checkVersionAndReqPatchnotes = throttle(function(...) {
  if (!isInBattleState.get()
      && maxVersionInt.get() >= 0
      && maxVersionInt.get() > patchnote.get().cachedUpdatedVersion) {
    requestPatchnotes()
    patchnote.mutate(function(v) {
      v.cachedUpdatedVersion = maxVersionInt.get()
      v.requestMadeTime = get_time_msec()
    })
  }
}, MIN_SEC_BETWEEN_REQUESTS, {leading=true, trailing=false})

gui_scene.setInterval(301, checkVersionAndReqPatchnotes) 
subscribeAndInit(checkVersionAndReqPatchnotes, isInBattleState) 

let needShowPatchnote = Computed(@() patchnotesReceived.get()
  && haveUnseenVersions.get()
  && (unlockProgress.get()?["not_a_new_player_unlock"].isCompleted ?? false)
  && patchnote.get().timeShown != patchnote.get().requestMadeTime
)

return {
  extNewsUrl
  changelogDisabled
  curPatchnote
  versions
  patchnotesReceived
  haveUnseenVersions
  curPatchnoteIdx
  nextPatchNote
  prevPatchNote
  updateVersion
  chosenPatchnote
  chosenPatchnoteContent
  chosenPatchnoteTitle
  chosenPatchnoteLoaded
  requestPatchnotes
  maxVersionInt
  markLastSeen
  selectPatchnote
  needShowPatchnote
  setViewedTs
}