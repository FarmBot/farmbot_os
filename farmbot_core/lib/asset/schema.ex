defmodule Farmbot.Asset.Schema do
  @moduledoc """
  Common Schema attributes.
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @behaviour Farmbot.Asset
      @behaviour Farmbot.Asset.View

      import Farmbot.Asset.View, only: [view: 2]

      @doc "Path on the Farmbot Web API"
      def path, do: Keyword.fetch!(unquote(opts), :path)
      @primary_key {:local_id, :binary_id, autogenerate: true}
      @timestamps_opts inserted_at: :created_at, type: :utc_datetime
    end
  end
end
