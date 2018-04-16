defmodule Farmbot.Firmware.Command do
  @moduledoc """
  Structured data to be sent to the Firmware.
  """
  alias Farmbot.Firmware.Command

  defstruct [:fun, :args, :from, :status]

  @doc "Add a status message to the Command."
  def add_status(%Command{} = command, status) do
    %{command | status: (command.status || []) ++ [status]}
  end

  def add_status(not_command, _), do: not_command

  def format_args(%Farmbot.Firmware.Vec3{x: x, y: y, z: z}) do
    "#{Farmbot.Firmware.Vec3.fmnt_float(x)}, #{Farmbot.Firmware.Vec3.fmnt_float(y)}, #{Farmbot.Firmware.Vec3.fmnt_float(z)}"
  end

  def format_args(arg) when is_atom(arg), do: to_string(arg)
  def format_args(arg) when is_binary(arg), do: arg
  def format_args(arg), do: inspect(arg)
end

defimpl Inspect, for: Farmbot.Firmware.Command do
  def inspect(cmd, _) do
    args = Enum.map(cmd.args, &Farmbot.Firmware.Command.format_args(&1))
    "#{cmd.fun}(#{Enum.join(args, ", ")})"
  end
end

defimpl String.Chars, for: Farmbot.Firmware.Command do
  def to_string(cmd) do
    args = Enum.map(cmd.args, &Farmbot.Firmware.Command.format_args(&1))
    "#{cmd.fun}(#{Enum.join(args, ", ")})"
  end
end
