defmodule Farmbot.Repo.FarmEvent.ExecutableType do
  @executable_types ~w(Sequence Regimen)

  @moduledoc """
  Custom Ecto.Type for FarmEvent :executable_type field.

      * Ensures the value is in #{inspect @executable_types}.
      * Changes to the module implementation when loaded from the DB.
  """

  @behaviour Ecto.Type


  def type, do: :string

  def cast(string), do: {:ok, string}

  # Load from DB
  Enum.map(@executable_types, fn(exp) ->
    def load(unquote(exp)) do
      {:ok, Module.concat([Farmbot, Repo, unquote(exp)])}
    end
  end)

  def load(_), do: :error

  # Dump to DB
  Enum.map(@executable_types, fn(exp) ->
    def dump(unquote(exp)) do
      {:ok, unquote(exp)}
    end
  end)

  def dump(exe_type), do: :error
end
