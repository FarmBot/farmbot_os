defmodule Farmbot.Log.EasterEggs do
  @moduledoc """
  Just some random stuff that Farmbot likes to say and do from time to time.
  """
  use GenServer
  require Logger
  # @path "#{:code.priv_dir(:farmbot)}/static/easter_eggs.json"

  @type json_map :: map
  @type parsed_json :: %{nouns: [parsed_noun], verbs: [String.t]}
  @type json_noun :: map # %{"some_key" => "some_value"}
  @type parsed_noun :: map # %{some_key: "some_value"}

  @doc """
  Starts the Easter Eggs server. You can pass in a json map, a path to a
  json file, or nothing and it will load the default one.
  """
  @spec start_link({:name, binary}) :: {:ok, pid}
  def start_link({:name, name}),
    do: GenServer.start_link(__MODULE__,
          "#{:code.priv_dir(:farmbot)}/static/easter_eggs.json", name: name)

  @spec start_link({:name, binary}, {:path, binary}) :: {:ok, pid}
  def start_link({:name, name}, {:path, path}),
    do: GenServer.start_link(__MODULE__, path, name: name)

  @spec start_link({:name, binary}, {:json, map}) :: {:ok, pid}
  def start_link({:name, name}, {:json, json}),
    do: GenServer.start_link(__MODULE__, json, name: name)

  @spec init(json_map | binary) :: {:ok, parsed_json}
  def init(%{"nouns" => _, "verbs" => _} = json),
    do: json |> parse_easter_eggs_json

  def init(path) when is_binary(path) do
    path
    |> File.read!
    |> Poison.decode!
    |> parse_easter_eggs_json
  end

  @spec parse_easter_eggs_json(json_map) :: {:ok, parsed_json}
  defp parse_easter_eggs_json(%{"nouns" => nouns, "verbs" => verbs}) do
    g =
      %{nouns: parse_nouns(nouns),
        verbs: verbs}
    {:ok, g}
  end

  @spec parse_nouns([json_noun]) :: parsed_noun
  defp parse_nouns(nouns_json) when is_list(nouns_json) do
    Enum.reduce(nouns_json, %{}, fn(noun, acc) ->
      noun
      |> parse_noun
      |> Map.merge(acc)
    end)
  end

  @spec parse_noun(json_noun) :: parsed_noun
  defp parse_noun(n) when is_map(n) do
    Map.new(n, fn({string_key, v}) ->
      {String.to_atom(string_key), v}
    end)
  end

  @doc """
  Gets a random Farmbot verb
  """
  @spec verb(pid) :: String.t
  def verb(pid \\ __MODULE__), do: GenServer.call(pid, :verb)

  @doc """
  Logs a random "fun" sentence to the Web Interface.
  """
  @spec say_random_sentence(pid) :: :ok
  def say_random_sentence(pid \\ __MODULE__), do: GenServer.cast(pid, verb())

  @doc ~s"""
  Loads new json into the state.
  Example:
    iex> json = %{"nouns" => [%{"im_a_var" => "im a string"}],
    ...> "verbs" => ["says look at me! {{im_a_var}}!"]}
    iex> #{__MODULE__}.load_json(json)
    iex> #{__MODULE__}.say_random_sentence()
    #=> "Farmbot says look at me! im a string!"
  """
  @spec load_json(json_map) :: :ok
  def load_json(%{"nouns" => _, "verbs" => _} = json_map, pid \\ __MODULE__) do
    GenServer.cast(pid, json_map)
  end

  @spec get_random_minute :: integer
  defp get_random_minute, do: 0..59 |> Enum.random

  @spec get_random_hour :: integer
  defp get_random_hour, do: 1..3 |> Enum.random

  @doc """
  Says a random sentence at a random minute every 1 to 3 hours.
  """
  @spec start_cron_job(binary) :: :ok
  def start_cron_job(schedule \\ "#{get_random_minute()} */#{get_random_hour()} * * *") do
    job = %Quantum.Job{
            schedule: schedule,
            task: fn -> Farmbot.EasterEggs.say_random_sentence end}
    Quantum.add_job(__MODULE__, job)
  end

  @doc """
    Stops an already started job.
  """
  @spec stop_cron_job :: :no_job | map
  def stop_cron_job, do: __MODULE__ |> Quantum.find_job() |> do_delete_job

  @spec do_delete_job(any) :: :no_job | map
  defp do_delete_job(%Quantum.Job{name: j_name}), do: Quantum.delete_job(j_name)
  defp do_delete_job(_), do: :no_job

  # GEN SERVER CALLBACKS
  def handle_cast(sentence, %{nouns: nouns, verbs: verbs})
  when is_binary(sentence) do
    rendered = Mustache.render sentence, nouns
    Logger.info ">> " <> rendered, type: :fun
    {:noreply, %{nouns: nouns, verbs: verbs}}
  end

  def handle_cast(%{"nouns" => _, "verbs" => _} = json, _state) do
    {:ok, state} = parse_easter_eggs_json(json)
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call(:verb, _from, %{nouns: n, verbs: v}) do
    rv = v |> Enum.random
    {:reply, rv, %{nouns: n, verbs: v}}
  end
  def handle_call(_event, _from, state), do: {:reply, :unhandled, state}

  def handle_info(_event, state), do: {:noreply, state}
end
