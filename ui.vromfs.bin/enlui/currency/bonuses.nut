from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/ui_library.nut" import *

return {
  bonusesList = mkComputedConfigGet("game_bonuses", {})
}
