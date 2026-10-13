module shell_events shared
require ecs
require DaWeaponProps

[cpp_event(unicast, with_sheme, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdShellExplodeClient
  pos : float3
  offsetedPos : float3
  shellVelocity : float3
  shellId : ShellPropIds
  gunPropsId : int
  offender : EntityId
  explVictim : EidList
  explDamageAndFatal : UInt8List
  fxInfoEid : EntityId