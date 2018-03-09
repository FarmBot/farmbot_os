defmodule Farmbot.CeleryScript.AST.Arg.PinType do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg
  alias Farmbot.Repo.Peripheral

  def decode("Peripheral"),   do: {:ok, Peripheral}
  def encode(Peripheral),     do: {:ok, "Peripheral"}
end
