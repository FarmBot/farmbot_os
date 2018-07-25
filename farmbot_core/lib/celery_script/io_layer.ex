defmodule Farmbot.CeleryScript.IOLayer do
  @callback handle_io(Csvm.AST.t()) :: {:ok, Csvm.AST.t()} | :ok | {:error, String.t()}
end
