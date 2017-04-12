defmodule Farmbot.CeleryScript.Command.Zero do
  @moduledoc """
    Zero
  """

  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Zero
    args: %{axis: axis},
    body: []
  """
  @spec run(%{axis: any}, []) :: no_return
  def run(%{axis: _axis}, []) do
    Logger.warn "ZERO IS TODO"
  end

end
