defmodule Farmbot.Repo.JSONType do
  @moduledoc "Stores JSON as :text data type."
  @behaviour Ecto.Type

  def type, do: :text

  # We don't need to translate anything for atoms or binaries.
  # We may have a problem with charlists here.
  def cast(basic) when is_binary(basic) or is_atom(basic) do
    {:ok, to_string(basic)}
  end

  # try to encode as json here.
  def cast(map_or_list) when is_list(map_or_list) or is_map(map_or_list) do
    case Poison.encode(map_or_list) do
      {:ok, bin} -> {:ok, bin}
      _ -> :error
    end
  end

  def cast(_), do: :error

  def load(text) do
    case Poison.decode(text, keys: :atoms) do
      {:ok, data} -> {:ok, data}
      _ -> :error
    end
  end

  # This doesn't feel correct.
  def dump(data), do: cast(data)
end
