defmodule BotState do
  use GenServer
  require Logger

  @bot_state_save_file Application.get_env(:fb, :bot_state_save_file)
  @save_interval 15000

  def init(_) do
    save_interval
    {:ok, load}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def save(state) do
    File.write!(@bot_state_save_file, :erlang.term_to_binary(state))
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
        :erlang.binary_to_term(contents)
        |> Map.put(:mcu_params, %{})
        |> Map.put(:pins, %{})
        |> Map.put(:informational_settings, %{ controller_version: Fw.version })
      _ -> default_state
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
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

  def apply_status(_state) do
    Logger.debug("TODO: Apply bot state")
  end

  defp save_interval do
    Process.send_after(__MODULE__, :save, @save_interval)
  end
end
