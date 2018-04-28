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
end

defimpl Inspect, for: Farmbot.Firmware.Command do
  def inspect(obj, _) do
    "#{obj.fun}(#{Enum.join(obj.args, ", ")})"
  end
end

defimpl String.Chars, for: Farmbot.Firmware.Command do
  def to_string(obj) do
    "#{obj.fun}(#{Enum.join(obj.args, ", ")})"
  end
end
