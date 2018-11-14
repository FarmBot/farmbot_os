defmodule Farmbot.OS.IOLayer.MoveAbsolute do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(args, _body) do
    IO.inspect(args, label: "move_abs")
    {:error, "stubbed"}
  end
end
