from "%ui/eula/eulaWnd.nut" import showEula
from "%ui/eula/eulaState.nut" import isNoVersion, getVersion, getAcceptedConfigVersion,
  setAcceptedConfigVersion
from "%ui/ui_library.nut" import *

function action(_login_status, cb) {
  function cbAccept(_) {
    setAcceptedConfigVersion()
    cb({})
  }

  let acceptedVersion = getAcceptedConfigVersion()
  log($"EULA config version {acceptedVersion}")
  if (isNoVersion(acceptedVersion)) {
    showEula(cbAccept, false, true)
    return
  }

  let eulaVersion = getVersion()
  log($"Current EULA version {eulaVersion}")
  if (eulaVersion != acceptedVersion) {
    showEula(cbAccept, true, true)
    return
  }

  cb({})
}

return {
  id = "eula_before_login"
  action
}