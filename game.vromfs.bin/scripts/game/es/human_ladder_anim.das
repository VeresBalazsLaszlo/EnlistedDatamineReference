require ecs
require game.es.events
require AnimV20
require GeomNodeTree
require EffectorData
require PhysVars
require math.base
require DagorMath
require DagorMathUtils
require enlisted.events_enlisted


[es(tag=gameClient, REQUIRE=human_on_ladder_animation, after=update_phys_es, before=animchar_es)]
def human_ladder_update_animation(info : ParallelUpdateFrameDelayed;
                                  game_effect__attachedTo : EntityId)
  assume attachedTo = game_effect__attachedTo
  query(attachedTo) <| $ [es(REQUIRE_NOT=deadEntity)] (human_anim__ladderProgressVarId : int;
                                                       var animchar_effectors__effectorsState : Object;
                                                       human_ladder__ladderTm : float3x4&;
                                                       human_ladder__numSteps : int;
                                                       transform : float3x4&;
                                                       var phys_vars : PhysVars;
                                                       human_anim__ladder__handToLegsOffset : float3&;
                                                       human_anim__ladder__effectorOffset : float3&;
                                                       animchar__visible : bool = true;
                                                       human_ladder__attached : bool;
                                                       animchar__actWhenInvisible = false;
                                                       human_anim__ladder__handSidesOffset : float  = 0.35f)
    if (!animchar__visible && !animchar__actWhenInvisible) || !human_ladder__attached
      return
    var rightHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "r.hand")
    var leftHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "l.hand")

    let d_wofs = geomtree_calc_optimal_wofs(transform[3])
    let ladderItm = inverse(human_ladder__ladderTm)
    let ladderZScale = length(human_ladder__ladderTm[2])
    let ladderZSign = sign(dot(human_ladder__ladderTm[2], transform[2]))
    let ladderWidth = length(human_ladder__ladderTm[0])
    let ladderUp = normalize(human_ladder__ladderTm[1])
    let tempDir = human_ladder__ladderTm[3] - transform[3]
    let toLadderDir = normalize(basis_aware_x0z(tempDir, ladderUp))
    let lhandZposInLadderTransform = ladderZSign * human_anim__ladder__handSidesOffset * safeinv(ladderZScale) * 0.5f
    let rhandZposInLadderTransform = -ladderZSign * human_anim__ladder__handSidesOffset * safeinv(ladderZScale) * 0.5f
    let topHandPos = transform[3] + human_anim__ladder__handToLegsOffset + ladderWidth / 2.f * toLadderDir
    let posInLadderTransform = ladderItm * topHandPos
    let vertPosInLadderTransform = posInLadderTransform.y + 0.5f// 0.5 basis
    var ladderProgress = vertPosInLadderTransform * float(human_ladder__numSteps - 1) * 0.5f // 1 cycle - 4 steps

    let step = safeinv(float(human_ladder__numSteps - 1))
    let rHandPos = float3(0.f, (floor(ladderProgress) * 2.f + 1.f) * step - 0.5f, rhandZposInLadderTransform)
    let lHandPos = float3(0.f, (floor(ladderProgress) * 2.f) * step - 0.5f, lhandZposInLadderTransform)

    ladderProgress -= floor(ladderProgress)
    setVar(phys_vars, human_anim__ladderProgressVarId, ladderProgress)

    var normLadderTm = human_ladder__ladderTm
    if posInLadderTransform.x < 0.f
      normLadderTm[0] = -normLadderTm[0]
    orthonormalize(normLadderTm)
    let worldOffset = normLadderTm |> rotate(human_anim__ladder__effectorOffset)

    var tm = IDENT_TM
    tm[0] = normLadderTm[1]
    tm[2] = transform[2]
    tm[1] = -cross(tm[2], tm[0])

    rightHandEffector.position = human_ladder__ladderTm * rHandPos - d_wofs + worldOffset
    rightHandEffector.wtm = tm
    rightHandEffector.wtm[3] = rightHandEffector.position
    rightHandEffector.weight = saturate(2.f * sin((ladderProgress - 0.5f) * TWOPI))

    leftHandEffector.position = human_ladder__ladderTm * lHandPos - d_wofs + worldOffset
    leftHandEffector.wtm = tm
    leftHandEffector.wtm[3] = leftHandEffector.position
    leftHandEffector.weight = saturate(2.f * sin(ladderProgress * TWOPI))


[es(tag=gameClient, track=human_ladder__attached)]
def human_ladder_end_animation(evt : Event;
                               human_ladder__attached : bool;
                               var animchar_effectors__effectorsState : Object)
  if !human_ladder__attached
    var rightHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "r.hand")
    var leftHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "l.hand")

    rightHandEffector.weight = 0.f
    leftHandEffector.weight = 0.f