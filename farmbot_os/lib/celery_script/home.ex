defmodule Farmbot.OS.IOLayer.Home do
  @moduledoc false

  alias Farmbot.Firmware

  def execute(%{axis: "all"}, _body) do
    command([:x, :y, :z])
  end

  def execute(%{axis: "x"}, _body) do
    command([:x])
  end

  def execute(%{axis: "y"}, _body) do
    command([:y])
  end

  def execute(%{axis: "z"}, _body) do
    command([:z])
  end

  defp command(args) do
    case Firmware.command({:command_movement_home, args}) do
      :ok -> :ok
      _ -> {:error, "Firmware Error"}
    end
  end
end
