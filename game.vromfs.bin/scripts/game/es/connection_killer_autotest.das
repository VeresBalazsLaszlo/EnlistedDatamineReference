require ecs
require app
require DagorConsole
require DngNet

[es(tag=server, REQUIRE=connectionTest__killOnLevelLoaded, on_event=EventLevelLoaded)]
def connection_test_kill_on_level_loaded(evt : Event)
  exit_game("app was closed by test mode")

[es(tag=server, REQUIRE=connectionTest__killOnEntityCreated, on_appear)]
def connection_test_kill_on_test_start(evt : Event)
  exit_game("app was closed by test mode")

[es(tag=server, on_event=EventOnPlayerConnected, REQUIRE=player)]
def connection_test_kick_on_player_connected(evt : Event;
                                             connid : int = INVALID_CONNECTION_ID)
  let kickTest = find_query() <| $ [es(REQUIRE=connectionTest__kickOnPlayerConnected)] ()
    return true
  if !kickTest
    return
  var cliConn : IConnection? = get_client_connection(connid)
  if cliConn != null
    net_disconnect(*cliConn, DisconnectionCause.DC_CONNECTION_CLOSED)
