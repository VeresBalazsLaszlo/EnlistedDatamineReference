import "%ui/control/gui_buttons.nut" as JB
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/unlocks/isNewbie.nut" as isNewbie
import "%ui/components/colorize.nut" as colorize
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/spinner.nut" as spinner
import "%ui/offers/mkSquadBuyPromo.nut" as mkSquadBuyPromo
from "%ui/style/fontsStyle.nut" import fontHeading1, fontBody
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/components/textButton.nut" import Regular, Accented
from "%ui/style/designConst.nut" import strokeStyle, midPadding, hoverBgColor, accentTitleTxtColor, titleTxtColor, sidePadding
from "%ui/components/formatText.nut" import mkFormatText
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/offers/offersState.nut" import isRequestInProgress, eventsData, eventsKeysSorted, isEventUnseen, markEventSeen
from "%ui/unlocks/tasksWidgetUi.nut" import eventTasksUi
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, casualFlagStyle
from "%ui/shop/armyShopState.nut" import curArmyShopItems
from "%ui/gameModes/eventModesState.nut" import openEventModes, isEventPlayable
from "%ui/components/wndManager.nut" import registerWnd, Wnd, WndEvents
from "%ui/components/wndPermissionFlags.nut" import canShowWindows, autoClose
from "%ui/ui_library.nut" import *

const PROMO_WIDTH = fsh(45)
const PROMO_GAP = fsh(2)
const DESC_WIDTH = fsh(120) - PROMO_WIDTH
const DESC_PADDING = hdpx(20)
let IMAGE_WIDTH = DESC_WIDTH - DESC_PADDING * 2
let waitingSpinner = spinner()

let header_txt = { font = Fonts.trebuchet, fontSize = fsh(2.78) }
let text_txt = { font = Fonts.trebuchet, fontSize = fsh(1.76) }

let formatText = mkFormatText({
  defTextColor = Color(200,200,200)
  h1FontStyle = header_txt
  h2FontStyle = header_txt
  h3FontStyle = header_txt
  textFontStyle = text_txt
  noteFontStyle = text_txt
  h1Color = titleTxtColor
  h2Color = titleTxtColor
  h3Color = titleTxtColor
  emphasisColor = titleTxtColor
  padding = fsh(1)
}, {
  image = function(obj, _, style) {
    local { width = IMAGE_WIDTH, height = null } = obj
    if (width > IMAGE_WIDTH) {
      height = height != null ? IMAGE_WIDTH * height / width : SIZE_TO_CONTENT
      width = IMAGE_WIDTH
    } else
      height = height ?? SIZE_TO_CONTENT
    return {
      size = FLEX_H
      halign = ALIGN_CENTER
      clipChildren = true
      children = [
        obj.__merge({
          rendObj = ROBJ_IMAGE
          size = [width, height]
          image = Picture(obj.v)
          keepAspect = KEEP_ASPECT_FIT
          imageAffectsLayout = true
        })
        !obj?.caption ? null : {
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          behavior = Behaviors.TextArea
          padding = style.padding
          halign = ALIGN_CENTER
          vplace = ALIGN_BOTTOM
          margin = const [fsh(1), fsh(3)]
          text = obj?.caption
        }.__update(text_txt, strokeStyle)
      ]
    }
  }
})

let scrollHandler = ScrollHandler()

let curEventId = mkWatched(persist, "curEventId", null)
let curEventData = Computed(@() eventsData.get()?[curEventId.get()])


let closeBtnSmall = closeBtnBase({
  padding = fsh(1)
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  onClick = @() curEventId.set(null)
}).__update({ margin = fsh(1) })

let closeBtn = Regular(loc("mainmenu/btnClose"), @() curEventId.set(null),
  { hotkeys = [[$"^{JB.B}"]] })

function mkHeaderTimeLeft(time) {
  let timeLeft = Computed(@() secondsToHoursLoc(max(0, time - serverTime.get())))
  return @() {
    watch = timeLeft
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = loc("offers/timeLeft", {
      time = colorize(accentTitleTxtColor, timeLeft.get())
    })
    vplace = ALIGN_BOTTOM
    margin = midPadding
    fontFx = FFT_BLUR
    fontFxColor = 0x7F000000
  }.__update(fontBody)
}

function offersWindowTitle() {
  let { title = "", heading = null, end = 0 } = curEventData.get()
  let headingBackImage = !heading ? null : {
    size = FLEX
    rendObj = ROBJ_IMAGE
    image = Picture(heading)
    keepAspect = KEEP_ASPECT_FILL
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_BOTTOM
  }
  return {
    watch = curEventData
    size = const [FLEX, hdpx(160)]
    valign = ALIGN_CENTER
    children = [
      headingBackImage
      mkHeaderTimeLeft(end)
      mkHeaderFlag({
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(title)
        padding = const [fsh(2), fsh(3)]
        color = titleTxtColor
      }.__update(fontHeading1),
      casualFlagStyle)
    ]
  }
}

let descriptionLoading = freeze({
  size = FLEX
  flow  = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = midPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("Loading")
    }.__update(fontHeading1)
    waitingSpinner
  ]
})

let descriptionCommon = {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXTAREA
    size = const [fsh(60), SIZE_TO_CONTENT]
    behavior = Behaviors.TextArea
    text = loc("offers/commonDescription")
  }.__update(fontBody)
}

function offersWindowDescription() {
  local { description = null } = curEventData.get()
  if (description)
    description = formatText(description)
  return {
    size = FLEX
    watch = [isRequestInProgress, curEventData]
    children = isRequestInProgress.get() ? descriptionLoading
      : description ? makeVertScroll({
          size = FLEX_H
          padding = DESC_PADDING
          children = description
        }, { scrollHandler, styling = thinStyle })
      : descriptionCommon
  }
}

function offersButtons() {
  let children = []
  let { linkedGameplayEvent = null } = curEventData.get()?.tags
  if (isEventPlayable(linkedGameplayEvent)) {
    children.append(Accented(loc("offers/toTheEvent"), function() {
      openEventModes(linkedGameplayEvent)
      curEventId.set(null)
    }, { hotkeys = [["^J:X", { description = { skip = true } }]]
  }))}
  children.append(closeBtn)

  return {
    watch = curEventData
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    gap = sidePadding
    children
  }
}

let curArmyShopSquads = Computed(function() {
  let res = {}
  foreach (item in curArmyShopItems.get())
    foreach (squad in item?.squads ?? [])
      res[squad.id] <- true

  return res
})

let curArmyOfferSquads = Computed(function() {
  let { squads = [] } = curEventData.get()
  if (squads.len() == 0)
    return null

  let availSquads = curArmyShopSquads.get()
  let res = squads.filter(@(id) id in availSquads)
  return res.len() == 0 ? null : res
})

function mkPromoSquads(offerSquads) {
  let children = []
  foreach (squadId in offerSquads)
    children.append(mkSquadBuyPromo(squadId, {
      size = const [PROMO_WIDTH, SIZE_TO_CONTENT]
    }))

  return {
    flow = FLOW_VERTICAL
    gap = PROMO_GAP
    halign = ALIGN_CENTER
    children
  }
}

let offersBlock = {
  rendObj = ROBJ_SOLID
  size = const [DESC_WIDTH, FLEX]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = midPadding
  color = 0xFF050A0F
  children = [
    offersWindowTitle
    offersWindowDescription
    offersButtons
  ]
}

function promoBlock() {
  let offerSquads = curArmyOfferSquads.get()
  let hasOfferSquads = offerSquads != null
  return {
    watch = [curArmyOfferSquads, curEventId]
    size = const [PROMO_WIDTH, FLEX]
    flow = FLOW_VERTICAL
    gap = PROMO_GAP
    valign = ALIGN_CENTER
    children = [
      hasOfferSquads ? mkPromoSquads(offerSquads) : null
      makeVertScroll(eventTasksUi(curEventId.get()), { styling = thinStyle })
    ]
  }
}

let offersWindow = @() {
  size = FLEX
  halign = ALIGN_CENTER
  watch = safeAreaBorders
  padding = safeAreaBorders.get()
  children = [
    {
      rendObj = ROBJ_WORLD_BLUR
      size = FLEX_V
      flow = FLOW_HORIZONTAL
      gap = fsh(1.5)
      color = hoverBgColor
      children = [
        offersBlock
        promoBlock
      ]
    }
    closeBtnSmall
  ]
}

function open() {
  sceneWithCameraAdd(offersWindow, "researches")
}

console_register_command(@(id) curEventId.set(id), "ui.offersPromoWindow")

function close() {
  markEventSeen()
  sceneWithCameraRemove(offersWindow)
}

let needSetCurOffer = keepref(Computed(@()
  eventsKeysSorted.get().len() > 0
    && isEventUnseen.get()
    && !isNewbie.get()))

needSetCurOffer.subscribe(function(v) {
  if (v)
    defer(@() curEventId.set(eventsKeysSorted.get()[0]))
})

let needOpenWnd = registerWnd({
  dataWatch = Computed(@() curEventId.get() != null)
  showWatch = canShowWindows
  closeWatch = autoClose
  name = Wnd.EVENT
  handlers = { [WndEvents.SUPPRESS] = markEventSeen }
})
needOpenWnd.subscribe(@(v) v ? open() : close())

return @(id) curEventId.set(id)
