defmodule Farmbot.Logger.NetLogger do
  @moduledoc false
  use GenStage
  use Farmbot.Logger

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    send self(), :try_connect
    {:consumer, %{client: nil}, subscribe_to: [Farmbot.Logger]}
  end

  def handle_events(_e, _from, %{client: nil} = state) do
    {:noreply, [], state}
  end

  def handle_events(events, _from, %{client: client} = state) do
    for e <- events do
      log = %NetLogger.Log{message: e.message, time: e.time, level: e.level, verbosity: e.verbosity}
      try do
        NetLogger.UDP.Client.log(client, log)
        :ok
      rescue
        _ -> :ok
      end
    end
    {:noreply, [], state}
  end

  def handle_info(:try_connect, %{client: nil} = state) do
    case NetLogger.UDP.Client.start_link([]) do
      {:ok, client} ->
        {:noreply, [], %{state | client: client}}
      {:error, _} ->
        Process.send_after(self(), :try_connect, 30_000)
        {:noreply, [], state}
    end
  end
end
