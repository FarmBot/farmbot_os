defmodule BotSync do
  use GenServer
  require Logger

  def init(_args) do
    {:ok, %{token: nil, resources: nil }}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast(_, %{token: nil, resources: _}) do
    spawn fn -> try_to_get_token end
    {:noreply, %{token: nil, resources: nil}}
  end

  def handle_cast(:sync, %{token: token, resources: old}) do
    server = Map.get(token, "unencoded") |> Map.get("iss")
    auth = Map.get(token, "encoded")

    case HTTPotion.get "#{server}/api/sync",
    [headers: ["Content-Type": "application/json",
               "Authorization": "Bearer " <> auth]] do

     %HTTPotion.Response{body: body,
                         headers: _headers,
                         status_code: 200} ->
       RPCMessageHandler.log("synced", [], ["BotSync"])
       new = Map.merge(old || %{}, Poison.decode!(body))
       {:noreply, %{token: token, resources: new }}
     error ->
       Logger.debug("Couldn't get resources: #{error}")
       RPCMessageHandler.log("Error syncing: #{inspect error}", [:error_toast], ["BotSync"])
       {:noreply, %{token: token, resources: %{}}}
    end
  end

  def handle_call({:token, token}, _from, %{token: _, resources: _}) do
    {:reply, :ok, %{token: token, resources: nil}}
  end

  def handle_call(_,_from, %{token: nil, resources: _}) do
    Logger.debug("Please make sure you have a token first.")
    {:reply, :no_token, %{token: nil, resources: nil}}
  end

  def handle_call({:save_sequence, seq}, _from, %{token: token, resources: resources}) do
    new_resources = Map.put(resources, "sequences", [seq | Map.get(resources, "sequences")] )
    {:reply, :ok, %{token: token, resources: new_resources}}
  end

  def handle_call(:fetch, _from, %{token: token, resources: resources}) do
    {:reply, resources, %{token: token, resources: resources}}
  end

  def handle_call({:get_sequence, id}, _from, %{token: token, resources: resources}) do
    sequences = Map.get(resources, "sequences")
    got = Enum.find(sequences, fn(sequence) -> Map.get(sequence, "id") == id end)
    {:reply, got, %{token: token, resources: resources}}
  end

  def handle_call(:get_sequences, _from, %{token: token, resources: resources}) do
    sequences = Map.get(resources, "sequences")
    {:reply, sequences, %{token: token, resources: resources}}
  end

  def handle_call({:get_regimen, id}, _from, %{token: token, resources: resources}) do
    regimens = Map.get(resources, "regimens")
    got = Enum.find(regimens, fn(regimen) -> Map.get(regimen, "id") == id end)
    {:reply, got, %{token: token, resources: resources}}
  end

  def handle_call(:get_regimens, _from, %{token: token, resources: resources}) do
    regimens = Map.get(resources, "regimens")
    {:reply, regimens, %{token: token, resources: resources}}
  end

  def handle_call({:get_regimen_item, id}, _from, %{token: token, resources: resources}) do
    regimens_items = Map.get(resources, "regimen_items")
    got = Enum.find(regimens_items, fn(regimen_item) -> Map.get(regimen_item, "id") == id end)
    {:reply, got, %{token: token, resources: resources}}
  end

  def handle_call(:get_regimen_items, _from, %{token: token, resources: resources}) do
    regimen_items = Map.get(resources, "regimen_items")
    {:reply, regimen_items, %{token: token, resources: resources}}
  end

  def handle_call({:add_regimen_item, item}, _from, %{token: token, resources: resources}) do
    {:reply, :ok, %{token: token, resources: Map.put(resources, "regimen_items", Map.get(resources, "regimen_items") ++ [item] )}}
  end

  # REALLY BAD LOGIC HERE
  # TODO: make this a little cleaner
  def handle_call({:get_corpus, id}, _from, %{token: token, resources: resources} ) do
    case Map.get(resources, "corpuses") do
      nil ->
        msg = "Compiling Sequence Instruction Set"
        Logger.debug(msg)
        RPCMessageHandler.log(msg, [], ["BotSync"])
        server = Map.get(token, "unencoded") |> Map.get("iss")
        c = get_corpus_from_server(server, id)
        m = String.to_atom("Elixir.SequenceInstructionSet_"<>"#{id}")
        m.create_instruction_set(c)
        {:reply, Module.concat(SiS, "Corpus_#{id}"), %{token: token, resources: Map.put(resources, "corpuses", [c])}}
      _corpuses ->
        {:reply, Module.concat(SiS, "Corpus_#{id}"), %{token: token, resources: resources}}
    end
  end

  defp get_corpus_from_server(server, id) do
     case HTTPotion.get(server<>"/api/corpuses/#{id}") do
       %HTTPotion.Response{body: body,
                           headers: _headers,
                           status_code: 200} ->
         Poison.decode!(body)
        error -> error
     end
  end


  def sync do
    GenServer.cast(__MODULE__, :sync)
  end

  def fetch do
    GenServer.call(__MODULE__, :fetch)
  end

  def get_sequence(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_sequence, id})
  end

  def get_sequences do
    GenServer.call(__MODULE__, :get_sequences)
  end

  def get_regimen(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_regimen, id})
  end

  def get_regimens do
    GenServer.call(__MODULE__, :get_regimens)
  end

  def get_regimen_item(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_regimen_item, id})
  end

  def get_regimen_items do
    GenServer.call(__MODULE__, :get_regimen_items)
  end

  def get_corpus(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_corpus, id})
  end

  def try_to_get_token do
    case Auth.get_token do
      nil -> try_to_get_token
      {:error, reason} -> {:error, reason}
      token -> GenServer.call(__MODULE__, {:token, token})
    end
  end
end
