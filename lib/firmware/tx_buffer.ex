defmodule FarmbotOS.Firmware.TxBuffer do
  @moduledoc """
  This is a data structure that manages a single "leg" of the
  UARTCore state tree. As the name suggests, it handles
  buffering of transmissions from FBOS to the Arduino firmware.
  """

  alias __MODULE__, as: State
  alias FarmbotOS.Firmware.UARTCoreSupport, as: Support
  alias FarmbotOS.Firmware.{GCode, ErrorDetector}
  # List of IDs that need to be processed (FIFO)
  defstruct queue: [],
            # Last `Q` param that was sent to MCU.
            autoinc: 1,
            # Job that the firmware is currently executing
            current: nil

  require Logger
  require FarmbotOS.Logger

  def new() do
    %State{}
  end

  @doc ~S"""
  Append a GCode line to the TxBuffer.

  iex> push(new(), nil, FarmbotOS.Firmware.GCode.new("E", []))
  %FarmbotOS.Firmware.TxBuffer{
    current: nil,
    autoinc: 2,
    queue: [
      %{
        id: 2,
        caller: nil,
        gcode: %FarmbotOS.Firmware.GCode{
          command: "E",
          echo: nil,
          params: [],
          string: "E"
        }
      }
    ]
  }
  """
  def push(%__MODULE__{} = state, caller, %GCode{} = gcode) do
    if is_binary(gcode), do: raise("gcode is not a string any more.")
    id = generate_next_q(state.autoinc)
    job = %{id: id, caller: caller, gcode: gcode}
    %{state | queue: state.queue ++ [job], autoinc: id}
  end

  def process_next_message(%State{current: nil, queue: [job | next]}, uart_pid) do
    q = job.id
    # 1. Attach a `Q` param to GCode.
    next_gcode = %{job.gcode | string: job.gcode.string <> " Q#{q}"}

    # 2. Move job to the "waiting area"
    next_job = %{job | gcode: next_gcode}

    # 3. Send GCode down the wire with newly minted Q param
    Support.uart_send(uart_pid, next_gcode.string)

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
  def process_echo(%State{} = state, echo), do: do_process_echo(state, echo)

  def process_error(%State{} = state, {queue, error_code}) do
    msg = ErrorDetector.detect(error_code)

    if msg do
      FarmbotOS.Logger.error(1, msg)
    end

    reply(state, queue, {:error, nil})
  end

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
  #            of jobs will be undetectable during the time
  #            between Lock => Unlock. Just ignore them.
  defp do_process_echo(%{current: nil} = s, e) do
    Logger.debug("Ignoring untracked echo: #{inspect(e)}")
    s
  end

  defp do_process_echo(%State{} = txb, echo_string) do
    job = txb.current
    gcode = job.gcode

    # Delete this after refactor:
    %GCode{} = gcode

    if echo_string != gcode.string do
      err = "CORRUPT ECHO! Expected echo "
      raise err <> "#{inspect(echo_string)} to equal #{inspect(gcode.string)}"
    end

    has_echo = %{job | gcode: %{gcode | echo: echo_string}}
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
