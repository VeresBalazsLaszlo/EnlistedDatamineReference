from "%ui/eula/eulaWnd.nut" import showEula
from "%ui/eula/eulaState.nut" import isNoVersion, getVersion, getAcceptedConfigVersion,
  getAcceptedOnlineVersion, setAcceptedOnlineVersion
from "%ui/ui_library.nut" import *

const EULA_ENABLED = true

function action(_login_status, cb) {
  if (!EULA_ENABLED) {
    log("EULA check disabled")
    cb({})
    return
  }

  function cbAccept(accept) {
    if (accept) {
      setAcceptedOnlineVersion()
      cb({})
    }
    else
      cb({ stop = true })
  }

  local acceptedVersion = getAcceptedConfigVersion()
  log($"EULA config version {acceptedVersion}")
  if (isNoVersion(acceptedVersion)) {
    acceptedVersion = getAcceptedOnlineVersion()
    log($"EULA online version {acceptedVersion}")
  }
  if (isNoVersion(acceptedVersion)) {
    showEula(cbAccept, false)
    return
  }

  let eulaVersion = getVersion()
  log($"Current EULA version {eulaVersion}")
  if (eulaVersion != acceptedVersion) {
    showEula(cbAccept, true)
    return
  }

  cb({})
}

return {
  id = "eula"
  action
}