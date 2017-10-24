defmodule Farmbot.HTTP do
  @moduledoc "Wraps an HTTP Adapter."
  use GenServer

  @adapter Application.get_env(:farmbot, :behaviour)[:http_adapter] || raise("No http adapter.")

  @doc "Make an HTTP Request."
  def request(method, url, body \\ "", headers \\ [], opts \\ [])

  @doc "HTTP GET request."
  def get(url, headers \\ [], opts \\ [])

  @doc "HTTP POST request."
  def post(url, headers \\ [], opts \\ [])

  @doc "Start HTTP Services."
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, adapter} = @adapter.start_link()
    Process.link(adapter)
    {:ok, %{adapter: adapter}}
  end
end
