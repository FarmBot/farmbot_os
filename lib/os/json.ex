defmodule FarmbotOS.JSON do
  @moduledoc "Wraps a dependency for easy upgrade and no vendor lock."

  @parser FarmbotOS.JSON.JasonParser
  @spec decode(iodata, term) :: {:ok, term} | {:error, term}
  def decode(iodata, opts \\ []), do: @parser.decode(iodata, opts)

  @spec encode(term, term) :: {:ok, term} | {:error, term}
  def encode(data, opts \\ []), do: @parser.encode(data, opts)

  def decode!(iodata, opts \\ []) do
    case decode(iodata, opts) do
      {:ok, results} -> results
      {:error, reason} -> raise(reason)
    end
  end

  def encode!(data, opts \\ []) do
    case encode(data, opts) do
      {:ok, results} -> results
      {:error, reason} -> raise(reason)
    end
  end
end
