defmodule FarmbotOS.Asset.Schema do
  @moduledoc """
  Common Schema attributes.
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @behaviour FarmbotOS.Asset.Schema
      @behaviour FarmbotOS.Asset.View

      import FarmbotOS.Asset.View, only: [view: 2]

      @doc "Path on the Farmbot Web API"
      def path, do: Keyword.fetch!(unquote(opts), :path)
      @primary_key {:local_id, :binary_id, autogenerate: true}
      @timestamps_opts inserted_at: :created_at, type: :utc_datetime_usec
    end
  end

  @doc "API path for HTTP requests."
  @callback path() :: Path.t() | false

  @doc "Apply params to a changeset or object."
  @callback changeset(map, map) :: Ecto.Changeset.t()
end
