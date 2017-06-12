defmodule Farmbot.Test.Helpers.HTTP do
  use   GenServer
  alias Farmbot.HTTP

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:request, :get, "http://localhost:3000/api/public_key", "", [], []}, _from, state) do
    pub_key = File.read!("fixture/api_fixture/public_key")
    response = %HTTP.Response{status_code: 200, body: pub_key, headers: []}
    {:reply, {:ok, response}, state}
  end

  def handle_call({:request, :get, "/api/" <> resource, "", [], []}, _from, state) do
    resource = String.replace(resource, "/", "_")
    if "#{resource}.json" in File.ls!("fixture/api_fixture") do
      json = File.read!("fixture/api_fixture/#{resource}.json") |> Poison.decode!
      response = %HTTP.Response{status_code: 200, body: json, headers: []}
      {:reply, {:ok, response}, state}
    else
      raise "Could not find: #{resource}"
    end
  end


  def handle_call({:request, :post, "http://localhost:3000/api/tokens", _, [], []}, _from, state) do
    token    = File.read!("fixture/api_fixture/token.json") |> Poison.decode!
    response = %HTTP.Response{status_code: 200, body: token, headers: []}
    {:reply, {:ok, response}, state}
  end


end
