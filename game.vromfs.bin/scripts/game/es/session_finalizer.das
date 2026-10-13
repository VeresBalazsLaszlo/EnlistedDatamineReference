require app
require ecs
require GameTimers
require DngNet
require DagorDataBlock
require DagorSystem
require game.events_game

def script_switch_to_menu_scene() //replace to broadcast event that will be handled in menu
  broadcastEvent(EventSwitchToMenu())
//  if dgs_get_settings() |> datablock_getBool("disableMenu", false)
//    // no exit for offline mode (must be handled elsewhere)
//    if is_sandbox_enabled()
//      return
//    // special case for levels run without menu or benchmarks
//    exit_game("session finished on EventTeamRoundResult")
//    return
//  broadcastEvent([[EventGameSessionFinished]])
//  switch_scene_and_update(datablock_getStr("menu", false))

[es(on_event=EventTeamRoundResult)]
def session_finalizer_es(evt : Event;
                         session_finalizer__timer : float = 10.f;
                         var is_session_finalizing : bool&;
                         var session_finalizer_timer__handle : uint64&)
  if is_session_finalizing
    return

  print("Starting finalizing session on EventTeamRoundResult")

  let exitFunc <- @ <| ()
    if is_dedicated()
      exit_game("session finished on EventTeamRoundResult")
    else
      script_switch_to_menu_scene()

  is_session_finalizing = true
  game_timer_clear(session_finalizer_timer__handle)
  session_finalizer_timer__handle = game_timer_set(exitFunc, session_finalizer__timer)
  broadcastEvent(EventSessionFinished())
