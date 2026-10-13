from "%dngscripts/globalState.nut" import nestWatched
from "console" import register_command as console_register_command

let controllerDisconnected = nestWatched("controllerDisconnected", false)
let controllerDisconnectedUpdate = @(v) controllerDisconnected.set(v)

console_register_command(@() controllerDisconnected.modify(@(v) !v), "ui.controllerDisconnected")

return freeze({
  controllerDisconnected,
  controllerDisconnectedUpdate
})