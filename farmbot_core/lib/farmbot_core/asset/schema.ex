defmodule FarmbotCore.Asset.Schema do
  @moduledoc """
  Common Schema attributes.
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @behaviour FarmbotCore.Asset.Schema
      @behaviour FarmbotCore.Asset.View

      import FarmbotCore.Asset.View, only: [view: 2]

      @doc "Path on the Farmbot Web API"
      def path, do: Keyword.fetch!(unquote(opts), :path)
      @primary_key {:local_id, :binary_id, autogenerate: true}
      @timestamps_opts inserted_at: :created_at, type: :utc_datetime
    end
  end

  @doc "API path for HTTP requests."
  @callback path() :: Path.t()

  @doc "Apply params to a changeset or object."
  @callback changeset(map, map) :: Ecto.Changeset.t()
end
