import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/navState.nut" import doesSceneExist, getTopScene, scenesListGeneration
from "%ui/mainMenu/mainMenuComp.nut" import getMainMenuComp, mainMenuVersion
from "%ui/ui_library.nut" import *

let notLoggedInText = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = loc("Error: not logged in")
}.__update(fontHeading2)

let mainMenu = @() {
  size = FLEX
  children = getMainMenuComp()
  watch = mainMenuVersion
}

function mainScreen() {
  let children = doesSceneExist()
    ? getTopScene()
    : userInfo.get()==null
      ? notLoggedInText
      : mainMenu

  return {
    watch = [userInfo, scenesListGeneration]
    size = const [sw(100), sh(100)]

    children
  }
}

return mainScreen
