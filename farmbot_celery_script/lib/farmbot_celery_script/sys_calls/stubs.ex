defmodule FarmbotCeleryScript.SysCalls.Stubs do
  @moduledoc """
  SysCall implementation that doesn't do anything. Useful for tests.
  """
  # @behaviour FarmbotCeleryScript.SysCalls

  require Logger

  @doc false
  def unquote(:"$handle_undefined_function")(function, args) do
    args = Enum.map(args, &inspect/1) |> Enum.join(", ")
    Logger.error("CeleryScript syscall stubbed: \n\n\t #{function}(#{args})")
    {:error, "SysCall stubbed by #{__MODULE__}"}
  end
end
