import "%ui/items/itemsMapping.nut" as itemsMapping
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import smallPadding, unitSize, listCtors, defSlotBgColor, hoverSlotBgColor
from "%ui/components/itemsInfo.nut" import itemNameFromItem
from "%ui/ui_library.nut" import *

let { txtColor } = listCtors

let eventPreviewSize = const [hdpxi(495), hdpxi(360)]
let eventItemSize = const [unitSize * 2, unitSize * 2]
let eventItemIcon = @(icon) {
  rendObj = ROBJ_IMAGE
  size = eventItemSize
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"!{icon}")
}

let isEventItem = @(item) item?.isConsumable ?? false
let has3dIcon = @(item) (item?.gametemplate ?? "") != ""

function eventItemPreview(item) {
  if (!isEventItem(item))
    return null

  let {
    previewImage = null, previewSize = eventPreviewSize
  } = itemsMapping.get().findvalue(@(i) i?.itemTemplate == item.basetpl)
  if (previewImage == null)
    return null

  return {
    rendObj = ROBJ_IMAGE
    image = Picture(previewImage)
    size = previewSize
  }
}

let eventItemImage = @(item, override = {}) function() {
  let watch = itemsMapping
  if (item == null)
    return { watch }

  let {
    eventImage = null, cardImage = null
  } = itemsMapping.get().findvalue(@(i) i?.itemTemplate == item.basetpl)
  return eventItemIcon(eventImage ?? cardImage).__update(override, { watch })
}

function mkEventItemCard(item, onClickCb, size = FLEX) {
  let { count = 1 } = item
  return watchElemState(@(sf) {
    rendObj = ROBJ_SOLID
    size
    behavior = Behaviors.Button
    onClick = onClickCb
    color = sf & S_HOVER ? hoverSlotBgColor : defSlotBgColor
    children = [
      eventItemImage(item, { hplace = ALIGN_CENTER })
      {
        rendObj = ROBJ_TEXT
        size = FLEX_H
        text = itemNameFromItem(item)
        color = txtColor(sf)
        vplace = ALIGN_BOTTOM
        padding = smallPadding
      }.__update(fontSub)
      count <= 1 ? null : {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        padding = smallPadding
        text = loc("common/amountShort", item)
        color = txtColor(sf)
      }.__update(fontSub)
    ]
  })
}

return freeze({
  eventItemIcon
  mkEventItemCard
  isEventItem
  has3dIcon
  eventItemImage
  eventItemPreview
})
