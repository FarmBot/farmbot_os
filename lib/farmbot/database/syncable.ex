defmodule Farmbot.Database.Syncable do
  @moduledoc """
    Provies functionality for syncables.
  """

  @enforce_keys [:ref_id, :body]
  defstruct @enforce_keys

  @typedoc """
    Module structs.
  """
  @type body :: map

  @type ref_id :: Farmbot.Database.ref_id
  @type t :: %__MODULE__{ref_id: ref_id, body: body}
  alias Farmbot.Context

  @doc """
    Pipe a HTTP request thru this. Trust me :tm:
  """
  def parse_resp({:error, message}, _module), do: {:error, message}
  def parse_resp({:ok, %{status_code: 200, body: resp_body}}, module) do
    try do


    stuff = resp_body |> Poison.decode!
    cond do
      is_list(stuff) -> Enum.map(stuff, fn(item) -> module.to_struct(item) end)
      is_map(stuff)  -> module.to_struct(stuff)
      true           -> {:error, "Hashes and arrays only, please."}
    end
  rescue
    e in Poison.SyntaxError ->
      require IEx
      IEx.pry
      reraise Poison.SyntaxError, e, System.stacktrace()
    end
  end

  def parse_resp({:ok, whatevs}, _module) do
    {:error, whatevs}
  end

  @doc ~s"""
    Builds common functionality for all Syncable Resources. `args` takes two keywords.
      * `model` - a definition of the struct.
      * `endpoint` -  a tuple shaped like: {"/single_url", "/plural_url"}

    Heres what it _WILL_ provide:
      * For HTTP access we have:
        * `sindular_url/0` - The single url endpoint
        * `plural_url/0` - The plural url endpoint
        * `fetch/1` and `fetch/2`
          * `fetch/1` - takes a callback of either an anon function, or a tuple
          shaped: {module, function, args} where the first arg is the result
          described below.
          * `fetch/2` - takes an id and a callback described above.

      * For Data manipulation
        * `to_struct/1` - takes a stringed map and _safely_ turns it into a stuct.

    Heres what it _WILL NOT_ provide:
      * local database access
      * extensibility
  """
  defmacro __using__(args) do
    model = Keyword.get(args, :model) || raise "You need a model!"
    {singular, plural} = Keyword.get(args, :endpoint) || raise "Syncable requ"
     <> "ires a endpoint: {singular_url, plural_url}"
    quote do
      alias Farmbot.HTTP
      import Farmbot.Database.Syncable, only: [parse_resp: 2]
      defstruct unquote(model) ++ [:id]

      @doc """
        The Singular api endpoing url.
      """
      def singular_url, do: unquote(singular)

      @doc """
        The plural api endpoint.
      """
      def plural_url, do: unquote(plural)

      @doc """
        Fetches all `#{__MODULE__}` objects from the API.
      """
      def fetch(%Context{} = context, then) do
        url = "/api" <> plural_url()
        result = HTTP.get(context, url) |> parse_resp(__MODULE__)
        case then do
          {module, function, args}    -> apply(module, function, [result | args])
          anon when is_function(anon) -> anon.(result)
        end
      end

      @doc """
        Fetches a specific `#{__MODULE__}` from the API, by it's id.
      """
      def fetch(%Context{} = context, id, then) do
        url = "/api" <> unquote(singular) <> "/#{id}"
        result = context |> HTTP.get(url) |> parse_resp(__MODULE__)
        case then do
          {module, function, args}    -> apply(module, function, [result | args])
          anon when is_function(anon) -> anon.(result)
        end
      end

      @doc """
        Changes a string map, to a struct
      """
      def to_struct(item) do
        module = __MODULE__
        sym_keys = Map.keys(%__MODULE__{})
        str_keys = Enum.map(sym_keys, fn(key) -> Atom.to_string(key) end)

        next = Map.take(item, str_keys)
        new = Map.new(next, fn({key, val}) -> {String.to_atom(key), val} end)
        struct(module, new)
      end

    end
  end
end
