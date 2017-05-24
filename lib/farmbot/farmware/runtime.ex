defmodule Farmbot.Farmware.Runtime do
  @moduledoc """
    Executes a farmware
  """
  use Farmbot.DebugLog
  alias Farmbot.{Farmware, Context}
  alias Farmware.RuntimeError, as: FarmwareRuntimeError

  @doc """
    Executes a Farmware inside a safe sandbox
  """
  def execute(%Context{} = _ctx, %Farmware{} = _fw) do
    raise FarmwareRuntimeError, "Farmware Runtime todo!"
  end
end
