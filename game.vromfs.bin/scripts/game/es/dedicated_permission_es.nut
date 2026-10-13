import "%dngscripts/ecs.nut" as ecs
let isDedicated = require_optional("dedicated") != null
let {disableRemoteNetServices} = require("%enlSqGlob/offline_mode.nut")
let {isInternalCircuit} = require("%enlSqGlob/appInfo.nut")
let {readPermissions} = require("%enlSqGlob/permission_utils.nut")
let {has_network, INVALID_CONNECTION_ID} = require("net")
let {find_human_player_by_connid, find_local_player} = require("%dngscripts/common_queries.nut")
let {debug} = require("dagor.debug")
let { EventSqDedicatedPermissions, mkEventSqDedicatedPermissions } = require("%enlSqGlob/sqevents.nut")

const LOCAL_PERM = "local."

let permissions = {}


function hasDedicatedPermission(userid, permission) {
  if (isInternalCircuit.get() || disableRemoteNetServices)
    return true

  let userPermissions = permissions?[userid].value ?? []
  return userPermissions.contains(permission) ||
    (!isDedicated && userPermissions.contains($"{LOCAL_PERM}{permission}"))
}


ecs.register_es("read_dedicated_permissions",
  {
    [EventSqDedicatedPermissions] = function(evt,eid,comp){
      let senderEid = has_network()
          ? find_human_player_by_connid(evt.data?.fromconnid ?? INVALID_CONNECTION_ID)
          : find_local_player()

      if (senderEid!=eid)
        return

      if (comp.userid <= 0)
        return

      let userPermissions = readPermissions(evt.data.jwt, comp.userid)
      let userPermissionsStr = ", ".join(userPermissions?.value ?? [])
      debug($"Read dedicated permissions: [{userPermissionsStr}] for user {comp.userid}")
      permissions[comp.userid] <- userPermissions
    }
  },
  {
    comps_rq=["player"],
    comps_ro = [["userid", ecs.TYPE_UINT64]]
  },
  {tags = "server"}
)


if (!isDedicated) { 
  let userInfo = require("%enlSqGlob/userInfo.nut")
  let {userPermissions} = require("%enlSqGlob/userInfoState.nut")
  ecs.register_es("send_dedicated_permissions",
    {
      [["onInit", "onChange"]] = function(eid, comp) {
        if (!comp.is_local)
          return

        let { dedicatedPermJwt = null } = userPermissions.get()
        if (dedicatedPermJwt == null)
          return

        debug($"Send dedicated permissions for user: {userInfo.get().userId}")
        ecs.client_send_event(eid, mkEventSqDedicatedPermissions({jwt = dedicatedPermJwt}))
      }
    },
    {
      comps_rq=["player"],
      comps_track = [["connid",ecs.TYPE_INT], ["is_local", ecs.TYPE_BOOL]]
    },
    {tags = "gameClient"}
  )
}


return {hasDedicatedPermission}
