defmodule Farmbot.Database.Syncable do
  @moduledoc """
    Defines a syncable.
  """

  @doc """
    Pipe a HTTP request thru this. Trust me :tm:
  """
  def parse_resp(_resp, _module) do

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
      defstruct unquote(model) ++ [:uuid, :id]

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
      def fetch do
        "/api" <> unquote(plural)
        |> HTTP.get()
        |> parse_resp(unquote(__MODULE__))
      end

      @doc """
        Fetches a specific `#{unquote(__MODULE__)}` from the API, by it's id.
      """
      def fetch(id) do
        "/api" <> unquote(singular) <> "/#{id}"
        |> HTTP.get()
        |> parse_resp(unquote(__MODULE__))
      end

    end
  end

end
