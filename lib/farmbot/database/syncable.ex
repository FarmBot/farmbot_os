defmodule Farmbot.Database.Syncable do
  @moduledoc """
    Defines a syncable.
  """

  defstruct [:resource_identifier, :body]

  @type resource_identifier :: Farmbot.Database.resource_identifier
  @type t :: %__MODULE__{resource_identifier: resource_identifier, body: map}

  @doc """
    Pipe a HTTP request thru this. Trust me :tm:
  """
  def parse_resp({:error, message}, _module), do: {:error, message}
  def parse_resp({:ok, %{status_code: 200, body: resp_body}}, module) do
    stuff = resp_body |> Poison.decode!
    cond do
      is_list(stuff) -> Poison.decode!(as: [struct(stuff)])
      is_map(stuff)  -> Poison.decode!(as:  struct(stuff) )
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
        Get a `#{unquote(__MODULE__)}` by its Api id.
      """
      def by_id(id), do: Database.get_by_id(unquote(__MODULE__), id)

      @doc """
        Get all `#{unquote(__MODULE__)}` items.
      """
      def all, do: Database.get_all(unquote(__MODULE__))

      @doc """
        Fetches all `#{unquote(__MODULE__)}` objects from the API.
      """
      def fetch(then) do
        result = "/api" <> unquote(plural)
                    |> HTTP.get()
                    |> parse_resp(unquote(__MODULE__))
        case then do
          {module, function, args} -> apply(module, function, [result | args])
          anon                     -> anon.(result)
        end
      end

      @doc """
        Fetches a specific `#{unquote(__MODULE__)}` from the API, by it's id.
      """
      def fetch(id, then) do
        results = "/api" <> unquote(singular) <> "/#{id}"
                    |> HTTP.get()
                    |> parse_resp(unquote(__MODULE__))
        then.(results)
      end
    end
  end
end
