defmodule Farmbot.Repo.Syncable do
  @moduledoc "Behaviour for syncable modules."

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
      import Farmbot.Repo.Syncable, only: [ensure_time: 2]
      require Logger

      def fetch(id) do
        {_, plural} = struct(__MODULE__).__meta__ |> Map.get(:source)
        Farmbot.HTTP.get!("/api/#{plural}/#{id}").body |> Poison.decode!(as: struct(__MODULE__))
      end

      if unquote(enable_sync) do
      end
    end
  end
end
