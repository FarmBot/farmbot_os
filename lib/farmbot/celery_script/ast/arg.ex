defmodule Farmbot.CeleryScript.AST.Arg do
  @moduledoc "CeleryScript Argument."

  @doc "Verify this arg."
  @callback decode(any) :: {:ok, any} | {:error, term}
  @callback encode(any) :: {:ok, any} | {:error, term}
end
