import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/control/gui_buttons.nut" as JB
import "%ui/hud/state/sessions_players.nut" as sessions_players
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/ui_library.nut" import *

let showPlayersMenu = mkWatched(persist, "showPlayersMenu", false)

function close(){
  showPlayersMenu.set(false)
}

let closebutton = fontIconButton("close", {
  onClick = close
  margin = hdpx(8)
  hplace = ALIGN_RIGHT
  hotkeys = [[$"^{JB.B}", {description={skip=true}}]]
  padding = 0
})

let mkPlayer = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontBody)

let header = {
  rendObj = ROBJ_TEXT
  text = loc("Players in session")
  margin = hdpx(8)
  color = Color(120,120,120,120)
}.__update(fontBody)

function menu(){
  return {
    watch = [sessions_players]
    size = const [sw(20), sh(60)]
    pos = const [sw(10),sh(10)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = Color(0,0,0,80)
    hotkeys = [["^Esc", close]]
    flow = FLOW_VERTICAL
    children = [
      {children = [header, closebutton] size = FLEX_H}
      scrollbar.makeVertScroll(
        {
          size = SIZE_TO_CONTENT
          flow = FLOW_VERTICAL
          padding = fsh(1)
          children = sessions_players.get().map(mkPlayer)
        },
        {
          needReservePlace = false
          wheelStep = hdpx(30)
        }
      )
    ]
  }
}

return {
  showPlayersMenu
  playersMenuUi = @(){
    size = FLEX
    watch = [showPlayersMenu]
    children = showPlayersMenu.get() ? menu : null
    behavior = DngBhv.ActivateActionSet
    actionSet = "StopInput"
  }
}