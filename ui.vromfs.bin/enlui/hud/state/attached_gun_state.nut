import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let attachedGun = mkEcsComputed({
  comps = [
    ["human_attached_gun__attachedGunEid", ecs.TYPE_EID],
    ["human_attached_gun__attachedGunAmmo", ecs.TYPE_INT]
  ]
  comps_rq = ["hero"]
})

let isAttachedToGun = Computed(@()
  (attachedGun.get()?.human_attached_gun__attachedGunEid ?? ecs.INVALID_ENTITY_ID) != ecs.INVALID_ENTITY_ID)
let attachedGunCurAmmo = Computed(@() attachedGun.get()?.human_attached_gun__attachedGunAmmo ?? 0)

return {
  isAttachedToGun
  attachedGunCurAmmo
}
