defmodule Mix.Tasks.Farmbot.FactoryReset do
  @moduledoc "Helper task for resetting development environment."
  use Mix.Config

  def run([]) do
    # Application.ensure_all_started(:farmbot_os)
    Farmbot.System.factory_reset("Mix task")
    :init.stop()
  end
end
