defmodule Farmbot.Regimen.NameProvider do
  alias Farmbot.Asset.Regimen
  import Farmbot.System.ConfigStorage, only: [persistent_regimen: 2, add_persistent_regimen: 2, delete_persistent_regimen: 2]

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def via(%Regimen{} = regimen, %DateTime{} = time) do
    {:via, __MODULE__, {regimen, time}}
  end

  def whereis_name({%Regimen{} = regimen, %DateTime{} = time}) do
    GenServer.call(__MODULE__, {:whereis_name, regimen, time})
  end

  def register_name({%Regimen{} = regimen, %DateTime{} = time}, pid) do
    GenServer.call(__MODULE__, {:register_name, regimen, time, pid})
  end

  def unregister_name({%Regimen{} = regimen, %DateTime{} = time}) do
    GenServer.call(__MODULE__, {:unregister_name, regimen, time})
  end

  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:whereis_name, regimen, time}, _, state) do
    case persistent_regimen(regimen, time) do
      nil -> {:reply, :undefined, state}
      %{id: id} -> {:reply, Map.get(state, id) || raise("#{regimen.name} is not registered"), state}
    end
  end

  def handle_call({:register_name, regimen, time, pid}, _, state) do
    case add_persistent_regimen(regimen, time) do
      {:ok, %{id: id}} -> {:reply, :yes, Map.put(state, id, pid)}
      {:error, _reason} -> {:reply, :no, state}
    end
  end

  def handle_call({:unregister_name, regimen, time}, _, state) do
    case delete_persistent_regimen(regimen, time) do
      {:ok, id} -> {:reply, :yes, Map.delete(state, id)}
      {:error, reason} -> {:reply, :no, state}
    end
  end
end
