defmodule Farmbot.Firmware.UartHandler do
  @moduledoc """
  Handles communication between farmbot and uart devices
  """

  use GenStage
  alias Nerves.UART
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [update_config_value: 4]
  alias Farmbot.Firmware
  alias Firmware.{UartHandler, Vec3}
  import Vec3, only: [fmnt_float: 1]
  @behaviour Firmware.Handler


  def start_link do
    GenStage.start_link(__MODULE__, [])
  end

  def move_absolute(handler, pos, x_speed, y_speed, z_speed) do
    GenStage.call(handler, {:move_absolute, pos, x_speed, y_speed, z_speed})
  end

  def calibrate(handler, axis) do
    GenStage.call(handler, {:calibrate, axis})
  end

  def find_home(handler, axis) do
    GenStage.call(handler, {:find_home, axis})
  end

  def home(handler, axis) do
    GenStage.call(handler, {:home, axis})
  end

  def home_all(handler) do
    GenStage.call(handler, :home_all)
  end

  def zero(handler, axis) do
    GenStage.call(handler, {:zero, axis})
  end

  def update_param(handler, param, val) do
    GenStage.call(handler, {:update_param, param, val})
  end

  def read_param(handler, param) do
    GenStage.call(handler, {:read_param, param})
  end

  def read_all_params(handler) do
    GenStage.call(handler, :read_all_params)
  end

  def emergency_lock(handler) do
    GenStage.call(handler, :emergency_lock)
  end

  def emergency_unlock(handler) do
    GenStage.call(handler, :emergency_unlock)
  end

  def set_pin_mode(handler, pin, mode) do
    GenStage.call(handler, {:set_pin_mode, pin, mode})
  end

  def read_pin(handler, pin, pin_mode) do
    GenStage.call(handler, {:read_pin, pin, pin_mode})
  end

  def write_pin(handler, pin, pin_mode, value) do
    GenStage.call(handler, {:write_pin, pin, pin_mode, value})
  end

  def request_software_version(handler) do
    GenStage.call(handler, :request_software_version)
  end

  def set_servo_angle(handler, pin, number) do
    GenStage.call(handler, {:set_servo_angle, pin, number})
  end

  ## Private

  defmodule State do
    @moduledoc false
    defstruct [
      nerves: nil,
      current_cmd: nil,
    ]
  end

  def init([]) do
    # If in dev environment,
    #   it is expected that this be done at compile time.
    # If in target environment,
    #   this should be done by `Farmbot.Firmware.AutoDetector`.
    error_msg = "Please configure uart handler!"
    tty = Application.get_env(:farmbot, :uart_handler)[:tty] || raise error_msg

    # Disable fw input logs after a reset of the
    # Fw handler if they were enabled.
    update_config_value(:bool, "settings", "firmware_input_log", false)

    # This looks up a hack file, flashes fw, and removes hack file.
    # Sorry about that.
    maybe_flash_fw(tty)

    gen_stage_opts = [
      dispatcher: GenStage.BroadcastDispatcher,
      subscribe_to: [ConfigStorage.Dispatcher]
    ]
    case open_tty(tty) do
      {:ok, nerves} ->
        {:producer_consumer, %State{nerves: nerves}, gen_stage_opts}
      err ->
        {:stop, err}
    end
  end

  defp maybe_flash_fw(_tty) do
    path_list = [Application.get_env(:farmbot, :data_path), "firmware_flash"]
    hack_file = Path.join(path_list)
    case File.read(hack_file) do
      {:ok, value} when value in ["arduino", "farmduino"] ->
        update_config_value(:string, "settings", "firmware_hardware", value)
        UartHandler.Update.force_update_firmware(value)
        File.rm!(hack_file)
      _ -> :ok
    end
  end

  def handle_events(events, _, state) do
    state = Enum.reduce(events, state, fn(event, state_acc) ->
      handle_config(event, state_acc)
    end)
    {:noreply, [], state}
  end

  defp handle_config({:config, "settings", key, _val}, state)
    when key in ["firmware_input_log", "firmware_output_log"]
  do
    # Restart the framing to pick up new changes.
    UART.configure state.nerves, [framing: UART.Framing.None, active: false]
    configure_uart(state.nerves, true)
    state
  end

  defp handle_config(_, state) do
    state
  end

  defp open_tty(tty) do
    {:ok, nerves} = UART.start_link()
    Process.link(nerves)
    case UART.open(nerves, tty, [speed: 115_200, active: true]) do
      :ok ->
        :ok = configure_uart(nerves, true)
        # Flush the buffers so we start fresh
        :ok = UART.flush(nerves)
        loop_until_idle(nerves)
      err ->
        err
    end
  end

  defp loop_until_idle(nerves) do
    receive do
      {:nerves_uart, _, {:error, reason}} -> {:stop, reason}
      {:nerves_uart, _, {:partial, _}} -> loop_until_idle(nerves)
      # {:nerves_uart, _, {_, :idle}} -> {:ok, nerves}
      {:nerves_uart, _, {_, {:debug_message, "ARDUINO STARTUP COMPLETE"}}} ->
          {:ok, nerves}
      {:nerves_uart, _, _msg} ->
        # Logger.info 3, "Got message: #{inspect msg}"
        loop_until_idle(nerves)
    after 30_000 -> {:stop, "Firmware didn't respond in 30 seconds."}
    end
  end

  defp configure_uart(nerves, active) do
    UART.configure(
      nerves,
      framing: {Farmbot.Firmware.UartHandler.Framing, separator: "\r\n"},
      active: active,
      rx_framing_timeout: 500
    )
  end

  def terminate(reason, state) do
    if state.nerves do
      UART.close(state.nerves)
      UART.stop(reason)
    end
  end

  # if there is an error, we assume something bad has happened, and we probably
  # Are better off crashing here, and being restarted.
  def handle_info({:nerves_uart, _, {:error, :eio}}, state) do
    Logger.error 1, "UART device removed."
    old_env = Application.get_env(:farmbot, :behaviour)
    new_env = Keyword.put(old_env, :firmware_handler, Firmware.StubHandler)
    Application.put_env(:farmbot, :behaviour, new_env)
    {:stop, {:error, :eio}, state}
  end

  def handle_info({:nerves_uart, _, {:error, reason}}, state) do
    {:stop, {:error, reason}, state}
  end

  # Unhandled gcodes just get ignored.
  def handle_info({:nerves_uart, _, {:unhandled_gcode, code_str}}, state) do
    Logger.debug 3, "Got unhandled gcode: #{code_str}"
    {:noreply, [], state}
  end

  def handle_info({:nerves_uart, _, {_, {:report_software_version, v}}}, state) do
    expected = Application.get_env(:farmbot, :expected_fw_versions)
    if v in expected do
      {:noreply, [{:report_software_version, v}], state}
    else
      err = "Firmware version #{v} is not in expected versions: #{inspect expected}"
      Logger.error 1, err
      old_env = Application.get_env(:farmbot, :behaviour)
      new_env = Keyword.put(old_env, :firmware_handler, Firmware.StubHandler)
      Application.put_env(:farmbot, :behaviour, new_env)
      {:stop, :normal, state}
    end
  end

  def handle_info({:nerves_uart, _, {:echo, _}}, %{current_cmd: nil} = state) do
    {:noreply, [], state}
  end
  def handle_info({:nerves_uart, _, {:echo, {:echo, "*F43" <> _}}}, state) do
    {:noreply, [], state}
  end

  def handle_info({:nerves_uart, _, {:echo, {:echo, code}}}, state) do
    distance = String.jaro_distance(state.current_cmd, code)
    if distance > 0.85 do
      :ok
    else
      err = "Echo #{code} does not match #{state.current_cmd} (#{distance})"
      Logger.error 3, err
    end
    {:noreply, [], %{state | current_cmd: nil}}
  end

  def handle_info({:nerves_uart, _, {_q, :done}}, state) do
    {:noreply, [:done], %{state | current_cmd: nil}}
  end

  def handle_info({:nerves_uart, _, {_q, gcode}}, state) do
    {:noreply, [gcode], state}
  end

  def handle_info({:nerves_uart, _, bin}, state) when is_binary(bin) do
    Logger.warn(3, "Unparsed Gcode: #{bin}")
    {:noreply, [], state}
  end

  defp do_write(bin, state, dispatch \\ []) do
    # Logger.debug 3, "writing: #{bin}"
    case UART.write(state.nerves, bin) do
      :ok -> {:reply, :ok, dispatch, %{state | current_cmd: bin}}
      err -> {:reply, err, [], %{state | current_cmd: nil}}
    end
  end

  def handle_call({:move_absolute, pos, x_speed, y_speed, z_speed}, _from, state) do
    cmd = "X#{fmnt_float(pos.x)} "
       <> "Y#{fmnt_float(pos.y)} "
       <> "Z#{fmnt_float(pos.z)} "
       <> "A#{fmnt_float(x_speed)} "
       <> "B#{fmnt_float(y_speed)} "
       <> "C#{fmnt_float(z_speed)}"
    wrote = "G00 #{cmd}"
    do_write(wrote, state)
  end

  def handle_call({:calibrate, axis}, _from, state) do
    num = case axis |> to_string() do
      "x" -> 14
      "y" -> 15
      "z" -> 16
    end
    do_write("F#{num}", state)
  end

  def handle_call({:find_home, axis}, _from, state) do
    cmd = case axis |> to_string() do
      "x" -> "11"
      "y" -> "12"
      "z" -> "13"
    end
    do_write("F#{cmd}", state)
  end

  def handle_call(:home_all, _from, state) do
    do_write("G28", state)
  end

  def handle_call({:home, axis}, _from, state) do
    cmd = case axis |> to_string() do
      "x" -> "X0"
      "y" -> "Y0"
      "z" -> "Z0"
    end
    do_write("G00 #{cmd}", state)
  end

  def handle_call({:zero, axis}, _from, state) do
    axis_format = case axis |> to_string() do
      "x" -> "X"
      "y" -> "Y"
      "z" -> "Z"
    end
    do_write("F84 #{axis_format}1", state)
  end

  def handle_call(:emergency_lock, _from, state) do
    r = UART.write(state.nerves, "E")
    {:reply, r, [], state}
  end

  def handle_call(:emergency_unlock, _from, state) do
    do_write("F09", state)
  end

  def handle_call({:read_param, param}, _from, state) do
    num = Farmbot.Firmware.Gcode.Param.parse_param(param)
    do_write("F21 P#{num}", state)
  end

  def handle_call({:update_param, param, val}, _from, state) do
    num = Farmbot.Firmware.Gcode.Param.parse_param(param)
    do_write("F22 P#{num} V#{val}", state)
  end

  def handle_call(:read_all_params, _from, state) do
    do_write("F20", state)
  end

  def handle_call({:set_pin_mode, pin, mode}, _from, state) do
    encoded_mode = if mode == :output, do: 1, else: 0
    do_write("F43 P#{pin} M#{encoded_mode}", state, [])
  end

  def handle_call({:read_pin, pin, mode}, _from, state) do
    encoded_mode = extract_pin_mode(mode)
    dispatch = [{:report_pin_mode, pin, mode}]
    do_write("F42 P#{pin} M#{encoded_mode}", state, dispatch)
  end

  def handle_call({:write_pin, pin, mode, value}, _from, state) do
    encoded_mode = extract_pin_mode(mode)
    dispatch = [{:report_pin_mode, pin, mode}, {:report_pin_value, pin, value}]
    do_write("F41 P#{pin} V#{value} M#{encoded_mode}", state, dispatch)
  end

  def handle_call(:request_software_version, _from, state) do
    do_write("F83", state)
  end

  def handle_call({:set_servo_angle, pin, angle}, _, state) do
    do_write("F61 P#{pin} V#{angle}", state)
  end

  def handle_call(_call, _from, state) do
    {:reply, {:error, :bad_call}, [], state}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end

  @compile {:inline, [extract_pin_mode: 1]}
  defp extract_pin_mode(:digital), do: 0
  defp extract_pin_mode(_), do: 1
end
