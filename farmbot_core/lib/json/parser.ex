defmodule Farmbot.JSON.Parser do
  @moduledoc """
  Callback module for wrapping a json dependency.
  """
  @callback decode(iodata) :: {:ok, term} | {:error, term}
  @callback encode(term) :: {:ok, iodata} | {:error, term}
end
