Enum.all?([
  Syncables.DeviceTest,
  # Syncables.PeripheralTest,
  # Syncables.RegimenItemTest,
  # Syncables.RegimenTest,
  # Syncables.SequenceTest,
  # Syncables.ToolBayTest,
  # Syncables.ToolSlotTest,
  # Syncables.ToolTest,
  # Syncables.UserTest
  ], fn(mod) ->
    defmodule mod do
      @moduledoc false
      use ExUnit.Case, async: true
      use SyncableHelper, __MODULE__
    end
  end)
