defmodule FarmbotExt.Bootstrap.DropPasswordTaskTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotExt.Bootstrap.DropPasswordTask

  test "drop_password (nil)" do
    result = DropPasswordTask.drop_password(%{password: nil}, %{})
    assert result == {:noreply, %{}, :hibernate}
  end
end
