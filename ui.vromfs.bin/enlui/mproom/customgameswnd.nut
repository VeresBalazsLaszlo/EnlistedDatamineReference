import "%ui/components/progressText.nut" as progressText
import "%ui/mpRoom/customRoomLobby.nut" as customRoomLobby
import "%ui/roomsList.nut" as roomsList
import "%ui/components/closeBtn.nut" as closeBtnBase
from "%ui/navState.nut" import addScene, removeScene
from "%ui/mpRoom/showCreateRoom.nut" import showCreateRoom
from "%ui/ui_library.nut" import *
from "%ui/state/roomState.nut" import isInRoom, roomIsLobby


let customGamesContent = @() {
  watch = [isInRoom, roomIsLobby]
  size = FLEX
  children = !isInRoom.get() ? roomsList
    : roomIsLobby.get() ? customRoomLobby
    : progressText(loc("lobbyStatus/gameIsRunning"))
}


let isCustomGamesOpened = mkWatched(persist, "isCustomGamesOpened", false)
let close = @() isCustomGamesOpened.set(false)
let closeBtnAction = @() showCreateRoom.get() ? showCreateRoom.set(false) : close()
let closeBtn = closeBtnBase({ onClick = closeBtnAction })

let customGamesScene = @() {
  watch = isInRoom
  size = FLEX
  margin = const [fsh(5), sw(5)]
  children = [
    customGamesContent
    isInRoom.get() ? null : closeBtn
  ]
}

if (isCustomGamesOpened.get())
  addScene(customGamesScene)
isCustomGamesOpened.subscribe(@(val) val
  ? addScene(customGamesScene)
  : removeScene(customGamesScene))


return {
  customGamesOpen = @() isCustomGamesOpened.set(true),
}