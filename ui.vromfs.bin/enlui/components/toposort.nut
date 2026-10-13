from "dagor.debug" import logerr









function toEdges(prioTbl) {
  let res = []
  foreach (after, before in prioTbl) {
    foreach (node in before)
      res.append([after, node])
  }
  return res
}

let getIncomingEdges = @(node, edges) edges.filter(@(edge) edge[0] == node)
let getOutgoingEdges = @(node, edges) edges.filter(@(edge) edge[1] == node)

let getEndings = @(edges) edges.reduce(function(res, edge) {
    res[edge[1]] <- true
    return res
  }, {})

function tSort(elements, priorities) {
  let topNodes = {}
  foreach (node, _ in elements) {
    let p = priorities?[node]
    if (p != null && p.len() == 0)
      topNodes[node] <- true
  }

  let edges = toEdges(priorities)
  let endingsTbl = getEndings(edges)
  let singleNodesTbl = elements.filter(@(_, node)
    (node not in endingsTbl) && (node not in priorities))

  let toProcess = endingsTbl.reduce(function(res, _, node) {
      if (node not in priorities || node in topNodes)
        res.append(node)
      return res
    }, [])

  let sortedNodes = []
  while (toProcess.len() > 0) {
    let node = toProcess.pop()
    if (node not in topNodes)
      sortedNodes.append(node)
    singleNodesTbl.$rawdelete(node)

    let outEdges = getOutgoingEdges(node, edges)

    foreach (edge in outEdges) {
      edges.remove(edges.indexof(edge))

      let [connectedNode] = edge
      let incEdges = getIncomingEdges(connectedNode, edges)

      if (incEdges.len() == 0)
        toProcess.append(connectedNode)
    }
  }

  if (edges.len() > 0)
    logerr("Error: the node graph has cycles")

  return [].extend(topNodes.keys(), sortedNodes, singleNodesTbl.keys())
}

return { tSort }
