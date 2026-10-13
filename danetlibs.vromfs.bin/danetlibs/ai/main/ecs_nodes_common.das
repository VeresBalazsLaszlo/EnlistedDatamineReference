module ecs_nodes_common shared

def compare_equal(a, b : float) : bool
  return a == b
def compare_not_equal(a, b : float) : bool
  return a != b
def compare_less_or_equal(a, b : float) : bool
  return a <= b
def compare_greater_or_equal(a, b : float) : bool
  return a >= b
def compare_greater(a, b : float) : bool
  return a > b
def compare_less(a, b : float) : bool
  return a < b
[unused_argument(a, b)] def compare_fail(a, b : float) : bool
  return false

def parse_comparison_operator(operator_str : string)
  if operator_str == ">"
    return @@compare_greater
  elif operator_str == "<"
    return @@compare_less
  elif operator_str == "<="
    return @@compare_less_or_equal
  elif operator_str == ">="
    return @@compare_greater_or_equal
  elif operator_str == "=="
    return @@compare_equal
  elif operator_str == "!="
    return @@compare_not_equal
  return @@compare_fail