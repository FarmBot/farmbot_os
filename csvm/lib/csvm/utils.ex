defmodule Csvm.Utils do
  @moduledoc """
  Common Csvm utilities
  """
  alias Csvm.AST

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
  @spec exception(Csvm.FarmProc.t(), String.t()) :: no_return
  def exception(farm_proc, message) when is_binary(message) do
    raise(Csvm.Error, farm_proc: farm_proc, message: message)
  end
end
