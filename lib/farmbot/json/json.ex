defmodule Farmbot.JSON do
  @moduledoc "Wraps a dependency for easy upgrade and no vendor lock."

  @parser Application.get_env(:farmbot, :behaviour)[:json_parser]
  @parser || Mix.raise("Unconfigured JSON Parser.")
  @spec decode(iodata) :: {:ok, term} | {:error, term}
  def decode(iodata), do: @parser.decode(iodata)

  @spec encode(term) :: {:ok, term} | {:error, term}
  def encode(data), do: @parser.encode(data)

  def decode!(iodata) do
    case decode(iodata) do
      {:ok, results}  -> results
      {:error, reason} -> raise(reason)
    end
  end

  def encode!(data) do
    case encode(data) do
      {:ok, results}  -> results
      {:error, reason} -> raise(reason)
    end
  end
end
