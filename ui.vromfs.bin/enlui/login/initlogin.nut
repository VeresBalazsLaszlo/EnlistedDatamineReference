import "%dngscripts/platform.nut" as platform
import "%ui/state/dmm_distr.nut" as isDmmDistr
from "%enlSqGlob/offline_mode.nut" import disableRemoteNetServices
from "%ui/login/currentLoginUi.nut" import getCurrentLoginUi, setCurrentLoginUi
from "dagor.system" import get_arg_value_by_name
from "%ui/login/chineseKongZhongVersion.nut" import isKZVersion
from "%ui/ui_library.nut" import *

if (getCurrentLoginUi() == null) { 
  if (disableRemoteNetServices)
    setCurrentLoginUi(require("%ui/login/ui/fake.nut"))
  else if (platform.is_gdk)
    setCurrentLoginUi(require("%ui/login/ui/xbox.nut"))
  else if (platform.is_sony)
    setCurrentLoginUi(require("%ui/login/ui/sony.nut"))
  else {
    let steam = require("steam")
    let wegame = require("wegame")
    let gfn = require("gfn")
    let isDMMLogin = get_arg_value_by_name("dmm_user_id") != null

    function updatePcComp() {
      if (isDmmDistr && !isDMMLogin)
        setCurrentLoginUi(require("%ui/login/ui/dmmRequire.nut"))
      else if (isDMMLogin)
        setCurrentLoginUi(require("%ui/login/ui/dmm.nut"))
      else if (steam.is_running())
        setCurrentLoginUi(require("%ui/login/ui/steam.nut"))
      else if (wegame.is_running())
        setCurrentLoginUi(require("%ui/login/ui/wegame.nut"))
      else if (gfn.is_running())
        setCurrentLoginUi(require("%ui/login/ui/gfn.nut"))
      else if (isKZVersion) {
        let kzToken = get_arg_value_by_name("wf-token")
        if (kzToken)
          setCurrentLoginUi(require("%ui/login/ui/kzLoginToken.nut"))
        else
          require("%ui/login/ui/kzLoginBrowser.nut")()
      }
      else
        setCurrentLoginUi(require("%ui/login/ui/go.nut"))
    }

    updatePcComp()
  }
}
