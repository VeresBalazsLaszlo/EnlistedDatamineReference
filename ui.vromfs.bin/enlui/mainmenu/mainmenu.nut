import "%ui/mainMenu/bottomRightButtons.nut" as bottomBar
from "%ui/mainMenu/sectionsState.nut" import sectionsSorted, sectionsGeneration, curSection
from "%ui/mainMenu/mkMenuScene.nut" import mkMenuScene, menuContentAnimation
from "%ui/ui_library.nut" import *

let navHeader = require("%ui/mainMenu/sectionsBlock.nut")


function sectionContent() {
  let section = (sectionsSorted ?? []).findvalue(@(val) val?.id == curSection.get())
  let children = section?.getContent()
  let sectionWatched = section?.sectionWatched
  return {
    watch = [curSection, sectionsGeneration] 
    size = FLEX
    children = @() {
      size = FLEX
      children
      watch = [sectionWatched, curSection]
      key = curSection.get()
      transform = true
      animations = menuContentAnimation
    }
  }
}

return mkMenuScene(navHeader, sectionContent, bottomBar)
