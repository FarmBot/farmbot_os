defmodule BotSync do
  use GenServer
  require Logger

  def init(_args) do
    token = case FarmbotAuth.get_token() do
      {:ok, token} -> token
      _ -> nil
    end
    {:ok, %{token: token,
            resources: load_old_resources,
            corpuses: load_old_corpuses
            }}
  end

  def load_old_corpuses do
    case SafeStorage.read(__MODULE__.Corpuses) do
      {:ok, old} ->
        Enum.each(old, fn(corpus) ->
          Logger.debug("Compiling last known good corpuses.")
          m = String.to_atom("Elixir.SequenceInstructionSet_"<>"#{corpus.tag}")
          m.create_instruction_set(corpus)
        end)
        old
      _ -> []
    end
    # []
  end

  def load_old_resources do
     default = Sync.create(%{"compat_num" => -1,
      "device" => %{
        "id" => -1,
        "planting_area_id" => -1,
        "webcam_url" => "loading...",
        "name" => "loading..."
        },
      "peripherals" =>   [],
      "plants" =>        [],
      "regimen_items" => [],
      "regimens" =>      [],
      "sequences" =>     [],
      "users" =>         []})
      case SafeStorage.read(__MODULE__.Resources) do
        {:ok, %Sync{} = old_state} -> old_state
        _ -> default
      end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast(:sync, %{token: nil, resources: old, corpuses: oldc}) do
    {:noreply, %{token: nil, resources: old, corpuses: oldc}}
  end

  # When new stuff comes in from a sync
  def handle_cast(:sync, %{token: token, resources: old, corpuses: oldc}) do
    "//" <> server = Map.get(token, "unencoded") |> Map.get("iss")
    auth = Map.get(token, "encoded")

    case HTTPotion.get "#{server}/api/sync",
    [headers: ["Content-Type": "application/json",
               "Authorization": "Bearer " <> auth]] do

     %HTTPotion.Response{body: body,
                         headers: _headers,
                         status_code: 200} ->
       new = Poison.decode!(body)
       |> Sync.create

       # If we didn't have any peripherals before this sync, read the new ones
       old_perifs = old.peripherals
       new_perifs = new.peripherals
       if(old_perifs != new_perifs) do
         Enum.all?(new_perifs, fn(x) ->
           Command.read_pin(x.pin, x.mode)
         end)
       end
       new_merged = Map.merge(old ,new)
       RPC.MessageHandler.log("Synced", [], ["BotSync"])
       SafeStorage.write(__MODULE__.Resources, :erlang.term_to_binary(new_merged))
       SafeStorage.write(__MODULE__.Corpuses, :erlang.term_to_binary(oldc))
       {:noreply, %{token: token, resources: new_merged, corpuses: oldc }}
     error ->
       Logger.debug("Couldn't get resources: #{inspect error}")
       RPC.MessageHandler.log("Error syncing: #{inspect error}", [:error_toast], ["BotSync"])
       {:noreply, %{token: token, resources: old, corpuses: oldc}}
    end
  end

  def handle_call({:save_sequence, seq}, _from, %{token: token, resources: resources, corpuses: oldc}) do
    new_resources = Map.put(resources, "sequences", [seq | Map.get(resources, "sequences")] )
    {:reply, :ok, %{token: token, resources: new_resources, corpuses: oldc}}
  end

  def handle_call(:fetch, _from, %{token: token, resources: resources, corpuses: oldc}) do
    {:reply, resources, %{token: token, resources: resources, corpuses: oldc}}
  end

  def handle_call({:get_sequence, id}, _from, %{token: token, resources: resources,corpuses: oldc }) do
    sequences = resources.sequences
    got = Enum.find(sequences, fn(sequence) -> Map.get(sequence, :id) == id end)
    {:reply, got, %{token: token, resources: resources, corpuses: oldc}}
  end

  def handle_call(:get_sequences, _from, %{token: token, resources: resources, corpuses: oldc}) do
    {:reply, resources.sequences, %{token: token, resources: resources, corpuses: oldc}}
  end

  def handle_call({:get_regimen, id}, _from, %{token: token, resources: resources, corpuses: oldc}) do
    regimens = resources.regimens
    got = Enum.find(regimens, fn(regimen) -> Map.get(regimen, :id) == id end)
    {:reply, got, %{token: token, resources: resources, corpuses: oldc}}
  end

  def handle_call(:get_regimens, _from, %{token: token, resources: resources, corpuses: oldc}) do
    {:reply, resources.regimens, %{token: token, resources: resources, corpuses: oldc}}
  end

  def handle_call({:get_regimen_item, id}, _from, %{token: token, resources: resources, corpuses: oldc}) do
    regimen_items = resources.regimen_items
    got = Enum.find(regimen_items, fn(regimen_item) -> regimen_item.id == id end)
    {:reply, got, %{token: token, resources: resources, corpuses: oldc}}
  end

  def handle_call(:get_regimen_items, _from, %{token: token, resources: resources, corpuses: oldc}) do
    regimen_items = resources.regimen_items
    {:reply, regimen_items, %{token: token, resources: resources, corpuses: oldc}}
  end

  # REALLY BAD LOGIC HERE
  # TODO: make this a little cleaner
  def handle_call({:get_corpus, id}, _from, %{token: token, resources: resources, corpuses: oldc} ) do
    case oldc do
      [] ->
        msg = "Compiling Sequence Instruction Set"
        Logger.debug(msg)
        RPC.MessageHandler.log(msg, [], ["BotSync"])
        "//"<>server = Map.get(token, "unencoded") |> Map.get("iss")
        c = get_corpus_from_server(server, id)
        m = String.to_atom("Elixir.SequenceInstructionSet_"<>"#{id}")
        m.create_instruction_set(c)
        {:reply, Module.concat(SiS, "Corpus_#{id}"),
          %{token: token,
            resources: resources, corpuses: oldc ++ [c] }}
      _corpuses ->
        {:reply, Module.concat(SiS, "Corpus_#{id}"),
          %{token: token, resources: resources, corpuses: oldc}}
    end
  end

  def handle_info({:authorization, token}, %{token: _, resources: resources, corpuses: cor}) do
    {:noreply, %{token: token, resources: resources, corpuses: cor}}
  end

  defp get_corpus_from_server(server, id) do
     case HTTPotion.get(server<>"/api/corpuses/#{id}") do
       %HTTPotion.Response{body: body,
                           headers: _headers,
                           status_code: 200} ->
         Poison.decode!(body)
         |> Corpus.create
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
end
