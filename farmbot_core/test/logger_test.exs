defmodule FarmbotCore.LoggerTest do
  use ExUnit.Case
  require FarmbotCore.Logger

  alias FarmbotCore.{Log, Logger.Repo}

  import Ecto.Query
  import ExUnit.CaptureLog

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

  @fake_msg %Log{
    message: "Hello, world!",
    verbosity: 3,
    level: :info,
    updated_at: ~U[1998-11-07 16:52:31.618000Z]
  }

  test "insert_log!/1 - unknown format" do
    t = fn -> FarmbotCore.Logger.insert_log!(%{foo: :bar}) end
    assert capture_log(t) =~ "Can't decode log: %{foo: :bar}"
  end

  # test "insert_log!/1 - pass in a %Log{}" do
  #   result1 = FarmbotCore.Logger.insert_log!(@fake_msg)

  #   expected1 = %Log{
  #     duplicates: 0,
  #     env: "test",
  #     message: "Hello, world!",
  #     target: "host"
  #   }

  #   assert result1.duplicates == expected1.duplicates
  #   assert result1.env == expected1.env
  #   assert result1.message == expected1.message
  #   assert result1.target == expected1.target

  #   result2 = FarmbotCore.Logger.insert_log!(@fake_msg)

  #   expected2 = %Log{
  #     duplicates: 1,
  #     env: "test",
  #     message: "Hello, world!",
  #     target: "host"
  #   }

  #   assert result2.duplicates == expected2.duplicates
  #   assert result2.env == expected2.env
  #   assert result2.message == expected2.message
  #   assert result2.target == expected2.target
  # end
end
