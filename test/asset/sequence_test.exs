defmodule FarmbotOS.Asset.SequenceTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.Sequence

  @expected_keys [:id, :name, :kind, :args, :body]

  test "render/1" do
    result = Sequence.render(%Sequence{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
