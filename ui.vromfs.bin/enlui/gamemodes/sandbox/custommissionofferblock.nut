from "%ui/components/mkDotPaginator.nut" import mkDotPaginator
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import accentTitleTxtColor, activeTxtColor, defBgColor, smallPadding
from "%ui/gameModes/eventModesState.nut" import isEventModesOpened
from "%ui/gameModes/sandbox/customMissionOfferState.nut" import featuredMods, offersModMsgbox
from "%ui/ui_library.nut" import *

const SWITCH_SEC = 8.0

let curWidgetIdx = Watched(0)

let mkOfferImage = @(img) {
  key = $"offer_{img}"
  rendObj = ROBJ_IMAGE
  size = FLEX
  image = Picture(img)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_RIGHT
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.6, play = true }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.6, playFadeOut = true }
  ]
}

let mkInfo = @(addChild) {
  rendObj = ROBJ_SOLID
  size = FLEX_H
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = smallPadding
  vplace = ALIGN_BOTTOM
  color = defBgColor
  children = addChild
}


let featuredModsList = Computed(function() {
  let list = []
  if (isEventModesOpened.get()) {
    featuredMods.get().each(function(mod) {
      let addChild = @(sf) [
        {
          size = FLEX_H
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          text = mod.title
          color = sf & S_HOVER ? accentTitleTxtColor : activeTxtColor
        }
        {
          rendObj = ROBJ_TEXT
          text = loc("mods/author", { author = mod.authorsNick })
          color = sf & S_HOVER ? accentTitleTxtColor : activeTxtColor
        }
      ]
      list.append({
        backImage = mod.imageToShow
        mkContent = @(sf) {
          size = FLEX
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          children = mkInfo(addChild(sf))
        }
        onClick = @() offersModMsgbox(mod)
      })
    })
  }
  return list
})

featuredModsList.subscribe(function(wlist) {
  let wCount = wlist.len()
  if (wCount == 0)
    return curWidgetIdx.set(-1)

  curWidgetIdx.set(clamp(curWidgetIdx.get(), 0, wCount - 1))
})

let paginatorTimer = Watched(SWITCH_SEC)

let header = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = accentTitleTxtColor
  hplace = ALIGN_CENTER
}.__update(fontBody)

let offersPaginator = mkDotPaginator("offers", curWidgetIdx, hdpx(9), paginatorTimer)

function customMissionOfferBlock() {
  let res = { watch = [curWidgetIdx, isEventModesOpened, featuredModsList] }
  let widgets = featuredModsList.get()
  if (widgets.len() == 0)
    return res

  return res.__update({
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      header(loc("mods/modOfWeek"))
      {
        size = FLEX_H
        children = [
          mkOfferImage(widgets?[curWidgetIdx.get()].backImage)
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              watchElemState(@(sf) {
                size = const [FLEX, hdpx(125)]
                behavior = Behaviors.Button
                onClick = widgets?[curWidgetIdx.get()].onClick
                onHover = @(on) paginatorTimer.set(on ? 0 : SWITCH_SEC)
                children = widgets?[curWidgetIdx.get()].mkContent(sf)
              })
              {
                rendObj = ROBJ_SOLID
                size = FLEX_H
                padding = smallPadding
                halign = ALIGN_CENTER
                color = defBgColor
                children = offersPaginator(widgets.len())
              }
            ]
          }
        ]
      }
    ]
  })
}

return customMissionOfferBlock
