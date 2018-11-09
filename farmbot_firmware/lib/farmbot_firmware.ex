defmodule Farmbot.Firmware do
  @moduledoc """
  Firmware wrapper for interacting with Farmbot-Arduino-Firmware.
  This GenServer is expected to be a pretty simple state machine
  with no side effects to anything in the rest of the Farmbot application.
  Side effects should be implemented using a callback/pubsub system. This
  allows for indpendent testing.

  Functionality that is needed to boot the firmware:
    * paramaters - Keyword list of {param_atom, float}

  Side affects that should be handled
    * position reports
    * end stop reports
    * calibration reports
    * busy reports

  # State machine
  The firmware starts in a `:boot` state. It then loads all paramaters
  writes all paramaters, and goes to idle if all params were loaded successfully.

  State machine flows go as follows:
  ## Boot
      :boot
      |> :no_config
      |> :configuration
      |> :idle

  ## Idle
      :idle
      |> :begin
      |> :busy
      |> :error | :invalid | :success

  # Constraints and Exceptions
  Commands will be queued as they received with some exceptions:
  * if a command is currently executing (state is not `:idle`),
    proceding commands will be queued in the order they are received.
  * the `:emergency_lock` and `:emergency_unlock` commands go to the front
    of the command queue and are started immediately.
  * if a `report_emergency_lock` message is received at any point during a
    commands execution, that command is considered an error.
    (this does not apply to `:boot` state, since `:write_paramater`
     is accepted while the firmware is locked.)
  * all reports outside of control flow reports (:begin, :error, :invalid,
    :success) will be discarded while in `:boot` state. This means while
    boot, position updates, end stop updates etc are ignored.

  # Transports
  GCODES should be exchanged in the following format:
      {tag, {command, args}}
  * `tag` - binary integer. This is translated to the `Q` paramater.
  * `command` - either a `RXX`, `FXX`, or `GXX` code.
  * `args` - a list of arguments to be processed.

  For example a report might look like:
      {"123", {:report_some_information, [h: 10.00, u: 90.10]}}
  and a command might look like:
      {"555", {:fire_laser, [w: 100.00]}}
  Numbers should be floats when possible. An Exeption to this is `:report_end_stops`
  where there is only two values: `1` or `0`.

  See the `GCODE` module for more information on available implemented GCODES.
  a `Transport` should be a process that implements standard `GenServer`
  behaviour.

  Upon `init/1` the args passed in should be a Keyword list required to configure
  the transport such as a serial device, etc. `args` will also contain a
  `:handle_gcode` function that should be called everytime a GCODE is received.

      Keyword.fetch!(args, :handle_gcode).({"999", {:report_software_version, ["Just a test!"]}})

  a transport should also implement a `handle_call` clause like:

      def handle_call({"166", {:write_paramater, [some_param: 100.00]}}, _from, state)

  and reply with `:ok | {:error, term()}`
  """
  use GenServer
  require Logger

  alias Farmbot.Firmware, as: State
  alias Farmbot.Firmware.GCODE
  @error_timeout_ms 2_000

  @type status :: :boot | :no_config | :configuration | :idle | :emergency_lock

  defstruct [
    :transport,
    :transport_pid,
    :side_effects,
    :status,
    :tag,
    :configuration_queue,
    :command_queue,
    :caller_pid,
    :current
  ]

  @type state :: %State{
          transport: module(),
          transport_pid: pid(),
          side_effects: nil | module(),
          status: status(),
          tag: GCODE.tag(),
          configuration_queue: [{GCODE.kind(), GCODE.args()}],
          command_queue: [{pid(), GCODE.t()}],
          caller_pid: nil | pid,
          current: nil | GCODE.t()
        }

  @doc """
  Command the firmware to do something. Takes a `{tag, {command, args}}`
  GCODE. This command will be queued if there is already a command
  executing. (this does not apply to `:emergency_lock` and `:emergency_unlock`)

  ## Response/Control Flow
  When executed, `command` will block until one of the following respones
  are received:
    * `{:report_success, []}` -> `:ok`
    * `{:report_invalid, []}` -> `{:error, :invalid_command}`
    * `{:report_error, []}` -> `{:error, :firmware_error}`
    * `{:report_emergency_lock, []}` -> {:error, :emergency_lock}`

  If the firmware is in any of the following states:
    * `:boot`
    * `:no_config`
    * `:configuration`
  `command` will fail with `{:error, state}`
  """
  @spec command(GenServer.server(), GCODE.t() | {GCODE.kind(), GCODE.args()}) ::
          :ok | {:error, :invalid_command | :firmware_error | :emergency_lock | status()}
  def command(firmware_server \\ __MODULE__, code)

  def command(firmware_server, {_tag, {_, _}} = code) do
    case GenServer.call(firmware_server, code, :infinity) do
      {:ok, tag} -> wait_for_result(tag, code)
      {:error, status} -> {:error, status}
    end
  end

  def command(firmware_server, {_, _} = code) do
    command(firmware_server, {to_string(:rand.uniform(100)), code})
  end

  defp wait_for_result(tag, code) do
    receive do
      {^tag, {:report_begin, []}} ->
        wait_for_result(tag, code)

      {^tag, {:report_busy, []}} ->
        wait_for_result(tag, code)

      {^tag, {:report_success, []}} ->
        :ok

      {^tag, {:report_error, []}} ->
        {:error, :firmware_error}

      {^tag, {:report_invalid, []}} ->
        {:error, :invalid_command}

      {_, {:report_emergency_lock, []}} ->
        {:error, :emergency_lock}

      {tag, _report} = code ->
        wait_for_result(tag, code)
    end
  end

  @doc """
  Starting the Firmware server requires at least:
  * `:transport` - a module implementing the Transport GenServer behaviour.
    See the `Transports` section of moduledoc.

  Every other arg passed in will be passed directly to the `:transport` module's
  `init/1` function.
  """
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    transport = Keyword.fetch!(args, :transport)
    side_effects = Keyword.get(args, :side_effects)
    fw = self()
    fun = fn {_, _} = code -> GenServer.cast(fw, code) end
    args = Keyword.put(args, :handle_gcode, fun)

    with {:ok, pid} <- GenServer.start_link(transport, args) do
      Process.link(pid)
      Logger.debug("Starting Firmware: #{inspect(args)}")

      state = %State{
        transport_pid: pid,
        transport: transport,
        side_effects: side_effects,
        status: :boot,
        command_queue: [],
        configuration_queue: []
      }

      {:ok, state}
    end
  end

  # @spec handle_info(:timeout, state) :: {:noreply, state}
  def handle_info(:timeout, %{configuration_queue: [code | rest]} = state) do
    Logger.debug("Starting next configuration code: #{inspect(code)}")

    case GenServer.call(state.transport_pid, {state.tag, code}) do
      :ok ->
        new_state = %{state | current: code, configuration_queue: rest}
        side_effects(new_state, :handle_output_gcode, [{state.tag, code}])
        {:noreply, new_state}

      {:error, _} ->
        {:noreply, state, @error_timeout_ms}
    end
  end

  def handle_info(:timeout, %{command_queue: [{pid, {tag, code}} | rest]} = state) do
    case GenServer.call(state.transport_pid, {tag, code}) do
      :ok ->
        new_state = %{state | tag: tag, current: code, command_queue: rest, caller_pid: pid}
        side_effects(new_state, :handle_output_gcode, [{state.tag, code}])
        {:noreply, new_state}

      {:error, _} ->
        {:noreply, state, @error_timeout_ms}
    end
  end

  def handle_info(:timeout, %{configuration_queue: []} = state) do
    {:noreply, state}
  end

  def handle_call({_tag, _code} = gcode, from, state) do
    handle_command(gcode, from, state)
  end

  @doc false
  @spec handle_command(GCODE.t(), GenServer.from(), state()) :: {:reply, term(), state()}
  def handle_command(_, _, %{status: s} = state) when s in [:boot, :no_config, :configuration] do
    {:reply, {:error, s.status}, state}
  end

  def handle_command({tag, {:command_emergency_lock, []}} = code, {pid, _ref}, state) do
    {:reply, {:ok, tag}, %{state | command_queue: [{pid, code} | state.command_queue]}, 0}
  end

  def handle_command({tag, {:command_emergency_unlock, []}} = code, {pid, _ref}, state) do
    {:reply, {:ok, tag}, %{state | command_queue: [{pid, code} | state.command_queue]}, 0}
  end

  def handle_command({tag, {_, _}} = code, {pid, _ref}, state) do
    new_state = %{state | command_queue: state.command_queue ++ [{pid, code}]}

    case new_state.status do
      :idle ->
        {:reply, {:ok, tag}, new_state, 0}

      _ ->
        {:reply, {:ok, tag}, new_state}
    end
  end

  # Extracts tag
  def handle_cast({tag, {_, _} = code}, state) do
    side_effects(state, :handle_input_gcode, [{tag, code}])
    handle_report(code, %{state | tag: tag})
  end

  @doc false
  @spec handle_report({GCODE.report_kind(), GCODE.args()}, state) ::
          {:noreply, state(), 0} | {:noreply, state()}
  def handle_report({:report_emergency_lock, []} = code, state) do
    Logger.info("Emergency lock")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, goto(%{state | current: nil, caller_pid: nil}, :emergency_lock), 0}
  end

  # "ARDUINO STARTUP COMPLETE" => goto(:boot, :no_config)
  def handle_report({:report_debug_message, ["ARDUINO STARTUP COMPLETE"]}, state) do
    Logger.info("ARDUINO STARTUP COMPLETE")
    {:noreply, goto(state, :no_config)}
  end

  def handle_report(report, %{status: :boot} = state) do
    Logger.debug(["still in state: :boot ", inspect(report)])
    {:noreply, state}
  end

  # report_idle => goto(_, :idle)
  def handle_report({:report_idle, []}, %{status: _} = state) do
    {:noreply, goto(%{state | caller_pid: nil, current: nil}, :idle), 0}
  end

  def handle_report({:report_begin, []} = code, state) do
    Logger.debug("#{inspect(state.current)} begin")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, state}
  end

  def handle_report({:report_success, []} = code, state) do
    Logger.debug("#{inspect(state.current)} success")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    new_state = %{state | current: nil, caller_pid: nil}

    if new_state.status == :emergency_lock do
      {:noreply, goto(new_state, :idle), 0}
    else
      {:noreply, new_state, 0}
    end
  end

  def handle_report({:report_busy, []} = code, state) do
    Logger.debug("#{inspect(state.current)} busy")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, state}
  end

  def handle_report({:report_error, []} = code, %{status: :configuration} = state) do
    Logger.error("#{inspect(state.current)} configuration command error")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:stop, {:error, state.current}, state}
  end

  def handle_report({:report_error, []} = code, state) do
    Logger.debug("#{inspect(state.current)} error")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, %{state | caller_pid: nil, current: nil}, 0}
  end

  def handle_report({:report_invalid, []} = code, %{status: :configuration} = state) do
    Logger.debug("#{inspect(state.current)} configuration error (invalid)")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:stop, {:error, state.current}, state}
  end

  def handle_report({:report_invalid, []} = code, state) do
    Logger.debug("#{inspect(state.current)} error (invalid)")
    if state.caller_pid, do: send(state.caller_pid, {state.tag, code})
    {:noreply, %{state | caller_pid: nil, current: nil}, 0}
  end

  # report_no_config => goto(_, :no_config)
  def handle_report({:report_no_config, []}, %{status: _} = state) do
    Logger.warn("Configuring paramaters.")
    tag = state.tag || "0"
    loaded_params = side_effects(state, :load_params, []) || []

    param_commands =
      Enum.reduce(loaded_params, [], fn {param, val}, acc ->
        if val, do: acc ++ [{:paramater_write, [param, val]}], else: acc
      end)

    to_process =
      param_commands ++
        [
          {:paramater_write, [{:param_config_ok, 1.0}]},
          {:paramater_read_all, []}
        ]

    {:noreply, goto(%{state | tag: tag, configuration_queue: to_process}, :configuration), 0}
  end

  # report_paramaters_complete => goto(:configuration, :idle)
  def handle_report({:report_paramaters_complete, []}, %{status: :configuration} = state) do
    {:noreply, goto(state, :idle)}
  end

  def handle_report(_, %{status: :no_config} = state) do
    Logger.debug("Still in state: :no_config")
    {:noreply, state}
  end

  def handle_report({:report_position, position} = _code, state) do
    side_effects(state, :handle_position, [position])
    {:noreply, state}
  end

  def handle_report({:report_encoders_scaled, encoders} = _code, state) do
    side_effects(state, :handle_encoders_scaled, [encoders])
    {:noreply, state}
  end

  def handle_report({:report_encoders_raw, encoders} = _code, state) do
    side_effects(state, :handle_encoders_raw, [encoders])
    {:noreply, state}
  end

  def handle_report({:report_end_stops, end_stops} = _code, state) do
    side_effects(state, :handle_end_stops, [end_stops])
    {:noreply, state}
  end

  def handle_report({:report_paramater, param}, state) do
    side_effects(state, :handle_paramater, [param])
    {:noreply, state}
  end

  # NOOP
  def handle_report({:report_echo, _}, state), do: {:noreply, state}

  def handle_report({_kind, _args} = code, state) do
    IO.inspect(code, label: "unknown code for #{state.status}")
    # {:stop, {:unhandled_code, code}, state}
    {:noreply, state}
  end

  @spec goto(state(), status()) :: state()
  defp goto(%{status: old} = state, new) do
    new_state = %{state | status: new}

    cond do
      old != new && new == :emergency_lock ->
        side_effects(new_state, :handle_emergency_lock, [])

      old != new && old == :emergency_lock ->
        side_effects(new_state, :handle_emergency_unlock, [])

      old == new ->
        :ok

      true ->
        Logger.debug("unhandled state change: #{old} => #{new}")
    end

    new_state
  end

  @spec side_effects(state, atom, GCODE.args()) :: any()
  defp side_effects(%{side_effects: nil}, _function, _args), do: nil
  defp side_effects(%{side_effects: m}, function, args), do: apply(m, function, args)
end
