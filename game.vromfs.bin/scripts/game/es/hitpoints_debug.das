options no_aot
require ecs
require ecs.common
require game.utils.hero
require game.es.net_console_macro

def set_hp_for_eid(eid : EntityId; value : float)
  query(eid) <| $ [es] (var hitpoints__hp : float&)
    hitpoints__hp = value

def set_no_burning_for_eid(eid : EntityId)
  if has(eid, "human__disableBurning")
    return
  remote_add_sub_template(eid, "human_disable_burning")

[net_console_cmd(name="hitpoints.set_hero_hp")]
def set_hero_hp(value : float; @net_hero eid : EntityId)
  set_hp_for_eid(eid, value)

[net_console_cmd(name="hitpoints.set_hero_maxhp")]
def set_hero_maxhp(value : float; @net_hero eid : EntityId)
  query(eid) <| $ [es] (var set_hero_maxhp : float&)
    set_hero_maxhp = value

[net_console_cmd(name="hitpoints.set_hero_downed")]
def set_hero_downed(@net_hero eid : EntityId)
  query(eid) <| $ [es] (var hitpoints__hp : float&; var hitpoints__alwaysAllowRevive : bool&)
    hitpoints__hp = 0f
    hitpoints__alwaysAllowRevive = true

[net_console_cmd(name="hitpoints.set_hero_downed_timed", hint="Down hero with a set timer and no HP drain. Disable death chance on down.")]
def set_hero_downed_long(time : float = 1500.0; @net_hero hero_eid : EntityId)
  query(hero_eid) <| $ [es] (var hitpoints__hp : float&;
                             var hitpoints__downedTimer : float&;
                             var hitpoints__downedKillChanceBase : float&;
                             var hitpoints__downedKillChanceMult : float&;
                             var hitpoints__downedHpPerSecond : float&;
                             var hitpoints__alwaysAllowRevive : bool&)
    hitpoints__downedKillChanceBase = 0.0
    hitpoints__downedKillChanceMult = 0.0
    hitpoints__downedHpPerSecond = 0.0
    hitpoints__downedTimer = time
    hitpoints__hp = 0f
    hitpoints__alwaysAllowRevive = true

[net_console_cmd(name="hitpoints.hero_god_mode")]
def hero_god_mode(@net_hero eid : EntityId)
  set_hp_for_eid(eid, 999999f)
  set_no_burning_for_eid(eid)

[net_console_cmd(name="hitpoints.squad_god_mode")]
def squad_god_mode(@net_hero eid : EntityId)
  set_hp_for_eid(eid, 999999f)
  set_no_burning_for_eid(eid)
  query(eid) <| $ [es] (squad_member__squad aka hero_squad_member__squad : EntityId)
    if hero_squad_member__squad != INVALID_ENTITY_ID
      query() <| $ [es] (squad_member__squad aka unit_squad_member__squad : EntityId; var hitpoints__hp : float&)
        if hero_squad_member__squad == unit_squad_member__squad
          hitpoints__hp = 999999f

[net_console_cmd(name="hitpoints.god_mode_everyone")]
def hero_god_mode_all()
  query() <| $ [es] (var hitpoints__hp : float&)
    hitpoints__hp = 999999f
