defmodule Farmbot.EctoTypes.TermType do
  @moduledoc "Encodes/decodes data via the Erlang Term Format"
  @behaviour Ecto.Type

  def type, do: :text

  def cast(binary) when is_binary(binary) do
    {:ok, :erlang.binary_to_term(binary)}
  end

  def cast(term) do
    {:ok, term}
  end

  def load(binary) when is_binary(binary), do: {:ok, :erlang.binary_to_term(binary)}
  def dump(term), do: {:ok, :erlang.term_to_binary(term)}
end
