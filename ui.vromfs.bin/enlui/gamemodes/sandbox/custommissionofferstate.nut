import "%ui/control/gui_buttons.nut" as JB
import "%ui/gameModes/sandbox/customMissionWnd.nut" as openCustomMissionWnd
import "%ui/components/colorize.nut" as colorize
import "%ui/helpers/isChineseVersion.nut" as isChineseVersion
from "%enlSqGlob/game_mods_constant.nut" import MOD_BY_VERSION_URL, MOD_LATEST_URL, MOD_FEATURED_URL
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "json" import parse_json
from "%ui/components/msgbox.nut" import showMsgboxWithCloseButton
from "%ui/components/defcomps.nut" import noteTextArea, txt
from "%ui/gameModes/sandbox/customMissionState.nut" import requestModManifest
from "%ui/gameModes/createEventRoomState.nut" import isEditEventRoomOpened
from "%ui/gameModes/eventModesState.nut" import isEventModesOpened, curTab
from "dagor.debug" import logerr
from "%ui/style/designConst.nut" import titleTxtColor, accentTitleTxtColor
from "%ui/components/openUrl.nut" import openUrl
from "%dngscripts/platform.nut" import is_pc
from "%ui/ui_library.nut" import *

let featuredMods = Watched([])
let featuredModsRoomsList = Watched([])
let urlData = {
  cdn_uris=true
  clean_description=true
  no_file=true
  only_preview=true
  charset="UTF-8"
}
let isFeaturedAvailable = is_pc && !isChineseVersion
let isFeaturedRequestNeeded = keepref(Computed(@() isFeaturedAvailable && isEventModesOpened.get()
  && featuredMods.get().len() == 0))

const FEATURED_MODS_TAB_ID = "featured_mod"

function getFeaturedModInfo(mod) {
  let { id = "" } = mod
  local res = null
  try {
    res = {
      id
      description = mod.description
      imageToShow = mod.preview.split("?")[0]
      title = mod.title
      authorsNick = mod.author.nick
      version = mod.version
      modUrl = MOD_LATEST_URL.subst(id)
    }
  }
  catch(e) {
    logerr($"incorrect featured mod /*{id}*/ with error {e}")
  }
  return res
}


async function requestMods(data = urlData) {
  let response = await httpFetch({
    method = "POST"
    url = MOD_FEATURED_URL
    data = data.__merge({content="gamemod"})
  })

  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    logerr($"unable to request featured mods: status = {status}, http_code = {http_code}")
    return
  }

  try {
    let mods = (parse_json(body?.as_string())?.data.list ?? [])
      .map(getFeaturedModInfo)
    featuredMods.set(mods)
  }
  catch (_e) {
    logerr("unable to parse featured mods request")
  }
}


if (isFeaturedRequestNeeded.get())
  requestMods()
isFeaturedRequestNeeded.subscribe(@(v) v ? requestMods() : null)


function offersModMsgbox(mod) {
  let { description, title, authorsNick, id, version, modUrl } = mod
  let  buttons = Computed(function(){
    let res = [
      {
        text = loc("mods/modOnSite")
        action = @() openUrl(modUrl)
      }
      {
        text = loc("downloadMission")
        action = function() {
          isEditEventRoomOpened.set(true)
          requestModManifest(MOD_BY_VERSION_URL.subst(id, version))
          openCustomMissionWnd()
        }
      }
      { text = loc("Cancel"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
    ]
    if (curTab.get() != FEATURED_MODS_TAB_ID && featuredModsRoomsList.get().len() > 0)
      res.insert(0, {
        text = loc("mods/featuredModsList")
        action = @() curTab.set(FEATURED_MODS_TAB_ID)
      })
    return res
  })

  showMsgboxWithCloseButton({
    uid = title
    children = {
      size = FLEX_H
      flow = FLOW_VERTICAL
      maxWidth = min(sw(80), hdpx(1000))
      gap = fsh(2)
      valign = ALIGN_CENTER
      children = [
        txt({ text = loc("featured_mod")}).__update(fontHeading2, { color = accentTitleTxtColor})
        noteTextArea({ text = title }).__update(fontHeading2, { color = titleTxtColor })
        noteTextArea({ text = loc("mods/featuring") }).__update(fontBody)
        noteTextArea({ text = loc("mods/authorModDescription", { description = colorize(titleTxtColor, description) }) })
          .__update(fontBody, { color = accentTitleTxtColor })
        noteTextArea({ text = loc("mods/author", { author = colorize(titleTxtColor, authorsNick) }) })
          .__update(fontBody, { color = accentTitleTxtColor })
      ]
    }
    buttons
  })
}

function updateUrlData(params = null) {
  if (params == null)
    requestMods(urlData)
  let updatedUrlData = $"{urlData}&{params}"
  requestMods(updatedUrlData)
}

console_register_command(@() updateUrlData(), "featuredMods.current")
console_register_command(@() updateUrlData("with_done=true"), "featuredMods.past")
console_register_command(@() updateUrlData("with_pending=true"), "featuredMods.future")


return {
  featuredMods
  offersModMsgbox
  FEATURED_MODS_TAB_ID
  featuredModsRoomsList
  isFeaturedAvailable
}