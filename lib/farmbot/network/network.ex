defmodule Farmbot.Network do
  @moduledoc """
    uh
  """

  defmodule State do
    defstruct [connected?: false]
    @type t :: %__MODULE__{connected?: boolean}
  end
  require Logger

  def start_link(hardware) do
    GenServer.start_link(__MODULE__, hardware, name: __MODULE__)
  end

  def init(hardware) do
    handler = Module.concat([Farmbot,Network,Handler,hardware])
    Logger.debug ">> is initializing networking on: #{inspect hardware}"
    {:ok, manager} = handler.manager
    GenEvent.add_handler(manager, handler, self())
    {:ok, %State{}}
  end

  def handle_info(:connected, state) do
    Logger.debug ">> is connected!"
    {:noreply, state}
  end


end
