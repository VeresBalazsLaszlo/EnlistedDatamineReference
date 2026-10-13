let { getExp } = require("%scripts/game/expScoringValues.nut")
let { round } = require("math")

let calcScore = @(comp, scoreMode) round(getExp(scoreMode)
  .reduce(@(sum, score, key) sum + score * (comp?[$"scoring_player__{key}"] ?? 0), 0))

return calcScore