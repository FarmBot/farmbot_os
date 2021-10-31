defmodule FarmbotOS.LoggerTest do
  use ExUnit.Case
  alias FarmbotOS.{Log, Asset.Repo}
  import Ecto.Query
  import ExUnit.CaptureLog
  require FarmbotOS.Logger

  def create_log(msg) do
    FarmbotOS.Logger.debug(1, msg)
  end

  def clear_logs(), do: Repo.delete_all(Log)
  def log_count(), do: Repo.one(from(l in "logs", select: count(l.id)))

  test "captures excess logs" do
    clear_logs()
    assert log_count() == 0
    ["log 1", "log 2", "log 3"] |> Enum.map(&create_log/1)
    assert log_count() == 3
    FarmbotOS.Logger.maybe_truncate_logs!(2)
    assert log_count() == 0
  end

  @tag :capture_log
  test "allows handling a log more than once by re-inserting it." do
    log = FarmbotOS.Logger.debug(1, "Test log ABC")
    # Handling a log should delete it from the store.
    assert Enum.find(
             FarmbotOS.Logger.handle_all_logs(),
             &Kernel.==(Map.fetch!(&1, :id), log.id)
           )

    # Thus, handling all logs again should mean the log
    # isn't there any more
    refute Enum.find(
             FarmbotOS.Logger.handle_all_logs(),
             &Kernel.==(Map.fetch!(&1, :id), log.id)
           )

    # insert the log again
    assert FarmbotOS.Logger.insert_log!(Map.from_struct(log))

    # Make sure the log is available for handling again.
    assert Enum.find(
             FarmbotOS.Logger.handle_all_logs(),
             &Kernel.==(Map.fetch!(&1, :id), log.id)
           )
  end

  test "insert_log!/1 - unknown format" do
    t = fn -> FarmbotOS.Logger.insert_log!(%{foo: :bar}) end
    assert capture_log(t) =~ "Can't decode log: %{foo: :bar}"
  end
end
