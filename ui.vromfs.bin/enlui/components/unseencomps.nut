from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%ui/ui_library.nut" import *

let smallUnseen = blinkUnseenIcon(0.8)
let smallUnseenNoBlink = freeze(smallUnseen.__merge({ key = "blink_off", animations = null }))
let smallUnseenBlink = smallUnseen.__merge({ key = "blink_on" })

const BLINK = "blink"
const NO_BLINK = "noBlink"

let unseenByType = {
  [true] = smallUnseenBlink,
  [BLINK] = smallUnseenBlink,
  [NO_BLINK] = smallUnseenNoBlink
}

return {
  BLINK
  NO_BLINK
  smallUnseenBlink
  smallUnseenNoBlink
  unseenByType
}
