defmodule FarmbotCore.Firmware.TxBuffer do
  @moduledoc """
  This is a data structure that manages a single "leg" of the
  UARTCore state tree. As the name suggests, it handles
  buffering of transmissions from FBOS to the Arduino firmware.
  """

  alias __MODULE__, as: State
  alias FarmbotCore.Firmware.UARTCoreSupport, as: Support

  # List of IDs that need to be processed (FIFO)
  defstruct queue: [],
            # Last `Q` param that was sent to MCU.
            autoinc: 1,
            # Job that the firmware is currently executing
            current: nil

  require Logger

  def new() do
    %State{}
  end

  @doc ~S"""
  Append a GCode line to the TxBufer.

  iex> push(new(), {nil, "E"})
  %FarmbotCore.Firmware.TxBuffer{
    current: nil,
    autoinc: 2,
    queue: [
      %{id: 2, caller: nil, echo: nil, gcode: "E"}
    ]
  }
  """
  def push(state, {caller, gcode}) do
    id = generate_next_q(state.autoinc)
    job = %{id: id, caller: caller, gcode: gcode, echo: nil}
    %{state | queue: state.queue ++ [job], autoinc: id}
  end

  def error_all(%{tx_buffer: txb} = old_state, reason) do
    reducer = fn %{id: id}, state ->
      reply(state, id, {:error, reason})
    end

    Enum.reduce(txb.queue, old_state, reducer)
  end

  def process_next_message(
        %{tx_buffer: %{current: nil, queue: [j | next_queue]}} = state
      ) do
    last_buffer = state.tx_buffer
    q = j.id
    # 1. Attach a `Q` param to GCode.
    gcode = j.gcode <> " Q#{q}"

    # 2. Move job to the "waiting area"
    next_job = %{j | gcode: gcode}

    # 3. Send GCode down the wire with newly minted Q param
    IO.inspect(gcode, label: "=== SENDING JOB")
    Support.uart_send(state.circuits_pid, gcode)

    # 4. Update state.
    updates = %{current: next_job, queue: next_queue, autoinc: q}

    %{state | tx_buffer: Map.merge(last_buffer, updates)}
  end

  # Reasons you could hit this state:
  # 1. No messages to process.
  # 2. Still waiting for last command to finish (current != nil)
  def process_next_message(state), do: state

  # Queue number 0 is special. If a response comes back on
  # Q00, assume it was not sent via this module and
  # ignore it.
  def process_ok(state, 0), do: state
  def process_ok(state, q), do: reply(state, q, {:ok, nil})
  def process_error(state, q), do: reply(state, q, {:error, nil})
  def process_echo(state, echo), do: do_process_echo(state, echo)

  defp reply(%{tx_buffer: txb} = old_state, q, response) when is_integer(q) do
    # 0. Fetch job.
    # `false` means "NOT FOUND"
    # `nil` means "DONT WANT REPLY"
    finish_reply(txb.current, response)
    %{old_state | tx_buffer: Map.merge(txb, %{current: nil})}
  end

  defp do_process_echo(%{tx_buffer: txb} = state, echo) do
    # 0. Retrieve old job
    no_echo = txb.current

    # 1. add `echo` to job record
    %{echo: echo, gcode: gcode} = has_echo = %{no_echo | echo: echo}

    # 2. Cross-check gcode with echo, crash if not ==
    if echo != gcode do
      err = "CORRUPT ECHO! Expected echo "
      raise err <> "#{inspect(echo)} to equal #{inspect(gcode)}"
    end

    # 3. Add updated record to state.
    %{state | tx_buffer: Map.merge(txb, %{current: has_echo})}
  end

  defp generate_next_q(q) do
    if Enum.member?(1..998, q) do
      q + 1
    else
      1
    end
  end

  # SCENARIO: The queue is not busy.
  defp finish_reply(nil, _), do: nil
  # SCENARIO: Got a response for a message that did not want
  #           a reply.
  defp finish_reply(%{caller: nil}, _), do: false
  # Base case
  defp finish_reply(%{caller: caller}, response) do
    GenServer.reply(caller, response)
  end
end
