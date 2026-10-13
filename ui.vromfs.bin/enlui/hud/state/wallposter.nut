import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let localPlayerWallPosters = mkEcsComputed({
  comps = [
    ["wallPosters__maxCount", ecs.TYPE_INT],
    ["wallPosters__curCount", ecs.TYPE_INT],
    ["wallPoster__preview", ecs.TYPE_BOOL],
    ["wallPosters", ecs.TYPE_ARRAY]
  ]
  comps_rq = ["player"]
  comps_filter = [["is_local", ecs.TYPE_BOOL]] 
  filter = "is_local"
})

let wallPostersMaxCount = Computed(@() localPlayerWallPosters.get()?.wallPosters__maxCount ?? 0)
let wallPostersCurCount = Computed(@() localPlayerWallPosters.get()?.wallPosters__curCount ?? 0)
let wallPosterPreview = Computed(@() localPlayerWallPosters.get()?.wallPoster__preview ?? false)

let wallPosters = Computed(@() (localPlayerWallPosters.get()?.wallPosters ?? []).map(@(p) p.template))

return {
  wallPostersMaxCount
  wallPostersCurCount
  wallPosterPreview
  wallPosters
}