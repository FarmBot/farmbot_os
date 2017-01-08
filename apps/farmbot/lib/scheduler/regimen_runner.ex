alias Farmbot.Sync.Database.Regimen
# alias Farmbot.Sync.Database.RegimenItem

defmodule Farmbot.Scheduler.RegimenRunner do
  @moduledoc """
    Follows a regimen thru its life.
  """
  defmodule State do
    @moduledoc """
      State of the Regimen Runner
    """
    @enforece_keys []
    defstruct @enforece_keys

    @typedoc """

    """
    @type t :: %__MODULE__{}
  end

  require Logger
  use GenServer

  @doc """
    Starts a regimen's life. Takes a Regimen and items that have already been
    finished (if this regimen was already running.)
  """
  @spec start_link([Regimen.t]) ::
    {:ok, pid} | {:error, {:already_started, pid}}
  def start_link([%Regimen{} = reg]) do
    name = "Regimen.#{reg.id}" |> String.to_atom
    GenServer.start_link(__MODULE__, [], name: name)
  end
  def start_link(regimen), do: start_link([regimen])

  def init([]) do
    {:ok, []}
  end
  def handle_call(:get_state,_, state), do: {:reply, state, state}
  def handle_call(_, _, state), do: {:reply, :unhandled, state}
  def handle_cast(_, state), do: {:noreply, state}
  def handle_info(_, state), do: {:noreply, state}

  def get_state(id) do
     name = "Regimen.#{id}" |> String.to_atom
     GenServer.call(name, :get_state)
  end
end
