defmodule Farmbot.CeleryScript.Utils do
  @moduledoc """
  Common Farmbot.CeleryScript.RunTime utilities
  """
  alias Farmbot.CeleryScript.AST

  @doc "Build a new AST."
  @spec ast(AST.kind(), AST.args(), AST.body()) :: AST.t()
  def ast(kind, args, body \\ []), do: AST.new(kind, args, body)

  @doc "Build a new pointer."
  @spec ptr(Address.value(), Address.value()) :: Pointer.t()
  def ptr(page, addr),
    do: Pointer.new(Address.new(page), Address.new(addr))

  @doc "Build a new address."
  @spec addr(Address.value()) :: Address.t()
  def addr(val), do: Address.new(val)

  # @compile {:inline, exception: 2}
  @spec exception(Farmbot.CeleryScript.RunTime.FarmProc.t(), String.t()) :: no_return
  def exception(farm_proc, message) when is_binary(message) do
    raise(Farmbot.CeleryScript.RunTime.Error, farm_proc: farm_proc, message: message)
  end
end
