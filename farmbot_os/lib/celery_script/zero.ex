defmodule Farmbot.OS.IOLayer.Zero do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(%{axis: "all"} = args, body) do
    with :ok <- execute(%{args | axis: "z"}, body),
         :ok <- execute(%{args | axis: "y"}, body),
         :ok <- execute(%{args | axis: "x"}, body) do
      :ok
    end
  end

  def execute(%{axis: axis}, _body) do
    command = {:position_write_zero, [String.to_existing_atom(axis)]}

    case Firmware.command(command) do
      :ok -> :ok
      _ -> {:error, "Firmware Error"}
    end
  end
end
