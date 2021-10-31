defmodule FarmbotOS.Firmware.Request do
  @moduledoc """
  The lifecycle of a firmware request explained:

  START -> RUNTIME ERROR (FBOS had a local problem)
  ==========================================================
    | The application needs to interact with the firmware
    | for some reason (estop, movement, pin control)
    |
    v
  PENDING -> FAILED (the firmware failed to receive the message)
  ==========================================================
    | FBOS has sent the message, but needs to confirm that
    | MCU received the message in its entirety.
    V
  ECHO OK -> ECHO FAIL (the command was damaged in transit)
  ==========================================================
    | The firmware has acknowledged the message by repeating
    | the contents back to FBOS verbatim.
    |
    V
  WAITING,.-> TIMEOUT: Firmware didn't hear back from hardware
           '> DROPPED: FBOS didn't hear back from firmware
  ==========================================================
    | The firmware has started executing the command, but is
    | not done yet.
    |
    V
    OK    -> ERROR (tried, but failed to perform the operation)
  ==========================================================
  """

  def new() do
  end

  # Write some GCode
  # Send the GCode
end
