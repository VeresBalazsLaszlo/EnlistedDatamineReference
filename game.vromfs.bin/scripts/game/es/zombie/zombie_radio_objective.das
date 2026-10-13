require ecs
require game.es.events
require enlisted.events_enlisted


[es(tag=(ui, render, gameClient), on_appear)]
def human_use_action_zombie_radio_objective(evt : Event;
                                            zombie_radio_objective__useText : string;
                                            var item__customUsePrompt : das_string&)
  item__customUsePrompt := zombie_radio_objective__useText

[es(tag=server)]
def zombie_radio_objective_use(evt : CmdUse;
                               eid : EntityId;
                               active : bool = true)
  if !active
    return
  sendEvent(eid, EventRadioObjectiveActivate(bombSiteOperator = evt.requesterEid))
