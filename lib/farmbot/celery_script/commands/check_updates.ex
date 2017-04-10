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
  @spec run(%{package: package}, []) :: no_return
  def run(%{package: package}, []) do
    case package do
      "arduino_firmware" ->
        Logger.warn "Arduino Firmware is now coupled to farmbot_os and can't " <>
        "updated individually.", channels: :toast
      "farmbot_os" ->
        Farmbot.System.Updates.check_and_download_updates()

      u -> Logger.info ">> got a request to check updates for an " <>
        "unrecognized package: #{u}"
    end
  end
end
