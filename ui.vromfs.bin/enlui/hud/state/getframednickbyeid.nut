import "%dngscripts/ecs.nut" as ecs
from "%ui/components/decoratorsPresentation.nut" import frameNick
from "%ui/helpers/remap_nick.nut" import remap_others

let getPlayerNickAndFrameQuery = ecs.SqQuery("getPlayerNickAndFrame",
  { comps_ro = [
      ["name", ecs.TYPE_STRING],
      ["decorators__nickFrame", ecs.TYPE_STRING],
    ]
  })

let getFramedNickByEid = @(playerEid, needHarmonize = false)
  getPlayerNickAndFrameQuery.perform(playerEid,
    @(_eid, comp) frameNick(remap_others(comp.name, needHarmonize), comp["decorators__nickFrame"]))

return getFramedNickByEid