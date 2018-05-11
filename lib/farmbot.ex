defmodule Farmbot do
  @moduledoc """
  Supervises the individual modules that make up the Farmbot Application.
  This is the entry point of the application.
  """

  require Farmbot.Logger
  require Logger
  use Application

  @version Farmbot.Project.version()
  @commit Farmbot.Project.commit()

  @doc false
  def start(type, start_opts)

  def start(_, _start_opts) do
    case Supervisor.start_link(__MODULE__, [], [name: __MODULE__]) do
      {:ok, pid} -> {:ok, pid, []}
      error ->
        IO.puts "Failed to boot Farmbot: #{inspect error}"
        Farmbot.System.factory_reset(error)
        exit(error)
    end
  end

  def init([]) do
    Logger.remove_backend :console
    RingLogger.attach()
    children = [
      {Farmbot.Logger.Supervisor, []},
      {Farmbot.System.Supervisor, []},
      {Farmbot.Bootstrap.Supervisor, []}
    ]

    Farmbot.Logger.info(1, "Booting Farmbot OS version: #{@version} - #{@commit}")
    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  def prep_stop(_state) do
    logs = RingLogger.get()
    formatted = Enum.map(logs, fn(level, {_logger, message, timestamp_tup, _meta}) ->
      # {{year, month, day}, {hour, minute, second, _}} = timestamp_tup
      timestamp  = Timex.to_datetime(timestamp_tup) |> DateTime.to_iso8601()
      "[#{level} #{timestamp}] - #{message}"
    end)
    |> Enum.join("\n")
    |> Farmbot.System.stop()
    formatted
  end

  def stop(_data) do
    :ok
  end

end
