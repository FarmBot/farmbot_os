defmodule Farmbot.BotState do
  @moduledoc "Central State accumulator."
  alias Farmbot.BotStateNG
  use GenServer

  @doc "Subscribe to BotState changes"
  def subscribe(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, :subscribe)
  end

  @doc "Set job progress."
  def set_job_progress(bot_state_server \\ __MODULE__, name, progress) do
    GenServer.call(bot_state_server, {:set_job_progress, name, progress})
  end

  def set_config_value(bot_state_server \\ __MODULE__, key, value) do
    GenServer.call(bot_state_server, {:set_config_value, key, value})
  end

  def set_user_env(bot_state_server \\ __MODULE__, key, value) do
    GenServer.call(bot_state_server, {:set_user_env, key, value})
  end

  @doc "Fetch the current state."
  def fetch(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, :fetch)
  end

  def report_disk_usage(bot_state_server \\ __MODULE__, percent) do
    GenServer.call(bot_state_server, {:report_disk_usage, percent})
  end

  def report_memory_usage(bot_state_server \\ __MODULE__, megabytes) do
    GenServer.call(bot_state_server, {:report_memory_usage, megabytes})
  end

  def report_soc_temp(bot_state_server \\ __MODULE__, temp_celcius) do
    GenServer.call(bot_state_server, {:report_soc_temp, temp_celcius})
  end

  def report_uptime(bot_state_server \\ __MODULE__, seconds) do
    GenServer.call(bot_state_server, {:report_uptime, seconds})
  end

  def report_wifi_level(bot_state_server \\ __MODULE__, level) do
    GenServer.call(bot_state_server, {:report_wifi_level, level})
  end

  @doc "Put FBOS into maintenance mode."
  def enter_maintenance_mode(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, :enter_maintenance_mode)
  end

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @doc false
  def init([]) do
    IO.puts "bot state init"
    {:ok, %{tree: BotStateNG.new(), subscribers: []}}
  end

  @doc false
  def handle_call(:subscribe, {pid, _} = _from, state) do
    Process.link(pid)
    {:reply, state.tree, %{state | subscribers: Enum.uniq([pid | state.subscribers])}}
  end

  def handle_call(:fetch, _from, state) do
    {:reply, state.tree, state}
  end

  def handle_call({:set_job_progress, name, progress}, _from, state) do
    {reply, state} =
      BotStateNG.set_job_progress(state.tree, name, progress)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_config_value, key, value}, _from, state) do
    change = %{configuration: %{key => value}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

    def handle_call({:set_user_env, key, value}, _from, state) do
    {reply, state} =
      BotStateNG.set_user_env(state.tree, key, value)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_disk_usage, percent}, _form, state) do
    change = %{informational_settings: %{disk_usage: percent}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:memory_usage, megabytes}, _form, state) do
    change = %{informational_settings: %{memory_usage: megabytes}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_soc_temp, temp}, _form, state) do
    change = %{informational_settings: %{soc_temp: temp}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:uptime, seconds}, _form, state) do
    change = %{informational_settings: %{uptime: seconds}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_wifi_level, level}, _form, state) do
    change = %{informational_settings: %{wifi_level: level}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call(:enter_maintenance_mode, _form, state) do
    change = %{informational_settings: %{sync_status: "maintenance"}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  defp dispatch_and_apply(%Ecto.Changeset{valid?: true} = change, state) do
    state = %{state | tree: Ecto.Changeset.apply_changes(change)}

    state =
      Enum.reduce(state.subscribers, state, fn pid, state ->
        if Process.alive?(pid) do
          send(pid, {__MODULE__, change})
          state
        else
          Process.unlink(pid)
          %{state | subscribers: List.delete(state.subscribers, pid)}
        end
      end)

    {:ok, state}
  end

  defp dispatch_and_apply(%Ecto.Changeset{valid?: false} = change, state) do
    {{:error, change}, state}
  end
end
