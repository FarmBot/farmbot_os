defmodule Farmbot.Repo.JSONFloatType do
  @moduledoc "JSON Formatters truncate .0 on floats."

  @behaviour Ecto.Type
  def type, do: :string

  def cast(string) when is_binary(string) do
    case Float.parse(string) do
      {float, _} when is_float(float) -> {:ok, float}
      _ -> :error
    end
  end

  # This might be slow..
  def cast(int) when is_integer(int) do
    int
    |> to_string()
    |> cast()
  end

  def cast(float) when is_float(float) do
    {:ok, float}
  end

  def cast(_), do: :error

  def load(float) when is_float(float), do: {:ok, float}

  def dump(num), do: cast(num)
end
