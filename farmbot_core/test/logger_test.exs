defmodule FarmbotCore.LoggerTest do
  use ExUnit.Case
  require FarmbotCore.Logger

  alias FarmbotCore.{Log, Logger.Repo}

  import Ecto.Query

  def create_log(msg), do: FarmbotCore.Logger.debug(1, msg)
  def clear_logs(), do: Repo.delete_all(Log)
  def log_count(), do: Repo.one(from(l in "logs", select: count(l.id)))

  test "captures excess logs" do
    clear_logs()
    assert log_count() == 0
    ["log 1", "log 2", "log 3"] |> Enum.map(&create_log/1)
    assert log_count() == 3
    FarmbotCore.Logger.maybe_truncate_logs!(2)
    assert log_count() == 0
  end

  @tag :capture_log
  test "allows handling a log more than once by re-inserting it." do
    log = FarmbotCore.Logger.debug(1, "Test log ABC")
    # Handling a log should delete it from the store.
    assert Enum.find(
             FarmbotCore.Logger.handle_all_logs(),
             &Kernel.==(Map.fetch!(&1, :id), log.id)
           )

    # Thus, handling all logs again should mean the log
    # isn't there any more
    refute Enum.find(
             FarmbotCore.Logger.handle_all_logs(),
             &Kernel.==(Map.fetch!(&1, :id), log.id)
           )

    # insert the log again
    assert FarmbotCore.Logger.insert_log!(Map.from_struct(log))

    # Make sure the log is available for handling again.
    assert Enum.find(
             FarmbotCore.Logger.handle_all_logs(),
             &Kernel.==(Map.fetch!(&1, :id), log.id)
           )
  end
end
