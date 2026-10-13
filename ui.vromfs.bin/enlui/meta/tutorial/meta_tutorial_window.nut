import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/style/cursors.nut" as cursors
import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontIconButton.nut" as fontIconButton
import "%ui/components/spinner.nut" as spinner
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2, fontSub
from "%ui/components/formatText.nut" import mkFormatText, defStyle
from "%ui/components/openUrl.nut" import openUrl, AuthenticationMode
from "%ui/meta/tutorial/meta_tutorial_utils.nut" import processHyphenations
from "math" import round
from "%ui/meta/tutorial/meta_tutorial_state.nut" import selectedPageContent, requestTutor, selectedTutor, requestVersions, isPageContentLoaded
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/components/textFormatters.nut" import transcodeTable, textArea, load_movie, textAreaContainer
from "%ui/style/designConst.nut" import transpBgColor, fullTransparentBgColor, smallPadding, transpPanelBgColor, selectedPanelBgColor, bigGap, hoverSlotBgColor
  , bigPadding, defTxtColor, darkPanelBgColor, midPadding, largePadding
from "%ui/ui_library.nut" import *

let { metaTutorialConfig, metaTutorialConfigById } = require("%ui/meta/tutorial/meta_tutorial_config.nut")

const metaTutorialWndUID = "meta_tutorial_wnd"
const CONTENT_WIDTH = 0.56
const CONTENT_HEIGHT = 0.315
const contentWidth = sw(80) - sw(20) - hdpx(10) * 3 - hdpx(12) * 0 - hdpx(30)

let scrollHandler = ScrollHandler()
let waitingSpinner = spinner()
let videoVisibility = Watched({})
let videoBounds = {}

local formattedContent = null
let formattedContentWatch = keepref(Watched(0))

let closeBtn = fontIconButton("close", {
  skipDirPadNav = true
  onClick = @() removeModalWindow(metaTutorialWndUID)
  hplace = ALIGN_RIGHT
  hotkeys = [[$"^{JB.B} | Esc", { description = loc("Close") }]]
})

let viewHeight = round(sh(90) - calc_comp_size(closeBtn)[1] - bigGap * 3)

let sound = {
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
}

let headersStyle = {
  h1 = { color = defStyle.h1Color, margin = [midPadding, bigPadding, midPadding, largePadding] }.__update(fontSub),
  h2 = { color = defStyle.h2Color, margin = [midPadding, bigPadding, midPadding, largePadding] }.__update(fontSub),
}

let mkHeader = @(config) watchElemState(@(sf) {
  behavior = Behaviors.Button
  rendObj = ROBJ_SOLID
  size = FLEX_H
  color = sf & S_HOVER ? hoverSlotBgColor : fullTransparentBgColor
  onClick = function() {
    scrollHandler.scrollToY(1000000)
    scrollHandler.scrollToChildren(@(desc) ("v" in desc) && (desc.v == config.v), 3, false, true)
  }
  valign = ALIGN_CENTER
  sound
  children = {
    rendObj = ROBJ_TEXTAREA
    size = FLEX_H
    behavior = Behaviors.TextArea
    text = config.v
  }.__update(headersStyle?[config.t] ?? {})
})

let mkHeaders = @(contentWatch) function() {
  let watch = contentWatch
  let { content = [] } = contentWatch.get()
  let headers = content.filter(@(chunk) ["h1", "h2"].contains(chunk?.t))
  if (headers.len() == 0)
    return { watch }

  return {
    watch
    flow = FLOW_VERTICAL
    size = FLEX_H
    children = headers.map(mkHeader)
  }
}

function mkSection(config) {
  let isCurrent = Computed(@() selectedTutor.get() == config.id)
  let selector = watchElemState(@(sf) {
    watch = isCurrent
    behavior = Behaviors.Button
    rendObj = ROBJ_SOLID
    size = FLEX_H
    color = sf & S_HOVER ? hoverSlotBgColor
      : isCurrent.get() ? selectedPanelBgColor
      : fullTransparentBgColor
    padding = [smallPadding, midPadding]
    onClick = isCurrent.get() ? null : function() {
      selectedTutor.set(config.id)
      scrollHandler.scrollToY(0)
    }
    valign = ALIGN_CENTER
    sound
    children = {
      rendObj = ROBJ_TEXT
      text = loc(config.locId)
    }.__update(fontBody)
  })

  return @() {
    watch = isCurrent
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      selector
      isCurrent.get() ? mkHeaders(selectedPageContent) : null
    ]
  }
}

function changeTab(delta) {
  let selected = selectedTutor.get()
  let currentIndex = metaTutorialConfig.findindex(@(v) v.id == selected) ?? 0
  let newIndex = clamp(currentIndex + delta, 0, metaTutorialConfig.len() - 1)
  if (newIndex != currentIndex) {
    selectedTutor.set(metaTutorialConfig[newIndex].id)
    sound_play(sound.click)
  }
}

let mkPagesList = @() {
  size = const [sw(20), FLEX]
  rendObj = ROBJ_SOLID
  color = transpBgColor
  children = scrollbar.makeVertScroll({
    flow = FLOW_VERTICAL
    size = FLEX_H
    padding = smallPadding
    gap = smallPadding
    children = metaTutorialConfig.map(mkSection)
    hotkeys = [
      ["^J:LB | L.Shift Tab | R.Shift Tab", { action = @() changeTab(-1),
        description = loc("meta/tutorial/previous_tab")} ],
      ["^J:RB | Tab", {action = @() changeTab(1),
        description = loc("meta/tutorial/next_tab")} ]
    ]
  })
}

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
  halign = ALIGN_CENTER
}.__update(fontHeading2)

let loading = freeze({
  flow  = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(20)
  valign = ALIGN_CENTER size = const [FLEX, fsh(20)]
  padding = fsh(2)
  children = [
    mkText(loc("Loading"))
    waitingSpinner
  ]
})

let noTextFormatFunc = @(object, _style = defStyle) object

function internalUrl(data, fmtFunc = noTextFormatFunc, style = defStyle){
  let { link = null } = data
  let transcodedData = transcodeTable(data)
  if (link == null)
    return textArea(transcodedData, fmtFunc, style)
  let stateFlags = Watched(0)
  let locId = metaTutorialConfigById?[link].locId
  return function() {
    let color = stateFlags.get() & S_HOVER ? style.urlHoverColor : style.urlColor
    return {
      watch = stateFlags
      rendObj = ROBJ_TEXT
      behavior = Behaviors.Button
      text = locId ? loc(locId)
        : data?.v
        ?? loc("see more...")
      color = color
      onElemState = @(sf) stateFlags.set(sf)
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
        active = "ui/enlist/button_action"
      }
      children = {
        rendObj = ROBJ_FRAME
        borderWidth = const [0, 0, hdpx(1), 0]
        color
        size = FLEX
      }
      onClick = function() {
        if (locId)
          selectedTutor.set(link)
        else
          openUrl(link, AuthenticationMode.WEGAME_AUTH)
      }
    }.__update(transcodedData)
  }
}

let missedTutorText = mkText(loc("meta/tutorial/missed"))

function video(obj, _fmtFunc, _style=defStyle) {
  let movieStatus = Watched({
    name = null
    error = null
  })
  load_movie(obj.v, movieStatus)
  videoVisibility.mutate(@(val) val[obj.v] <- false)
  let isVideoVisible = Computed(@() videoVisibility.get()?[obj.v] ?? false)

  return {
    size = [sw((obj?.width ?? 100) * CONTENT_WIDTH), sw((obj?.height ?? 100) * CONTENT_HEIGHT)]
    cursor = cursors.normal
    hplace = ALIGN_CENTER
    children = function() {
      let status = movieStatus.get()
      return {
        watch = [movieStatus, isVideoVisible]
        size = FLEX
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          status.name && isVideoVisible.get()
            ? {
                size = FLEX
                rendObj = ROBJ_MOVIE
                movie = status.name
                behavior = Behaviors.Movie
                keepAspect = KEEP_ASPECT_FIT
                loop = true
              }
            : {
                rendObj = ROBJ_SOLID
                size = FLEX
                color = darkPanelBgColor
              }
          status.error
            ? {
                rendObj = ROBJ_TEXT
                text = status.error
              }.__update(fontSub)
            : status.name ? null
            : loading
        ]
      }
    }
  }.__merge(obj)
}

function image(obj, _fmtFunc=noTextFormatFunc, style=defStyle) {
  let { rSize = 100 } = obj?.customData ?? {}
  let width = obj.width.tofloat()
  let aspectRatio = obj.height.tofloat() / width
  let w = rSize * CONTENT_WIDTH
  let h = w * aspectRatio
  return {
    rendObj = ROBJ_IMAGE
    image = Picture(obj.v)
    size = [sw(w), sw(h)]
    keepAspect = true
    padding = style.padding
    children = {
      rendObj = ROBJ_TEXT
      text = obj?.caption
      vplace = ALIGN_BOTTOM
      fontFxColor = Color(0,0,0,150)
      fontFxFactor = min(64, hdpx(64))
      fontFx = FFT_GLOW
    }
    hplace = ALIGN_CENTER
  }.__update(obj)
}

let h1 = @(text, fmtFunc=noTextFormatFunc, style=defStyle) textAreaContainer({ padding = const [hdpx(15), 0, hdpx(25), 0] }, text.__merge(style.h1FontStyle, {color=style.h1Color}), fmtFunc, style)
let h2 = @(text, fmtFunc=noTextFormatFunc, style=defStyle) textAreaContainer({ padding = const [hdpx(10), 0, hdpx(15), 0] }, text.__merge(style.h2FontStyle, {color=style.h2Color}), fmtFunc, style)
let h3 = @(text, fmtFunc=noTextFormatFunc, style=defStyle) textAreaContainer({ padding = const [hdpx(5), 0, hdpx(10), 0] }, text.__merge(style.h3FontStyle, {color=style.h3Color}), fmtFunc, style)

let formatText = mkFormatText(defStyle, { link = internalUrl, video, h1, h2, h3, image })

scrollHandler.subscribe(function(_) {
  let { id = null } = selectedPageContent.get()
  if (!id)
    return

  let posy = scrollHandler?.elem.getScrollOffsY() ?? 0
  let viewTop = posy
  let viewBottom = posy + viewHeight - 1
  const offset = sh(20)
  let { videos = null } = videoBounds?[id]
  if (videos) {
    let changes = {}
    foreach (k, v in videos) {
      if (videoVisibility.get()?[k]) {
        if (v.top > viewBottom || v.bottom < viewTop)
          changes[k] <- false
      }
      else {
        let isVisible = !(v.top > viewBottom - offset || v.bottom < viewTop + offset)
        if (videoVisibility.get()?[k] != isVisible)
          changes[k] <- isVisible
      }
    }

    if (changes.len() > 0)
      videoVisibility.mutate(@(val) val.__update(changes))
  }
})

function calculateVideoBounds(id, rev, content) {
  let videos = {}
  videoBounds[id] <- {
    videos
    rev
  }

  local y = 0
  let tmpList = {
    flow = FLOW_VERTICAL
    size = const [contentWidth, SIZE_TO_CONTENT]
    gap = defStyle.lineGaps
  }
  foreach (i, obj in content) {
    tmpList.children <- obj
    let height = calc_comp_size(tmpList)[1] + (i > 0 ? defStyle.lineGaps : 0)
    if (obj?.t == "video") {
      videos[obj.v] <- {
        top = y
        bottom = y + height - 1
      }
    }

    y += height
  }
}

function pageContent() {
  let contentArea = formattedContent
    ? formattedContent.__update({
        size = FLEX_H
        padding = bigPadding
      })
    : {
        size = FLEX_H
        padding = bigPadding
        children = loading
      }

  return {
    watch = formattedContentWatch
    size = FLEX
    rendObj = ROBJ_SOLID
    color = transpBgColor
    children = scrollbar.makeVertScroll(contentArea, { scrollHandler })
  }
}

isPageContentLoaded.subscribe(function(v) {
  if (!v) {
    formattedContent = null
    formattedContentWatch.modify(@(val) val + 1)
    return
  }

  let { content = null, rev = 0, id = null } = selectedPageContent.get()
  local text = content ?? missedTutorText

  processHyphenations(text)

  let formatted = formatText(text)
  let cachedRev = videoBounds?[id].rev ?? -1
  if (id && cachedRev < rev)
    calculateVideoBounds(id, rev, formatted?.children)

  formattedContent = formatted
  formattedContentWatch.modify(@(val) val + 1)
})

let mkContent = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = const [sw(80), sh(90)]
  fillColor = transpPanelBgColor
  flow = FLOW_VERTICAL
  padding = bigGap
  gap = bigGap
  children = [
    closeBtn
    {
      flow = FLOW_HORIZONTAL
      size = FLEX
      gap = bigGap
      children = [
        mkPagesList()
        pageContent
      ]
    }
  ]
}

selectedTutor.subscribe(function(v) {
  requestTutor(v)
})

function showMetaTutorialWindow(pageId) {
  requestVersions()
  selectedTutor.set(pageId)

  addModalWindow({
    key = metaTutorialWndUID
    rendObj = ROBJ_SOLID
    color = Color(30,30,30,250)
    size = FLEX
    onClick = @() null
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    cursor = cursors.normal
    stopMouse = true
    stopHotkeys = true
    children = mkContent()
  })
}

return {
  showMetaTutorialWindow
}
