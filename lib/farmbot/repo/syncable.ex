defmodule Farmbot.Repo.Syncable do
  @moduledoc "Behaviour for syncable modules."

  @doc "Sync this module."
  @callback sync!(GenServer.server) :: any | no_return

  @doc "Changes iso8601 times to DateTime structs."
  def ensure_time(struct, []), do: struct
  def ensure_time(struct, [field | rest]) do
    {:ok, dt, _} = DateTime.from_iso8601(Map.get(struct, field))
    %{struct | field => dt}
    |> ensure_time(rest)
  end

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Farmbot.Repo.Syncable
      import Farmbot.Repo.Syncable, only: [ensure_time: 2]

      @doc """
      Syncs all #{__MODULE__ |> Module.split() |> List.last()}'s from the Farmbot Web App.
          1) Fetches JSON from the API.
          2) Parses JSON as a list of #{__MODULE__ |> Module.split() |> List.last()}'s.
          3) Inserts into the Repo.
      """
      def sync!(http) do
        {_, source} = struct(__MODULE__).__meta__.source
        http
        |> Farmbot.HTTP.get!("/api/#{source}")
        |> Map.fetch!(:body)
        |> Poison.decode!(as: [%__MODULE__{}])
        # |> fn(obj) -> IO.inspect obj end.()
        |> Enum.each(fn(obj) ->
          {:ok, _} = __MODULE__.changeset(obj, %{}) |> Farmbot.Repo.insert()
        end)
      end
    end

  end
end
