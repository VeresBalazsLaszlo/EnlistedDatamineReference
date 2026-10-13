require ecs
require app
require DagorSystem
require enlisted.game.utils.sandbox_state

[es(tag=gameClient, track=ai_enabled__inSandbox, on_event=CmdEditorInvalidateAI, on_appear, before=switch_ai_on_possess_unpossess)]
def sandbox_toggle_ai_es(evt : Event; ai_enabled__inSandbox : bool; var ai_enabled : bool&)
  if is_sandbox_enabled()
    ai_enabled = ai_enabled__inSandbox
