defmodule Farmbot.CeleryScript.Command.CheckUpdates do
  @moduledoc """
    CheckUpdates
  """

  require Logger
  alias Farmbot.CeleryScript.{Command, Error}
  @behaviour Command

  @doc ~s"""
    Checks updates for given package
      args: %{package: "farmbot_os"},
      body: []
  """
  @type package :: String.t # "farmbot_os"
  @spec run(%{package: package}, [], Context.t) :: Context.t
  def run(%{package: package}, [], context) do
    case package do
      "arduino_firmware" ->
        raise Error, context: context,
          message: "arduino firmware is now bundled into the OS."

      "farmbot_os" ->
        Farmbot.System.Updates.check_and_download_updates(context)

      u -> raise(Error, message: "unknown package: #{u}", context: context)
    end
    context
  end
end
