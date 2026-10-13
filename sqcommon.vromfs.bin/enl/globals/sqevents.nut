from "%dngscripts/ecs.nut" import registerUnicastEvent, registerBroadcastEvent

let broadcastEvents = {}
foreach (name, payload in {
  EventSquadMembersStats = { list = [] }
  EventOnBattleResult = {stats = {guid = {}}}
})
  broadcastEvents.__update(registerBroadcastEvent(payload,name))

let unicastEvents = {}
foreach (name, payload in {
  EventSqDedicatedPermissions = {},
  CmdPsnExternalMatchId = {match_id=""}
  CmdChatMessage = {mode="team", text="", qmsg=null, sound=null},
  EventSqChatMessage = {team = "", name="", sender=0, text="", qmsg=null, sound=null},
  EventBotSpawned = {eid=0},
  EventSetCamTmAndFov = { tm = null, fov = 0.0 },

  CmdEnableDedicatedLogger = { on = true },
  EventOnSpawnError = {reason=""},
  CmdDevSquadsData = {}
  CmdTutorialSquadsData = {}
  CmdProfileJwtData = {} 
  CmdGetMySquadsData = {}
  CmdSetMySquadsData = {}
  CmdSelectBuildingType = { index = 0 },
  EventOnSquadStats = {},
  CmdTutorialHint = { event = "", unique = "", text = "", hotkey = "", ttl = 15}

})
  unicastEvents.__update(registerUnicastEvent(payload, name))

return freeze(broadcastEvents.__merge(unicastEvents))
