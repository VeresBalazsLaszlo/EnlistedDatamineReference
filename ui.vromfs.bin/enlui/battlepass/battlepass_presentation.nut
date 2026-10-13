from "%ui/ui_library.nut" import *

const bpColors = [0xFFD04B2C, 0xFF31DDED, 0xFFC5EA2D, 0xFFF57E32]
const bpBgColors = [0xFFDA532C, 0xFF00C3FE, 0xFF6CB934, 0xFFD7762E]

let battlePassPresentation = freeze({
  
  
  
  
  
  
  
  

  [17] = {
    bgColor = 0xFF00C3FE
    starColor = 0xFF31DDED
  },
  [18] = {
    bgColor = 0xFF00C3FE
    starColor = 0xFF31DDED
    taskColor = 0xFF31DDED
  },
  [19] = {
    bgColor = 0xFF6CB934
    starColor = 0xFFC5EA2D
    taskColor = 0xFFC5EA2D
  },
  [20] = {
    bgColor = 0xFF6CB934
    starColor = 0xFFC5EA2D
    taskColor = 0xFFC5EA2D
  },
  [21] = {
    bgColor = 0xFFDA532C
    starColor = 0xFFD04B2C
    taskColor = 0xFFD04B2C
  },
  [22] = {
    bgColor = 0xFFDA532C
    starColor = 0xFFD04B2C
    taskColor = 0xFFD04B2C
  },
  [23] = {
    bgColor = 0xFFD7762E
    starColor = 0xFFF57E32
    taskColor = 0xFFF57E32
  },
  [24] = {
    bgColor = 0xFFD7762E
    starColor = 0xFFF57E32
    taskColor = 0xFFF57E32
  },
  [25] = {
    bgColor = 0xFF00C3FE
    starColor = 0xFF31DDED
    taskColor = 0xFF31DDED
  },
  [26] = {
    bgColor = 0xFF00C3FE
    starColor = 0xFF31DDED
    taskColor = 0xFF31DDED
  },
  [27] = {
    bgColor = 0xFF00C3FE
    starColor = 0xFF31DDED
    taskColor = 0xFF31DDED
  },
  [28] = {
    bgColor = 0xFF6CB934
    starColor = 0xFFC5EA2D
    taskColor = 0xFFC5EA2D
  },
  [29] = {
    bgColor = 0xFF6CB934
    starColor = 0xFFC5EA2D
    taskColor = 0xFFC5EA2D
  },
  [30] = {
    bgColor = 0xFF6CB934
    starColor = 0xFFC5EA2D
    taskColor = 0xFFC5EA2D
  },
  [31] = {
    bgColor = 0xFFDA532C
    starColor = 0xFFD04B2C
    taskColor = 0xFFD04B2C
  },
  [32] = {
    bgColor = 0xFFDA532C
    starColor = 0xFFD04B2C
    taskColor = 0xFFD04B2C
  },
  [33] = {
    bgColor = 0xFFD7762E
    starColor = 0xFFF57E32
    taskColor = 0xFFF57E32
  },
  [34] = {
    bgColor = 0xFFD7762E
    starColor = 0xFFF57E32
    taskColor = 0xFFF57E32
  }
})

function getBpPresentation(index) {
  let { bgColor = null, starColor = null, icon = null,
    taskColor = null } = battlePassPresentation?[index] ?? {}

  let color = bpColors[index % bpColors.len()]
  return {
    bgColor = bgColor ?? bpBgColors[index % bpBgColors.len()]
    starColor = starColor ?? color
    icon
    taskColor = taskColor ?? color
  }
}

return {
  getBpPresentation
}
