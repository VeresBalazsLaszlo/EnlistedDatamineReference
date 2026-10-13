from "%dngscripts/globalState.nut" import globalWatched

let {userInfo, userInfoUpdate} = globalWatched("userInfo")
let {userPermissions, userPermissionsUpdate} = globalWatched("userPermissions", @() {})

return freeze({userInfo, userInfoUpdate, userPermissions, userPermissionsUpdate})
