require app
require ecs
require ecs.common
require ecs.safe
require net
require game.utils.net_utils
require math
require math.base
require Grid
require game.utils.sound_utils
require DagorMath
require DagorConsole
require DagorSystem
require RendInst
require RendInstPhys
require enlisted.events_enlisted
require game.es.events
require DngDm


[es(tag=server, on_appear)]
def game_trigger_timer_init(evt : Event;
                            game_trigger_processor_timer__time : float;
                            var game_trigger_processor_timer__timestamp : float&)
  game_trigger_processor_timer__timestamp = get_sync_time() + game_trigger_processor_timer__time


[es(tag=server, no_order)]
def game_trigger_timer_update(act : ParallelUpdateFrameDelayed;
                              eid : EntityId;
                              game_trigger_processor_timer__timestamp : float;
                              game_trigger_processor_timer__eventTrigger : string)
  if act.curTime >= game_trigger_processor_timer__timestamp
    assume eventTrigger = game_trigger_processor_timer__eventTrigger
    broadcast_net_event(EventGameTrigger(source = eid, triggerHash = int(ecs_hash(eventTrigger))))
    destroyEntity(eid)


def check_entity_has_components(entity : EntityId; compNames : StringList; compHashes : UInt32List)
  assert(length(compNames) == length(compHashes))
  for i in iter_range(compNames)
    if !has(entity, string(compNames[i]), compHashes[i])
      return false
  return true


[es(tag=server, on_appear)]
def game_trigger_box_init(evt : Event;
                          game_trigger__includeGrids : StringList;
                          game_trigger__requireComponents : StringList;
                          var game_trigger__includeGridsHashes : UInt32List;
                          var game_trigger__requireComponentsHashes : UInt32List)
  for gridName in game_trigger__includeGrids
    push(game_trigger__includeGridsHashes, ecs_hash(string(gridName)))

  for compName in game_trigger__requireComponents
    push(game_trigger__requireComponentsHashes, ecs_hash(string(compName)))


[es(tag=server, no_order)]
def game_trigger_box_update(act : UpdateStageInfoAct;
                            eid aka trigger_box_eid : EntityId;
                            transform aka zone_transform : float3x4;
                            game_trigger_box__onEnterEventTrigger : string;
                            game_trigger_box__onLeaveEventTrigger : string;
                            game_trigger__requireComponents : StringList;
                            game_trigger__includeGridsHashes : UInt32List;
                            game_trigger__requireComponentsHashes : UInt32List;
                            var game_trigger_box__currentVisitors : EidList)
  var thisFrameVisitors : array<EntityId>
  let bbox = zone_transform * BBox3(float3(), 1.0)
  let inverseTm = inverse(zone_transform)
  for gridHash in game_trigger__includeGridsHashes
    for_each_entity_in_grid(gridHash, bbox, GridEntCheck.POS) <| $(entity : EntityId)
      query(entity) <| $ [es] (transform : float3x4)
        let posLS = inverseTm * transform[3]
        if BBox3(float3(), 1.0) & posLS
          if check_entity_has_components(entity, game_trigger__requireComponents, game_trigger__requireComponentsHashes)
            push(thisFrameVisitors, entity)

  if !empty(game_trigger_box__onLeaveEventTrigger)
    for entity in game_trigger_box__currentVisitors
      if !has_value(thisFrameVisitors, entity)
        using() <| $(var data : Object)
          data |> set("entity", entity)
          broadcast_net_event(EventGameTrigger(source = trigger_box_eid, triggerHash = int(ecs_hash(game_trigger_box__onLeaveEventTrigger)), data = ecs_addr(data)))

  if !empty(game_trigger_box__onEnterEventTrigger)
    for entity in thisFrameVisitors
      if !has_value(game_trigger_box__currentVisitors, entity)
        using() <| $(var data : Object)
          data |> set("entity", entity)
          broadcast_net_event(EventGameTrigger(source = trigger_box_eid, triggerHash = int(ecs_hash(game_trigger_box__onEnterEventTrigger)), data = ecs_addr(data)))

  clear(game_trigger_box__currentVisitors)
  for visitor in thisFrameVisitors
    push(game_trigger_box__currentVisitors, visitor)


[es(tag=server, no_order)]
def game_trigger_sphere_update(act : UpdateStageInfoAct;
                               eid aka trigger_sphere_eid : EntityId;
                               transform aka zone_transform : float3x4;
                               sphere_zone__radius : float;
                               game_trigger_sphere__onEnterEventTrigger : string;
                               game_trigger_sphere__onLeaveEventTrigger : string;
                               game_trigger__requireComponents : StringList;
                               game_trigger__includeGridsHashes : UInt32List;
                               game_trigger__requireComponentsHashes : UInt32List;
                               var game_trigger_sphere__currentVisitors : EidList)
  var thisFrameVisitors : array<EntityId>
  let bsphere = BSphere3(zone_transform[3], sphere_zone__radius)
  for gridHash in game_trigger__includeGridsHashes
    for_each_entity_in_grid(gridHash, bsphere, GridEntCheck.POS) <| $(entity : EntityId)
      if check_entity_has_components(entity, game_trigger__requireComponents, game_trigger__requireComponentsHashes)
        push(thisFrameVisitors, entity)

  if !empty(game_trigger_sphere__onLeaveEventTrigger)
    for entity in game_trigger_sphere__currentVisitors
      if !has_value(thisFrameVisitors, entity)
        using() <| $(var data : Object)
          data |> set("entity", entity)
          broadcast_net_event(EventGameTrigger(source = trigger_sphere_eid, triggerHash = int(ecs_hash(game_trigger_sphere__onLeaveEventTrigger)), data = ecs_addr(data)))

  if !empty(game_trigger_sphere__onEnterEventTrigger)
    for entity in thisFrameVisitors
      if !has_value(game_trigger_sphere__currentVisitors, entity)
        using() <| $(var data : Object)
          data |> set("entity", entity)
          broadcast_net_event(EventGameTrigger(source = trigger_sphere_eid, triggerHash = int(ecs_hash(game_trigger_sphere__onEnterEventTrigger)), data = ecs_addr(data)))

  clear(game_trigger_sphere__currentVisitors)
  for visitor in thisFrameVisitors
    push(game_trigger_sphere__currentVisitors, visitor)


[es(on_appear)]
def game_trigger_processor_init(evt : Event;
                                game_trigger_processor__onTrigger : string;
                                var game_trigger_processor__onTriggerHash : int&)
  game_trigger_processor__onTriggerHash = int(ecs_hash(game_trigger_processor__onTrigger))


[es(tag=server)]
def game_trigger_processor_create_entity(evt : EventGameTrigger;
                                         transform aka trigger_transform : float3x4;
                                         game_trigger_processor__onTriggerHash : int;
                                         game_trigger_processor_create_entity__template : string;
                                         game_trigger_processor_create_entity__initTransform : bool;
                                         var game_trigger_processor_create_entity__entityEid : EntityId&)
  if evt.triggerHash != game_trigger_processor__onTriggerHash
    return

  game_trigger_processor_create_entity__entityEid = createEntity(game_trigger_processor_create_entity__template) <| $(var init : ComponentsInitializer)
    if game_trigger_processor_create_entity__initTransform
      init |> set("transform", transform)
      init |> set("initialTransform", transform)


[es(tag=server, on_disappear)]
def game_trigger_processor_create_entity_disappear(evt : Event;
                                                   game_trigger_processor_create_entity__destroyEntityOnDisappear : bool;
                                                   game_trigger_processor_create_entity__entityEid : EntityId)
  if game_trigger_processor_create_entity__destroyEntityOnDisappear
    destroyEntity(game_trigger_processor_create_entity__entityEid)


[es(tag=server, REQUIRE=game_trigger_processor_self_destroy)]
def game_trigger_processor_self_destroy(evt : EventGameTrigger;
                                        eid : EntityId;
                                        game_trigger_processor_targeted_self_destroy : Tag const?;
                                        game_trigger_processor__onTriggerHash : int)
  if evt.triggerHash != game_trigger_processor__onTriggerHash
    return

  let targetedDestroy = game_trigger_processor_targeted_self_destroy != null
  if targetedDestroy && ((evt.data.entity ?? INVALID_ENTITY_ID) != eid)
    return

  destroyEntity(eid)


enum GameTriggerTransformTransitionState
  NONE
  FORWARD
  BACKWARD


[es(tag=server, on_appear)]
def game_trigger_processor_transform_transition_init(evt : Event;
                                                     transform : float3x4;
                                                     game_trigger_processor_transform_transition__forwardTrigger : string;
                                                     game_trigger_processor_transform_transition__backwardTrigger : string;
                                                     var game_trigger_processor_transform_transition__forwardTriggerHash : int&;
                                                     var game_trigger_processor_transform_transition__backwardTriggerHash : int&;
                                                     var game_trigger_processor_transform_transition__fromPos : float3&;
                                                     var game_trigger_processor_transform_transition__fromRot : float4&)
  game_trigger_processor_transform_transition__forwardTriggerHash = int(ecs_hash(game_trigger_processor_transform_transition__forwardTrigger))
  game_trigger_processor_transform_transition__backwardTriggerHash = int(ecs_hash(game_trigger_processor_transform_transition__backwardTrigger))

  game_trigger_processor_transform_transition__fromPos = transform[3]
  game_trigger_processor_transform_transition__fromRot = float4(DagorMath::quat(transform))


[es(tag=server)]
def game_trigger_processor_transform_transition(evt : EventGameTrigger;
                                                game_trigger_processor_transform_transition__forwardTriggerHash : int;
                                                game_trigger_processor_transform_transition__backwardTriggerHash : int;
                                                var game_trigger_processor_transform_transition__state : int&)
  if evt.triggerHash == game_trigger_processor_transform_transition__forwardTriggerHash
    game_trigger_processor_transform_transition__state = int(GameTriggerTransformTransitionState.FORWARD)
  elif evt.triggerHash == game_trigger_processor_transform_transition__backwardTriggerHash
    game_trigger_processor_transform_transition__state = int(GameTriggerTransformTransitionState.BACKWARD)


[es(tag=server, track=game_trigger_processor_transform_transition__state)]
def game_trigger_processor_transform_transition_track(evt : Event;
                                                      eid : EntityId;
                                                      game_trigger_processor_transform_transition__state : int)
  if (game_trigger_processor_transform_transition__state == int(GameTriggerTransformTransitionState.FORWARD) ||
     game_trigger_processor_transform_transition__state == int(GameTriggerTransformTransitionState.BACKWARD))
    addSubTemplate(eid, "game_trigger_processor_transform_transition_update")
  elif game_trigger_processor_transform_transition__state == int(GameTriggerTransformTransitionState.NONE)
    removeSubTemplate(eid, "game_trigger_processor_transform_transition_update")


[es(tag=server, no_order, REQUIRE=game_trigger_processor_transform_transition_update)]
def game_trigger_processor_transform_transition_update(act : ParallelUpdateFrameDelayed;
                                                       game_trigger_processor_transform_transition__forwardSpeed : float;
                                                       game_trigger_processor_transform_transition__backwardSpeed : float;
                                                       game_trigger_processor_transform_transition__fromPos : float3;
                                                       game_trigger_processor_transform_transition__fromRot : float4;
                                                       game_trigger_processor_transform_transition__toPos : float3;
                                                       game_trigger_processor_transform_transition__toRot : float4;
                                                       ri_extra : RiExtraComponent const?;
                                                       var transform : float3x4;
                                                       var game_trigger_processor_transform_transition__state : int&;
                                                       var game_trigger_processor_transform_transition__progress : float&)
  assume state = game_trigger_processor_transform_transition__state
  assume progress = game_trigger_processor_transform_transition__progress

  if state == int(GameTriggerTransformTransitionState.FORWARD)
    progress += game_trigger_processor_transform_transition__forwardSpeed * act.dt
    if progress >= 1.0
      progress = 1.0
      state = int(GameTriggerTransformTransitionState.NONE)
  elif state == int(GameTriggerTransformTransitionState.BACKWARD)
    progress -= game_trigger_processor_transform_transition__backwardSpeed * act.dt
    if progress <= 0.0
      progress = 0.0
      state = int(GameTriggerTransformTransitionState.NONE)

  let pos = lerp(game_trigger_processor_transform_transition__fromPos, game_trigger_processor_transform_transition__toPos, float3(progress))
  let rot = slerp(DagorMath::quat(game_trigger_processor_transform_transition__fromRot), DagorMath::quat(game_trigger_processor_transform_transition__toRot), progress)

  var tm : float3x4
  make_tm(rot, pos, tm)

  if ri_extra != null
    move_ri_extra_tm(ri_extra.handle, tm)
  else
    transform = tm


[es(tag=server, REQUIRE=net_sound__descs)]
def game_trigger_processor_sound_oneshot(evt : EventGameTrigger;
                                         eid : EntityId;
                                         game_trigger_processor__onTriggerHash : int;
                                         game_trigger_processor_sound_oneshot__soundName : string)
  if evt.triggerHash != game_trigger_processor__onTriggerHash
    return
  broadcast_net_sound(eid, game_trigger_processor_sound_oneshot__soundName)


[es(REQUIRE=game_trigger_processor_visual_log)]
def game_trigger_processor_visual_log(evt : EventGameTrigger;
                                      eid : EntityId;
                                      game_trigger_processor__onTrigger : string;
                                      game_trigger_processor__onTriggerHash : int)
  if evt.triggerHash != game_trigger_processor__onTriggerHash
    return
  visual_log("<{eid}> TRIGGERED: {game_trigger_processor__onTrigger}")


[es(tag=server, REQUIRE=game_trigger_processor_kill)]
def game_trigger_processor_kill(evt : EventGameTrigger;
                                game_trigger_processor__onTriggerHash : int;
                                dm__damageTypeId : int)
  if evt.triggerHash != game_trigger_processor__onTriggerHash
    return

  let victim = evt.data.entity ?? INVALID_ENTITY_ID
  if victim == INVALID_ENTITY_ID
    logwarn("kill trigger triggered with no entity")
    return

  query(victim) <| $ [es] (transform : float3x4)
    let damageDesc = DamageDesc(DamageType(dm__damageTypeId), VERY_BIG_NUMBER, transform[3])
    damage_entity(victim, victim, damageDesc)


[es(tag=server, on_appear)]
def game_trigger_processor_attach_game_effect_init(evt : Event;
                                                   game_trigger_processor_attach_game_effect__attachOnTrigger : string;
                                                   game_trigger_processor_attach_game_effect__removeOnTrigger : string;
                                                   var game_trigger_processor_attach_game_effect__attachOnTriggerHash : int&;
                                                   var game_trigger_processor_attach_game_effect__removeOnTriggerHash : int&)
  game_trigger_processor_attach_game_effect__attachOnTriggerHash = int(ecs_hash(game_trigger_processor_attach_game_effect__attachOnTrigger))
  game_trigger_processor_attach_game_effect__removeOnTriggerHash = int(ecs_hash(game_trigger_processor_attach_game_effect__removeOnTrigger))


[es(tag=server)]
def game_trigger_processor_attach_game_effect(evt : EventGameTrigger;
                                              game_trigger_processor_attach_game_effect__attachOnTriggerHash : int;
                                              game_trigger_processor_attach_game_effect__removeOnTriggerHash : int;
                                              game_trigger_processor_attach_game_effect__template : string;
                                              var game_trigger_processor_attach_game_effect__eid : EntityId&)
  let entity = evt.data.entity ?? INVALID_ENTITY_ID
  if entity == INVALID_ENTITY_ID
    return

  if evt.triggerHash == game_trigger_processor_attach_game_effect__attachOnTriggerHash
    if game_trigger_processor_attach_game_effect__eid != INVALID_ENTITY_ID
      return
    game_trigger_processor_attach_game_effect__eid = createEntity(game_trigger_processor_attach_game_effect__template) <| $(var init)
      set(init, "game_effect__attachedTo", entity)
  elif evt.triggerHash == game_trigger_processor_attach_game_effect__removeOnTriggerHash
    destroyEntity(game_trigger_processor_attach_game_effect__eid)
    game_trigger_processor_attach_game_effect__eid = INVALID_ENTITY_ID


[es(on_appear)]
def game_trigger_appear(evt : Event; eid : EntityId; game_trigger_appear__emitEvent : string)
  broadcast_net_event(EventGameTrigger(source = eid, triggerHash = int(ecs_hash(game_trigger_appear__emitEvent))))


[es(on_disappear)]
def game_trigger_disappear(evt : Event; eid : EntityId; game_trigger_disappear__emitEvent : string)
  broadcast_net_event(EventGameTrigger(source = eid, triggerHash = int(ecs_hash(game_trigger_disappear__emitEvent))))


[es(tag=server)]
def game_trigger_use(evt : CmdUse; eid : EntityId; game_interactable_object__eventTrigger : string)
  broadcast_net_event(EventGameTrigger(source = eid, triggerHash = int(ecs_hash(game_interactable_object__eventTrigger))))
