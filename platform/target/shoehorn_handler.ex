defmodule Farmbot.ShoehornHandler do
  use Shoehorn.Handler
  require Logger

  def init do
    {:ok, %{}}
  end

  def application_exited(:farmbot, reason, state) do
    Logger.error "Farmbot exited: #{inspect reason}"
    Application.ensure_all_started(:farmbot)
    {:continue, state}
  end

  def application_exited(_app, _reason, state) do
    {:continue, state}
  end
end
