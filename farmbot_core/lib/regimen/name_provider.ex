defmodule Farmbot.Regimen.NameProvider do
  @moduledoc """
  Provides global names for running regimens as started by the
  RegimenSupervisor.

  # Example
  ```
    %Regimen{} = reg = Farmbot.Asset.get_regimen_by_id(123, 100)
    via = Farmbot.Regimen.NameProvider.via(reg)
    pid = GenServer.whereis(via)
  ```
  """

  alias Farmbot.Asset.Regimen
  import Farmbot.Asset, only: [get_persistent_regimen: 1, delete_persistent_regimen: 1]
  use GenServer
  require Farmbot.Logger

  @checkup 45_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def via(%Regimen{} = regimen) do
    regimen.farm_event_id || raise "Regimen lookups require a farm_event_id"
    {:via, __MODULE__, regimen}
  end

  def whereis_name(%Regimen{} = regimen) do
    GenServer.call(__MODULE__, {:whereis_name, regimen})
  end

  def register_name(%Regimen{} = regimen, pid) do
    GenServer.call(__MODULE__, {:register_name, regimen, pid})
  end

  def unregister_name(%Regimen{} = regimen) do
    GenServer.call(__MODULE__, {:unregister_name, regimen})
  end

  def init([]) do
    start_timer()
    {:ok, %{}}
  end

  def handle_call({:whereis_name, regimen}, _, state) do
    # Farmbot.Logger.info 3, "whereis_name: #{regimen.name} #{regimen.farm_event_id}"
    case get_persistent_regimen(regimen) do
      nil ->
        {:reply, :undefined, state}
      %{id: id} ->
        {:reply, Map.get(state, id) || :undefined, state}
    end
  end

  def handle_call({:register_name, regimen, pid}, _, state) do
    # Farmbot.Logger.info 3, "register_name: #{regimen.name} #{regimen.farm_event_id}"
    case get_persistent_regimen(regimen) do
      nil ->
        Farmbot.Logger.error 1, "No persistent regimen for #{regimen.name} #{regimen.farm_event_id}"
        {:reply, :no, state}
      %{id: id} ->
        {:reply, :yes, Map.put(state, id, pid)}
    end
  end

  def handle_call({:unregister_name, regimen}, _, state) do
    # Farmbot.Logger.info 3, "unregister_name: #{regimen.name}"
    case delete_persistent_regimen(regimen) do
      {:ok, id} -> {:reply, :yes, Map.delete(state, id)}
      {:error, reason} ->
        Farmbot.Logger.error 1, "Failed to unregister #{regimen.name}: #{inspect reason}"
        {:reply, :no, state}
    end
  end

  def handle_info(:checkup, state) do
    new_state = Enum.filter(state, fn({_pr_id, pid}) ->
      Process.alive?(pid)
    end) |> Map.new()
    start_timer()
    {:noreply, new_state}
  end

  defp start_timer do
    Process.send_after(self(), :checkup, @checkup)
  end
end
