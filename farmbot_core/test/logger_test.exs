defmodule FarmbotCore.LoggerTest do
  use ExUnit.Case
  require FarmbotCore.Logger

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
    assert FarmbotCore.Logger.insert_log!(log)

    # Make sure the log is available for handling again.
    assert Enum.find(
             FarmbotCore.Logger.handle_all_logs(),
             &Kernel.==(Map.fetch!(&1, :id), log.id)
           )
  end
end
