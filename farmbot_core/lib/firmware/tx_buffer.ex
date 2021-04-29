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

  # List of IDs that need to be processed (FIFO)
  defstruct queue: [],
            # Last `Q` param that was sent to MCU.
            q: 1,
            # How many Q codes sent vs. received (busy if != 0)
            balance: 0,
            # Jobs pending, indexed by unique ID
            pending: %{}

  require Logger

  def new() do
    %State{}
  end

  def push(state, {caller, gcode}) do
    job = %{caller: caller, gcode: gcode, echo: nil}
    %{state | queue: state.queue ++ [job]}
  end

  def error_all(%{tx_buffer: txb} = old_state, reason) do
    reducer = fn job_id, state -> reply(state, job_id, {:error, reason}) end
    Enum.reduce(txb.queue, old_state, reducer)
  end

  def process_next_message(
        %{tx_buffer: %{q: q0, queue: [j | next_queue], balance: 0}} = state
      ) do
    last_buffer = state.tx_buffer
    # 0. Create q param
    q =
      if Enum.member?(1..98, q0) do
        q0 + 1
      else
        1
      end

    # 1. Attach a `Q` param to GCode.
    gcode = j.gcode <> " Q#{q}"

    # 2. Move job to the "waiting area"
    pending_updates = %{q => %{j | gcode: gcode}}
    next_pending = Map.merge(last_buffer.pending, pending_updates)

    # 3. Send GCode down the wire with newly minted Q param
    IO.inspect(gcode, label: "=== SENDING JOB")
    FarmbotCore.Firmware.UARTCoreSupport.uart_send(state.circuits_pid, gcode)

    # 4. Update state.
    next_balance = state.tx_buffer.balance + 1

    updates = %{
      pending: next_pending,
      queue: next_queue,
      q: q,
      balance: next_balance
    }

    %{state | tx_buffer: Map.merge(last_buffer, updates)}
  end

  # Reasons you could hit this state:
  # 1. No messages to process.
  # 2. Still waiting for last command to finish (balance != 0)
  def process_next_message(state) do
    state
  end

  # Queue number 0 is special. If a response comes back on
  # Q00, assume it was not sent via this module and
  # ignore it.
  def process_ok(state, 0), do: state
  def process_ok(state, q), do: reply(state, q, {:ok, nil})
  def process_error(state, q), do: reply(state, q, {:error, nil})
  def process_echo(state, echo), do: handle_echo(state, echo, extract_q(echo))

  defp handle_echo(state, _echo, nil) do
    # If there is no Q param, there's
    # no way to retrieve the job
    state
  end

  defp handle_echo(%{tx_buffer: txb} = state, echo, q) do
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

  defp reply(%{tx_buffer: txb} = old_state, q, response) do
    # 0. Fetch job.
    # `false` means "NOT FOUND"
    # `nil` means "DONT WANT REPLY"
    %{caller: caller} = Map.get(txb.pending, q, %{caller: false})
    # 1. If job exists and has a caller, send a Genserver.reply.
    case caller do
      # SCENARIO: Handler crashed or e-stopped.
      false -> Logger.warn("Could not find firmware job #{inspect(q)}.")
      # SCENARIO: Something sent a raw message and didn't care
      #           about reply. This is normal.
      nil -> nil
      # SCENARIOD: Routine call/response RPC to firmware.
      real_caller -> GenServer.reply(real_caller, response)
    end

    updates = %{
      pending: Map.delete(txb.pending, q),
      balance: txb.balance - 1
    }

    %{old_state | tx_buffer: Map.merge(txb, updates)}
  end

  defp extract_q(text) do
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
