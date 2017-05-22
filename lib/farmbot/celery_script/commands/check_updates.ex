defmodule Farmbot.CeleryScript.Command.CheckUpdates do
  @moduledoc """
    CheckUpdates
  """

  require Logger
  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    Checks updates for given package
      args: %{package: "farmbot_os"},
      body: []
  """
  @type package :: String.t # "farmbot_os"
  @spec run(%{package: package}, [], Ast.context) :: Ast.context
  def run(%{package: package}, [], context) do
    case package do
      "arduino_firmware" ->
        raise "arduino firmware is now bundled into the OS."

      "farmbot_os" ->
        Farmbot.System.Updates.check_and_download_updates()

      u -> raise("unknown package: #{u}")
    end
    context
  end
end
