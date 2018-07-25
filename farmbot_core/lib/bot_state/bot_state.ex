defmodule Farmbot.BotState do
  @moduledoc "Central State accumulator."
  alias Farmbot.BotState
  alias BotState.{
    McuParams,
    LocationData,
    Configuration,
    InformationalSettings,
    Pin
  }

  defstruct [
    mcu_params: struct(McuParams),
    location_data: struct(LocationData),
    configuration: struct(Configuration),
    informational_settings: struct(InformationalSettings),
    pins: %{},
    process_info: %{farmwares: %{}},
    gpio_registry: %{},
    user_env: %{},
    jobs: %{}
  ]

  use GenStage

  def download_progress_fun(name) do
    alias Farmbot.BotState.JobProgress
    require Farmbot.Logger
    fn(bytes, total) ->
      {do_send, prog} = cond do
        # if the total is complete spit out the bytes,
        # and put a status of complete.
        total == :complete ->
          Farmbot.Logger.success 3, "#{name} complete."
          {true, %JobProgress.Bytes{bytes: bytes, status: :complete}}

        # if we don't know the total just spit out the bytes.
        total == nil ->
          # debug_log "#{name} - #{bytes} bytes."
          {rem(bytes, 10) == 0, %JobProgress.Bytes{bytes: bytes}}
        # if the number of bytes == the total bytes,
        # percentage side is complete.
        (div(bytes, total)) == 1 ->
          Farmbot.Logger.success 3, "#{name} complete."
          {true, %JobProgress.Percent{percent: 100, status: :complete}}
        # anything else is a percent.
        true ->
          percent = ((bytes / total) * 100) |> round()
          # Logger.busy 3, "#{name} - #{bytes}/#{total} = #{percent}%"
          {rem(percent, 10) == 0, %JobProgress.Percent{percent: percent}}
      end
      if do_send do
        Farmbot.BotState.set_job_progress(name, prog)
      else
        :ok
      end
    end
  end

  @doc "Set job progress."
  def set_job_progress(name, progress) do
    GenServer.call(__MODULE__, {:set_job_progress, name, progress})
  end

  def clear_progress_fun(name) do
    GenServer.call(__MODULE__, {:clear_progress_fun, name})
  end

  @doc "Fetch the current state."
  def fetch do
    GenStage.call(__MODULE__, :fetch)
  end

  def report_disk_usage(percent) when is_number(percent) do
    GenStage.call(__MODULE__, {:report_disk_usage, percent})
  end

  def report_memory_usage(megabytes) when is_number(megabytes) do
    GenStage.call(__MODULE__, {:report_memory_usage, megabytes})
  end

  def report_soc_temp(temp_celcius) when is_number(temp_celcius) do
    GenStage.call(__MODULE__, {:report_soc_temp, temp_celcius})
  end

  def report_uptime(seconds) when is_number(seconds) do
    GenStage.call(__MODULE__, {:report_uptime, seconds})
  end

  def report_wifi_level(level) when is_number(level) do
    GenStage.call(__MODULE__, {:report_wifi_level, level})
  end

  @doc "Put FBOS into maintenance mode."
  def enter_maintenance_mode do
    GenStage.call(__MODULE__, :enter_maintenance_mode)
  end

  @doc false
  def start_link(args) do
    GenStage.start_link(__MODULE__, args, [name: __MODULE__])
  end

  @doc false
  def init([]) do
    Farmbot.Registry.subscribe()
    send(self(), :get_initial_configuration)
    send(self(), :get_initial_mcu_params)
    {:consumer, struct(BotState), [subscribe_to: [Farmbot.Firmware]]}
  end

  @doc false
  def handle_call(:fetch, _from, state) do
    Farmbot.Registry.dispatch(__MODULE__, state)
    {:reply, state, [], state}
  end

  # TODO(Connor) - Fix this to use event system.
  def handle_call({:set_job_progress, name, progress}, _from, state) do
    jobs = Map.put(state.jobs, name, progress)
    new_state = %{state | jobs: jobs}
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:reply, :ok, [], new_state}
  end

  # TODO(Connor) - Fix this to use event system.
  def handle_call({:clear_progress_fun, name}, _from, state) do
    jobs = Map.delete(state.jobs, name)
    new_state = %{state | jobs: jobs}
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:reply, :ok, [], new_state}
  end

  def handle_call({:report_disk_usage, percent}, _form, state) do
    event = {:informational_settings, %{disk_usage: percent}}
    new_state = handle_event(event, state)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:reply, :ok, [], new_state}
  end

  def handle_call({:memory_usage, megabytes}, _form, state) do
    event = {:informational_settings, %{memory_usage: megabytes}}
    new_state = handle_event(event, state)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:reply, :ok, [], new_state}
  end

  def handle_call({:report_soc_temp, temp}, _form, state) do
    event = {:informational_settings, %{soc_temp: temp}}
    new_state = handle_event(event, state)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:reply, :ok, [], new_state}
  end

  def handle_call({:uptime, seconds}, _form, state) do
    event = {:informational_settings, %{uptime: seconds}}
    new_state = handle_event(event, state)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:reply, :ok, [], new_state}
  end

  def handle_call({:report_wifi_level, level}, _form, state) do
    event = {:informational_settings, %{wifi_level: level}}
    new_state = handle_event(event, state)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:reply, :ok, [], new_state}
  end

  def handle_call(:enter_maintenance_mode, _form, state) do
    event = {:informational_settings, %{sync_status: :maintenance}}
    new_state = handle_event(event, state)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:reply, :ok, [], new_state}
  end

  @doc false
  def handle_info({Farmbot.Registry, {Farmbot.Config, {"settings", key, val}}}, state) do
    event = {:settings, %{String.to_atom(key) => val}}
    new_state = handle_event(event, state)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:noreply, [], new_state}
  end

  def handle_info({Farmbot.Registry, {Farmbot.Asset.Repo, {:sync_status, status}}}, state) do
    event = {:informational_settings, %{sync_status: status}}
    new_state = handle_event(event, state)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:noreply, [], new_state}
  end

  def handle_info({Farmbot.Registry, _}, state), do: {:noreply, [], state}

  def handle_info(:get_initial_configuration, state) do
    full_config = Farmbot.Config.get_config_as_map()
    settings = full_config["settings"]
    new_state = Enum.reduce(settings, state, fn({key, val}, state) ->
      event = {:settings, %{String.to_atom(key) => val}}
      handle_event(event, state)
    end)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:noreply, [], new_state}
  end

  def handle_info(:get_initial_mcu_params, state) do
    full_config = Farmbot.Config.get_config_as_map()
    settings = full_config["hardware_params"]
    new_state = Enum.reduce(settings, state, fn({key, val}, state) ->
      event = {:mcu_params, %{String.to_atom(key) => val}}
      handle_event(event, state)
    end)
    Farmbot.Registry.dispatch(__MODULE__, new_state)
    {:noreply, [], new_state}
  end

  @doc false
  def handle_events(events, _from, state) do
    state = Enum.reduce(events, state, &handle_event(&1, &2))
    Farmbot.Registry.dispatch(__MODULE__, state)
    {:noreply, [], state}
  end

  @doc false
  def handle_event({:informational_settings, data}, state) do
    new_data = Map.merge(state.informational_settings, data) |> Map.from_struct()
    new_informational_settings = struct(InformationalSettings, new_data)
    %{state | informational_settings: new_informational_settings}
  end

  def handle_event({:mcu_params, data}, state) do
    new_data = Map.merge(state.mcu_params, data) |> Map.from_struct()
    new_mcu_params = struct(McuParams, new_data)
    %{state | mcu_params: new_mcu_params}
  end

  def handle_event({:location_data, data}, state) do
    new_data = Map.merge(state.location_data, data) |> Map.from_struct()
    new_location_data = struct(LocationData, new_data)
    %{state | location_data: new_location_data}
  end

  def handle_event({:pins, data}, state) do
    new_data = Enum.reduce(data, state.pins, fn({number, pin_state}, pins) ->
      Map.put(pins, number, struct(Pin, pin_state))
    end)
    %{state | pins: new_data}
  end

  def handle_event({:settings, data}, state) do
    new_data = Map.merge(state.configuration, data) |> Map.from_struct()
    new_configuration = struct(Configuration, new_data)
    %{state | configuration: new_configuration}
  end

  def handle_event(event, state) do
    IO.inspect event, label: "unhandled event"
    state
  end
end
