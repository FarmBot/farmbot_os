defmodule SerializedTest do
  use ExUnit.Case, async: true
  test "it serializes a state object" do
    t = %Serialized{}
    assert is_map(t) == true
  end
end
