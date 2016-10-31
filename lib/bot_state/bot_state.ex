defmodule BotState do
  use GenServer
  require Logger

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
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
    state
  end

  def load do
    default_state = %{
      mcu_params: %{},
      location: [0, 0, 0],
      pins: %{},
      configuration: %{ os_auto_update: false,
                        fw_auto_update: false,
                        steps_per_mm:   500 },
      informational_settings: %{
        controller_version: Fw.version,
        private_ip: nil
      }
    }
    case SafeStorage.read(__MODULE__) do
      { :ok, rcontents } ->
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

  # This call should probably be a cast actually, and im sorry.
  # Returns true for configs that exist and are the correct typpe,
  # and false for anything else
  # TODO make sure these are properly typed.
  def handle_call({:update_config, "os_auto_update", value}, _from, state)
  when is_boolean(value) do
    new_config = Map.put(state.configuration, :os_auto_update, value)
    {:reply, true, Map.put(state, :configuration, new_config)}
  end

  def handle_call({:update_config, "fw_auto_update", value}, _from, state)
  when is_boolean(value) do
    new_config = Map.put(state.configuration, :fw_auto_update, value)
    {:reply, true, Map.put(state, :configuration, new_config)}
  end

  def handle_call({:update_config, "steps_per_mm", value}, _from, state)
  when is_integer(value) do
    new_config = Map.put(state.configuration, :steps_per_mm, value)
    {:reply, true, Map.put(state, :configuration, new_config)}
  end

  def handle_call({:update_config, key, _value}, _from, state) do
    Logger.error("#{key} is not a valid config.")
    {:reply, false, state}
  end

  def handle_call({:get_config, key}, _from, state)
  when is_atom(key) do
    {:reply, Map.get(state.configuration, key), state}
  end

  def handle_cast({:update_info, key, value}, state) do
    new_info = Map.put(state.informational_settings, key, value)
    {:noreply, Map.put(state, :informational_settings, new_info)}
  end

  def handle_cast({:set_pos, {x, y, z}}, state) do
    {:noreply, Map.put(state, :location, [x, y, z])}
  end

  def handle_cast({:set_pin_value, {pin, value}}, state) do
    pin_state = state.pins
    new_pin_value =
    case Map.get(pin_state, Integer.to_string(pin)) do
      nil                     ->
        %{mode: -1,   value: value}
      %{mode: mode, value: _} ->
        %{mode: mode, value: value}
    end
    # I REALLY don't want this to be here.
    spawn fn -> RPCMessageHandler.log("PIN #{pin} set: #{new_pin_value.value}", [], ["BotControl"]) end
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
    # THIS SHOULDN'T BE HERE
    msg = "Checking for updates!"
    Logger.debug(msg)
    spawn fn -> RPCMessageHandler.log(msg, [], ["BotUpdates"]) end
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

  def apply_status(state) do
    p = Process.whereis(NewHandler)
    if(is_pid(p) == true and Process.alive?(p) == true) do
      Process.sleep(500) # I don't remember why i did this.
      Command.home_all(100)
      apply_params(state.mcu_params)
      apply_pins(state.pins)
    else
      Process.sleep(10)
      apply_status(state)
    end
    state
  end

  def apply_params(params) when is_map(params) do
    case Enum.partition(params, fn({param, value}) ->
      # WILL SOMEONE JUST DOWNCASE THE PARAMS.
      param_int = Gcode.parse_param(Atom.to_string(param))
      spawn fn -> Command.update_param(param_int, value) end
    end)
    do
      {[], []} -> Logger.debug("Fresh mcu params state")
                  Command.read_all_params
      {_, []} -> Logger.debug("Params are set!")
      {_, errors} -> Logger.error("Error resetting params: #{inspect errors}")
    end
  end

  def apply_params(params) do
    Logger.error("Something weird happened applying last params: #{inspect params}")
  end

  def apply_pins(pins) when is_map(pins) do
    Logger.debug("Setting Pins")
    case Enum.all?(pins, fn({pin_str, %{mode: mode, value: value} }) ->
      p = String.to_integer(pin_str)
      spawn fn -> Command.write_pin(p, value, mode) end
    end) do
      true -> Logger.debug("Pins are set!")
      false -> Logger.error("Error resetting pins")
    end
  end

  def update_config(config_key, value)
  when is_bitstring(config_key) do
    GenServer.call(__MODULE__, {:update_config, config_key, value})
  end

  def get_config(config_key) when is_atom(config_key) do
    GenServer.call(__MODULE__, {:get_config, config_key})
  end

  defp save_interval do
    Process.send_after(__MODULE__, :save, @save_interval)
  end

  defp check_updates do
    Process.send_after(__MODULE__, :check_updates, @twelve_hours)
  end
end
