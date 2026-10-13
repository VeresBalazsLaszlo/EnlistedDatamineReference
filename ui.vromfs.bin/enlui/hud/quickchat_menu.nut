from "%ui/hud/state/look_at_zone.nut" import zoneTitle, zoneCanBeAttacked, zoneCanBeDefended
from "%ui/hud/huds/send_quick_chat_msg.nut" import sendQuickChatSoundMsg
from "dasevents" import CmdRequestAmmoBoxMarker, CmdRequestRallyPointMarker, sendNetEvent
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/ui_library.nut" import *

let getPieElementByCmd = @(cmd) {
  action = function() {
    sendQuickChatSoundMsg(cmd.text, cmd?.qmsg ?? {}, cmd?.sound)
    cmd?.action()
  }
  text = loc(cmd.text, cmd?.qmsg)
}

let askCommands = [
  { text = "quickchat/needCoordinates", sound = "qm_mark_enemy_vehicle" },
  
  
  { text = "quickchat/requestRallyPoint", sound = "qm_request_rally_point", action = @() sendNetEvent(watchedHeroEid.get(), CmdRequestRallyPointMarker()) },
  { text = "quickchat/requestAmmoBox", sound = "qm_request_ammo_box", action = @() sendNetEvent(watchedHeroEid.get(), CmdRequestAmmoBoxMarker()) }
].map(getPieElementByCmd)

let baseCommands = [
  { text = "quickchat/thanks", sound = "qm_thanks" },
  { text = "quickchat/goodJob", sound = "qm_well_done" },
  { text = "quickchat/sorry", sound = "qm_sorry" },
].map(getPieElementByCmd)

let answerCommands = [
  { text = "quickchat/yes", sound = "qm_accept" },
  { text = "quickchat/no", sound = "qm_decline" },
].map(getPieElementByCmd)

let zoneCommands = [
  {
    text = Computed(@() loc(zoneCanBeAttacked.get() ? "quickchat/attackPoint" : "quickchat/defendPoint", { zone = zoneTitle.get() })),
    available = Computed(@() zoneCanBeAttacked.get() || zoneCanBeDefended.get()),
    action = @() sendQuickChatSoundMsg(zoneCanBeAttacked.get() ? "quickchat/attackPoint" : "quickchat/defendPoint", { zone = zoneTitle.get() }, null)
  },
]

return {
  quickChatCommands = [].extend(askCommands, baseCommands, zoneCommands, answerCommands)
}