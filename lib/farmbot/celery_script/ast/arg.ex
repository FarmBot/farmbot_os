defmodule Farmbot.CeleryScript.AST.Arg do
  @moduledoc "CeleryScript Argument."

  @doc "Verify this arg."
  @callback verify(any) :: {:ok, any} | {:error, term}
end
