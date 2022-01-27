defmodule FarmbotOS.Celery.VariableTransformerTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotOS.Celery.Compiler.VariableTransformer
  alias FarmbotOS.Celery.SysCallGlue.Stubs

  setup :verify_on_exit!

  test "text types" do
    text = %{kind: :text, args: %{string: "Hello, world!"}}
    actual = VariableTransformer.run!(text)
    assert actual == ["Hello, world!"]
  end

  test "numeric types" do
    num = %{kind: :numeric, args: %{number: 26}}
    actual = VariableTransformer.run!(num)
    assert actual == [26]
  end

  test "always has an x/y/z value at root" do
    actual = VariableTransformer.run!(%{x: 1, y: 2, z: 3.4})
    expected = [%{x: 1, y: 2, z: 3.4}]
    assert actual == expected

    actual =
      VariableTransformer.run!(%{
        x: 1,
        y: 2,
        z: 3.4,
        args: %{x: 1, y: 2, z: 3.4}
      })

    expected = [%{x: 1, y: 2, z: 3.4, args: %{x: 1, y: 2, z: 3.4}}]
    assert actual == expected

    error2 = "LUA ERROR: Sequence does not contain variable"

    actual = VariableTransformer.run!(:misc)
    expected = [:misc]
    assert actual == expected

    actual = VariableTransformer.run!(nil)
    expected = [%{kind: :error, error: error2, x: nil, y: nil, z: nil}, error2]
    assert actual == expected

    fake_stuff = %{
      name: "broccoli",
      resource_id: 1,
      resource_type: "Plant",
      x: 80.0,
      y: 80.0,
      z: 0.0
    }

    expect(Stubs, :point, 1, fn _kind, _id -> fake_stuff end)

    cs_point = %{args: %{pointer_id: 123, pointer_type: "Point"}}

    actual = VariableTransformer.run!(cs_point)
    expected = [fake_stuff]
    assert actual == expected
  end

  test "CS Resource" do
    id = 999_999
    _ = FarmbotOS.Asset.new_sequence!(%{id: id})
    params = %{args: %{resource_id: id, resource_type: "Sequence"}}

    result =
      VariableTransformer.run!(params)
      |> List.first()
      |> Map.new()

    expected = %{
      "args" => nil,
      "body" => nil,
      "id" => 999_999,
      "kind" => nil,
      "name" => nil
    }

    assert result == expected
  end

  test "CS Resource - not known" do
    unknown = %{args: %{resource_id: 111, resource_type: "Foo"}}
    [result] = VariableTransformer.run!(unknown)
    assert result == unknown
  end

  test "CS Resource - not found" do
    not_found = %{args: %{resource_id: 111, resource_type: "Sequence"}}
    [result] = VariableTransformer.run!(not_found)
    refute result
  end
end
