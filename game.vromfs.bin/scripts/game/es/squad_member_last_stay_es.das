require ecs
require app
require math.base

[es(tag=server, no_order)]
def squad_member_last_stay_es(act : UpdateStageInfoAct;
                              transform : float3x4;
                              var squad_member__lastStayTime : float&;
                              var squad_member__lastStayPos : float3&;
                              var squad_member__lastStayDir : float2&;
                              squad_member__lastStayDirCoef : float;
                              squad_member__lastStayTimeout : float;
                              squad_member__lastStayRange : float;
                              var squad_member__lastStayNewDirTime : float&;
                              var squad_member__lastStayNewDir : float2&)
  let curTime = get_sync_time()
  assume pos = transform[3]
  assume dir = normalize(transform[0].xz)

  if squad_member__lastStayTime < 0.0 || distance_sq(pos, squad_member__lastStayPos) > square(squad_member__lastStayRange)
    squad_member__lastStayTime = curTime
    squad_member__lastStayPos = pos
    squad_member__lastStayDir = dir
    squad_member__lastStayNewDirTime = -1.0
    return

  if dot(dir, squad_member__lastStayDir) > squad_member__lastStayDirCoef
    squad_member__lastStayNewDirTime = -1.0
    return

  if squad_member__lastStayNewDirTime < 0.0 || dot(dir, squad_member__lastStayNewDir) < squad_member__lastStayDirCoef
    squad_member__lastStayNewDirTime = curTime
    squad_member__lastStayNewDir = dir
    return

  if curTime - squad_member__lastStayNewDirTime > squad_member__lastStayTimeout
    squad_member__lastStayTime = curTime
    squad_member__lastStayPos = pos
    squad_member__lastStayDir = dir
    squad_member__lastStayNewDirTime = -1.0
