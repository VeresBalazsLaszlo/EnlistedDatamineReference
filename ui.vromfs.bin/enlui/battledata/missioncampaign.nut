import "%dngscripts/ecs.nut" as ecs

let missionCampaignQuery = ecs.SqQuery("missionCampaignQuery", {comps_ro=[["mission_campaign", ecs.TYPE_STRING]]})
let getCampaignOutfit = @() missionCampaignQuery.perform(@(_, comp) comp.mission_campaign)

return {
  getCampaignOutfit
}
