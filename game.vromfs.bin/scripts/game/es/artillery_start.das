require ecs
require ecs.safe
require math
require math.base
require DagorMath
require Dacoll
require DngNet
require game.es.events
require game.utils.team
require DagorSystem
require enlisted.game.es.artillery_radio_common
require enlisted.events_enlisted
require game.events_game
require game.es.paratroopers_common
require app


def calc_artillery_source_pos(owner : EntityId; target_pos : float3; artillery__sourceDistOffset : float; artillery__sourceHeightOffset : float)
  var count = 0.0
  var pos = float3()
  ecs::query(owner) <| $ [es] (team : int)
    let ownerTeam = team
    ecs::query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=customRespawnBase)] (active : bool; team : int; respawnbaseType : string; transform : float3x4)
      if !active || (team != ownerTeam && team != TEAM_UNASSIGNED) || respawnbaseType != "human"
        return
      count += 1.0
      pos += transform[3]

  if count == 0.0
    logwarn("no respawn base for calc_artillery_source_pos")
    pos =  float3(0.0, 0.0, 0.0)
    count = 1.0

  pos *= rcp(count)

  var dir = (pos - target_pos).xz
  dir = normalize_default(dir, float2(1, 1)) * artillery__sourceDistOffset
  return target_pos + float3(dir.x, artillery__sourceHeightOffset, dir.y)


def calc_artillery_target_pos(eid : EntityId; var result : float3&) : bool
  let aimTm = deref(get_TMatrix(eid, "human__aimTm"))

  var len = 200.0
  var norm : float3
  if traceray_normalized(aimTm[3], aimTm[0], len, norm)
    result = aimTm[3] + aimTm[0] * len
    return true

  return false


def artillery_start(tpl_name : string; offender, owner_player : EntityId; by_team : int; source_pos, target_pos, target_pos_end : float3; is_artillery_box : bool)
  let templ = tpl_name + (is_artillery_box ? "+artillery_from_box" : "")
  let callerName = get_string(owner_player, "name", "")
  let artilleryEid = createEntity(templ) <| $(var init : ComponentsInitializer)
    set(init, "artillery__offender", offender)
    set(init, "artillery__callerEid", owner_player)
    set(init, "artillery__calledByTeam", by_team)
    set(init, "artillery__sourcePos", source_pos)
    set(init, "artillery__targetPos", target_pos)
    set(init, "artillery__targetPosEnd", target_pos_end)
  debug("Artillery created eid - {artilleryEid}, templ - {templ}, caller - {callerName}")

[es(tag=server, on_appear, before=artillery_strike_es)]
def artillery_strike_validate_line_length(evt : Event;
                                          artillery__maxLineLength : float;
                                          artillery__targetPos : float3;
                                          var artillery__targetPosEnd : float3&)
  var dir = artillery__targetPosEnd.xz - artillery__targetPos.xz
  let lenSq = length_sq(dir)
  if lenSq > 0.0 && lenSq > artillery__maxLineLength * artillery__maxLineLength
    dir *= (artillery__maxLineLength / sqrt(lenSq))
    artillery__targetPosEnd = artillery__targetPos + float3(dir.x, 0.0, dir.y)

[es(tag=server)]
def artillery_strike_start_at_pos_es(evt : CmdStartArtilleryStrikeAtPos;
                                     eid : EntityId;
                                     artillery__templates : StringList;
                                     name : string = "";
                                     possessed : EntityId = INVALID_ENTITY_ID;
                                     team : int)
  let artilleryBox = get_Eid(possessed, "human_use_object__artilleryBox") ?? INVALID_ENTITY_ID
  var artilleryTemplate = getTemplateByName("")
  var artilleryTemplateName = ""
  if !!artilleryBox
    query(artilleryBox) <| $ [es] (artillery_box__artilleryTemplates1 : StringList;
                                   artillery_box__artilleryTemplates2 : StringList;
                                   var artillery_box__availableTime : float&;
                                   artillery_box__cooldown : float)
      artilleryTemplateName = string((team == 1 ? artillery_box__artilleryTemplates1 : artillery_box__artilleryTemplates2)[evt.typeIndex])
      artilleryTemplate = getTemplateByName(artilleryTemplateName)
      if artilleryTemplate != null
        artillery_box__availableTime = get_sync_time() + artillery_box__cooldown
    if artilleryTemplate == null
      logerr("Artillery template /*{artilleryTemplateName}*/ not exist, box artillery, player {name}")
      return
  else
    if evt.typeIndex < 0 || evt.typeIndex >= length(artillery__templates)
      logerr("CmdStartArtilleryStrikeAtPos has out of bounds index /*{evt.typeIndex}*/ of /*{length(artillery__templates)}*/ templates, player {name}")
      return

    artilleryTemplateName = string(artillery__templates[evt.typeIndex])
    artilleryTemplate = getTemplateByName(artilleryTemplateName)
    if artilleryTemplate == null
      logerr("Artillery template /*{artilleryTemplateName}*/ not exist, player {name}")
      return

    let group = getTemplateComponent(*artilleryTemplate, "artillery__group") ?? 0
    if is_artillery_max_limit_reached_by_group(team, group)
      debug("Artillery limit reached /*{artilleryTemplateName}*/, player {name}")
      query(evt.owner) <| $ [es] (possessedByPlr : EntityId)
        send_net_event(possessedByPlr, CmdHeroLogEvent(event = "artillery", text = "artillery/team_limit_reached"))
      return

    artillery_change_limit(team, 1, group)

  if !!evt.owner
    send_net_event(evt.owner, CmdArtilleryStartSpeeches(ind = evt.typeIndex))
  let artilleryDistOffset = getTemplateComponent(*artilleryTemplate, "artillery__sourceDistOffset") ?? 100.
  let artilleryHeighOffset = getTemplateComponent(*artilleryTemplate, "artillery__sourceHeightOffset") ?? 70.
  artillery_start(artilleryTemplateName, evt.owner, eid, team, calc_artillery_source_pos(evt.owner, evt.pos, artilleryDistOffset, artilleryHeighOffset), evt.pos, evt.posEnd, !!artilleryBox)


[es(tag=server)]
def artillery_strike_start_delayed_es(evt : CmdStartDelayedArtilleryStrikeAtPos; eid : EntityId)
  createEntity("delayed_artillery_strike") <| $(var init)
    init |> set("delayed_artillery__playerEid", eid)
    init |> set("delayed_artillery__ownerEid", evt.owner)
    init |> set("delayed_artillery__typeIndex", evt.typeIndex)
    init |> set("delayed_artillery__pos", evt.pos)
    init |> set("delayed_artillery__posEnd", evt.posEnd)
    init |> set("delayed_artillery__delayTime", evt.delayTime)

[es(tag=server, no_order)]
def artillery_strike_update_delayed_es(info : UpdateStageInfoAct;
                                       eid : EntityId;
                                       delayed_artillery__playerEid : EntityId;
                                       delayed_artillery__ownerEid : EntityId;
                                       delayed_artillery__typeIndex : int;
                                       delayed_artillery__pos : float3;
                                       delayed_artillery__posEnd : float3;
                                       var delayed_artillery__delayTime : float&)
  delayed_artillery__delayTime -= info.dt
  if delayed_artillery__delayTime <= 0.0
    sendEvent(delayed_artillery__playerEid, CmdStartArtilleryStrikeAtPos(owner = delayed_artillery__ownerEid, pos = delayed_artillery__pos, typeIndex = delayed_artillery__typeIndex, posEnd = delayed_artillery__posEnd))
    destroyEntity(eid)

[es(tag=server, on_appear, REQUIRE=supplyArtillery)]
def create_supply_aircraft(evt : Event;
                           artillery__callerEid : EntityId;
                           artillery__baseCooldown : float;
                           artillery__targetPos : float3)
  create_paratroopers_aircraft(artillery__callerEid, artillery__targetPos, true/*supply*/)
  query(artillery__callerEid) <| $ [es] (var artillery__availableAtTime : float&)
    artillery__availableAtTime = get_sync_time() + artillery__baseCooldown
