import "%dngscripts/platform.nut" as platform
import "steam" as steam
import "regexp2" as regexp2
import "wegame" as wegame
from "dagor.shell" import shell_execute
from "string" import startswith, strip
from "eventbus" import eventbus_subscribe_onehit
from "settings" import get_setting_by_blk_path
from "%ui/components/browserWidget.nut" import showBrowser
from "%ui/networkedUrls.nut" import getStoreUrl, getReplayPortalUrl, getEventUrl, getPremiumUrl, getBattlePassUrl, getSquadCashUrl, getPromoUrl
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf
from "types" import String

let { get_authenticated_url_sso = null, YU2_OK } = require("auth")
let { get_kongzhong_authenticated_url = null } = require_optional("auth.kongzhong")
let logOU = with_prefix("[OPEN_URL] ")
let circuitConf = get_circuit_conf()

let openLinksInEmbeddedBrowser = get_setting_by_blk_path("openLinksInEmbeddedBrowser") ?? false
let useKongZhongOpenUrl = get_setting_by_blk_path("useKongZhongOpenUrl") ?? false

let requestQueue = {}
local requestAuth = null
enum AuthenticationMode {
  NOT_AUTHENTICATED = 0
  AUTHENTICATED = 1
  WEGAME_AUTH = 2
}

function open_url(url) {
  if (!(url instanceof String) || (!startswith(url, "http://") && !startswith(url, "https://")))
    return false
  if (platform.is_sony)
    require("sony.www").open(url, "" , {})
  else if (platform.is_gdk)
    require("gdk.app").launch_browser(url)
  else if (platform.is_pc) {
    if (openLinksInEmbeddedBrowser)
      showBrowser(url)
    else
      shell_execute({file=url, force_sync=false}) 
  }
  else if (platform.is_android)
    shell_execute({file=url, cmd="action"})
  else
    log_for_user("Open url not implemented on this platform")
  return true
}

const URL_ANY_ENDING = @"(\/.*$|\/$|$)"
let AUTH_TOKEN_HOST = circuitConf?.getShortTokenUrl
  ?? "https://login.gaijin.net/sso/getShortToken"

let addEnding = @(url) $"{url}{URL_ANY_ENDING}"

let localMarketUrlRegExp = circuitConf?.marketUrlRegExp ?? @"^https?:\/\/store\.gaijin\.net"
let localSupportUrlRegExp = circuitConf?.supportUrlRegExp ?? @"^https?:\/\/support\.gaijin\.net"
let localForumUrlRegExp = circuitConf?.forumUrlRegExp ?? @"^https?:\/\/forum\.enlisted\.net"
let localBugreportUrlRegExp = circuitConf?.bgreportUrlRegExp ?? @"^https?:\/\/community\.gaijin\.net\/issues"
let localReplaystUrlRegExp = circuitConf?.replaystUrlRegExp ?? @"^https:\/\/enlisted\.net\/replays"
let localProfileUrlRegExp = circuitConf?.profileUrlRegExp ?? @"^https?:\/\/login\.gaijin\.net"

let urlTypes = [
  {
    typeName = "marketplace"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(localMarketUrlRegExp)),
      regexp2(addEnding(@"^https?:\/\/store\.gaijin\.net")),
      regexp2(addEnding(@"^https?:\/\/inventory-test-01\.gaijin\.lan")),
    ]
  },
  {
    typeName = "steam_market"
    autologin = false
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/store\.steampowered\.com"))
    ]
  },
  {
    typeName = "gaijin_support"
    autologin = true
    ssoService = "zendesk"
    urlRegexpList = [
      regexp2(addEnding(localSupportUrlRegExp))
    ]
  },
  {
    typeName = "enlisted_forum"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(localForumUrlRegExp))
    ]
  },
  {
    typeName = "bugreport"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(localBugreportUrlRegExp))
    ]
  },
  {
    typeName = "gss"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/gss\.gaijin\.net"))
    ]
  },
  {
    typeName = "replays"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(localReplaystUrlRegExp))
    ]
  },
  {
    typeName = "kongzhong"
    autologin = true
    urlRegexpList = [
      regexp2(addEnding(@"^https?:\/\/.*kongzhong\.com")),
      regexp2(addEnding(@"^https?:\/\/.*zhanhuo\.com"))
    ]
  },
  {
    typeName = "profile"
    autologin = true
    ssoService = "any"
    urlRegexpList = [
      regexp2(addEnding(localProfileUrlRegExp))
    ]
  },
  {
    typeName = "match any url"
    autologin = false
    urlRegexpList = null
  }
]

function getUrlTypeByUrl(url) {
  foreach (urlType in urlTypes) {
    if (!urlType.urlRegexpList)
      return urlType

    foreach (r in urlType.urlRegexpList)
      if (r.match(url))
        return urlType
  }

  return null
}


function isWegameLoginRequiredUrl(url) {
  if (!wegame.is_running())
    return false

  return url == getStoreUrl() || url == getEventUrl() || url == getPremiumUrl()
    || url == getBattlePassUrl() || url == getSquadCashUrl() || url == getReplayPortalUrl()
    || url == getPromoUrl()
}


function processQueue() {
  if (requestQueue.len() == 0) {
    logOU("Queue is empty")
    return
  }
  if (requestAuth != null) {
    logOU($"Processing {requestAuth}")
    return
  }

  let self = callee()
  requestAuth = requestQueue.findindex(@(_) true)
  let { baseUrl, goToUrl, authenticationType, ssoService = null } = requestQueue[requestAuth] 
  eventbus_subscribe_onehit(requestAuth,
    function(result)  {
      requestQueue.$rawdelete(requestAuth)
      requestAuth = null
      if (result.status == YU2_OK) {
        
        logOU($"Authenticated Url = {result.url}")
        goToUrl(result.url)
      }
      else {
        logOU($"Error: failed to get_authenticated_url, status = {result.status}")
        goToUrl(baseUrl) 
      }
      self()
    }
  )

  if (!useKongZhongOpenUrl) {
    if (ssoService == null || get_authenticated_url_sso == null) {
      logOU($"Error: failed to get_authenticated_url_sso, service is undefined")
      goToUrl(baseUrl) 
      requestQueue.$rawdelete(requestAuth)
      requestAuth = null
      self()
    }
    else
      get_authenticated_url_sso(baseUrl, AUTH_TOKEN_HOST, ssoService, requestAuth)
  }
  else if ((wegame.is_running() && AuthenticationMode.WEGAME_AUTH == authenticationType)
    || isWegameLoginRequiredUrl(baseUrl))
      wegame.get_authenticated_url(baseUrl, requestAuth)
  else
    get_kongzhong_authenticated_url?(baseUrl, requestAuth)
}


function openUrl(baseUrl, authenticationType = AuthenticationMode.NOT_AUTHENTICATED,
  shouldExternalBrowser = false, goToUrl = null
) {
  let url = baseUrl ? strip(baseUrl) : ""
  if (url == "") {
    logOU("Error: tried to openUrl an empty url")
    return
  }

  let urlType = getUrlTypeByUrl(url)
  logOU($"Open type<{urlType.typeName}> url: {url}")
  logOU($"Base Url = {baseUrl}")

  if (goToUrl == null)
    goToUrl = (!shouldExternalBrowser && steam.is_overlay_enabled()) ? steam.open_url : open_url

  if (urlType.typeName == "steam_market" && !steam.is_overlay_enabled())
    logOU("Warning: trying to open steam url without steam overlay")

  if (AuthenticationMode.AUTHENTICATED == authenticationType || !urlType.autologin) {
    logOU($"Direct Url = {url}")
    goToUrl(url)
    return
  }

  let cbEvent = $"openUrl.{url}"
  if (cbEvent in requestQueue) {
    logOU("Already queued")
    return
  }

  let queuedData = urlType.__merge({ baseUrl, goToUrl, authenticationType })
  logOU("Queued data:", queuedData)
  requestQueue[cbEvent] <- queuedData
  processQueue()
}

console_register_command(open_url, "app.open_url")

return {
  openUrl
  AuthenticationMode
}
