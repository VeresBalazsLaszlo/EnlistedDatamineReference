module paratroopers_supply_box_common shared
require ecs
require ecs.safe
require ecs.common
require game.utils.team
require DagorSystem

def push_valid(var list : StringList; val : string)
  if !empty(val)
    list |> push(val)

def private gather_preset_templates(preset : Object const?; var deps_list : StringList&)
  let soldiers = preset?.soldiers ?as Array
  if soldiers == null
    return
  for soldierObj in *soldiers
    let soldier = soldierObj as Object
    let weapTemplates = soldier?.human_weap__weapTemplates ?as Object
    if weapTemplates != null
      for it in *weapTemplates
        deps_list |> push_valid(it.value ?? "")
    let weapInfos = soldier?.human_weap__weapInfo ?as Array
    if weapInfos != null
      for it in *weapInfos
        let weapInfo = it as Object
        deps_list |> push_valid(weapInfo?.reserveAmmoTemplate ?? "")
        let additionalAmmoTemplates = weapInfo?.additionalReserveAmmoTemplates ?as Array
        if additionalAmmoTemplates != null
          for ammoTemplateItem in *additionalAmmoTemplates
            deps_list |> push_valid(ammoTemplateItem ?? "")

def private gather_supply_box_dependencies(squad : EntityId; var res : StringList)
  var squadFound = false
  var presetsNotFoundError = ""
  query(squad) <| $ [es] (squad__squadProfileId : string)
    squadFound = true
    query() <| $ [es] (paratroopers__supplySchemes : Object; paratroopers__supplySchemesAndSquads : Object)
      let presets = paratroopers__supplySchemes[paratroopers__supplySchemesAndSquads[squad__squadProfileId] ?? "default"] ?as Array
      if presets == null
        presetsNotFoundError = "gather_supply_box_dependencies: no presets found for /*{squad__squadProfileId}*/ or default in /*{paratroopers__supplySchemes}*/ of squad (/*{squad}*/) /*{getEntityTemplateName(squad)}*/"
        return
      for it in *presets
        gather_preset_templates(it as Object, res)

  if !squadFound
    logerr("gather_supply_box_dependencies: squad query failed (/*{squad}*/) /*{getEntityTemplateName(squad)}*/")
    return

  if presetsNotFoundError != ""
    logerr(presetsNotFoundError)
    return

def spawn_supply_box(template_name : string; pos : float3; squad : EntityId; velocity : float3; landing_pos : float2; team : int; aircraft_eid : EntityId; is_supply : bool)
  createEntity(template_name) <| $(var init : ComponentsInitializer)
    var transform : float3x4
    identity(transform)
    transform[3] = pos
    init |> set("transform", transform)
    init |> set("team", team)
    init |> set("supply_box__initVel", velocity)
    init |> set("supply_box__squad", squad)
    init |> set("human_parachute_wind__landingPoint", landing_pos)

    if !!aircraft_eid
      using() <| $(var skipCollisions : EidList)
        skipCollisions |> push(aircraft_eid)
        init |> set("collidable_ignore_list", skipCollisions)

    if is_supply
      query(squad) <| $ [es] (squad__leader : EntityId; squad__ownerPlayer : EntityId)
        init |> set("buildByPlayer", squad__ownerPlayer)
        init |> set("buildByEngineerEid", squad__leader)
    else
      using() <| $(var deps : StringList)
        gather_supply_box_dependencies(squad, deps)
        if length(deps) != 0
          init |> set("supply_box__template_deps_list", deps)
        else
          let squadId = get_string(squad, "squad__squadProfileId", "")
          var curBr = ""
          find_query() <| $ [es] (matching_info__engineerBuildingsLevel : string)
            curBr = matching_info__engineerBuildingsLevel
            return true
          logerr("Empty paratroopers supply scheme for squad /*{squadId}*/, squad eid /*{squad}*/, match BR /*{curBr}*/")
