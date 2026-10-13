module timer_common shared

enum TimerOutput
  NOT_STARTED
  STARTED
  TIMEOUT_1
  TIMEOUT_2
  TIMEOUT_3
  TIMEOUT_4

//Simple timer only has timer_value and wait_times (constant)
//Variable timer has 'paused' variable in addition to those. Unlike simple timer, variable time can have its timer_value increased or decreased by a certain value
//Both timers can be paused or reset
def process_simple_timer(cur_time : float; input : bool; pause : bool; wait_times : auto(WaitTimes); var timer_value : float&)
  var paused = timer_value <= 0.0
  return process_variable_timer(cur_time, input, pause, wait_times, timer_value, paused)

def process_variable_timer(cur_time : float; input : bool; pause : bool; wait_times : auto(WaitTimes); var timer_value : float&; var paused : bool&)
  //WaitTimes can be float, float2, float3, or float4.
  //If it's float2/float3/float4, each value in it should be greater than the previous one
  assume waitTimesCount = typeinfo sizeof(type<WaitTimes>) / typeinfo sizeof(type<float>)

  if !input
    timer_value = cur_time
    return int(TimerOutput.NOT_STARTED)

  if pause
    if !paused
      timer_value -= cur_time // timer_value now stores elapsed time with minus sign, signifying that the timer has been paused
      paused = true
  else
    if paused
      timer_value += cur_time // timer_value now stores the time from which to measure the elapsed time
      paused = false

  return check_variable_timer(cur_time, wait_times, timer_value, paused)

def reset_timer(cur_time : float; var timer_value : float&)
  timer_value = cur_time

def check_simple_timer(cur_time : float; wait_times : auto(WaitTimes); timer_value : float)
  var timeElapsed = 0.0
  return check_simple_timer(cur_time, wait_times, timer_value, timeElapsed)

def check_simple_timer(cur_time : float; wait_times : auto(WaitTimes); timer_value : float; var time_elapsed : float&)
  return check_variable_timer(cur_time, wait_times, timer_value, /*paused*/ timer_value <= 0.0, time_elapsed)

def check_variable_timer(cur_time : float; wait_times : auto(WaitTimes); timer_value : float; paused : bool)
  var timeElapsed = 0.0
  return check_variable_timer(cur_time, wait_times, timer_value, paused, timeElapsed)

def check_variable_timer(cur_time : float; wait_times : auto(WaitTimes); timer_value : float; paused : bool; var time_elapsed : float&)
  if paused
    time_elapsed = -timer_value
  else
    time_elapsed = cur_time - timer_value

  assume waitTimesCount = typeinfo sizeof(type<WaitTimes>) / typeinfo sizeof(type<float>)
  static_if waitTimesCount == 1
    if time_elapsed < wait_times
      return int(TimerOutput.STARTED)
    else
      return int(TimerOutput.TIMEOUT_1)
  else
    for i in range(waitTimesCount)
      if time_elapsed < wait_times[i]
        return int(TimerOutput.STARTED) + i
    return int(TimerOutput.STARTED) + waitTimesCount

//DO NOT use this with simple timers, it might be unsafe
//if value > 0.0, elapsed time is increased
//Otherwise, it is decreased, but it can't be less than 0.0
def add_elapsed_time_to_variable_timer(value : float; paused : bool; cur_time : float; var timer_value : float&)
  timer_value -= value
  if paused
    if timer_value > 0.0
      timer_value = 0.0       // elapsed time = 0.0
  else
    if timer_value > cur_time
      timer_value = cur_time  // elapsed time = 0.0
