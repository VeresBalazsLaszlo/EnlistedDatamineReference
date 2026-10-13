require ecs
require game.utils.team

[es(tag=server, on_appear, before=weap_anim_shield_creator)]
def weap_anim_shield_init_state(evt : Event;
                                customProps : Object;
                                var weap_anim__gunShieldDead : bool&)
  let gunInitComps = customProps["initialComponents"] |> get_ecs_object()
  if gunInitComps != null && has(*gunInitComps, "weap_anim__gunShieldDead")
    weap_anim__gunShieldDead = get_bool(*gunInitComps, "weap_anim__gunShieldDead") ?? false

[es(tag=server, on_appear)]
def weap_anim_shield_creator(evt : Event;
                             eid : EntityId;
                             weap_anim__gunShieldTeamplate : string;
                             var weap_anim__gunShieldEid : EntityId&;
                             item__ownedByTeam : int = TEAM_UNASSIGNED;
                             gun__owner : EntityId = INVALID_ENTITY_ID;
                             weap_anim__gunShieldDead : bool = false)
  if !!weap_anim__gunShieldEid || weap_anim__gunShieldDead
    return
  let shieldTeam = get_int(gun__owner, "team") ?? item__ownedByTeam
  weap_anim__gunShieldEid = createEntity(weap_anim__gunShieldTeamplate) <| $(var init : ComponentsInitializer)
    set(init, "team", shieldTeam)
    set(init, "animchar_attach__attachedTo", eid)

[es(tag=server, on_disappear)]
def weap_anim_shield_destroyer(evt : Event;
                               weap_anim__gunShieldEid : EntityId)
  if !!weap_anim__gunShieldEid
    destroyEntity(weap_anim__gunShieldEid)

[es(tag=server, on_event=EventEntityDied)]
def weap_save_shield_destroyed(evt : Event;
                               animchar_attach__attachedTo : EntityId)
  query(animchar_attach__attachedTo) <| $ [es] (var weap_anim__gunShieldDead : bool&)
    weap_anim__gunShieldDead = true