defmodule FarmbotCore.Firmware do
  def command(_), do: wip("command")
  def request(_), do: wip("request")
  def arduino_commit(), do: "WORK_IN_PROGRESS_000000"
  def wip(name), do: {:error, "Not yet implemented: #{inspect(name)}"}
end
