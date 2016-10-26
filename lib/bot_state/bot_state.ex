defmodule BotState do
  use GenServer
  require Logger

  @bot_state_save_file Application.get_env(:fb, :bot_state_save_file)
  @save_interval 15000
  @twelve_hours 3600000

  def init(_) do
    save_interval
    check_updates
    {:ok, load}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def save(state) do
    File.write!(@bot_state_save_file, :erlang.term_to_binary(state))
    state
  end

  def load do
    default_state = %{
      mcu_params: %{},
      location: [0, 0, 0],
      pins: %{},
      configuration: %{ os_auto_update: false,
                        fw_auto_update: false },
      informational_settings: %{ controller_version: Fw.version }
    }
    case File.read(@bot_state_save_file) do
      { :ok, contents } ->
        rcontents = :erlang.binary_to_term(contents)
        l = Map.keys(default_state)
        r = Map.keys(rcontents)
        Logger.debug("default: #{inspect l} saved: #{inspect r}")
        if(l != r) do # SORRY ABOUT THIS
          Logger.debug "UPDATING TO NEW STATE TREE FORMAT OR SOMETHING"
          spawn fn -> apply_status(default_state) end
          default_state
        else
          Logger.debug("Trying to apply last bot state")
          spawn fn -> apply_status(rcontents) end
          default_state
        end
      _ ->
      spawn fn -> apply_status(default_state) end
      default_state
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_pin, pin_number}, _from, state) do
    {:reply, Map.get(state.pins, Integer.to_string(pin_number)), state}
  end

  def handle_call(:get_current_pos, _from, state) do
    {:reply, state.location, state}
  end

  def handle_cast({:set_pos, {x, y, z}}, state) do
    {:noreply, Map.put(state, :location, [x, y, z])}
  end

  def handle_cast({:set_pin_value, {pin, value}}, state) do
    pin_state = state.pins
    new_pin_value =
    case Map.get(pin_state, Integer.to_string(pin)) do
      nil                     -> %{mode: -1,   value: value}
      %{mode: mode, value: _} -> %{mode: mode, value: value}
    end
    pin_state = Map.put(pin_state, Integer.to_string(pin), new_pin_value)
    {:noreply, Map.put(state, :pins, pin_state)}
  end

  def handle_cast({:set_pin_mode, {pin, mode}}, state) do
    pin_state = state.pins
    new_pin_value =
    case Map.get(pin_state, Integer.to_string(pin)) do
      nil                      -> %{mode: mode, value: -1}
      %{mode: _, value: value} -> %{mode: mode, value: value}
    end
    pin_state = Map.put(pin_state, Integer.to_string(pin), new_pin_value)
    {:noreply, Map.put(state, :pins, pin_state)}
  end

  def handle_cast(:toggle_fw_auto_update, state) do
    next =
    case Map.get(state.configuration, :fw_auto_update) do
      false ->
        Map.put(state.configuration, :fw_auto_update, true)
      _ ->
        Map.put(state.configuration, :fw_auto_update, false)
    end
    {:noreply, Map.put(state, :configuration, next)}
  end

  def handle_cast(:toggle_os_auto_update, state) do
    next =
    case Map.get(state.configuration, :os_auto_update) do
      false ->
        Map.put(state.configuration, :os_auto_update, true)
      _ ->
        Map.put(state.configuration, :os_auto_update, false)
    end
    {:noreply, Map.put(state, :configuration, next)}
  end

  def handle_cast({:set_param, {param_string, value} }, state) do
    new_params = Map.put(state.mcu_params, param_string, value)
    {:noreply, Map.put(state, :mcu_params, new_params)}
  end

  def handle_info(:save, state) do
    save(state)
    save_interval
    {:noreply, state}
  end

  def handle_info(:check_updates, state) do
    Logger.debug("Doing scheduled update check.")
    if(state.configuration.os_auto_update == true) do
      spawn fn -> Fw.check_and_download_os_update end
    end

    if(state.configuration.fw_auto_update == true) do
      spawn fn -> Fw.check_and_download_fw_update end
    end
    check_updates
    {:noreply, state}
  end

  def get_status do
    GenServer.call(__MODULE__, :state)
  end

  def get_current_pos do
    GenServer.call(__MODULE__, :get_current_pos)
  end

  def set_pos(x, y, z)
  when is_integer(x) and is_integer(y) and is_integer(z) do
    GenServer.cast(__MODULE__, {:set_pos, {x, y, z}})
  end

  def set_pin_value(pin, value) when is_integer(pin) and is_integer(value) do
    GenServer.cast(__MODULE__, {:set_pin_value, {pin, value}})
  end

  def set_pin_mode(pin, mode)
  when is_integer(pin) and is_integer(mode) do
    GenServer.cast(__MODULE__, {:set_pin_mode, {pin, mode}})
  end

  def set_param(param_string, value) do
    GenServer.cast(__MODULE__, {:set_param, {param_string, value}})
  end

  def get_pin(pin_number) when is_integer(pin_number) do
    GenServer.call(__MODULE__, {:get_pin, pin_number})
  end

  def set_end_stop(_something) do
    #TODO
    nil
  end

  def toggle_fw_auto_update do
    GenServer.cast(__MODULE__, :toggle_fw_auto_update)
  end

  def toggle_os_auto_update do
    GenServer.cast(__MODULE__, :toggle_os_auto_update)
  end

  def apply_status(state) do
    p = Process.whereis(NewHandler)
    if(is_pid(p) and Process.alive?(p)) do
      Process.sleep(1000)
      Command.home_all(100)
      apply_params(state.mcu_params)
      apply_pins(state.pins)
    else
      Process.sleep(10)
      apply_status(state)
    end
    state
  end

  def apply_params(%{}) do
    Command.read_all_params
  end

  def apply_params(params) when is_map(params) do
    case Enum.all?(params, fn({param, value}) ->
      # WILL SOMEONE JUST DOWNCASE THE PARAMS.
      param_int = Gcode.parse_param(Atom.to_string(param))
      spawn fn -> Command.update_param(param_int, value) end
    end)
    do
      true -> Logger.debug("Params are set!")
      false -> Logger.error("Error resetting params")
    end
  end

  def apply_pins(pins) when is_map(pins) do
    case Enum.all?(pins, fn({pin_str, %{mode: mode, value: value} }) ->
      p = String.to_integer(pin_str)
      spawn fn -> Command.write_pin(p, value, mode) end
    end) do
      true -> Logger.debug("Pins are set!")
              RPCMessageHandler.log("Bot Online!", "ticker")
      false -> Logger.error("Error resetting pins")
    end
  end

  defp save_interval do
    Process.send_after(__MODULE__, :save, @save_interval)
  end

  defp check_updates do
    Process.send_after(__MODULE__, :check_updates, @twelve_hours)
  end
end
