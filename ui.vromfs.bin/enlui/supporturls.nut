from "%enlSqGlob/appInfo.nut" import circuit, version
from "settings" import get_setting_by_blk_path
from "%dngscripts/platform.nut" import platformId
from "%ui/httpPkg.nut" import getLanguageId
from "app" import get_circuit_conf

let circuitConf = get_circuit_conf()

let gaijinSupportUrl = circuitConf?.supportURL
  ?? get_setting_by_blk_path("gaijinSupportUrl")
  ?? "https://support.gaijin.net/"

let enlistedForumUrl = circuitConf?.forumUrl
  ?? get_setting_by_blk_path("enlistedForumUrl")
  ?? "https://forum.enlisted.net/"

let feedbackUrl = circuitConf?.feedbackUrl
  ?? get_setting_by_blk_path("feedbackUrl")
  ?? ""

local bugReportUrl = circuitConf?.communityURL
  ?? get_setting_by_blk_path("communityBugTrackerURL")
if (bugReportUrl != null)
  bugReportUrl = $"{bugReportUrl}?f.platform={platformId}&f.version={version.get()}&f.circuit={circuit.get()}"
else
  bugReportUrl = ""

let legalsUrl = circuitConf?.eulaURL
  ?? $"https://legal.gaijin.net/{getLanguageId()}"

return {
  gaijinSupportUrl
  enlistedForumUrl
  feedbackUrl
  bugReportUrl
  legalsUrl
}
