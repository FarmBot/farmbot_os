defmodule Farmbot do
  use GenServer

  def init(args) do
    resp = HTTPotion.get(args)
    Process.send_after(__MODULE__, :emit_message, 10000)
    case resp do
      %HTTPotion.ErrorResponse{message: _} -> {:ok, %{}}
      _ -> {:ok, Poison.decode!(resp.body)}
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def download_personality(url) do
    resp = HTTPotion.get(url)
    case resp do
      %HTTPotion.ErrorResponse{message: _} -> {:error, :could_not_get_personality}
      _ -> GenServer.call(__MODULE__, {:update_personality, Poison.decode!(resp.body) })
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update_personality, new_personality_map}, _from, _old_personality_map) do
    {:reply, :ok, new_personality_map}
  end

  def handle_info(:emit_message,personality_map) do
    {:noreply, personality_map}
  end
end
