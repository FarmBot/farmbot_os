defmodule FarmbotOS.Platform.Target.ShoehornHandler do
  @moduledoc """
  Custom shoehorn handler responsible for restarting farmbot applications
  in the correct order
  """

  use Shoehorn.Handler
  require FarmbotTelemetry
  require Logger

  @impl true
  def init(_opts) do
    {:ok, %{restart_counts: 0}}
  end

  @impl true
  def application_exited(:nerves_runtime, _, state) do
    # https://github.com/nerves-project/nerves_runtime/issues/152
    _ =
      System.cmd("killall", ["-9", "kmsg_tailer"],
        into: IO.stream(:stdio, :line)
      )

    {:continue, state}
  end

  def application_exited(app, reason, %{restart_counts: count} = state)
      when count >= 5 do
    error_log(
      "Farmbot app: #{app} exited #{count}: #{inspect(reason, limit: :infinity)}"
    )

    # Force a factory reset.
    # FarmbotOS.System.factory_reset(
    #   "Farmbot app: #{app} exited #{count}: #{inspect(reason, limit: :infinity)}"
    # )

    # FarmbotTelemetry.event(:shoehorn, :application_exit, nil, application: app)

    {:continue, %{state | restart_counts: count + 1}}
  end

  def application_exited(app, reason, %{restart_counts: count} = state) do
    error_log(
      "Farmbot app: #{app} exited #{count}: #{inspect(reason, limit: :infinity)}"
    )

    # FarmbotTelemetry.event(:shoehorn, :application_exit, nil, application: app)

    with {:ok, _} <- Application.ensure_all_started(:farmbot) do
      success_log("Recovered from application exit")
    end

    {:continue, %{state | restart_counts: count + 1}}
  end

  def application_exited(app, reason, state) do
    error_log(
      "Application stopped: #{inspect(app)} #{inspect(reason, limit: :infinity)}"
    )

    # FarmbotTelemetry.event(:shoehorn, :application_exit, nil, application: app)
    # Application.ensure_all_started(app)
    {:continue, state}
  end

  def error_log(msg) do
    try do
      Logger.error(msg)
      :ok
    catch
      _, _ ->
        Logger.error(msg)
    end
  end

  def success_log(msg) do
    try do
      Logger.info(msg)
      :ok
    catch
      _, _ ->
        Logger.info(msg)
    end
  end
end
