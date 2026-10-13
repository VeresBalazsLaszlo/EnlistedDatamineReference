from "%ui/state/roomState.nut" import roomIsLobby, setMemberAttributes
from "%ui/ui_library.nut" import *

let attribs = {}

function addAttrib(name, watched) {
  attribs[name] <- watched
  watched.subscribe(@(val) setMemberAttributes({ public = { [name] = val } }))
}

roomIsLobby.subscribe(function(val) {
  if (val && attribs.len() > 0)
    setMemberAttributes({ public = attribs.map(@(v) v.get()) })
})

return {
  addAttrib
}
