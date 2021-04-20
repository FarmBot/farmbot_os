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
  PROCESSING _,-> TIMEOUT: Firmware didn't hear back from hardware
               `-> DROPPED: FBOS didn't hear back from firmware
  ==========================================================
    | The firmware has started executing the command, but is
    | not done yet.
    |
    V
    OK    -> ERROR (tried, but failed to perform the operation)
  ==========================================================
  """

  alias __MODULE__, as: State

  # List of IDs that need to be processed
  defstruct queue: [],
            # Last `Q` param that was sent to MCU.
            q: 1,
            # Jobs pending, indexed by unique ID
            pending: %{}

  def new() do
    %State{}
  end

  def push(state, {caller, gcode}) do
    job = %{caller: caller, gcode: gcode, echo: nil}
    %{state | queue: state.queue ++ [job]}
  end

  def process_next_message(
        %{tx_buffer: %{q: old_q, queue: [job | next_queue]}} = state
      ) do
    last_buffer = state.tx_buffer

    # 0. Create q param
    q =
      if Enum.member?(1..98, old_q) do
        old_q + 1
      else
        1
      end

    # 1. Attach a `Q` param to GCode.
    gcode = job.gcode <> " Q#{q}"

    # 2. Move job to the "waiting area"
    pending_updates = %{q => %{job | gcode: gcode}}
    next_pending = Map.merge(last_buffer.pending, pending_updates)

    # 3. Send GCode down the wire with newly minted Q param
    IO.inspect(gcode, label: "=== SENDING JOB")
    FarmbotCore.Firmware.UARTCoreSupport.uart_send(state.circuits_pid, gcode)

    # 4. Update state.
    updates = %{pending: next_pending, queue: next_queue, q: q}
    %{state | tx_buffer: Map.merge(last_buffer, updates)}
  end

  def process_next_message(%{tx_buffer: %{queue: []}} = state) do
    state
  end

  # Queue number 0 is special. If a response comes back on
  # Q00, assume it was not sent via this module and
  # ignore it.
  def process_ok(state, 0), do: state

  def process_ok(%{tx_buffer: txb} = state, q) do
    old_pending = txb.pending
    # 0. Fetch job, crashing if it does not exist.
    %{caller: caller} = Map.fetch!(old_pending, q)
    # 1. If job had a caller, send a Genserver.reply.
    if caller do
      IO.puts("SENT FIRMWARE REPLY TO CALLER PID!!")
      GenServer.reply(caller, {:ok, nil})
    end

    # 2. Remove job from state tree
    new_txb = %{txb | pending: Map.delete(old_pending, q)}
    %{state | tx_buffer: new_txb}
  end

  def process_error(%{tx_buffer: txb} = state, q) do
    old_pending = txb.pending
    # 0. Fetch job, crashing if it does not exist.
    %{caller: pid} = Map.fetch!(old_pending, q)

    if pid do
      # 1. If job had a PID, and it is still alive, send a Genserver.reply.
      GenServer.reply(pid, {:error, nil})
    end

    # 2. Remove job from state tree
    new_txb = %{txb | pending: Map.delete(old_pending, q)}
    %{state | tx_buffer: new_txb}
  end

  def process_echo(state, echo) do
    do_process_echo(state, echo, extract_q_param(echo))
  end

  defp do_process_echo(state, _echo, nil) do
    # If there is no Q param, there's
    # no way to retrieve the job
    state
  end

  defp do_process_echo(%{tx_buffer: txb} = state, echo, q) do
    # 0. Retrieve old job
    old_job = Map.fetch!(state.tx_buffer.pending, q)

    # 1. add `echo` to job record
    %{echo: echo, gcode: gcode} = new_job = %{old_job | echo: echo}

    # 2. Cross-check gcode with echo, crash if not ==
    if echo != gcode do
      err = "CORRUPT ECHO! Expected echo "
      raise err <> "#{inspect(echo)} to equal #{inspect(gcode)}"
    end

    # 3. Add updated record to state.
    new_pending = Map.put(txb.pending, q, new_job)
    new_txb = Map.merge(txb, %{pending: new_pending})
    %{state | tx_buffer: new_txb}
  end

  defp extract_q_param(text) do
    regex = ~r/Q\d\d?/

    if Regex.match?(regex, text) do
      {q, _} =
        Regex.run(regex, text)
        |> Enum.at(0)
        |> String.replace("Q", "")
        |> Integer.parse(10)

      q
    end
  end
end
