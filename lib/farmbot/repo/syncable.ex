defmodule Farmbot.Repo.Syncable do
  @moduledoc "Behaviour for syncable modules."

  @doc "Sync this module."
  @callback sync!(GenServer.server) :: any | no_return
  @optional_callbacks [sync!: 1]

  @doc "Changes iso8601 times to DateTime structs."
  def ensure_time(struct, []), do: struct
  def ensure_time(struct, [field | rest]) do
    {:ok, dt, _} = DateTime.from_iso8601(Map.get(struct, field))
    %{struct | field => dt}
    |> ensure_time(rest)
  end

  @doc false
  defmacro __using__(opts) do
    enable_sync = Keyword.get(opts, :sync, true)
    quote do
      @behaviour Farmbot.Repo.Syncable
      import Farmbot.Repo.Syncable, only: [ensure_time: 2]
      require Logger

      if unquote(enable_sync) do

        @doc """
        Syncs all #{__MODULE__ |> Module.split() |> List.last()}'s from the Farmbot Web App.
            1) Fetches JSON from the API.
            2) Parses JSON as a list of #{__MODULE__ |> Module.split() |> List.last()}'s.
            3) For each record in the list, checks if the item exists already,
            4) Inserts or Updates each item in the list into the Repo.
        """
        def sync!(http) do
          {_, source} = struct(__MODULE__).__meta__.source
          color = Farmbot.DebugLog.color(:RANDOM)
          Logger.info "#{color}[#{source}] Begin sync."
          http
          |> Farmbot.HTTP.get!("/api/#{source}")
          |> Map.fetch!(:body)
          # |> fn(bin) -> IO.inspect(Poison.decode!(bin)); bin end.()
          |> Poison.decode!(as: [%__MODULE__{}])
          # |> fn(obj) -> IO.inspect(obj); obj end.()
          |> Enum.each(fn(obj) ->
            # We need to check if this object exists in the database.
            case Farmbot.Repo.get(__MODULE__, obj.id) do
              # If it does not, just return the newly created object.
              nil -> obj
              # if there is an existing record, copy the ecto  meta from the old
              # record. This allows `insert_or_update` to work properly.
              existing -> %{obj | __meta__: existing.__meta__}
            end
            |>  __MODULE__.changeset() |> Farmbot.Repo.insert_or_update!()
          end)
          Logger.info "#{color}[#{source}] Complete sync."
        end

      end

      @doc "Fetch all #{__MODULE__}'s from the Repo."
      def fetch_all() do
        import Ecto.Query
        (from i in __MODULE__, select: i) |> Farmbot.Repo.all()
      end
    end

  end
end
