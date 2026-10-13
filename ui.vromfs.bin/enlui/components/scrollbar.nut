import "%ui/components/base_scrollbar.nut" as baseScrollbar
from "%ui/style/colors.nut" import Interactive, Active, HoverItemBg, FullTransparent, ScrollBgColor
from "%ui/helpers/gradients.nut" import mkColoredGradientY
from "%ui/ui_library.nut" import *

let styling = freeze({
  Knob = {
    rendObj = ROBJ_SOLID
    colorCalc = @(sf) sf & S_ACTIVE ? Active
      : sf & S_HOVER ? HoverItemBg
      : Interactive
    sound = { active = "ui/enlist/combobox_action" }
  }

  Bar = function(has_scroll) {
    if (has_scroll) {
      return {
        rendObj = ROBJ_SOLID
        color = Color(40, 40, 40, 160)
        _width = fsh(1)
        _height = fsh(1)
        sound = { hover  = "ui/enlist/combobox_highlight" }
        skipDirPadNav = true
      }
    } else {
      return {
        rendObj = null
        _width = sh(0)
        _height = sh(0)
        skipDirPadNav = true
      }
    }
  }

  ContentRoot = {
    size = FLEX
    skipDirPadNav = true
  }
})

let thinStyle = freeze({
  Knob = {
    rendObj = ROBJ_SOLID
    colorCalc = @(_sf) Color(0, 0, 0, 0)
    hoverChild = @(sf){
      size = const [hdpx(2), FLEX]
      rendObj = ROBJ_SOLID
      hplace = ALIGN_RIGHT
      color = sf & S_ACTIVE  ? Color(255, 255, 255)
              : sf & S_HOVER ? Color(110, 120, 140, 80)
              : Color(110, 120, 140, 160)
    }
  }
  Bar = function(has_scroll) {
    if (!has_scroll)
      return {
        _width = 0
        _height = 0
        skipDirPadNav = true
      }
    return {
      rendObj = ROBJ_SOLID
      color = Color(0, 0, 0, 60)
      _width = hdpx(4)
      _height = fsh(1)
      skipDirPadNav = true
    }
  }

  ContentRoot = {
    size = FLEX
    skipDirPadNav = true
  }
})


function scrollbar(scroll_handler) {
  return baseScrollbar.scrollbar(scroll_handler, {styling=styling})
}


let makeHorizScroll = @(content, options={})
  baseScrollbar.makeHorizScroll(content, "styling" in options ? options : options.__merge({ styling }))

let makeVertScroll = @(content, options={})
  baseScrollbar.makeVertScroll(content, "styling" in options ? options : options.__merge({ styling }))

let topGradient = mkColoredGradientY({ colorTop = ScrollBgColor, colorBottom = FullTransparent})
let bottomGradient = mkColoredGradientY({ colorTop = FullTransparent, colorBottom = ScrollBgColor })

function makeGradientVertScroll(content, options = {}) {
  let hasBottomScroll = Watched(false)
  let hasTopScroll = Watched(true)
  let scrollHandler = ScrollHandler()

  function updateScroll(elem) {
    hasTopScroll.set(elem.getScrollOffsY() > 0)
    let overflow = elem.getContentHeight() - elem.getHeight()
    hasBottomScroll.set(overflow > elem.getScrollOffsY())
  }

  scrollHandler.subscribe(function(_) {
    let { elem = null } = scrollHandler
    if (elem == null)
      return
    updateScroll(elem)
  })

  let { gradientSize, size = FLEX_V } = options
  let topScroll = freeze({
    rendObj = ROBJ_IMAGE
    size = [FLEX, gradientSize]
    image = topGradient
  })

  let bottomScroll = freeze({
    rendObj = ROBJ_IMAGE
    size = [FLEX, gradientSize]
    image = bottomGradient
  })

  let opt = options.__merge({ scrollHandler })

  return @() {
    size
    children = [
      makeVertScroll(content, opt)
      @() {
        watch = hasTopScroll
        size = [FLEX, gradientSize]
        children = hasTopScroll.get() ? topScroll : null
        vplace = ALIGN_TOP
      }
      @() {
        watch = hasBottomScroll
        size = [FLEX, gradientSize]
        children = hasBottomScroll.get() ? bottomScroll : null
        vplace = ALIGN_BOTTOM
      }
    ]
  }
}


return freeze({
  scrollbar
  makeHorizScroll
  makeVertScroll
  styling
  thinStyle
  makeGradientVertScroll
})
