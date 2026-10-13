require ecs
require DngNet
require rapidjson
require enlisted.events_enlisted

[es(tag=server, on_appear, on_event=EventLevelLoaded)]
def matching_info(evt : Event;
                  var teamsSlots : IntList&)
  teamsSlots |> clear()
  get_matching_invite_data() |> FindMember("teamsSlots", JsonType.kArrayType) <| $(teamsSlotsJson : JsonValue)
    teamsSlotsJson |> GetArray() <| $(teamsSlotsArray : JsonConstArray)
      for teamsSlot in teamsSlotsArray
        let slotsCount = json_value_or(teamsSlot, 0)
        teamsSlots |> push(slotsCount)

[es(tag=server, REQUIRE=player)]
def save_local_matching_info(evt : CmdSendArmyBr)
  query() <| $ [es] (matching_info__engineerBuildingsLevelReceived : bool;
                     var matching_info__engineerBuildingsLevel : das_string&)
    if !matching_info__engineerBuildingsLevelReceived
      matching_info__engineerBuildingsLevel := evt.armyBr < 3 ? "1_3" : "3_5"
      query() <| $ [es(REQUIRE=paratroopers__supplySchemesAndSquadsJson)] (eid : EntityId)
        sendEvent(eid, CmdUpdateParatroopersSchemes())