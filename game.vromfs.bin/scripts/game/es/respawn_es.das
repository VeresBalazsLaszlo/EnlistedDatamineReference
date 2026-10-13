require enlisted.game.utils.sandbox_state
require game.es.sandbox_config_common
require ecs
require DagorConsole
require daslib/strings_boost
require app

[es(tag=server, track=isFirstSpawn)]
def respawn_on_squad_from_console_es(evt : Event; userid : uint64; isFirstSpawn : bool)
  if !isFirstSpawn  // respawner was inited
    let respawnerUserid = "{int(userid)}"

    if is_sandbox_enabled()
      let squadId = sandbox_config_get_string("squad", "")
      if squadId != ""
        console_command("squad.spawn {squadId} 0")
        return

    dgs_get_argv_all("spawnSquadId") <| $(spawnSquadId : string)
      var ids : array<string>
      ids <- split_by_chars(spawnSquadId, ",")
      let userId = ids[0]
      let squadId = ids[1]
      if userId == respawnerUserid
        console_command("squad.spawn {squadId} {userId}")
        return true
      return false
