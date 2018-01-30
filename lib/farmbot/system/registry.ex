defmodule Farmbot.System.Registry do
  @moduledoc "Farmbot System Global Registry"
  @reg FarmbotRegistry

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc "Dispatch a global event from a namespace."
  def dispatch(namespace, event) do
    GenServer.call(__MODULE__, {:dispatch, namespace, event})
  end

  def subscribe(pid) do
    Elixir.Registry.register(@reg, __MODULE__, pid)
  end

  def init([]) do
    opts = [keys: :duplicate, partitions: System.schedulers_online, name: @reg]
    {:ok, reg} = Elixir.Registry.start_link(opts)
    {:ok, %{reg: reg}}
  end

  def handle_call({:dispatch, ns, event}, _from, state) do
    Elixir.Registry.dispatch(@reg, __MODULE__, fn(entries) ->
      for {pid, _} <- entries, do: send(pid, {__MODULE__, {ns, event}})
    end)
    {:reply, :ok, state}
  end
end
