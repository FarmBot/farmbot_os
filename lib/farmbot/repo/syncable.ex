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
  defmacro __using__(_opts) do
    quote do
      import Farmbot.Repo.Syncable, only: [ensure_time: 2]
    end
  end
end
