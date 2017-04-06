defmodule Farmbot.SequenceRunner.Binding do
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, [], opts)

  def stop(binding), do: GenServer.stop(binding)

  def init([]) do
    {:ok, []}
  end

end
