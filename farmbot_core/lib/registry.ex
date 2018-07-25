defmodule Farmbot.Registry do
  @moduledoc "Farmbot System Global Registry"
  @reg FarmbotRegistry
  use GenServer

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  @doc "Dispatch a global event from a namespace."
  def dispatch(namespace, event) do
    GenServer.call(__MODULE__, {:dispatch, namespace, event})
  end

  def subscribe(pid \\ self()) do
    Elixir.Registry.register(@reg, __MODULE__, pid)
  end

  def drop_pattern(pattern, me, acc \\ []) do
    receive do
      {__MODULE__, {^pattern, _}} -> drop_pattern(pattern, me, acc)
      other -> drop_pattern(pattern, me, [other | acc])
    after 100 ->
      for msg <- Enum.reverse(acc) do
        send(me, msg)
      end
    end
  end

  def init([]) do
    # partitions = System.schedulers_online
    partitions = 1
    opts = [keys: :duplicate, partitions: partitions, name: @reg]
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
