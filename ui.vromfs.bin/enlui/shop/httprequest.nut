import "%enlSqGlob/userInfo.nut" as userInfo
from "json" import parse_json
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "%ui/ui_library.nut" import *

let hasLog = {}
function logByUrlOnce(url, text) {
  if (url in hasLog)
    return
  hasLog[url] <- true
  log(text)
}

async function requestData(url, params) {
  let response = await httpFetch({ method = "POST", url, data = params })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code)
    return null

  let str = body?.as_string()
  if (str == null)
    return null

  if (str.len() > 6 && str.slice(0, 6) == "<html>") { 
    logByUrlOnce(url, $"ShopState: Request result is html page instead of data {url}\n{str}")
    return null
  }

  local data
  try {
    data = parse_json(str)
  }
  catch(_e) {
    logByUrlOnce(url, $"ShopState: Request result error {url}")
    return null
  }

  if (data?.status != "OK")
    return null
  return data
}

function createGuidsRequestParams(guids) {
  local res = guids.reduce(@(acc, guid) $"{acc}guids[]={guid}&", "")
  res = $"{res}jwt={userInfo.get()?.token ?? ""}&special=1"
  return res
}

return {
  requestData
  createGuidsRequestParams
}
