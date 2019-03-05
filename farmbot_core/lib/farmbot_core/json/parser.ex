defmodule FarmbotCore.JSON.Parser do
  @moduledoc """
  Callback module for wrapping a json dependency.
  """
  @callback decode(iodata, term) :: {:ok, term} | {:error, term}
  @callback encode(term, term) :: {:ok, iodata} | {:error, term}
end
