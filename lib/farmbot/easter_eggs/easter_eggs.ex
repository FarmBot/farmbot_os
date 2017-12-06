defmodule Farmbot.EasterEggs do
  @moduledoc false

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    data =
      Path.join(:code.priv_dir(:farmbot), "easter_eggs.json")
      |> File.read!()
      |> Poison.decode!()

    {:ok, data}
  end
end
