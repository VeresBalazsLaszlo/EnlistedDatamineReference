from "dagor.http" import httpFetch, HTTP_SUCCESS, HTTP_ABORTED, HTTP_FAILED
from "dagor.debug" import logerr
from "%ui/ui_library.nut" import *

let logDM = with_prefix("[DOWNLOAD MANAGER] ")

let HTTP_REQUESTED = persist("HTTP_REQUESTED", @() freeze({}))
let HTTP_READY = persist("HTTP_READY", @() freeze({}))

let downloadCache = persist("downloadCache", @() {})
let downloadStatus = Watched(downloadCache.map(@(_) HTTP_READY))

function setDownloadStatusMul(statuses){
  downloadStatus.modify(@(v) v.__merge(statuses))
}
downloadStatus.whiteListMutatorClosure(setDownloadStatusMul)

function setDownloadStatus(key, status){
  logDM("set status for", key)
  setDownloadStatusMul({[key] = status})
}

let downloadCacheGen = Watched(0)


function setDownloadedFile(key, file){
  logDM("populate cache for", key)
  downloadCache.__update({[key] = file})
  downloadCacheGen.modify(@(v) v + 1)
}


async function httpGetRequest(url, cache_key=null){
  cache_key = cache_key ?? url
  logDM($"HTTP requested for' {cache_key}', url = {url}")

  let response = await httpFetch({ url, method = "GET" })
  let { status = -1, http_code = -1, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    setDownloadStatus(cache_key, HTTP_FAILED)
    logDM("ERROR DOWNLOADING", $"status = {status}, http_code = {http_code}")
    return
  }
  if (body == null) {
    logerr($"incorrect file downloaded, {cache_key}")
    logDM("ERROR DOWNLOADING", "empty file")
    return
  }
  logDM("successfully downloaded file for key", cache_key)
  setDownloadedFile(cache_key, body)
  setDownloadStatus(cache_key, HTTP_READY)
}

function requestCachedFile(url, cache_key=null){
  cache_key = cache_key ?? url
  if (cache_key in downloadCache){
    return HTTP_READY
  }
  if (downloadStatus?[cache_key] == HTTP_REQUESTED)
    return HTTP_REQUESTED
  httpGetRequest(url, cache_key)
  setDownloadStatus(cache_key, HTTP_REQUESTED)
  return HTTP_REQUESTED
}

function requestCachedFiles(urlAndCacheKeys, useCache = true){
  let toRequest = []
  let statuses = {}
  foreach (urlAndKey in urlAndCacheKeys) {
    let url = (typeof urlAndKey == "string") ? urlAndKey : urlAndKey.url
    let cache_key = urlAndKey?.cache_key ?? url

    if (useCache && cache_key in downloadCache){
      if (downloadStatus.get()?[cache_key] != HTTP_READY)
        statuses[cache_key] <- HTTP_READY
    }
    else if (cache_key not in downloadCache && downloadStatus.get()?[cache_key] != HTTP_REQUESTED) {
      toRequest.append({url, cache_key})
      statuses[cache_key] <- HTTP_REQUESTED
      break
    }
  }
  if (toRequest.len()==0)
    return HTTP_READY
  foreach (urlAndKey in toRequest)
    httpGetRequest(urlAndKey.url, urlAndKey.cache_key)
  setDownloadStatusMul(statuses)
  return HTTP_REQUESTED
}

function getDownloadedFile(cache_key){
  logDM("get downloaded file by cache key", cache_key)
  let res = downloadCache?[cache_key]
  if (res==null){
    logDM("no file downloaded! files:", downloadCache.keys())
    logDM("statuses:", downloadStatus.get().keys())
  }
  return res
}

return {
  requestCachedFile = kwarg(requestCachedFile)
  downloadStatus
  getDownloadedFile
  HTTP_READY
  HTTP_FAILED
  HTTP_ABORTED
  requestCachedFiles
}
