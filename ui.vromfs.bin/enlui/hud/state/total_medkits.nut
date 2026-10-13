import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

const selfHealMedkitsDefValue = 0

let selfHealMedkits = mkEcsComputed({
  comps = [["total_kits__selfHeal", ecs.TYPE_INT]]
  comps_rq = ["watchedByPlr"]
  defVal = selfHealMedkitsDefValue
})

return {selfHealMedkits}
