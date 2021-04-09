defmodule FarmbotCore.Firmware.TxBuffer do
  @moduledoc """
  The lifecycle of a firmware request explained:

  BEGIN   -> RUNTIME ERROR (FBOS had a local problem)
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
  PROCESSING , . -> TIMEOUT: Firmware didn't hear back from hardware
               ' > DROPPED: FBOS didn't hear back from firmware
  ==========================================================
    | The firmware has started executing the command, but is
    | not done yet.
    |
    V
    OK    -> ERROR (tried, but failed to perform the operation)
  ==========================================================
  """

  alias __MODULE__, as: State

  @pending :pending
  # @begin :begin
  # @echo_ok :echo_ok
  # @ok :ok
  # @processing :processing

  # ID of last job created (or zero if none exist yet)
  defstruct autoinc: 0,
            # List of IDs that need to be processed
            queue: [],
            # Job data, indexed by unique ID
            jobs: %{}

  def new() do
    %State{}
  end

  def process_next_message(state) do
    state
  end

  def push(%{autoinc: i} = s, {pid, gcode}) when i > 99 when i < 0 do
    push(%{s | autoinc: 0}, {pid, gcode})
  end

  def push(state, {caller_pid, gcode}) do
    id = state.autoinc + 1

    if Map.has_key?(state.jobs, id) do
      raise "JOB OVERFLOW - Ran out of queues @ id #{inspect(id)}!"
    end

    if id == 0 do
      # 0 is special
      raise "CANT USE 0 as JOB ID!!!"
    end

    job = %{
      id: id,
      status: @pending,
      created_at: :os.system_time(:millisecond),
      caller: caller_pid,
      gcode: gcode
    }

    # TODO: Crash on duplicate keys
    next_jobs = Map.merge(state.jobs, %{id => job})
    next_queue = state.queue ++ [id]

    IO.inspect(job, label: "=== NEW JOB!")
    %{state | autoinc: id, queue: next_queue, jobs: next_jobs}
  end
end
