defmodule Farmbot.Database.Syncable do
  @moduledoc """
    Defines a syncable.
  """

  @enforce_keys [:ref_id, :body]
  defstruct @enforce_keys

  @type ref_id :: Farmbot.Database.ref_id
  @type t :: %__MODULE__{ref_id: ref_id, body: map}

  @doc """
    Pipe a HTTP request thru this. Trust me :tm:
  """
  def parse_resp({:error, message}, _module), do: {:error, message}
  def parse_resp({:ok, %{status_code: 200, body: resp_body}}, module) do
    stuff = resp_body |> Poison.decode!
    cond do
      is_list(stuff) -> Enum.map(stuff, fn(item) -> module.to_struct(item) end)
      is_map(stuff)  -> module.to_struct(stuff)
      true           -> {:error, "Hashes and arrays only, please."}
    end
  end

  def parse_resp({:ok, whatevs}, _module) do
    {:error, whatevs}
  end

  @doc false
  defmacro __using__(args) do
    model = Keyword.get(args, :model) || raise "You need a model!"
    {singular, plural} = Keyword.get(args, :endpoint) || raise "Syncable requ"
     <> "ires a endpoint: {singular_url, plural_url}"
    quote do
      alias Farmbot.Database
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
        Get a `#{__MODULE__}` by its Api id.
      """
      def by_id(id), do: Database.get_by_id(__MODULE__, id)

      @doc """
        Get all `#{__MODULE__}` items.
      """
      def all, do: Database.get_all(__MODULE__)

      @doc """
        Fetches all `#{__MODULE__}` objects from the API.
      """
      def fetch(then) do
        result = "/api" <> unquote(plural)
                    |> HTTP.get()
                    |> parse_resp(__MODULE__)
        case then do
          {module, function, args} -> apply(module, function, [result | args])
          anon                     -> anon.(result)
        end
      end

      @doc """
        Fetches a specific `#{__MODULE__}` from the API, by it's id.
      """
      def fetch(id, then) do
        result = "/api" <> unquote(singular) <> "/#{id}"
                    |> HTTP.get()
                    |> parse_resp(__MODULE__)
        case then do
          {module, function, args} -> apply(module, function, [result | args])
          anon                     -> anon.(result)
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
