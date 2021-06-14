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

  def process_next_message(%State{current: nil, queue: [j | next]}, uart_pid) do
    q = j.id
    # 1. Attach a `Q` param to GCode.
    gcode = j.gcode <> " Q#{q}"

    # 2. Move job to the "waiting area"
    next_job = %{j | gcode: gcode}

    # 3. Send GCode down the wire with newly minted Q param
    Support.uart_send(uart_pid, gcode)

    # 4. Update state.
    %State{current: next_job, queue: next, autoinc: q}
  end

  # 1. No messages to process.
  def process_next_message(%State{current: nil, queue: []} = s, _), do: s

  # Still waiting for last command to finish (current != nil)
  def process_next_message(state, _uart_pid) do
    current = inspect(state.current)
    q = Enum.count(state.queue)
    m = "Firmware handler waiting on #{q} responses. Next: #{current}"
    Logger.debug(m)
    state
  end

  # Queue number 0 is special. If a response comes back on
  # Q00, assume it was not sent via this module and
  # ignore it.
  def process_ok(%State{} = state, 0), do: state
  def process_ok(%State{} = state, q), do: reply(state, q, {:ok, nil})
  def process_error(%State{} = state, q), do: reply(state, q, {:error, nil})
  def process_echo(%State{} = state, echo), do: do_process_echo(state, echo)

  def error_all(state, reason) do
    mapper = fn
      %{id: id} -> reply(state, id, {:error, reason})
      nil -> nil
    end

    mapper.(state.current)
    Enum.map(state.queue, mapper)
    new()
  end

  defp reply(txb, q, response) when is_integer(q) do
    finish_reply(txb.current, response)
    Map.merge(txb, %{current: nil})
  end

  # EDGE CASE: Locking the device causes a state reset. Lots
  #            of jobs will be undetecable during the time
  #            between Lock => Unlock. Just ignore them.
  defp do_process_echo(%{current: nil} = s, e) do
    Logger.debug("Ignoring untracked echo: #{inspect(e)}")
    s
  end

  defp do_process_echo(%State{} = txb, echo) do
    # 0. Retrieve old job
    no_echo = txb.current
    # 1. add `echo` to job record
    %{echo: echo, gcode: gcode} = has_echo = %{no_echo | echo: echo}

    # 2. Cross-check gcode with echo, crash if not ==
    if echo != gcode && !String.contains?(echo, "Q0") do
      err = "CORRUPT ECHO! Expected echo "
      raise err <> "#{inspect(echo)} to equal #{inspect(gcode)}"
    end

    # 3. Add updated record to state.
    Map.merge(txb, %{current: has_echo})
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
    Support.reply(caller, response)
  end
end
