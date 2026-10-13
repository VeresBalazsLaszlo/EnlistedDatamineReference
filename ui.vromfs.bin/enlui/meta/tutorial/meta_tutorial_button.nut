from "%ui/components/textButton.nut" import FARegular
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/meta/tutorial/meta_tutorial_window.nut" import showMetaTutorialWindow
from "%ui/style/designConst.nut" import navigationBtnHeight, defTxtColor
from "%ui/ui_library.nut" import *

const buttonSize = hdpxi(36)

let mkButton = @(page, watch = null) {
  watch
  size = [SIZE_TO_CONTENT, navigationBtnHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = FARegular("question", function() {
    showMetaTutorialWindow(page)
  }, {
    btnWidth = buttonSize
    btnHeight = buttonSize
    hint = {
      rendObj = ROBJ_TEXT
      text = loc("meta/tutorial/help")
      color = defTxtColor
    }.__update(fontSub)
  })
}

let mkPageButton = @(page) mkButton(page)

let mkWatchedButton = @(watch) function() {
  let page = watch.get()
  return page == null ? { watch }
    : mkButton(page, watch)
}

return {
  mkPageButton
  mkWatchedButton
}
